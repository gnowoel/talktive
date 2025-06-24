import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Comprehensive logging service for the Talktive app
/// Provides structured logging, performance tracking, and error reporting
class LoggingService extends ChangeNotifier {
  static const String _prefsPrefix = 'logging_service_';
  static const int _maxMemoryLogs = 1000;
  static const int _maxFileSize = 10 * 1024 * 1024; // 10MB
  static const int _maxLogFiles = 5;
  static const Duration _logFlushInterval = Duration(seconds: 30);
  static const Duration _logCleanupInterval = Duration(hours: 6);

  // Singleton instance
  static LoggingService? _instance;
  static LoggingService get instance => _instance ??= LoggingService._();

  LoggingService._();

  // Configuration
  LogLevel _minLogLevel = LogLevel.info;
  bool _isEnabled = true;
  bool _enableFileLogging = true;
  bool _enableRemoteLogging = false;
  bool _enableConsoleLogging = kDebugMode;
  bool _enablePerformanceLogging = true;
  String? _remoteEndpoint;
  String? _apiKey;

  // Storage
  final List<LogEntry> _memoryLogs = [];
  final Map<String, List<LogEntry>> _categorizedLogs = {};
  File? _currentLogFile;
  Timer? _flushTimer;
  Timer? _cleanupTimer;

  // State tracking
  bool _isInitialized = false;
  int _totalLogsWritten = 0;
  DateTime? _lastFlushTime;
  final Map<String, int> _logCounts = {};

  // Buffer for batch operations
  final List<LogEntry> _pendingLogs = [];
  bool _isFlushingLogs = false;

  /// Initialize the logging service
  Future<void> initialize({
    LogLevel minLogLevel = LogLevel.info,
    bool enableFileLogging = true,
    bool enableRemoteLogging = false,
    bool enableConsoleLogging = kDebugMode,
    bool enablePerformanceLogging = true,
    String? remoteEndpoint,
    String? apiKey,
  }) async {
    if (_isInitialized) return;

    _minLogLevel = minLogLevel;
    _enableFileLogging = enableFileLogging;
    _enableRemoteLogging = enableRemoteLogging;
    _enableConsoleLogging = enableConsoleLogging;
    _enablePerformanceLogging = enablePerformanceLogging;
    _remoteEndpoint = remoteEndpoint;
    _apiKey = apiKey;

    await _loadConfiguration();
    await _initializeFileLogging();
    _startPeriodicTasks();

    _isInitialized = true;

    info('LoggingService initialized', category: 'system', metadata: {
      'min_level': minLogLevel.name,
      'file_logging': enableFileLogging,
      'remote_logging': enableRemoteLogging,
      'console_logging': enableConsoleLogging,
    });
  }

  /// Log a debug message
  void debug(
    String message, {
    String category = 'general',
    Map<String, dynamic>? metadata,
    String? userId,
    String? sessionId,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.debug, message, category, metadata, userId, sessionId,
        stackTrace);
  }

  /// Log an info message
  void info(
    String message, {
    String category = 'general',
    Map<String, dynamic>? metadata,
    String? userId,
    String? sessionId,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.info, message, category, metadata, userId, sessionId,
        stackTrace);
  }

  /// Log a warning message
  void warning(
    String message, {
    String category = 'general',
    Map<String, dynamic>? metadata,
    String? userId,
    String? sessionId,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.warning, message, category, metadata, userId, sessionId,
        stackTrace);
  }

  /// Log an error message
  void error(
    String message, {
    String category = 'general',
    Map<String, dynamic>? metadata,
    String? userId,
    String? sessionId,
    StackTrace? stackTrace,
    Exception? exception,
  }) {
    final errorMetadata = Map<String, dynamic>.from(metadata ?? {});
    if (exception != null) {
      errorMetadata['exception'] = exception.toString();
      errorMetadata['exception_type'] = exception.runtimeType.toString();
    }

    _log(LogLevel.error, message, category, errorMetadata, userId, sessionId,
        stackTrace);
  }

  /// Log a critical error message
  void critical(
    String message, {
    String category = 'general',
    Map<String, dynamic>? metadata,
    String? userId,
    String? sessionId,
    StackTrace? stackTrace,
    Exception? exception,
  }) {
    final criticalMetadata = Map<String, dynamic>.from(metadata ?? {});
    if (exception != null) {
      criticalMetadata['exception'] = exception.toString();
      criticalMetadata['exception_type'] = exception.runtimeType.toString();
    }

    _log(LogLevel.critical, message, category, criticalMetadata, userId,
        sessionId, stackTrace);
  }

