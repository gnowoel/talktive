import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'performance_monitor.dart';

/// Comprehensive error handling and recovery service for the Talktive app
/// Provides retry mechanisms, offline support, and graceful degradation
class ErrorRecoveryService extends ChangeNotifier {
  static const String _prefsPrefix = 'error_recovery_';
  static const int _maxRetries = 3;
  static const int _maxQueueSize = 1000;
  static const Duration _initialRetryDelay = Duration(seconds: 1);
  static const Duration _maxRetryDelay = Duration(minutes: 5);
  static const Duration _healthCheckInterval = Duration(seconds: 30);
  static const Duration _queueProcessingInterval = Duration(seconds: 10);

  final PerformanceMonitor _perfMonitor;

  // Connectivity monitoring
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOnline = true;
  bool _isRecovering = false;

  // Error tracking
  final Map<String, ErrorTracker> _errorTrackers = {};
  final Queue<FailedOperation> _operationQueue = Queue();
  final Map<String, ServiceHealth> _serviceHealth = {};

  // Recovery mechanisms
  Timer? _healthCheckTimer;
  Timer? _queueProcessingTimer;
  Timer? _connectivityRetryTimer;

  // Configuration
  bool _isEnabled = true;
  bool _useOfflineMode = true;
  int _maxConcurrentRetries = 5;
  double _circuitBreakerThreshold = 0.7;
  Duration _circuitBreakerTimeout = const Duration(minutes: 2);

  // State tracking
  int _activeRetries = 0;
  DateTime? _lastSuccessfulOperation;
  final Map<String, CircuitBreaker> _circuitBreakers = {};

  ErrorRecoveryService({
    required PerformanceMonitor perfMonitor,
  }) : _perfMonitor = perfMonitor {
    _initialize();
  }

  // Public API

  /// Initialize the error recovery service
  Future<void> _initialize() async {
    await _loadConfiguration();
    await _initializeConnectivityMonitoring();
    _startHealthChecking();
    _startQueueProcessing();
    _initializeCircuitBreakers();
  }

  /// Execute an operation with automatic error handling and recovery
  Future<T> executeWithRecovery<T>(
    String operationId,
    Future<T> Function() operation, {
    String? fallbackMessage,
    T? fallbackValue,
    bool useCache = true,
    bool queueIfOffline = true,
    int? maxRetries,
  }) async {
    final tracker = _getOrCreateErrorTracker(operationId);
    final circuitBreaker = _getOrCreateCircuitBreaker(operationId);

    // Check circuit breaker
    if (circuitBreaker.isOpen) {
      if (fallbackValue != null) {
        return fallbackValue;
      }
      throw CircuitBreakerException(
          'Service temporarily unavailable: $operationId');
    }

    // Check if offline and should queue
    if (!_isOnline && queueIfOffline) {
      _queueOperation(FailedOperation(
        id: _generateOperationId(),
        operationId: operationId,
        operation: operation,
        fallbackMessage: fallbackMessage,
        fallbackValue: fallbackValue,
        useCache: useCache,
        queuedAt: DateTime.now(),
      ));

      if (fallbackValue != null) {
        return fallbackValue;
      }
      throw OfflineException('Operation queued for when online: $operationId');
    }

    return await _executeWithRetry(
      operationId,
      operation,
      tracker,
      circuitBreaker,
      maxRetries ?? _maxRetries,
      fallbackMessage: fallbackMessage,
      fallbackValue: fallbackValue,
      useCache: useCache,
    );
  }

  /// Report a service error for monitoring
  void reportError(
    String serviceId,
    Exception error, {
    String? context,
    Map<String, dynamic>? metadata,
  }) {
    final tracker = _getOrCreateErrorTracker(serviceId);
    tracker.addError(error, context: context, metadata: metadata);

    _updateServiceHealth(serviceId, false);
    _perfMonitor.incrementCounter('service_errors');
    _perfMonitor.incrementCounter('service_${serviceId}_errors');

    if (kDebugMode) {
      debugPrint('ErrorRecoveryService: Error in $serviceId - $error');
    }

    notifyListeners();
  }

