import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'paginated_message_service.dart';
import 'fireauth.dart';
import 'firedata.dart';
import 'firestore.dart';

import 'user_cache.dart';
import 'follow_cache.dart';
import 'topic_followers_cache.dart';
import 'message_meta_cache.dart';
import 'topic_cache.dart';
import 'tribe_cache.dart';
import 'chat_cache.dart';
import 'report_cache.dart';
import 'settings.dart';
import 'server_clock.dart';
import 'avatar.dart';
import 'logging_service.dart';

import 'error_recovery_service.dart';

class ServiceLocator {
  static ServiceLocator? _instance;
  static ServiceLocator get instance => _instance ??= ServiceLocator._();

  ServiceLocator._();

  // Services
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

  /// Initialize all services - simplified without SQLite cache
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
        print('ServiceLocator: Starting simplified initialization...');
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

      throw Exception('Service initialization failed: ${e.toString()}');
    } finally {
      _isInitializing = false;
    }
  }

  /// Create simplified paginated message service with dependencies
  PaginatedMessageService createPaginatedMessageService({
    required Firedata firedata,
    required Firestore firestore,
  }) {
    _paginatedMessageService ??= PaginatedMessageService(
      firedata,
      firestore,
    );

    return _paginatedMessageService!;
  }

  /// Get simplified paginated message service instance
  PaginatedMessageService? get paginatedMessageService =>
      _paginatedMessageService;

  /// Get error recovery service instance (nullable)
  ErrorRecoveryService? get errorRecoveryService {
    return _errorRecoveryService;
  }

  /// Dispose all services
  Future<void> dispose() async {
    try {
      // Dispose managed services
      _paginatedMessageService?.dispose();
      _errorRecoveryService?.dispose();

      // Dispose singleton cache services
      try {
        UserCache().dispose();
      } catch (e) {
        if (kDebugMode) {
          print('ServiceLocator: Error disposing UserCache: $e');
        }
      }

      try {
        FollowCache().dispose();
      } catch (e) {
        if (kDebugMode) {
          print('ServiceLocator: Error disposing FollowCache: $e');
        }
      }

      try {
        TopicCache().dispose();
      } catch (e) {
        if (kDebugMode) {
          print('ServiceLocator: Error disposing TopicCache: $e');
        }
      }

      try {
        ChatCache().dispose();
      } catch (e) {
        if (kDebugMode) {
          print('ServiceLocator: Error disposing ChatCache: $e');
        }
      }

      try {
        Avatar().dispose();
      } catch (e) {
        if (kDebugMode) {
          print('ServiceLocator: Error disposing Avatar: $e');
        }
      }

      try {
        LoggingService.instance.dispose();
      } catch (e) {
        if (kDebugMode) {
          print('ServiceLocator: Error disposing LoggingService: $e');
        }
      }

      // Note: TribeCache and TopicFollowersCache are not singletons
      // They are managed by Provider and will be disposed automatically

      _paginatedMessageService = null;
      _errorRecoveryService = null;
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
      // Core Firebase services
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

      // Cache services (keep these as they're still useful)
      ChangeNotifierProvider<UserCache>(
        create: (_) => UserCache(),
      ),
      ChangeNotifierProvider<FollowCache>(
        create: (_) => FollowCache(),
      ),
      ChangeNotifierProvider<TopicFollowersCache>(
        create: (_) => TopicFollowersCache(),
      ),
      ChangeNotifierProvider<MessageMetaCache>(
        create: (_) => MessageMetaCache(),
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

      // New simplified message service
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

  /// Get memory usage statistics for debugging
  Future<Map<String, dynamic>> getMemoryStats() async {
    try {
      final stats = <String, dynamic>{};

      if (_paginatedMessageService != null) {
        stats['simple_paginated_service_initialized'] = true;
        // Add pagination state statistics if needed
        // Could add counts of active chat/topic states, etc.
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

  /// Clear message service state (useful for logout or data reset)
  Future<void> clearAllMessageData() async {
    try {
      // Clear all pagination states
      _paginatedMessageService?.dispose();
      _paginatedMessageService = null;

      if (kDebugMode) {
        print('ServiceLocator: All message data cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('ServiceLocator: Error clearing message data: $e');
      }
    }
  }
}