  /// Log performance metrics
  void performance(
    String operation,
    Duration duration, {
    String category = 'performance',
    Map<String, dynamic>? metadata,
    String? userId,
    String? sessionId,
  }) {
    if (!_enablePerformanceLogging) return;

    final perfMetadata = Map<String, dynamic>.from(metadata ?? {});
    perfMetadata['duration_ms'] = duration.inMilliseconds;
    perfMetadata['operation'] = operation;

    _log(
        LogLevel.info,
        'Performance: $operation took ${duration.inMilliseconds}ms',
        category,
        perfMetadata,
        userId,
        sessionId,
        null);
  }

  /// Log user action for analytics
  void userAction(
    String action,
    String target, {
    String category = 'user_action',
    Map<String, dynamic>? metadata,
    String? userId,
    String? sessionId,
  }) {
    final actionMetadata = Map<String, dynamic>.from(metadata ?? {});
    actionMetadata['action'] = action;
    actionMetadata['target'] = target;
    actionMetadata['timestamp'] = DateTime.now().toIso8601String();

    _log(LogLevel.info, 'User action: $action on $target', category,
        actionMetadata, userId, sessionId, null);
  }

  /// Log network operation
  void network(
    String method,
    String url,
    int statusCode, {
    Duration? duration,
    int? requestSize,
    int? responseSize,
    String category = 'network',
    Map<String, dynamic>? metadata,
    String? userId,
    String? sessionId,
  }) {
    final networkMetadata = Map<String, dynamic>.from(metadata ?? {});
    networkMetadata['method'] = method;
    networkMetadata['url'] = url;
    networkMetadata['status_code'] = statusCode;

    if (duration != null) {
      networkMetadata['duration_ms'] = duration.inMilliseconds;
    }
    if (requestSize != null) {
      networkMetadata['request_size'] = requestSize;
    }
    if (responseSize != null) {
      networkMetadata['response_size'] = responseSize;
    }

    final level = statusCode >= 400 ? LogLevel.error : LogLevel.info;
    _log(level, 'Network: $method $url -> $statusCode', category,
        networkMetadata, userId, sessionId, null);
  }

  /// Get logs by category
  List<LogEntry> getLogsByCategory(String category, {int? limit}) {
    final categoryLogs = _categorizedLogs[category] ?? [];
    if (limit != null && categoryLogs.length > limit) {
      return categoryLogs.sublist(categoryLogs.length - limit);
    }
    return List.from(categoryLogs);
  }

  /// Get logs by level
  List<LogEntry> getLogsByLevel(LogLevel level, {int? limit}) {
    final levelLogs = _memoryLogs.where((log) => log.level == level).toList();
    if (limit != null && levelLogs.length > limit) {
      return levelLogs.sublist(levelLogs.length - limit);
    }
    return levelLogs;
  }

  /// Search logs by message content
  List<LogEntry> searchLogs(String query, {int? limit}) {
    final searchResults = _memoryLogs
        .where((log) => log.message.toLowerCase().contains(query.toLowerCase()))
        .toList();

    if (limit != null && searchResults.length > limit) {
      return searchResults.sublist(searchResults.length - limit);
    }
    return searchResults;
  }

  /// Get recent logs
  List<LogEntry> getRecentLogs({int limit = 100}) {
    if (_memoryLogs.length <= limit) {
      return List.from(_memoryLogs);
    }
    return _memoryLogs.sublist(_memoryLogs.length - limit);
  }

  /// Get logging statistics
  LoggingStats getStats() {
    final errorCount = _logCounts[LogLevel.error.name] ?? 0;
    final warningCount = _logCounts[LogLevel.warning.name] ?? 0;
    final criticalCount = _logCounts[LogLevel.critical.name] ?? 0;

    return LoggingStats(
      totalLogs: _totalLogsWritten,
      memoryLogs: _memoryLogs.length,
      errorCount: errorCount,
      warningCount: warningCount,
      criticalCount: criticalCount,
      categoriesTracked: _categorizedLogs.keys.length,
      lastFlushTime: _lastFlushTime,
      isFileLoggingEnabled: _enableFileLogging,
      isRemoteLoggingEnabled: _enableRemoteLogging,
      currentLogFileSize: _getCurrentLogFileSize(),
    );
  }

