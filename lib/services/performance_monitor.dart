import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Performance monitoring service for tracking app performance metrics
class PerformanceMonitor {
  static PerformanceMonitor? _instance;
  static PerformanceMonitor get instance =>
      _instance ??= PerformanceMonitor._();

  PerformanceMonitor._();

  // Performance metrics storage
  final Map<String, List<double>> _metrics = {};
  final Map<String, int> _counters = {};
  final Map<String, DateTime> _timers = {};
  final List<PerformanceEvent> _events = [];

  // Configuration
  bool _isEnabled = kDebugMode;
  int _maxEventsToKeep = 1000;
  Duration _metricsRetentionPeriod = const Duration(hours: 24);

  /// Initialize performance monitoring
  void initialize({
    bool enabled = true,
    int maxEventsToKeep = 1000,
    Duration metricsRetentionPeriod = const Duration(hours: 24),
  }) {
    _isEnabled = enabled;
    _maxEventsToKeep = maxEventsToKeep;
    _metricsRetentionPeriod = metricsRetentionPeriod;

    if (_isEnabled) {
      _startPeriodicCleanup();
      _logEvent('performance_monitor_initialized', {
        'enabled': enabled,
        'max_events': maxEventsToKeep,
        'retention_hours': metricsRetentionPeriod.inHours,
      });
    }
  }

  /// Start timing an operation
  void startTimer(String name) {
    if (!_isEnabled) return;
    _timers[name] = DateTime.now();
  }

  /// End timing an operation and record the duration
  double? endTimer(String name) {
    if (!_isEnabled) return null;

    final startTime = _timers.remove(name);
    if (startTime == null) return null;

    final duration =
        DateTime.now().difference(startTime).inMicroseconds / 1000.0;
    recordMetric('${name}_duration_ms', duration);

    return duration;
  }

  /// Record a numeric metric
  void recordMetric(String name, double value) {
    if (!_isEnabled) return;

    _metrics[name] ??= [];
    _metrics[name]!.add(value);

    // Keep only recent metrics to avoid memory issues
    if (_metrics[name]!.length > 1000) {
      _metrics[name]!.removeRange(0, _metrics[name]!.length - 1000);
    }

    _logEvent('metric_recorded', {
      'name': name,
      'value': value,
    });
  }

  /// Increment a counter
  void incrementCounter(String name, [int amount = 1]) {
    if (!_isEnabled) return;
    _counters[name] = (_counters[name] ?? 0) + amount;
  }

  /// Log a performance event
  void _logEvent(String type, Map<String, dynamic> data) {
    if (!_isEnabled) return;

    final event = PerformanceEvent(
      type: type,
      timestamp: DateTime.now(),
      data: data,
    );

    _events.add(event);

    // Keep only recent events
    if (_events.length > _maxEventsToKeep) {
      _events.removeRange(0, _events.length - _maxEventsToKeep);
    }

    if (kDebugMode) {
      debugPrint('PerformanceMonitor: $type - ${data.toString()}');
    }
  }

  // Message Loading Performance

  /// Track message loading performance
  void trackMessageLoad({
    required String chatId,
    required int messageCount,
    required bool fromCache,
    double? loadTimeMs,
  }) {
    if (!_isEnabled) return;

    incrementCounter('total_message_loads');
    incrementCounter(fromCache ? 'cache_hits' : 'cache_misses');
    recordMetric('messages_loaded_count', messageCount.toDouble());

    if (loadTimeMs != null) {
      recordMetric('message_load_time_ms', loadTimeMs);
    }

    _logEvent('message_load', {
      'chat_id': chatId,
      'message_count': messageCount,
      'from_cache': fromCache,
      'load_time_ms': loadTimeMs,
    });
  }

  /// Track pagination performance
  void trackPagination({
    required String chatId,
    required int pageSize,
    required bool hasMore,
    double? loadTimeMs,
  }) {
    if (!_isEnabled) return;

    incrementCounter('pagination_requests');
    recordMetric('pagination_page_size', pageSize.toDouble());

    if (loadTimeMs != null) {
      recordMetric('pagination_load_time_ms', loadTimeMs);
    }

    _logEvent('pagination', {
      'chat_id': chatId,
      'page_size': pageSize,
      'has_more': hasMore,
      'load_time_ms': loadTimeMs,
    });
  }

  // Database Performance

