import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'cache/sqlite_message_cache.dart';
import 'paginated_message_service.dart';
import 'fireauth.dart';
import 'firedata.dart';
import 'firestore.dart';

import 'user_cache.dart';
import 'follow_cache.dart';
import 'topic_cache.dart';
import 'tribe_cache.dart';
import 'chat_cache.dart';
import 'report_cache.dart';
import 'settings.dart';
import 'server_clock.dart';

import 'error_recovery_service.dart';

class ServiceLocator {
  static ServiceLocator? _instance;
  static ServiceLocator get instance => _instance ??= ServiceLocator._();

  ServiceLocator._();

  // Services
  SqliteMessageCache? _sqliteCache;
  PaginatedMessageService? _paginatedMessageService;
  ErrorRecoveryService? _errorRecoveryService;

  bool _isInitialized = false;
  bool _isInitializing = false;
  String? _initializationError;
  DateTime? _initializationTime;

  /// Check if services are properly initialized
  bool get isInitialized => _isInitialized;

  /// Check if services are currently being initialized
  bool get isInitializing => _isInitializing;

  /// Get initialization error if any
  String? get initializationError => _initializationError;

  /// Get time when services were initialized
  DateTime? get initializationTime => _initializationTime;

  /// Initialize all services with enhanced error handling and tracking
  Future<void> initialize() async {
    if (_isInitialized) return;
    if (_isInitializing) {
      // Wait for ongoing initialization
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return;
    }

    _isInitializing = true;
    _initializationError = null;

    try {
      if (kDebugMode) {
        print('ServiceLocator: Starting initialization...');
      }

      // Initialize SQLite cache first
      if (kDebugMode) {
        print('ServiceLocator: Creating SQLite cache instance...');
      }
      _sqliteCache = SqliteMessageCache();

      // Initialize the database
      if (kDebugMode) {
        print('ServiceLocator: Initializing SQLite database...');
      }
      try {
        await _sqliteCache!.database;
        if (kDebugMode) {
          print('ServiceLocator: SQLite database initialized successfully');
        }
      } catch (e) {
        if (kDebugMode) {
          print('ServiceLocator: SQLite database initialization failed: $e');
        }
        throw Exception('Failed to initialize local database: ${e.toString()}');
      }

      // Perform initial cleanup of old messages (older than 30 days)
      if (kDebugMode) {
        print('ServiceLocator: Starting database cleanup...');
      }
      try {
        await _sqliteCache!.cleanupOldMessages(maxAgeInDays: 30);
        if (kDebugMode) {
          print('ServiceLocator: Database cleanup completed');
        }
      } catch (e) {
        if (kDebugMode) {
          print('ServiceLocator: Database cleanup failed: $e');
        }
        // Cleanup failure is not critical, continue
      }

      // Initialize error recovery service (optional)
      if (kDebugMode) {
        print('ServiceLocator: Initializing error recovery service...');
      }
      try {
        _errorRecoveryService = ErrorRecoveryService();
        if (kDebugMode) {
          print('ServiceLocator: Error recovery service initialized');
        }
      } catch (e) {
        if (kDebugMode) {
          print(
              'ServiceLocator: Error recovery service initialization failed: $e');
          print('ServiceLocator: Continuing without error recovery service');
        }
        // Error recovery service is optional, continue without it
        _errorRecoveryService = null;
      }

      _isInitialized = true;
      _initializationTime = DateTime.now();

      if (kDebugMode) {
        print('ServiceLocator: All services initialized successfully');
      }
    } catch (e) {
      _initializationError = e.toString();

      if (kDebugMode) {
        print('ServiceLocator: Failed to initialize services: $e');
        print('ServiceLocator: Stack trace: ${StackTrace.current}');
      }

      // Provide more user-friendly error messages
      String userFriendlyMessage;
      if (e.toString().contains('DatabaseException') ||
          e.toString().contains('database') ||
          e.toString().contains('SQLite')) {
        userFriendlyMessage =
            'Failed to initialize local storage. This may be due to insufficient permissions or corrupted data.';
      } else {
        userFriendlyMessage = 'Service initialization failed: ${e.toString()}';
      }

      throw Exception(userFriendlyMessage);
    } finally {
      _isInitializing = false;
    }
  }

  /// Create paginated message service with dependencies
  PaginatedMessageService createPaginatedMessageService({
    required Firedata firedata,
    required Firestore firestore,
  }) {
    if (!_isInitialized) {
      throw StateError(
          'ServiceLocator must be initialized before creating services');
    }

    _paginatedMessageService ??= PaginatedMessageService(
      firedata: firedata,
      firestore: firestore,
      cache: _sqliteCache!,
    );

    return _paginatedMessageService!;
  }