  /// Export logs to JSON
  Future<String> exportLogs({
    LogLevel? minLevel,
    String? category,
    DateTime? since,
    int? limit,
  }) async {
    var logsToExport = List<LogEntry>.from(_memoryLogs);

    // Apply filters
    if (minLevel != null) {
      logsToExport = logsToExport
          .where((log) => log.level.index >= minLevel.index)
          .toList();
    }

    if (category != null) {
      logsToExport =
          logsToExport.where((log) => log.category == category).toList();
    }

    if (since != null) {
      logsToExport =
          logsToExport.where((log) => log.timestamp.isAfter(since)).toList();
    }

    if (limit != null && logsToExport.length > limit) {
      logsToExport = logsToExport.sublist(logsToExport.length - limit);
    }

    final exportData = {
      'timestamp': DateTime.now().toIso8601String(),
      'total_logs': logsToExport.length,
      'filters': {
        'min_level': minLevel?.name,
        'category': category,
        'since': since?.toIso8601String(),
        'limit': limit,
      },
      'logs': logsToExport.map((log) => log.toJson()).toList(),
    };

    return jsonEncode(exportData);
  }

  /// Clear all logs
  Future<void> clearLogs() async {
    _memoryLogs.clear();
    _categorizedLogs.clear();
    _logCounts.clear();
    _pendingLogs.clear();

    if (_enableFileLogging) {
      await _rotateLogFile(force: true);
    }

    info('All logs cleared', category: 'system');
    notifyListeners();
  }

  /// Configure logging behavior
  void configure({
    LogLevel? minLogLevel,
    bool? enableFileLogging,
    bool? enableRemoteLogging,
    bool? enableConsoleLogging,
    bool? enablePerformanceLogging,
    String? remoteEndpoint,
    String? apiKey,
  }) {
    _minLogLevel = minLogLevel ?? _minLogLevel;
    _enableFileLogging = enableFileLogging ?? _enableFileLogging;
    _enableRemoteLogging = enableRemoteLogging ?? _enableRemoteLogging;
    _enableConsoleLogging = enableConsoleLogging ?? _enableConsoleLogging;
    _enablePerformanceLogging =
        enablePerformanceLogging ?? _enablePerformanceLogging;
    _remoteEndpoint = remoteEndpoint ?? _remoteEndpoint;
    _apiKey = apiKey ?? _apiKey;

    _saveConfiguration();
  }

  /// Force flush pending logs
  Future<void> flushLogs() async {
    if (_isFlushingLogs || _pendingLogs.isEmpty) return;

    _isFlushingLogs = true;

    try {
      final logsToFlush = List<LogEntry>.from(_pendingLogs);
      _pendingLogs.clear();

      if (_enableFileLogging) {
        await _writeLogsToFile(logsToFlush);
      }

      if (_enableRemoteLogging && _remoteEndpoint != null) {
        await _sendLogsToRemote(logsToFlush);
      }

      _lastFlushTime = DateTime.now();
    } catch (e) {
      // Re-add logs to pending if flush fails
      _pendingLogs.addAll(_pendingLogs);

      if (_enableConsoleLogging) {
        debugPrint('LoggingService: Failed to flush logs: $e');
      }
    } finally {
      _isFlushingLogs = false;
    }
  }

  // Private implementation

  void _log(
    LogLevel level,
    String message,
    String category,
    Map<String, dynamic>? metadata,
    String? userId,
    String? sessionId,
    StackTrace? stackTrace,
  ) {
    if (!_isEnabled || level.index < _minLogLevel.index) return;

    final entry = LogEntry(
      level: level,
      message: message,
      category: category,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
      userId: userId,
      sessionId: sessionId,
      stackTrace: stackTrace?.toString(),
    );

    _addLogEntry(entry);

    // Console logging
    if (_enableConsoleLogging) {
      _printToConsole(entry);
    }
  }

  void _addLogEntry(LogEntry entry) {
    // Add to memory logs
    _memoryLogs.add(entry);
    if (_memoryLogs.length > _maxMemoryLogs) {
      _memoryLogs.removeAt(0);
    }

    // Add to categorized logs
    _categorizedLogs[entry.category] ??= [];
    _categorizedLogs[entry.category]!.add(entry);
    if (_categorizedLogs[entry.category]!.length > _maxMemoryLogs ~/ 4) {
      _categorizedLogs[entry.category]!.removeAt(0);
    }

    // Update counters
    _logCounts[entry.level.name] = (_logCounts[entry.level.name] ?? 0) + 1;
    _totalLogsWritten++;

    // Add to pending flush queue
    _pendingLogs.add(entry);

    notifyListeners();
  }

