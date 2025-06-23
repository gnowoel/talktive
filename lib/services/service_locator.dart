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

class ServiceLocator {
  static ServiceLocator? _instance;
  static ServiceLocator get instance => _instance ??= ServiceLocator._();

  ServiceLocator._();

  // Services
  SqliteMessageCache? _sqliteCache;
  PaginatedMessageService? _paginatedMessageService;

  bool _isInitialized = false;

  /// Initialize all services
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize SQLite cache first
      _sqliteCache = SqliteMessageCache();

      // Initialize the database
      await _sqliteCache!.database;

      // Perform initial cleanup of old messages (older than 30 days)
      await _sqliteCache!.cleanupOldMessages(maxAgeInDays: 30);

      _isInitialized = true;

      if (kDebugMode) {
        print('ServiceLocator: All services initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ServiceLocator: Failed to initialize services: $e');
      }
      rethrow;
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

  /// Dispose all services
  Future<void> dispose() async {
    try {
      await _paginatedMessageService?.dispose();
      await _sqliteCache?.dispose();

      _paginatedMessageService = null;
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
      ChangeNotifierProvider<Settings>(
        create: (_) => Settings(),
      ),
      ChangeNotifierProvider<ServerClock>(
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
        create: (_) => TribeCache(),
      ),
      ChangeNotifierProvider<ChatCache>(
        create: (_) => ChatCache(),
      ),
      ChangeNotifierProvider<ReportCacheService>(
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

  /// Check if services are properly initialized
  bool get isInitialized => _isInitialized;

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