  /// Track SQLite operation performance
  void trackSqliteOperation({
    required String operation,
    required String table,
    int? rowCount,
    double? executionTimeMs,
  }) {
    if (!_isEnabled) return;

    incrementCounter('sqlite_operations');
    incrementCounter('sqlite_${operation}_operations');

    if (rowCount != null) {
      recordMetric('sqlite_row_count', rowCount.toDouble());
    }

    if (executionTimeMs != null) {
      recordMetric('sqlite_execution_time_ms', executionTimeMs);
    }

    _logEvent('sqlite_operation', {
      'operation': operation,
      'table': table,
      'row_count': rowCount,
      'execution_time_ms': executionTimeMs,
    });
  }

  // Memory Performance

  /// Get current memory usage (Android/iOS only)
  Future<MemoryInfo?> getCurrentMemoryUsage() async {
    if (!_isEnabled) return null;

    try {
      if (Platform.isAndroid || Platform.isIOS) {
        const platform = MethodChannel('flutter/system');
        final Map<dynamic, dynamic> memoryUsage =
            await platform.invokeMethod('SystemChrome.getSystemMemoryInfo');

        final info = MemoryInfo(
          totalMemoryMB: (memoryUsage['totalMemory'] as num?)?.toDouble() ?? 0,
          availableMemoryMB:
              (memoryUsage['availableMemory'] as num?)?.toDouble() ?? 0,
          usedMemoryMB: 0, // Calculate from total - available
        );

        info.usedMemoryMB = info.totalMemoryMB - info.availableMemoryMB;

        recordMetric('memory_used_mb', info.usedMemoryMB);
        recordMetric('memory_available_mb', info.availableMemoryMB);

        return info;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to get memory info: $e');
      }
    }

    return null;
  }

  /// Track memory usage periodically
  void startMemoryMonitoring(
      {Duration interval = const Duration(seconds: 30)}) {
    if (!_isEnabled) return;

    Timer.periodic(interval, (timer) async {
      final memoryInfo = await getCurrentMemoryUsage();
      if (memoryInfo != null) {
        _logEvent('memory_sample', {
          'used_mb': memoryInfo.usedMemoryMB,
          'available_mb': memoryInfo.availableMemoryMB,
          'total_mb': memoryInfo.totalMemoryMB,
        });
      }
    });
  }

  // Network Performance

  /// Track Firebase operation performance
  void trackFirebaseOperation({
    required String operation,
    required String collection,
    int? documentCount,
    double? networkTimeMs,
    bool? fromCache,
  }) {
    if (!_isEnabled) return;

    incrementCounter('firebase_operations');
    incrementCounter('firebase_${operation}_operations');

    if (fromCache == true) {
      incrementCounter('firebase_cache_hits');
    } else if (fromCache == false) {
      incrementCounter('firebase_cache_misses');
    }

    if (documentCount != null) {
      recordMetric('firebase_document_count', documentCount.toDouble());
    }

    if (networkTimeMs != null) {
      recordMetric('firebase_network_time_ms', networkTimeMs);
    }

    _logEvent('firebase_operation', {
      'operation': operation,
      'collection': collection,
      'document_count': documentCount,
      'network_time_ms': networkTimeMs,
      'from_cache': fromCache,
    });
  }

  // Analytics and Reporting

  /// Get performance statistics
  PerformanceStats getStats() {
    if (!_isEnabled) return PerformanceStats.empty();

    return PerformanceStats(
      metrics: Map.from(_metrics),
      counters: Map.from(_counters),
      recentEvents: List.from(_events.take(100)),
    );
  }

  /// Get average value for a metric
  double? getAverageMetric(String name) {
    if (!_isEnabled) return null;

    final values = _metrics[name];
    if (values == null || values.isEmpty) return null;

    return values.reduce((a, b) => a + b) / values.length;
  }

  /// Get cache hit ratio
  double getCacheHitRatio() {
    if (!_isEnabled) return 0.0;

    final hits = _counters['cache_hits'] ?? 0;
    final misses = _counters['cache_misses'] ?? 0;
    final total = hits + misses;

    return total > 0 ? hits / total : 0.0;
  }