  void _printToConsole(LogEntry entry) {
    final timestamp = entry.timestamp.toIso8601String();
    final level = entry.level.name.toUpperCase().padRight(8);
    final category = entry.category.padRight(12);

    var output = '[$timestamp] $level [$category] ${entry.message}';

    if (entry.metadata.isNotEmpty) {
      output += ' | ${jsonEncode(entry.metadata)}';
    }

    switch (entry.level) {
      case LogLevel.debug:
        debugPrint('🔍 $output');
        break;
      case LogLevel.info:
        debugPrint('ℹ️  $output');
        break;
      case LogLevel.warning:
        debugPrint('⚠️  $output');
        break;
      case LogLevel.error:
        debugPrint('❌ $output');
        break;
      case LogLevel.critical:
        debugPrint('🚨 $output');
        break;
    }

    if (entry.stackTrace != null) {
      debugPrint('Stack trace:\n${entry.stackTrace}');
    }
  }

  Future<void> _initializeFileLogging() async {
    if (!_enableFileLogging) return;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final logsDir = Directory(join(appDir.path, 'logs'));

      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }

      final logFileName =
          'talktive_${DateTime.now().millisecondsSinceEpoch}.log';
      _currentLogFile = File(join(logsDir.path, logFileName));
    } catch (e) {
      _enableFileLogging = false;
      if (_enableConsoleLogging) {
        debugPrint('LoggingService: Failed to initialize file logging: $e');
      }
    }
  }

  Future<void> _writeLogsToFile(List<LogEntry> logs) async {
    if (_currentLogFile == null || logs.isEmpty) return;

    try {
      final logLines = logs.map((log) => jsonEncode(log.toJson())).join('\n');
      await _currentLogFile!
          .writeAsString('$logLines\n', mode: FileMode.append);

      // Check if we need to rotate the log file
      await _checkLogRotation();
    } catch (e) {
      if (_enableConsoleLogging) {
        debugPrint('LoggingService: Failed to write logs to file: $e');
      }
    }
  }

  Future<void> _checkLogRotation() async {
    if (_currentLogFile == null) return;

    try {
      final fileSize = await _currentLogFile!.length();
      if (fileSize > _maxFileSize) {
        await _rotateLogFile();
      }
    } catch (e) {
      // File might not exist yet, ignore
    }
  }

  Future<void> _rotateLogFile({bool force = false}) async {
    if (_currentLogFile == null) return;

    try {
      if (!force && await _currentLogFile!.exists()) {
        // Rename current file with timestamp
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final oldPath = _currentLogFile!.path;
        final newPath = oldPath.replaceAll('.log', '_$timestamp.log');
        await _currentLogFile!.rename(newPath);
      }

      // Create new log file
      final appDir = await getApplicationDocumentsDirectory();
      final logsDir = Directory(join(appDir.path, 'logs'));
      final logFileName =
          'talktive_${DateTime.now().millisecondsSinceEpoch}.log';
      _currentLogFile = File(join(logsDir.path, logFileName));

      // Clean up old log files
      await _cleanupOldLogFiles();
    } catch (e) {
      if (_enableConsoleLogging) {
        debugPrint('LoggingService: Failed to rotate log file: $e');
      }
    }
  }

  Future<void> _cleanupOldLogFiles() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final logsDir = Directory(join(appDir.path, 'logs'));

      if (!await logsDir.exists()) return;

      final logFiles = await logsDir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.log'))
          .cast<File>()
          .toList();

      if (logFiles.length > _maxLogFiles) {
        // Sort by modification time and delete oldest
        logFiles.sort(
            (a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));

        for (int i = 0; i < logFiles.length - _maxLogFiles; i++) {
          await logFiles[i].delete();
        }
      }
    } catch (e) {
      if (_enableConsoleLogging) {
        debugPrint('LoggingService: Failed to cleanup old log files: $e');
      }
    }
  }

  Future<void> _sendLogsToRemote(List<LogEntry> logs) async {
    if (_remoteEndpoint == null || logs.isEmpty) return;

    try {
      final client = HttpClient();
      final request = await client.postUrl(Uri.parse(_remoteEndpoint!));

      request.headers.set('Content-Type', 'application/json');
      if (_apiKey != null) {
        request.headers.set('Authorization', 'Bearer $_apiKey');
      }

      final payload = {
        'timestamp': DateTime.now().toIso8601String(),
        'app_version': '1.0.0', // Should come from app configuration
        'logs': logs.map((log) => log.toJson()).toList(),
      };

      request.write(jsonEncode(payload));

      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception(
            'Remote logging failed with status: ${response.statusCode}');
      }

      client.close();
    } catch (e) {
      if (_enableConsoleLogging) {
        debugPrint('LoggingService: Failed to send logs to remote: $e');
      }
    }
  }

  void _startPeriodicTasks() {
    // Log flushing timer
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(_logFlushInterval, (timer) {
      flushLogs();
    });

    // Log cleanup timer
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(_logCleanupInterval, (timer) {
      _cleanupOldLogFiles();
    });
  }

  int _getCurrentLogFileSize() {
    try {
      return _currentLogFile?.lengthSync() ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _loadConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final levelIndex =
          prefs.getInt('${_prefsPrefix}min_level') ?? LogLevel.info.index;
      _minLogLevel =
          LogLevel.values[levelIndex.clamp(0, LogLevel.values.length - 1)];

      _isEnabled = prefs.getBool('${_prefsPrefix}enabled') ?? true;
      _enableFileLogging = prefs.getBool('${_prefsPrefix}file_logging') ?? true;
      _enableRemoteLogging =
          prefs.getBool('${_prefsPrefix}remote_logging') ?? false;
      _enableConsoleLogging =
          prefs.getBool('${_prefsPrefix}console_logging') ?? kDebugMode;
      _enablePerformanceLogging =
          prefs.getBool('${_prefsPrefix}performance_logging') ?? true;

      _remoteEndpoint = prefs.getString('${_prefsPrefix}remote_endpoint');
      _apiKey = prefs.getString('${_prefsPrefix}api_key');
    } catch (e) {
      // Use defaults if loading fails
    }
  }

  Future<void> _saveConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setInt('${_prefsPrefix}min_level', _minLogLevel.index);
      await prefs.setBool('${_prefsPrefix}enabled', _isEnabled);
      await prefs.setBool('${_prefsPrefix}file_logging', _enableFileLogging);
      await prefs.setBool(
          '${_prefsPrefix}remote_logging', _enableRemoteLogging);
      await prefs.setBool(
          '${_prefsPrefix}console_logging', _enableConsoleLogging);
      await prefs.setBool(
          '${_prefsPrefix}performance_logging', _enablePerformanceLogging);

      if (_remoteEndpoint != null) {
        await prefs.setString(
            '${_prefsPrefix}remote_endpoint', _remoteEndpoint!);
      }
      if (_apiKey != null) {
        await prefs.setString('${_prefsPrefix}api_key', _apiKey!);
      }
    } catch (e) {
      // Ignore save errors
    }
  }

  @override
  void dispose() {
    _flushTimer?.cancel();
    _cleanupTimer?.cancel();
    flushLogs(); // Final flush
    super.dispose();
  }
}