  /// Get SQLite cache instance
  SqliteMessageCache get sqliteCache {
    if (!_isInitialized || _sqliteCache == null) {
      throw StateError(
          'ServiceLocator must be initialized before accessing services');
    }
    return _sqliteCache!;
  }

  /// Get paginated message service instance
  PaginatedMessageService? get paginatedMessageService =>
      _paginatedMessageService;

  /// Get error recovery service instance (nullable)
  ErrorRecoveryService? get errorRecoveryService {
    if (!_isInitialized) {
      throw StateError(
          'ServiceLocator must be initialized before accessing services');
    }
    return _errorRecoveryService;
  }

  /// Dispose all services
  Future<void> dispose() async {
    try {
      _paginatedMessageService?.dispose();
      _errorRecoveryService?.dispose();
      await _sqliteCache?.dispose();

      _paginatedMessageService = null;
      _errorRecoveryService = null;
      _sqliteCache = null;
      _isInitialized = false;

      if (kDebugMode) {
        print('ServiceLocator: All services disposed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ServiceLocator: Error disposing services: $e');
      }
    }
  }

  /// Create providers for the widget tree
  static List<SingleChildWidget> createProviders({
    required Fireauth fireauth,
    required Firedata firedata,
    required Firestore firestore,
  }) {
    return [
      // Existing services
      Provider<Fireauth>.value(value: fireauth),
      Provider<Firedata>.value(value: firedata),
      Provider<Firestore>.value(value: firestore),

      // Singleton services
      Provider<Settings>(
        create: (_) => Settings(),
      ),
      Provider<ServerClock>(
        create: (_) => ServerClock(),
      ),

      // Cache services
      ChangeNotifierProvider<UserCache>(
        create: (_) => UserCache(),
      ),
      ChangeNotifierProvider<FollowCache>(
        create: (_) => FollowCache(),
      ),
      ChangeNotifierProvider<TopicCache>(
        create: (_) => TopicCache(),
      ),
      ChangeNotifierProvider<TribeCache>(
        create: (_) => TribeCache(firestore),
      ),
      ChangeNotifierProvider<ChatCache>(
        create: (_) => ChatCache(),
      ),
      Provider<ReportCacheService>(
        create: (_) => ReportCacheService(),
      ),

      // New optimized services
      ChangeNotifierProvider<SqliteMessageCache>(
        create: (_) => ServiceLocator.instance.sqliteCache,
      ),
      ChangeNotifierProxyProvider2<Firedata, Firestore,
          PaginatedMessageService>(
        create: (context) =>
            ServiceLocator.instance.createPaginatedMessageService(
          firedata: firedata,
          firestore: firestore,
        ),
        update: (context, firedata, firestore, previous) {
          return previous ??
              ServiceLocator.instance.createPaginatedMessageService(
                firedata: firedata,
                firestore: firestore,
              );
        },
      ),
      // Error recovery service (optional)
      if (ServiceLocator.instance.errorRecoveryService != null)
        ChangeNotifierProvider<ErrorRecoveryService>(
          create: (_) => ServiceLocator.instance.errorRecoveryService!,
        ),
    ];
  }

  /// Perform periodic maintenance tasks
  Future<void> performMaintenance() async {
    if (!_isInitialized) return;

    try {
      // Clean up old cached messages (older than 30 days)
      await _sqliteCache!.cleanupOldMessages(maxAgeInDays: 30);

      if (kDebugMode) {
        print('ServiceLocator: Maintenance tasks completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ServiceLocator: Error during maintenance: $e');
      }
    }
  }

  /// Get memory usage statistics for debugging
  Future<Map<String, dynamic>> getMemoryStats() async {
    if (!_isInitialized) {
      return {'error': 'Services not initialized'};
    }

    try {
      final stats = <String, dynamic>{};

      // Get cache statistics
      if (_sqliteCache != null) {
        // You could add methods to get cache size, message counts, etc.
        stats['sqlite_cache_initialized'] = true;
      }

      if (_paginatedMessageService != null) {
        stats['paginated_service_initialized'] = true;
        // Add pagination state statistics if needed
      }

      if (_errorRecoveryService != null) {
        stats['error_recovery_initialized'] = true;
        final errorStats = _errorRecoveryService!.getStats();
        stats['error_recovery_stats'] = {
          'total_errors': errorStats.totalErrors,
          'total_retries': errorStats.totalRetries,
          'queued_operations': errorStats.queuedOperations,
          'is_online': errorStats.isOnline,
          'is_recovering': errorStats.isRecovering,
        };
      }

      return stats;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Clear all cached data (useful for logout or data reset)
  Future<void> clearAllCache() async {
    if (!_isInitialized) return;

    try {
      await _sqliteCache?.clearAllCache();

      if (kDebugMode) {
        print('ServiceLocator: All cache cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ServiceLocator: Error clearing cache: $e');
      }
    }
  }
}
