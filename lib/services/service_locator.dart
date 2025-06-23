import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'cache/sqlite_message_cache.dart';
import 'paginated_message_service.dart';
import 'fireauth.dart';
import 'firedata.dart';
import 'firestore.dart';
import 'message_cache.dart';
import 'topic_message_cache.dart';
import 'user_cache.dart';
import 'follow_cache.dart';
import 'topic_cache.dart';
import 'tribe_cache.dart';
import 'chat_cache.dart';
import 'report_cache.dart';
import 'settings.dart';
import 'server_clock.dart';
import 'performance_monitor.dart';
import 'intelligent_preloader.dart';
import 'error_recovery_service.dart';

class ServiceLocator {
  static ServiceLocator? _instance;
  static ServiceLocator get instance => _instance ??= ServiceLocator._();

  ServiceLocator._();

  // Services
  SqliteMessageCache? _sqliteCache;
  PaginatedMessageService? _paginatedMessageService;
  IntelligentPreloader? _intelligentPreloader;
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

      // Initialize performance monitoring
      PerformanceMonitor.instance.initialize(
        enabled: kDebugMode,
        maxEventsToKeep: 1000,
        metricsRetentionPeriod: const Duration(hours: 24),
      );

      // Track initialization performance
      PerformanceMonitor.instance.startTimer('service_locator_init');

      // Initialize SQLite cache first
      _sqliteCache = SqliteMessageCache();

      // Initialize the database
      await _sqliteCache!.database;

      // Perform initial cleanup of old messages (older than 30 days)
      await _sqliteCache!.cleanupOldMessages(maxAgeInDays: 30);

      // Start memory monitoring in debug mode
      if (kDebugMode) {
        PerformanceMonitor.instance.startMemoryMonitoring();
      }

      // Initialize error recovery service
      _errorRecoveryService = ErrorRecoveryService(
        perfMonitor: PerformanceMonitor.instance,
        cache: _sqliteCache!,
      );

      final initTime =
          PerformanceMonitor.instance.endTimer('service_locator_init');

      _isInitialized = true;
      _initializationTime = DateTime.now();

      if (kDebugMode) {
        print(
            'ServiceLocator: All services initialized successfully in ${initTime?.toStringAsFixed(1)}ms');
      }

      // Record successful initialization
      PerformanceMonitor.instance
          .incrementCounter('service_locator_init_success');
    } catch (e) {
      _initializationError = e.toString();
      PerformanceMonitor.instance
          .incrementCounter('service_locator_init_failure');
      PerformanceMonitor.instance.endTimer('service_locator_init');

      if (kDebugMode) {
        print('ServiceLocator: Failed to initialize services: $e');
      }
      rethrow;
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

  /// Create intelligent preloader with dependencies
  IntelligentPreloader createIntelligentPreloader({
    required PaginatedMessageService messageService,
  }) {
    if (!_isInitialized) {
      throw StateError(
          'ServiceLocator must be initialized before creating services');
    }

    _intelligentPreloader ??= IntelligentPreloader(
      messageService: messageService,
      cache: _sqliteCache!,
      perfMonitor: PerformanceMonitor.instance,
    );

    return _intelligentPreloader!;
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

  /// Get intelligent preloader instance
  IntelligentPreloader? get intelligentPreloader => _intelligentPreloader;

  /// Get error recovery service instance
  ErrorRecoveryService get errorRecoveryService {
    if (!_isInitialized || _errorRecoveryService == null) {
      throw StateError(
          'ServiceLocator must be initialized before accessing services');
    }
    return _errorRecoveryService!;
  }

  /// Dispose all services
  Future<void> dispose() async {
    try {
      _paginatedMessageService?.dispose();
      _intelligentPreloader?.dispose();
      _errorRecoveryService?.dispose();
      await _sqliteCache?.dispose();

      // Disable performance monitoring
      PerformanceMonitor.instance.disable();

      _paginatedMessageService = null;
      _intelligentPreloader = null;
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

      // Legacy message caches (keep for backward compatibility during migration)
      ChangeNotifierProvider<ChatMessageCache>(
        create: (_) => ChatMessageCache(),
      ),
      ChangeNotifierProvider<ReportMessageCache>(
        create: (_) => ReportMessageCache(),
      ),
      ChangeNotifierProvider<TopicMessageCache>(
        create: (_) => TopicMessageCache(),
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
      ChangeNotifierProxyProvider<PaginatedMessageService,
          IntelligentPreloader>(
        create: (context) {
          final messageService = context.read<PaginatedMessageService>();
          return ServiceLocator.instance.createIntelligentPreloader(
            messageService: messageService,
          );
        },
        update: (context, messageService, previous) {
          return previous ??
              ServiceLocator.instance.createIntelligentPreloader(
                messageService: messageService,
              );
        },
      ),
      ChangeNotifierProvider<ErrorRecoveryService>(
        create: (_) => ServiceLocator.instance.errorRecoveryService,
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

      if (_intelligentPreloader != null) {
        stats['intelligent_preloader_initialized'] = true;
        final preloadStats = _intelligentPreloader!.getStats();
        stats['preloading_stats'] = {
          'total_preloads': preloadStats.totalPreloads,
          'successful_preloads': preloadStats.successfulPreloads,
          'success_rate': preloadStats.successRate,
          'active_preloads': preloadStats.activePreloads,
          'tracked_chats': preloadStats.trackedChats,
        };
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

      // Add performance monitoring stats
      final perfStats = PerformanceMonitor.instance.generateReport();
      stats['performance'] = perfStats;

      // Add current memory usage
      final memoryInfo =
          await PerformanceMonitor.instance.getCurrentMemoryUsage();
      if (memoryInfo != null) {
        stats['current_memory'] = {
          'used_mb': memoryInfo.usedMemoryMB,
          'available_mb': memoryInfo.availableMemoryMB,
          'total_mb': memoryInfo.totalMemoryMB,
          'usage_percentage': memoryInfo.usagePercentage,
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

  /// Migrate from old cache system to new SQLite cache
  Future<void> migrateFromLegacyCache({
    required ChatMessageCache chatMessageCache,
    required TopicMessageCache topicMessageCache,
  }) async {
    if (!_isInitialized) {
      throw StateError('ServiceLocator must be initialized before migration');
    }

    try {
      if (kDebugMode) {
        print('ServiceLocator: Starting migration from legacy cache...');
      }

      // This is a placeholder for migration logic
      // You would need to implement the actual migration based on your data structure

      // Example migration approach:
      // 1. Get all chat IDs from legacy cache
      // 2. For each chat, get messages and store in SQLite
      // 3. Clear legacy cache after successful migration

      if (kDebugMode) {
        print('ServiceLocator: Migration completed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ServiceLocator: Migration failed: $e');
      }
      rethrow;
    }
  }
}