// Enums and data classes

enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

class LogEntry {
  final LogLevel level;
  final String message;
  final String category;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  final String? userId;
  final String? sessionId;
  final String? stackTrace;

  LogEntry({
    required this.level,
    required this.message,
    required this.category,
    required this.timestamp,
    required this.metadata,
    this.userId,
    this.sessionId,
    this.stackTrace,
  });

  Map<String, dynamic> toJson() {
    return {
      'level': level.name,
      'message': message,
      'category': category,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
      if (userId != null) 'user_id': userId,
      if (sessionId != null) 'session_id': sessionId,
      if (stackTrace != null) 'stack_trace': stackTrace,
    };
  }

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      level: LogLevel.values.firstWhere((l) => l.name == json['level']),
      message: json['message'],
      category: json['category'],
      timestamp: DateTime.parse(json['timestamp']),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      userId: json['user_id'],
      sessionId: json['session_id'],
      stackTrace: json['stack_trace'],
    );
  }
}

class LoggingStats {
  final int totalLogs;
  final int memoryLogs;
  final int errorCount;
  final int warningCount;
  final int criticalCount;
  final int categoriesTracked;
  final DateTime? lastFlushTime;
  final bool isFileLoggingEnabled;
  final bool isRemoteLoggingEnabled;
  final int currentLogFileSize;

  LoggingStats({
    required this.totalLogs,
    required this.memoryLogs,
    required this.errorCount,
    required this.warningCount,
    required this.criticalCount,
    required this.categoriesTracked,
    this.lastFlushTime,
    required this.isFileLoggingEnabled,
    required this.isRemoteLoggingEnabled,
    required this.currentLogFileSize,
  });
}