  /// Report a successful operation
  void reportSuccess(String serviceId) {
    final tracker = _getOrCreateErrorTracker(serviceId);
    tracker.recordSuccess();

    _updateServiceHealth(serviceId, true);
    _lastSuccessfulOperation = DateTime.now();

    final circuitBreaker = _circuitBreakers[serviceId];
    circuitBreaker?.recordSuccess();
  }

  /// Get current service health status
  Map<String, ServiceHealthStatus> getServiceHealth() {
    final status = <String, ServiceHealthStatus>{};

    for (final entry in _serviceHealth.entries) {
      final health = entry.value;
      status[entry.key] = ServiceHealthStatus(
        isHealthy: health.isHealthy,
        errorRate: health.errorRate,
        lastError: health.lastError,
        consecutiveErrors: health.consecutiveErrors,
        lastSuccessful: health.lastSuccessful,
      );
    }

    return status;
  }

  /// Get error recovery statistics
  ErrorRecoveryStats getStats() {
    final totalErrors = _errorTrackers.values
        .map((tracker) => tracker.totalErrors)
        .fold(0, (sum, count) => sum + count);

    final totalRetries = _errorTrackers.values
        .map((tracker) => tracker.totalRetries)
        .fold(0, (sum, count) => sum + count);

    final queuedOperations = _operationQueue.length;
    final activeCircuitBreakers =
        _circuitBreakers.values.where((cb) => cb.isOpen).length;

    return ErrorRecoveryStats(
      totalErrors: totalErrors,
      totalRetries: totalRetries,
      queuedOperations: queuedOperations,
      activeRetries: _activeRetries,
      isOnline: _isOnline,
      isRecovering: _isRecovering,
      activeCircuitBreakers: activeCircuitBreakers,
      lastSuccessfulOperation: _lastSuccessfulOperation,
    );
  }

  /// Force retry all queued operations
  Future<void> retryQueuedOperations() async {
    if (_isRecovering || !_isOnline) return;

    _isRecovering = true;
    notifyListeners();

    try {
      final operations = List<FailedOperation>.from(_operationQueue);
      _operationQueue.clear();

      for (final operation in operations) {
        if (_activeRetries >= _maxConcurrentRetries) break;

        try {
          await _retryOperation(operation);
        } catch (e) {
          // Re-queue if still failing
          if (_operationQueue.length < _maxQueueSize) {
            _operationQueue.add(operation);
          }
        }
      }
    } finally {
      _isRecovering = false;
      notifyListeners();
    }
  }

  /// Clear all error tracking data
  void clearErrorHistory() {
    _errorTrackers.clear();
    _serviceHealth.clear();
    _operationQueue.clear();
    _circuitBreakers.clear();
    _perfMonitor.incrementCounter('error_history_cleared');
    notifyListeners();
  }

  /// Configure error recovery behavior
  void configure({
    bool? enabled,
    bool? offlineMode,
    int? maxConcurrentRetries,
    double? circuitBreakerThreshold,
    Duration? circuitBreakerTimeout,
  }) {
    _isEnabled = enabled ?? _isEnabled;
    _useOfflineMode = offlineMode ?? _useOfflineMode;
    _maxConcurrentRetries = maxConcurrentRetries ?? _maxConcurrentRetries;
    _circuitBreakerThreshold =
        circuitBreakerThreshold ?? _circuitBreakerThreshold;
    _circuitBreakerTimeout = circuitBreakerTimeout ?? _circuitBreakerTimeout;

    _saveConfiguration();
  }

  // Private implementation