  /// Generate performance report
  Map<String, dynamic> generateReport() {
    if (!_isEnabled) return {'enabled': false};

    final now = DateTime.now();

    return {
      'enabled': _isEnabled,
      'timestamp': now.toIso8601String(),
      'uptime_minutes': _getUptimeMinutes(),
      'cache_hit_ratio': getCacheHitRatio(),
      'average_message_load_time_ms': getAverageMetric('message_load_time_ms'),
      'average_sqlite_time_ms': getAverageMetric('sqlite_execution_time_ms'),
      'total_message_loads': _counters['total_message_loads'] ?? 0,
      'total_sqlite_operations': _counters['sqlite_operations'] ?? 0,
      'total_firebase_operations': _counters['firebase_operations'] ?? 0,
      'recent_events_count': _events.length,
      'memory_metrics': _getMemoryMetrics(),
      'top_slow_operations': _getSlowOperations(),
    };
  }

  /// Export performance data for analysis
  Map<String, dynamic> exportData() {
    if (!_isEnabled) return {'enabled': false};

    return {
      'metrics': _metrics,
      'counters': _counters,
      'events': _events.map((e) => e.toJson()).toList(),
      'generated_at': DateTime.now().toIso8601String(),
    };
  }

  // Utility Methods

  double _getUptimeMinutes() {
    final initEvent = _events.firstWhere(
      (e) => e.type == 'performance_monitor_initialized',
      orElse: () => PerformanceEvent(
        type: 'unknown',
        timestamp: DateTime.now(),
        data: {},
      ),
    );

    return DateTime.now().difference(initEvent.timestamp).inMinutes.toDouble();
  }

  Map<String, double> _getMemoryMetrics() {
    return {
      'avg_memory_used_mb': getAverageMetric('memory_used_mb') ?? 0,
      'avg_memory_available_mb': getAverageMetric('memory_available_mb') ?? 0,
    };
  }

  List<Map<String, dynamic>> _getSlowOperations() {
    final slowOps = <Map<String, dynamic>>[];

    _metrics.forEach((key, values) {
      if (key.endsWith('_duration_ms') && values.isNotEmpty) {
        final avgTime = values.reduce((a, b) => a + b) / values.length;
        if (avgTime > 100) {
          // Operations slower than 100ms
          slowOps.add({
            'operation': key.replaceAll('_duration_ms', ''),
            'avg_time_ms': avgTime,
            'max_time_ms': values.reduce((a, b) => a > b ? a : b),
            'count': values.length,
          });
        }
      }
    });

    slowOps.sort((a, b) =>
        (b['avg_time_ms'] as double).compareTo(a['avg_time_ms'] as double));
    return slowOps.take(10).toList();
  }

  void _startPeriodicCleanup() {
    Timer.periodic(const Duration(hours: 1), (timer) {
      _cleanupOldData();
    });
  }

  void _cleanupOldData() {
    final cutoff = DateTime.now().subtract(_metricsRetentionPeriod);

    // Remove old events
    _events.removeWhere((event) => event.timestamp.isBefore(cutoff));

    // Limit metrics data
    _metrics.forEach((key, values) {
      if (values.length > 500) {
        _metrics[key] = values.sublist(values.length - 500);
      }
    });
  }

  /// Clear all performance data
  void clear() {
    _metrics.clear();
    _counters.clear();
    _timers.clear();
    _events.clear();
  }

  /// Disable performance monitoring
  void disable() {
    _isEnabled = false;
    clear();
  }
}

// Data Classes

class PerformanceEvent {
  final String type;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  const PerformanceEvent({
    required this.type,
    required this.timestamp,
    required this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
    };
  }
}

class PerformanceStats {
  final Map<String, List<double>> metrics;
  final Map<String, int> counters;
  final List<PerformanceEvent> recentEvents;

  const PerformanceStats({
    required this.metrics,
    required this.counters,
    required this.recentEvents,
  });

  factory PerformanceStats.empty() {
    return const PerformanceStats(
      metrics: {},
      counters: {},
      recentEvents: [],
    );
  }
}

class MemoryInfo {
  final double totalMemoryMB;
  final double availableMemoryMB;
  double usedMemoryMB;

  MemoryInfo({
    required this.totalMemoryMB,
    required this.availableMemoryMB,
    required this.usedMemoryMB,
  });

  double get usagePercentage =>
      totalMemoryMB > 0 ? (usedMemoryMB / totalMemoryMB) * 100 : 0;

  @override
  String toString() {
    return 'MemoryInfo(used: ${usedMemoryMB.toStringAsFixed(1)}MB, '
        'available: ${availableMemoryMB.toStringAsFixed(1)}MB, '
        'total: ${totalMemoryMB.toStringAsFixed(1)}MB, '
        'usage: ${usagePercentage.toStringAsFixed(1)}%)';
  }
}