  Future<T> _executeWithRetry<T>(
    String operationId,
    Future<T> Function() operation,
    ErrorTracker tracker,
    CircuitBreaker circuitBreaker,
    int maxRetries, {
    String? fallbackMessage,
    T? fallbackValue,
    bool useCache = true,
  }) async {
    Exception? lastError;

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        _activeRetries++;
        _perfMonitor.startTimer('operation_$operationId');

        final result = await operation();

        _perfMonitor.endTimer('operation_$operationId');
        _activeRetries--;

        reportSuccess(operationId);
        return result;
      } catch (error) {
        _perfMonitor.endTimer('operation_$operationId');
        _activeRetries--;

        lastError = error is Exception ? error : Exception(error.toString());
        tracker.addError(lastError, context: 'Attempt ${attempt + 1}');
        circuitBreaker.recordFailure();

        if (attempt < maxRetries) {
          final delay = _calculateRetryDelay(attempt);
          _perfMonitor.incrementCounter('operation_retries');

          if (kDebugMode) {
            debugPrint(
                'Retrying $operationId in ${delay.inSeconds}s (attempt ${attempt + 1}/$maxRetries)');
          }

          await Future.delayed(delay);
        }
      }
    }

    // All retries failed
    reportError(operationId, lastError!);

    if (fallbackValue != null) {
      _perfMonitor.incrementCounter('fallback_used');
      return fallbackValue;
    }

    throw RetryExhaustedException(
        'Operation failed after $maxRetries retries: $operationId', lastError);
  }

  Duration _calculateRetryDelay(int attempt) {
    // Exponential backoff with jitter
    final baseDelay = _initialRetryDelay.inMilliseconds;
    final exponentialDelay = baseDelay * pow(2, attempt);
    final jitter = Random().nextInt(baseDelay ~/ 2);
    final totalDelay = exponentialDelay + jitter;

    return Duration(
        milliseconds: min(totalDelay.toInt(), _maxRetryDelay.inMilliseconds));
  }

  ErrorTracker _getOrCreateErrorTracker(String operationId) {
    return _errorTrackers.putIfAbsent(
      operationId,
      () => ErrorTracker(operationId),
    );
  }

  CircuitBreaker _getOrCreateCircuitBreaker(String operationId) {
    return _circuitBreakers.putIfAbsent(
      operationId,
      () => CircuitBreaker(
        threshold: _circuitBreakerThreshold,
        timeout: _circuitBreakerTimeout,
      ),
    );
  }

  void _queueOperation(FailedOperation operation) {
    if (_operationQueue.length >= _maxQueueSize) {
      // Remove oldest operation
      _operationQueue.removeFirst();
    }

    _operationQueue.add(operation);
    _perfMonitor.incrementCounter('operations_queued');
    notifyListeners();
  }

  Future<void> _retryOperation(FailedOperation operation) async {
    try {
      await operation.operation();
      _perfMonitor.incrementCounter('queued_operation_success');
    } catch (e) {
      _perfMonitor.incrementCounter('queued_operation_failed');
      rethrow;
    }
  }

  String _generateOperationId() {
    return 'op_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  void _updateServiceHealth(String serviceId, bool success) {
    final health = _serviceHealth.putIfAbsent(
      serviceId,
      () => ServiceHealth(serviceId),
    );

    health.update(success);
  }

  Future<void> _initializeConnectivityMonitoring() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _isOnline = !results.contains(ConnectivityResult.none);

      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        (List<ConnectivityResult> results) {
          final wasOnline = _isOnline;
          _isOnline = !results.contains(ConnectivityResult.none);

          if (!wasOnline && _isOnline) {
            _onConnectivityRestored();
          } else if (wasOnline && !_isOnline) {
            _onConnectivityLost();
          }

          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Failed to initialize connectivity monitoring: $e');
      _isOnline = true; // Assume online if we can't check
    }
  }

  void _onConnectivityRestored() {
    _perfMonitor.incrementCounter('connectivity_restored');

    if (kDebugMode) {
      debugPrint('ErrorRecoveryService: Connectivity restored');
    }

    // Retry queued operations after a short delay
    Timer(const Duration(seconds: 2), () {
      retryQueuedOperations();
    });
  }

  void _onConnectivityLost() {
    _perfMonitor.incrementCounter('connectivity_lost');

    if (kDebugMode) {
      debugPrint('ErrorRecoveryService: Connectivity lost');
    }
  }

  void _startHealthChecking() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(_healthCheckInterval, (timer) {
      _performHealthCheck();
    });
  }

  void _startQueueProcessing() {
    _queueProcessingTimer?.cancel();
    _queueProcessingTimer = Timer.periodic(_queueProcessingInterval, (timer) {
      if (_isOnline && !_isRecovering && _operationQueue.isNotEmpty) {
        retryQueuedOperations();
      }
    });
  }

  void _performHealthCheck() {
    // Check circuit breakers and reset if timeout has passed
    for (final circuitBreaker in _circuitBreakers.values) {
      circuitBreaker.checkTimeout();
    }

    // Clean up old error tracking data
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    _errorTrackers.removeWhere((key, tracker) {
      return tracker.lastError.isBefore(cutoff);
    });

    // Update performance metrics
    _perfMonitor.recordMetric(
        'error_queue_size', _operationQueue.length.toDouble());
    _perfMonitor.recordMetric('active_retries', _activeRetries.toDouble());
    _perfMonitor.recordMetric('circuit_breakers_open',
        _circuitBreakers.values.where((cb) => cb.isOpen).length.toDouble());
  }

  void _initializeCircuitBreakers() {
    // Initialize circuit breakers for common services
    final services = [
      'firebase_auth',
      'firestore',
      'realtime_database',
      'storage',
      'functions'
    ];
    for (final service in services) {
      _getOrCreateCircuitBreaker(service);
    }
  }

  Future<void> _loadConfiguration() async {
    final prefs = await SharedPreferences.getInstance();

    _isEnabled = prefs.getBool('${_prefsPrefix}enabled') ?? true;
    _useOfflineMode = prefs.getBool('${_prefsPrefix}offline_mode') ?? true;
    _maxConcurrentRetries = prefs.getInt('${_prefsPrefix}max_concurrent') ?? 5;
    _circuitBreakerThreshold =
        prefs.getDouble('${_prefsPrefix}cb_threshold') ?? 0.7;

    final timeoutMs = prefs.getInt('${_prefsPrefix}cb_timeout') ?? 120000;
    _circuitBreakerTimeout = Duration(milliseconds: timeoutMs);
  }

  Future<void> _saveConfiguration() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('${_prefsPrefix}enabled', _isEnabled);
    await prefs.setBool('${_prefsPrefix}offline_mode', _useOfflineMode);
    await prefs.setInt('${_prefsPrefix}max_concurrent', _maxConcurrentRetries);
    await prefs.setDouble(
        '${_prefsPrefix}cb_threshold', _circuitBreakerThreshold);
    await prefs.setInt(
        '${_prefsPrefix}cb_timeout', _circuitBreakerTimeout.inMilliseconds);
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _healthCheckTimer?.cancel();
    _queueProcessingTimer?.cancel();
    _connectivityRetryTimer?.cancel();
    super.dispose();
  }
}

// Supporting classes

class ErrorTracker {
  final String operationId;
  final List<ErrorRecord> errors = [];
  int totalRetries = 0;
  DateTime lastError = DateTime.now();

  ErrorTracker(this.operationId);

  int get totalErrors => errors.length;

  void addError(Exception error,
      {String? context, Map<String, dynamic>? metadata}) {
    errors.add(ErrorRecord(
      error: error,
      timestamp: DateTime.now(),
      context: context,
      metadata: metadata,
    ));
    lastError = DateTime.now();
    totalRetries++;

    // Keep only recent errors
    final cutoff = DateTime.now().subtract(const Duration(hours: 6));
    errors.removeWhere((record) => record.timestamp.isBefore(cutoff));
  }

  void recordSuccess() {
    // Reset consecutive errors on success
    errors.clear();
  }

  double getErrorRate() {
    if (errors.isEmpty) return 0.0;

    final recentCutoff = DateTime.now().subtract(const Duration(minutes: 30));
    final recentErrors =
        errors.where((e) => e.timestamp.isAfter(recentCutoff)).length;

    return recentErrors / 30.0; // Errors per minute
  }
}

class ErrorRecord {
  final Exception error;
  final DateTime timestamp;
  final String? context;
  final Map<String, dynamic>? metadata;

  ErrorRecord({
    required this.error,
    required this.timestamp,
    this.context,
    this.metadata,
  });
}

class CircuitBreaker {
  final double threshold;
  final Duration timeout;

  int _failures = 0;
  int _successes = 0;
  DateTime? _lastFailure;
  bool _isOpen = false;

  CircuitBreaker({required this.threshold, required this.timeout});

  bool get isOpen => _isOpen;

  void recordFailure() {
    _failures++;
    _lastFailure = DateTime.now();

    final total = _failures + _successes;
    if (total >= 10 && (_failures / total) >= threshold) {
      _isOpen = true;
    }
  }

  void recordSuccess() {
    _successes++;
    _isOpen = false; // Close circuit on success
  }

  void checkTimeout() {
    if (_isOpen && _lastFailure != null) {
      if (DateTime.now().difference(_lastFailure!) >= timeout) {
        _isOpen = false;
        _failures = 0;
        _successes = 0;
      }
    }
  }
}

class ServiceHealth {
  final String serviceId;
  bool isHealthy = true;
  int consecutiveErrors = 0;
  DateTime? lastError;
  DateTime? lastSuccessful;
  double errorRate = 0.0;

  ServiceHealth(this.serviceId);

  void update(bool success) {
    if (success) {
      isHealthy = true;
      consecutiveErrors = 0;
      lastSuccessful = DateTime.now();
    } else {
      consecutiveErrors++;
      lastError = DateTime.now();

      if (consecutiveErrors >= 5) {
        isHealthy = false;
      }
    }

    _calculateErrorRate();
  }

  void _calculateErrorRate() {
    // Simplified error rate calculation
    errorRate =
        consecutiveErrors > 0 ? min(consecutiveErrors / 10.0, 1.0) : 0.0;
  }
}

class FailedOperation {
  final String id;
  final String operationId;
  final Future Function() operation;
  final String? fallbackMessage;
  final dynamic fallbackValue;
  final bool useCache;
  final DateTime queuedAt;

  FailedOperation({
    required this.id,
    required this.operationId,
    required this.operation,
    this.fallbackMessage,
    this.fallbackValue,
    required this.useCache,
    required this.queuedAt,
  });
}

// Data classes for reporting

class ServiceHealthStatus {
  final bool isHealthy;
  final double errorRate;
  final DateTime? lastError;
  final int consecutiveErrors;
  final DateTime? lastSuccessful;

  ServiceHealthStatus({
    required this.isHealthy,
    required this.errorRate,
    this.lastError,
    required this.consecutiveErrors,
    this.lastSuccessful,
  });
}

class ErrorRecoveryStats {
  final int totalErrors;
  final int totalRetries;
  final int queuedOperations;
  final int activeRetries;
  final bool isOnline;
  final bool isRecovering;
  final int activeCircuitBreakers;
  final DateTime? lastSuccessfulOperation;

  ErrorRecoveryStats({
    required this.totalErrors,
    required this.totalRetries,
    required this.queuedOperations,
    required this.activeRetries,
    required this.isOnline,
    required this.isRecovering,
    required this.activeCircuitBreakers,
    this.lastSuccessfulOperation,
  });
}

// Custom exceptions

class CircuitBreakerException implements Exception {
  final String message;
  CircuitBreakerException(this.message);

  @override
  String toString() => 'CircuitBreakerException: $message';
}

class OfflineException implements Exception {
  final String message;
  OfflineException(this.message);

  @override
  String toString() => 'OfflineException: $message';
}

class RetryExhaustedException implements Exception {
  final String message;
  final Exception originalError;

  RetryExhaustedException(this.message, this.originalError);

  @override
  String toString() =>
      'RetryExhaustedException: $message (Original: $originalError)';
}
