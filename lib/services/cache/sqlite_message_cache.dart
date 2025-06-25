import 'dart:async';
import 'dart:convert';
import 'dart:io'; // Includes gzip compression
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/message.dart';
import '../../models/image_message.dart';
import '../../models/text_message.dart';
import '../../models/topic_message.dart';
import 'database_init.dart';

class _DatabaseLock {
  final Map<String, Completer<void>> _locks = {};
  static const Duration _lockTimeout = Duration(seconds: 30);

  Future<T> withLock<T>(String key, Future<T> Function() operation) async {
    final startTime = DateTime.now();

    // Wait for any existing operation on this key with timeout
    while (_locks.containsKey(key)) {
      if (DateTime.now().difference(startTime) > _lockTimeout) {
        throw Exception('Database lock timeout for operation: $key');
      }
      await Future.delayed(const Duration(milliseconds: 100));
      if (_locks.containsKey(key)) {
        try {
          await _locks[key]!.future.timeout(const Duration(seconds: 5));
        } catch (e) {
          // If waiting times out, force remove the lock
          _locks.remove(key);
          break;
        }
      }
    }

    // Create a new lock for this operation
    final completer = Completer<void>();
    _locks[key] = completer;

    try {
      final result = await operation().timeout(_lockTimeout);
      return result;
    } catch (e) {
      debugPrint('Database operation failed for $key: $e');
      rethrow;
    } finally {
      // Release the lock
      _locks.remove(key);
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
  }
}

class SqliteMessageCache extends ChangeNotifier {
  static final _DatabaseLock _dbLock = _DatabaseLock();
  static const String _databaseName = 'talktive_cache.db';
  static const int _databaseVersion = 2;

  // Table names
  static const String _chatMessagesTable = 'chat_messages';
  static const String _topicMessagesTable = 'topic_messages';
  static const String _metadataTable = 'cache_metadata';

  // Performance constants - will be dynamically adjusted based on device capabilities
  int _maxBatchSize = 100;
  int _compressionThreshold = 1000; // Characters
  int _maxCacheSize = 50000; // Maximum messages per chat/topic
  Duration _backgroundCleanupInterval = const Duration(hours: 6);

  // Low-end device thresholds
  static const int _lowEndMemoryThresholdMB = 3072; // 3GB
  static const int _lowEndStorageThresholdGB = 32;

  // Device capability flags
  bool _isLowEndDevice = false;
  bool _isVeryLowEndDevice = false;
  int _availableMemoryMB = 0;
  int _availableStorageGB = 0;

  Database? _database;
  Timer? _backgroundCleanupTimer;
  bool _isOptimizing = false;
  bool _deviceCapabilitiesDetected = false;
  DateTime? _lastStorageCheck;
  DateTime? _lastMemoryCheck;
  int _currentMemoryUsageMB = 0;
  bool _memoryPressure = false;

  // Singleton pattern
  SqliteMessageCache._();
  static final SqliteMessageCache _instance = SqliteMessageCache._();
  factory SqliteMessageCache() => _instance;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      // Detect device capabilities first
      await _detectDeviceCapabilities();

      // Initialize database factory for the current platform
      await DatabaseInit.initialize();

      final path = await DatabaseInit.getDatabasePath(_databaseName);

      Database? db;
      int retryCount = 0;
      const maxRetries = 3;

      while (db == null && retryCount < maxRetries) {
        try {
          db = await openDatabase(
            path,
            version: _databaseVersion,
            onCreate: _onCreate,
            onUpgrade: _onUpgrade,
            onOpen: _onOpen,
          );

          if (kDebugMode) {
            print(
                'SqliteMessageCache: Database opened successfully on attempt ${retryCount + 1}');
          }
        } catch (e) {
          retryCount++;
          if (kDebugMode) {
            print(
                'SqliteMessageCache: Database open attempt $retryCount failed: $e');
          }

          if (retryCount < maxRetries) {
            // Try to recover by deleting the corrupted database
            try {
              await _deleteCorruptedDatabase(path);
              if (kDebugMode) {
                print(
                    'SqliteMessageCache: Deleted corrupted database, retrying...');
              }
            } catch (deleteError) {
              if (kDebugMode) {
                print(
                    'SqliteMessageCache: Failed to delete corrupted database: $deleteError');
              }
            }

            // Wait before retry
            await Future.delayed(Duration(milliseconds: 500 * retryCount));
          } else {
            // Final attempt failed, try in-memory database as last resort
            if (kDebugMode) {
              print(
                  'SqliteMessageCache: All attempts failed, trying in-memory database');
            }
            try {
              db = await _createInMemoryDatabase();
              if (kDebugMode) {
                print(
                    'SqliteMessageCache: In-memory database created successfully');
              }
            } catch (memoryError) {
              if (kDebugMode) {
                print(
                    'SqliteMessageCache: In-memory database creation failed: $memoryError');
              }
              throw Exception(
                  'Failed to initialize database after $maxRetries attempts. Last error: $e');
            }
          }
        }
      }

      if (db == null) {
        throw Exception(
            'Failed to initialize database after $maxRetries attempts');
      }

      // Start background cleanup timer
      _startBackgroundCleanup();

      // Perform initial cleanup if this is a low-end device
      if (_isLowEndDevice) {
        // Schedule cleanup after a short delay to not block initialization
        Timer(const Duration(seconds: 5), () async {
          await _performLowEndDeviceCleanup();
        });
      }

      return db;
    } catch (e) {
      if (kDebugMode) {
        print('SqliteMessageCache: Database initialization failed: $e');
      }
      rethrow;
    }
  }

  Future<void> _onOpen(Database db) async {
    // Try to enable WAL mode for better concurrent access, but don't fail if not supported
    try {
      await db.execute('PRAGMA journal_mode=WAL');
      if (kDebugMode) {
        print('SqliteMessageCache: WAL mode enabled successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print(
            'SqliteMessageCache: WAL mode not supported, continuing with default mode: $e');
      }
      // WAL mode is not critical, continue without it
    }

    // Apply other optimizations with error handling
    try {
      await db.execute('PRAGMA synchronous=NORMAL');
      await db.execute('PRAGMA cache_size=10000');
      await db.execute('PRAGMA temp_store=MEMORY');
      await db.execute('PRAGMA foreign_keys=ON');
      if (kDebugMode) {
        print(
            'SqliteMessageCache: Database optimizations applied successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print(
            'SqliteMessageCache: Some database optimizations failed, but continuing: $e');
      }
      // These optimizations are not critical, continue without them
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Chat messages table with optimized schema
    await db.execute('''
      CREATE TABLE $_chatMessagesTable (
        id TEXT PRIMARY KEY,
        chat_id TEXT NOT NULL,
        type TEXT NOT NULL,
        user_id TEXT NOT NULL,
        user_display_name TEXT NOT NULL,
        user_photo_url TEXT,
        content TEXT NOT NULL,
        content_compressed BLOB,
        uri TEXT,
        created_at INTEGER NOT NULL,
        recalled INTEGER DEFAULT 0,
        cached_at INTEGER NOT NULL,
        content_size INTEGER DEFAULT 0,
        is_compressed INTEGER DEFAULT 0
      )
    ''');

    // Optimized indexes for chat messages
    await db.execute('''
      CREATE INDEX idx_chat_messages_chat_created
      ON $_chatMessagesTable(chat_id, created_at DESC)
    ''');
    await db.execute('''
      CREATE INDEX idx_chat_messages_chat_cached
      ON $_chatMessagesTable(chat_id, cached_at DESC)
    ''');
    await db.execute('''
      CREATE INDEX idx_chat_messages_user
      ON $_chatMessagesTable(user_id, created_at DESC)
    ''');
    await db.execute('''
      CREATE INDEX idx_chat_messages_type
      ON $_chatMessagesTable(type, created_at DESC)
    ''');

    // Topic messages table with optimized schema
    await db.execute('''
      CREATE TABLE $_topicMessagesTable (
        id TEXT PRIMARY KEY,
        topic_id TEXT NOT NULL,
        type TEXT NOT NULL,
        user_id TEXT NOT NULL,
        user_display_name TEXT NOT NULL,
        user_photo_url TEXT,
        content TEXT NOT NULL,
        content_compressed BLOB,
        uri TEXT,
        created_at INTEGER NOT NULL,
        cached_at INTEGER NOT NULL,
        content_size INTEGER DEFAULT 0,
        is_compressed INTEGER DEFAULT 0
      )
    ''');

    // Optimized indexes for topic messages
    await db.execute('''
      CREATE INDEX idx_topic_messages_topic_created
      ON $_topicMessagesTable(topic_id, created_at DESC)
    ''');
    await db.execute('''
      CREATE INDEX idx_topic_messages_topic_cached
      ON $_topicMessagesTable(topic_id, cached_at DESC)
    ''');
    await db.execute('''
      CREATE INDEX idx_topic_messages_user
      ON $_topicMessagesTable(user_id, created_at DESC)
    ''');

    // Metadata table for tracking cache state
    await db.execute('''
      CREATE TABLE $_metadataTable (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Cache statistics table
    await db.execute('''
      CREATE TABLE cache_stats (
        stat_key TEXT PRIMARY KEY,
        stat_value INTEGER NOT NULL,
        last_updated INTEGER NOT NULL
      )
    ''');

    // Initialize cache statistics
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert('cache_stats', {
      'stat_key': 'total_queries',
      'stat_value': 0,
      'last_updated': now,
    });
    await db.insert('cache_stats', {
      'stat_key': 'cache_hits',
      'stat_value': 0,
      'last_updated': now,
    });
    await db.insert('cache_stats', {
      'stat_key': 'cache_misses',
      'stat_value': 0,
      'last_updated': now,
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database schema upgrades here
    if (oldVersion < 2 && newVersion >= 2) {
      // Add compression and optimization columns
      try {
        await db.execute(
            'ALTER TABLE $_chatMessagesTable ADD COLUMN content_compressed BLOB');
        await db.execute(
            'ALTER TABLE $_chatMessagesTable ADD COLUMN content_size INTEGER DEFAULT 0');
        await db.execute(
            'ALTER TABLE $_chatMessagesTable ADD COLUMN is_compressed INTEGER DEFAULT 0');

        await db.execute(
            'ALTER TABLE $_topicMessagesTable ADD COLUMN content_compressed BLOB');
        await db.execute(
            'ALTER TABLE $_topicMessagesTable ADD COLUMN content_size INTEGER DEFAULT 0');
        await db.execute(
            'ALTER TABLE $_topicMessagesTable ADD COLUMN is_compressed INTEGER DEFAULT 0');

        // Create new optimized indexes
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_chat_messages_chat_created ON $_chatMessagesTable(chat_id, created_at DESC)');
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_topic_messages_topic_created ON $_topicMessagesTable(topic_id, created_at DESC)');

        // Create cache stats table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS cache_stats (
            stat_key TEXT PRIMARY KEY,
            stat_value INTEGER NOT NULL,
            last_updated INTEGER NOT NULL
          )
        ''');
      } catch (e) {
        // If upgrade fails, recreate everything
        await db.execute('DROP TABLE IF EXISTS $_chatMessagesTable');
        await db.execute('DROP TABLE IF EXISTS $_topicMessagesTable');
        await db.execute('DROP TABLE IF EXISTS $_metadataTable');
        await db.execute('DROP TABLE IF EXISTS cache_stats');
        await _onCreate(db, newVersion);
      }
    }
  }

  // Chat Messages Methods
  Future<void> storeChatMessages(String chatId, List<Message> messages) async {
    if (messages.isEmpty) return;

    return _withDatabaseLock('store_chat_$chatId', () async {
      try {
        final db = await database;
        final now = DateTime.now().millisecondsSinceEpoch;

        // Use a single transaction for all operations
        await db.transaction((txn) async {
          // Process messages in batches for better performance
          // Use smaller batches for low-end devices to reduce memory pressure
          final batchSize =
              _isLowEndDevice ? (_maxBatchSize ~/ 2) : _maxBatchSize;
          final batches = _createBatches(messages, batchSize);

          for (final messageBatch in batches) {
            final batch = txn.batch();

            for (final message in messageBatch) {
              final content = message.content;
              final contentSize = content.length;
              // More aggressive compression for low-end devices
              final compressionThreshold = _isLowEndDevice
                  ? (_compressionThreshold ~/ 2)
                  : _compressionThreshold;
              final shouldCompress = contentSize > compressionThreshold;

              Map<String, dynamic> messageData = {
                'id': message.id,
                'chat_id': chatId,
                'type': message.runtimeType == ImageMessage ? 'image' : 'text',
                'user_id': message.userId,
                'user_display_name': message.userDisplayName,
                'user_photo_url': message.userPhotoURL,
                'content': shouldCompress ? '' : content,
                'content_compressed':
                    shouldCompress ? _compressString(content) : null,
                'uri': message is ImageMessage ? message.uri : null,
                'created_at': message.createdAt,
                'recalled': message.recalled ? 1 : 0,
                'cached_at': now,
                'content_size': contentSize,
                'is_compressed': shouldCompress ? 1 : 0,
              };

              batch.insert(
                _chatMessagesTable,
                messageData,
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }

            await batch.commit(noResult: true);
          }

          // Update last sync timestamp within the same transaction
          await txn.insert(
            _metadataTable,
            {
              'key': 'last_sync_chat_$chatId',
              'value': now.toString(),
              'updated_at': now,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        });

        // Perform cache size cleanup for this chat with device-appropriate limits
        await _limitCacheSize(chatId, _chatMessagesTable, 'chat_id');

        notifyListeners();
      } catch (e) {
        debugPrint('Error storing chat messages: $e');
        rethrow;
      }
    });
  }

  List<List<T>> _createBatches<T>(List<T> items, int batchSize) {
    final batches = <List<T>>[];

    // Reduce batch size further if under memory pressure
    final effectiveBatchSize = _memoryPressure ? (batchSize ~/ 2) : batchSize;

    for (int i = 0; i < items.length; i += effectiveBatchSize) {
      final end = (i + effectiveBatchSize < items.length)
          ? i + effectiveBatchSize
          : items.length;
      batches.add(items.sublist(i, end));
    }
    return batches;
  }

  List<int> _compressString(String text) {
    try {
      if (_isLowEndDevice) {
        // Use simple RLE compression for low-end devices
        final compressed = _simpleCompress(text);
        return compressed.codeUnits;
      } else {
        // Use gzip compression for better compression ratio
        final bytes = utf8.encode(text);
        final compressed = gzip.encode(bytes);
        return compressed;
      }
    } catch (e) {
      // Fallback to original text if compression fails
      return text.codeUnits;
    }
  }

  String _decompressString(List<int> compressed) {
    try {
      if (_isLowEndDevice) {
        // Handle simple RLE compression
        final text = String.fromCharCodes(compressed);
        return _simpleDecompress(text);
      } else {
        // Handle gzip compression
        try {
          final decompressed = gzip.decode(compressed);
          return utf8.decode(decompressed);
        } catch (e) {
          // Fallback to treating as uncompressed
          return String.fromCharCodes(compressed);
        }
      }
    } catch (e) {
      // Final fallback
      return String.fromCharCodes(compressed);
    }
  }

  Future<List<Message>> getChatMessages(
    String chatId, {
    int? limit,
    int? offset,
    int? minCreatedAt,
  }) async {
    return _withDatabaseLock('get_chat_$chatId', () async {
      try {
        final db = await database;

        // Apply device-specific limits to prevent memory issues
        final effectiveLimit = _getEffectiveQueryLimit(limit);

        String whereClause = 'chat_id = ?';
        List<dynamic> whereArgs = [chatId];

        if (minCreatedAt != null) {
          whereClause += ' AND created_at >= ?';
          whereArgs.add(minCreatedAt);
        }

        // For low-end devices, use more selective queries
        final columns = _isLowEndDevice
            ? [
                'id',
                'chat_id',
                'type',
                'user_id',
                'user_display_name',
                'content',
                'content_compressed',
                'uri',
                'created_at',
                'recalled',
                'is_compressed'
              ]
            : null;

        final List<Map<String, dynamic>> maps = await db.query(
          _chatMessagesTable,
          columns: columns,
          where: whereClause,
          whereArgs: whereArgs,
          orderBy: 'created_at DESC',
          limit: effectiveLimit,
          offset: offset,
        );

        final messages = maps.map((map) => _chatMessageFromMap(map)).toList();

        // Update cache statistics
        await _updateCacheStats('total_queries', 1);
        if (messages.isNotEmpty) {
          await _updateCacheStats('cache_hits', 1);
        } else {
          await _updateCacheStats('cache_misses', 1);
        }

        return messages;
      } catch (e) {
        debugPrint('Error getting chat messages for $chatId: $e');
        return <Message>[]; // Return empty list on error
      }
    });
  }

  Future<int> getChatMessageCount(String chatId, {int? minCreatedAt}) async {
    return _withDatabaseLock('count_chat_$chatId', () async {
      final db = await database;

      String whereClause = 'chat_id = ?';
      List<dynamic> whereArgs = [chatId];

      if (minCreatedAt != null) {
        whereClause += ' AND created_at >= ?';
        whereArgs.add(minCreatedAt);
      }

      final result = await db.rawQuery(
        'SELECT COUNT(*) FROM $_chatMessagesTable WHERE $whereClause',
        whereArgs,
      );

      return Sqflite.firstIntValue(result) ?? 0;
    });
  }

  Future<Message?> getLatestChatMessage(String chatId) async {
    return _withDatabaseLock('latest_chat_$chatId', () async {
      final db = await database;

      final List<Map<String, dynamic>> maps = await db.query(
        _chatMessagesTable,
        where: 'chat_id = ?',
        whereArgs: [chatId],
        orderBy: 'created_at DESC',
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return _chatMessageFromMap(maps.first);
    });
  }

  Future<int?> getLastChatMessageTimestamp(String chatId) async {
    final message = await getLatestChatMessage(chatId);
    return message?.createdAt;
  }

  // Topic Messages Methods
  Future<void> storeTopicMessages(
      String topicId, List<TopicMessage> messages) async {
    if (messages.isEmpty) return;

    return _withDatabaseLock('store_topic_$topicId', () async {
      try {
        final db = await database;
        final now = DateTime.now().millisecondsSinceEpoch;

        // Use a single transaction for all operations
        await db.transaction((txn) async {
          final batch = txn.batch();

          for (final message in messages) {
            batch.insert(
              _topicMessagesTable,
              {
                'id': message.id,
                'topic_id': topicId,
                'type':
                    message.runtimeType == TopicImageMessage ? 'image' : 'text',
                'user_id': message.userId,
                'user_display_name': message.userDisplayName,
                'user_photo_url': message.userPhotoURL,
                'content': message.content,
                'uri': message is TopicImageMessage ? message.uri : null,
                'created_at': message.createdAt.millisecondsSinceEpoch,
                'cached_at': now,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }

          await batch.commit(noResult: true);

          // Update last sync timestamp within the same transaction
          await txn.insert(
            _metadataTable,
            {
              'key': 'last_sync_topic_$topicId',
              'value': now.toString(),
              'updated_at': now,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        });

        // Perform cache size cleanup for this topic with device-appropriate limits
        await _limitCacheSize(topicId, _topicMessagesTable, 'topic_id');

        notifyListeners();
      } catch (e) {
        debugPrint('Error storing topic messages: $e');
        rethrow;
      }
    });
  }

  Future<List<TopicMessage>> getTopicMessages(
    String topicId, {
    int? limit,
    int? offset,
  }) async {
    return _withDatabaseLock('get_topic_$topicId', () async {
      try {
        final db = await database;

        // Apply device-specific limits to prevent memory issues
        final effectiveLimit = _getEffectiveQueryLimit(limit);

        // For low-end devices, use more selective queries
        final columns = _isLowEndDevice
            ? [
                'id',
                'topic_id',
                'type',
                'user_id',
                'user_display_name',
                'content',
                'content_compressed',
                'uri',
                'created_at',
                'recalled',
                'is_compressed'
              ]
            : null;

        final List<Map<String, dynamic>> maps = await db.query(
          _topicMessagesTable,
          columns: columns,
          where: 'topic_id = ?',
          whereArgs: [topicId],
          orderBy: 'created_at DESC',
          limit: effectiveLimit,
          offset: offset,
        );

        final messages = maps.map((map) => _topicMessageFromMap(map)).toList();

        // Update cache statistics
        await _updateCacheStats('total_queries', 1);
        if (messages.isNotEmpty) {
          await _updateCacheStats('cache_hits', 1);
        } else {
          await _updateCacheStats('cache_misses', 1);
        }

        return messages;
      } catch (e) {
        debugPrint('Error getting topic messages for $topicId: $e');
        return <TopicMessage>[]; // Return empty list on error
      }
    });
  }

  Future<int> getTopicMessageCount(String topicId) async {
    return _withDatabaseLock('count_topic_$topicId', () async {
      final db = await database;

      final result = await db.rawQuery(
        'SELECT COUNT(*) FROM $_topicMessagesTable WHERE topic_id = ?',
        [topicId],
      );

      return Sqflite.firstIntValue(result) ?? 0;
    });
  }

  Future<TopicMessage?> getLatestTopicMessage(String topicId) async {
    return _withDatabaseLock('latest_topic_$topicId', () async {
      final db = await database;

      final List<Map<String, dynamic>> maps = await db.query(
        _topicMessagesTable,
        where: 'topic_id = ?',
        whereArgs: [topicId],
        orderBy: 'created_at DESC',
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return _topicMessageFromMap(maps.first);
    });
  }

  Future<int?> getLastTopicMessageTimestamp(String topicId) async {
    final message = await getLatestTopicMessage(topicId);
    return message?.createdAt.millisecondsSinceEpoch;
  }

  // Cache Management Methods
  Future<void> cleanupOldMessages({int maxAgeInDays = 30}) async {
    return _withDatabaseLock('cleanup', () async {
      final db = await database;
      final cutoffTime = DateTime.now()
          .subtract(Duration(days: maxAgeInDays))
          .millisecondsSinceEpoch;

      await db.transaction((txn) async {
        await txn.delete(
          _chatMessagesTable,
          where: 'cached_at < ?',
          whereArgs: [cutoffTime],
        );

        await txn.delete(
          _topicMessagesTable,
          where: 'cached_at < ?',
          whereArgs: [cutoffTime],
        );
      });
    });
  }

  Future<void> clearChatMessages(String chatId) async {
    return _withDatabaseLock('clear_chat_$chatId', () async {
      final db = await database;
      await db.transaction((txn) async {
        await txn.delete(
          _chatMessagesTable,
          where: 'chat_id = ?',
          whereArgs: [chatId],
        );

        await txn.delete(
          _metadataTable,
          where: 'key = ?',
          whereArgs: ['last_sync_chat_$chatId'],
        );
      });
    });
  }

  Future<void> clearTopicMessages(String topicId) async {
    return _withDatabaseLock('clear_topic_$topicId', () async {
      final db = await database;
      await db.transaction((txn) async {
        await txn.delete(
          _topicMessagesTable,
          where: 'topic_id = ?',
          whereArgs: [topicId],
        );

        await txn.delete(
          _metadataTable,
          where: 'key = ?',
          whereArgs: ['last_sync_topic_$topicId'],
        );
      });
    });
  }

  Future<void> clearAllCache() async {
    return _withDatabaseLock('clear_all', () async {
      final db = await database;
      await db.transaction((txn) async {
        await txn.delete(_chatMessagesTable);
        await txn.delete(_topicMessagesTable);
        await txn.delete(_metadataTable);
      });
    });
  }

  // Helper method to wrap database operations with locking and retry
  Future<T> _withDatabaseLock<T>(
      String operation, Future<T> Function() callback) async {
    const maxRetries = 3;
    const retryDelay = Duration(milliseconds: 500);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await _dbLock.withLock('db_$operation', callback);
      } catch (e) {
        debugPrint(
            'Database operation attempt $attempt failed for $operation: $e');

        if (attempt == maxRetries) {
          // If all retries failed, check if database is corrupted
          if (e.toString().contains('database is locked') ||
              e.toString().contains('database disk image is malformed')) {
            debugPrint(
                'Database appears to be corrupted, attempting recovery...');
            try {
              await _handleCorruptedDatabase();
              // Try one more time after recovery
              return await _dbLock.withLock('db_$operation', callback);
            } catch (recoveryError) {
              debugPrint('Database recovery failed: $recoveryError');
              rethrow;
            }
          }
          rethrow;
        }

        // Wait before retry
        await Future.delayed(retryDelay * attempt);
      }
    }

    throw Exception('Unreachable code');
  }

  Future<void> _handleCorruptedDatabase() async {
    try {
      debugPrint('Attempting to recover corrupted database...');

      // Close existing database connection
      final db = _database;
      if (db != null) {
        await db.close();
        _database = null;
      }

      // Delete the corrupted database file
      final databasePath = join(await getDatabasesPath(), _databaseName);
      await _deleteCorruptedDatabase(databasePath);

      // Reinitialize the database
      _database = await _initDatabase();

      debugPrint('Database recovery completed successfully');
    } catch (e) {
      debugPrint('Database recovery failed: $e');
      rethrow;
    }
  }

  // Metadata Management
  Future<int?> getLastSyncTimestamp(String key) async {
    return _withDatabaseLock('sync_$key', () async {
      final db = await database;
      final result = await db.query(
        _metadataTable,
        where: 'key = ?',
        whereArgs: ['last_sync_$key'],
      );

      if (result.isEmpty) return null;
      return int.tryParse(result.first['value'] as String? ?? '');
    });
  }

  // Helper Methods
  Message _chatMessageFromMap(Map<String, dynamic> map) {
    final isImage = map['type'] == 'image';
    final isCompressed = map['is_compressed'] == 1;

    String content;
    if (isCompressed && map['content_compressed'] != null) {
      content = _decompressString(List<int>.from(map['content_compressed']));
    } else {
      content = map['content'] ?? '';
    }

    if (isImage) {
      return ImageMessage(
        id: map['id'],
        userId: map['user_id'] ?? '',
        userDisplayName: map['user_display_name'] ?? '',
        userPhotoURL: map['user_photo_url'] ?? '',
        content: content,
        uri: map['uri'] ?? '',
        createdAt: map['created_at'],
        recalled: map['recalled'] == 1,
      );
    } else {
      return TextMessage(
        id: map['id'],
        userId: map['user_id'] ?? '',
        userDisplayName: map['user_display_name'] ?? '',
        userPhotoURL: map['user_photo_url'] ?? '',
        content: content,
        createdAt: map['created_at'],
        recalled: map['recalled'] == 1,
      );
    }
  }

  TopicMessage _topicMessageFromMap(Map<String, dynamic> map) {
    final isImage = map['type'] == 'image';
    final isCompressed = map['is_compressed'] == 1;
    final createdAt = Timestamp.fromMillisecondsSinceEpoch(map['created_at']);

    String content;
    if (isCompressed && map['content_compressed'] != null) {
      content = _decompressString(List<int>.from(map['content_compressed']));
    } else {
      content = map['content'] ?? '';
    }

    if (isImage) {
      return TopicImageMessage(
        id: map['id'],
        userId: map['user_id'] ?? '',
        userDisplayName: map['user_display_name'] ?? '',
        userPhotoURL: map['user_photo_url'] ?? '',
        content: content,
        uri: map['uri'] ?? '',
        createdAt: createdAt,
      );
    } else {
      return TopicTextMessage(
        id: map['id'],
        userId: map['user_id'] ?? '',
        userDisplayName: map['user_display_name'] ?? '',
        userPhotoURL: map['user_photo_url'] ?? '',
        content: content,
        createdAt: createdAt,
      );
    }
  }

  Future<void> _startBackgroundCleanup() async {
    _backgroundCleanupTimer?.cancel();

    // Use device-appropriate cleanup interval
    final interval =
        _isLowEndDevice ? const Duration(hours: 2) : _backgroundCleanupInterval;

    _backgroundCleanupTimer = Timer.periodic(interval, (timer) async {
      if (!_isOptimizing) {
        await _performBackgroundMaintenance();
      }
    });
  }

  Future<void> _performBackgroundMaintenance() async {
    if (_isOptimizing) return;
    _isOptimizing = true;

    try {
      final db = await database;

      // Check storage levels and perform emergency cleanup if needed
      await _checkStorageAndCleanup();

      // Skip expensive operations on very low-end devices during peak usage
      if (!_isVeryLowEndDevice ||
          DateTime.now().hour < 8 ||
          DateTime.now().hour > 22) {
        // Vacuum database to reclaim space
        await db.execute('VACUUM');

        // Analyze tables for query optimization
        await db.execute('ANALYZE');
      }

      // Clean up old metadata entries
      final oldMetadataCutoff = DateTime.now()
          .subtract(const Duration(days: 7))
          .millisecondsSinceEpoch;
      await db.delete(
        _metadataTable,
        where: 'updated_at < ?',
        whereArgs: [oldMetadataCutoff],
      );

      // Check memory usage before expensive operations
      await _checkMemoryUsage();

      // Perform cache size management for all chats and topics
      await _performCacheSizeCleanup();

      // More frequent cleanup for low-end devices
      if (_isLowEndDevice) {
        await _performLowEndDeviceCleanup();
      }

      // Emergency memory cleanup if under pressure
      if (_memoryPressure) {
        await _performEmergencyMemoryCleanup();
      }
    } catch (e) {
      debugPrint('Background maintenance error: $e');
    } finally {
      _isOptimizing = false;
    }
  }

  Future<void> _performCacheSizeCleanup() async {
    final db = await database;

    // Get all unique chat_ids and topic_ids
    final chatIds =
        await db.rawQuery('SELECT DISTINCT chat_id FROM $_chatMessagesTable');
    final topicIds =
        await db.rawQuery('SELECT DISTINCT topic_id FROM $_topicMessagesTable');

    // Clean up each chat
    for (final row in chatIds) {
      final chatId = row['chat_id'] as String;
      await _limitCacheSize(chatId, _chatMessagesTable, 'chat_id');
    }

    // Clean up each topic
    for (final row in topicIds) {
      final topicId = row['topic_id'] as String;
      await _limitCacheSize(topicId, _topicMessagesTable, 'topic_id');
    }
  }

  Future<void> _limitCacheSize(String entityId, String table, String idColumn,
      [int? customLimit]) async {
    final db = await database;
    final limit = customLimit ?? _maxCacheSize;

    // Count messages for this entity
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $table WHERE $idColumn = ?',
      [entityId],
    );

    final messageCount = countResult.first['count'] as int;

    if (messageCount > limit) {
      // Remove oldest messages beyond the limit
      final deleteCount = messageCount - limit;
      await db.rawDelete('''
        DELETE FROM $table
        WHERE $idColumn = ?
        AND id IN (
          SELECT id FROM $table
          WHERE $idColumn = ?
          ORDER BY created_at ASC
          LIMIT ?
        )
      ''', [entityId, entityId, deleteCount]);

      debugPrint(
          'Cache cleanup: Removed $deleteCount old messages for $entityId in $table (limit: $limit)');
    }
  }

  Future<void> _updateCacheStats(String statKey, int increment) async {
    try {
      final db = await database;
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.rawUpdate('''
        UPDATE cache_stats
        SET stat_value = stat_value + ?, last_updated = ?
        WHERE stat_key = ?
      ''', [increment, now, statKey]);
    } catch (e) {
      // Ignore stats update errors to not affect main functionality
      debugPrint('Cache stats update error: $e');
    }
  }

  Future<void> _detectDeviceCapabilities() async {
    if (_deviceCapabilitiesDetected) return;

    try {
      // Try to estimate available memory and storage
      // These are conservative estimates since exact values require platform channels
      _availableMemoryMB = 4096; // Default assumption for mid-range device

      // Check available storage space
      try {
        final directory = await getApplicationDocumentsDirectory();
        final stat = directory.statSync();
        final spaceFree = stat.size;
        _availableStorageGB = (spaceFree / (1024 * 1024 * 1024)).round();
      } catch (e) {
        _availableStorageGB = 32; // Conservative default
      }

      // Classify device based on estimated capabilities
      _isLowEndDevice = _availableMemoryMB <= _lowEndMemoryThresholdMB ||
          _availableStorageGB <= _lowEndStorageThresholdGB;

      _isVeryLowEndDevice =
          _availableMemoryMB <= 2048 || _availableStorageGB <= 16;

      // Adjust cache parameters based on device capabilities
      if (_isVeryLowEndDevice) {
        _maxCacheSize = 5000; // Very conservative for very low-end devices
        _maxBatchSize = 25;
        _compressionThreshold = 200;
        _backgroundCleanupInterval = const Duration(hours: 2);
      } else if (_isLowEndDevice) {
        _maxCacheSize = 15000; // Conservative for low-end devices
        _maxBatchSize = 50;
        _compressionThreshold = 500;
        _backgroundCleanupInterval = const Duration(hours: 4);
      }

      _deviceCapabilitiesDetected = true;

      debugPrint('Device capabilities detected:');
      debugPrint('  Memory: ${_availableMemoryMB}MB');
      debugPrint('  Storage: ${_availableStorageGB}GB');
      debugPrint('  Low-end device: $_isLowEndDevice');
      debugPrint('  Very low-end device: $_isVeryLowEndDevice');
      debugPrint('  Max cache size: $_maxCacheSize');
      debugPrint('  Max batch size: $_maxBatchSize');
      debugPrint('  Compression threshold: $_compressionThreshold');
    } catch (e) {
      debugPrint('Error detecting device capabilities: $e');
      // Use conservative defaults on error
      _isLowEndDevice = true;
      _isVeryLowEndDevice = false;
      _maxCacheSize = 10000;
      _maxBatchSize = 50;
      _compressionThreshold = 500;
      _deviceCapabilitiesDetected = true;
    }
  }

  Future<void> _checkStorageAndCleanup() async {
    final now = DateTime.now();

    // Only check storage every hour to avoid performance impact
    if (_lastStorageCheck != null &&
        now.difference(_lastStorageCheck!).inHours < 1) {
      return;
    }

    _lastStorageCheck = now;

    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = directory.path;

      // Get database file size
      final dbFile = File(join(path, _databaseName));
      if (await dbFile.exists()) {
        final dbSize = await dbFile.length();
        final dbSizeMB = dbSize / (1024 * 1024);

        // If database is getting large, perform emergency cleanup
        if (dbSizeMB > 100 || (_isLowEndDevice && dbSizeMB > 50)) {
          debugPrint(
              'Database size: ${dbSizeMB.toStringAsFixed(1)}MB - performing emergency cleanup');
          await _performEmergencyCleanup();
        }
      }
    } catch (e) {
      debugPrint('Error checking storage: $e');
    }
  }

  Future<void> _performEmergencyCleanup() async {
    final db = await database;

    try {
      // Remove messages older than 7 days for low-end devices
      final cutoffDays = _isVeryLowEndDevice ? 3 : (_isLowEndDevice ? 7 : 30);
      final cutoffTime = DateTime.now()
          .subtract(Duration(days: cutoffDays))
          .millisecondsSinceEpoch;

      final chatDeleted = await db.delete(
        _chatMessagesTable,
        where: 'created_at < ?',
        whereArgs: [cutoffTime],
      );

      final topicDeleted = await db.delete(
        _topicMessagesTable,
        where: 'created_at < ?',
        whereArgs: [cutoffTime],
      );

      debugPrint(
          'Emergency cleanup: Removed $chatDeleted chat messages and $topicDeleted topic messages older than $cutoffDays days');

      // Vacuum after emergency cleanup
      await db.execute('VACUUM');
    } catch (e) {
      debugPrint('Error in emergency cleanup: $e');
    }
  }

  Future<void> _performLowEndDeviceCleanup() async {
    final db = await database;

    try {
      // For low-end devices, be more aggressive about cache limits
      final aggressiveLimit = _isVeryLowEndDevice ? 1000 : 3000;

      // Get all unique chat_ids and topic_ids with limits to avoid memory issues
      final chatIds = await db.rawQuery(
          'SELECT DISTINCT chat_id FROM $_chatMessagesTable LIMIT 100');
      final topicIds = await db.rawQuery(
          'SELECT DISTINCT topic_id FROM $_topicMessagesTable LIMIT 100');

      // Clean up each chat with aggressive limits
      for (final row in chatIds) {
        final chatId = row['chat_id'] as String;
        await _limitCacheSize(
            chatId, _chatMessagesTable, 'chat_id', aggressiveLimit);
      }

      // Clean up each topic with aggressive limits
      for (final row in topicIds) {
        final topicId = row['topic_id'] as String;
        await _limitCacheSize(
            topicId, _topicMessagesTable, 'topic_id', aggressiveLimit);
      }

      // Remove duplicate entries (can happen with rapid message updates)
      await db.execute('''
        DELETE FROM $_chatMessagesTable
        WHERE rowid NOT IN (
          SELECT MIN(rowid)
          FROM $_chatMessagesTable
          GROUP BY id, chat_id
        )
      ''');

      await db.execute('''
        DELETE FROM $_topicMessagesTable
        WHERE rowid NOT IN (
          SELECT MIN(rowid)
          FROM $_topicMessagesTable
          GROUP BY id, topic_id
        )
      ''');

      // Optimize database after cleanup
      if (!_isVeryLowEndDevice) {
        await db.execute('ANALYZE');
      }

      debugPrint(
          'Low-end device cleanup completed with aggressive limit: $aggressiveLimit');
    } catch (e) {
      debugPrint('Error in low-end device cleanup: $e');
    }
  }

  int _getEffectiveQueryLimit(int? requestedLimit) {
    if (requestedLimit == null) {
      return _isVeryLowEndDevice ? 25 : (_isLowEndDevice ? 50 : 100);
    }

    if (_isVeryLowEndDevice && requestedLimit > 25) {
      return 25;
    } else if (_isLowEndDevice && requestedLimit > 50) {
      return 50;
    }

    return requestedLimit;
  }

  String _simpleCompress(String data) {
    // Simple Run-Length Encoding for very low-end devices
    final buffer = StringBuffer('RLE:');
    if (data.isEmpty) return buffer.toString();

    String currentChar = data[0];
    int count = 1;

    for (int i = 1; i < data.length; i++) {
      if (data[i] == currentChar && count < 255) {
        count++;
      } else {
        if (count > 3 || currentChar == '\n' || currentChar == ' ') {
          buffer.write('$count$currentChar');
        } else {
          buffer.write(currentChar * count);
        }
        currentChar = data[i];
        count = 1;
      }
    }

    // Handle last sequence
    if (count > 3 || currentChar == '\n' || currentChar == ' ') {
      buffer.write('$count$currentChar');
    } else {
      buffer.write(currentChar * count);
    }

    final result = buffer.toString();
    return result.length < data.length ? result : data;
  }

  String _simpleDecompress(String compressedData) {
    if (!compressedData.startsWith('RLE:')) return compressedData;

    final data = compressedData.substring(4); // Remove 'RLE:' prefix
    final buffer = StringBuffer();

    for (int i = 0; i < data.length; i++) {
      final char = data[i];
      if (char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57) {
        // It's a digit, get the count
        int count = int.parse(char);
        if (i + 1 < data.length) {
          final repeatedChar = data[i + 1];
          buffer.write(repeatedChar * count);
          i++; // Skip the repeated character
        }
      } else {
        buffer.write(char);
      }
    }

    return buffer.toString();
  }

  Future<void> _checkMemoryUsage() async {
    final now = DateTime.now();

    // Only check memory every 5 minutes to avoid performance impact
    if (_lastMemoryCheck != null &&
        now.difference(_lastMemoryCheck!).inMinutes < 5) {
      return;
    }

    _lastMemoryCheck = now;

    try {
      // Estimate current memory usage (this is approximate)
      final db = await database;

      // Check database size as a proxy for memory usage
      final result = await db.rawQuery('''
        SELECT
          (SELECT COUNT(*) FROM $_chatMessagesTable) as chat_count,
          (SELECT COUNT(*) FROM $_topicMessagesTable) as topic_count
      ''');

      final chatCount = result.first['chat_count'] as int;
      final topicCount = result.first['topic_count'] as int;
      final totalMessages = chatCount + topicCount;

      // Rough estimate: each message takes about 1KB in memory when processed
      _currentMemoryUsageMB = totalMessages ~/ 1024;

      // Determine if we're under memory pressure
      final memoryThreshold =
          _isVeryLowEndDevice ? 50 : (_isLowEndDevice ? 100 : 200);
      _memoryPressure = _currentMemoryUsageMB > memoryThreshold;

      if (_memoryPressure) {
        debugPrint(
            'Memory pressure detected: ${_currentMemoryUsageMB}MB used (threshold: ${memoryThreshold}MB)');
      }
    } catch (e) {
      debugPrint('Error checking memory usage: $e');
    }
  }

  Future<void> _performEmergencyMemoryCleanup() async {
    final db = await database;

    try {
      debugPrint('Performing emergency memory cleanup...');

      // Remove all but the most recent 500 messages per chat/topic for very low-end devices
      final emergencyLimit = _isVeryLowEndDevice ? 200 : 500;

      // Clean up chat messages
      await db.execute('''
        DELETE FROM $_chatMessagesTable
        WHERE rowid NOT IN (
          SELECT rowid FROM $_chatMessagesTable
          ORDER BY created_at DESC
          LIMIT $emergencyLimit
        )
      ''');

      // Clean up topic messages
      await db.execute('''
        DELETE FROM $_topicMessagesTable
        WHERE rowid NOT IN (
          SELECT rowid FROM $_topicMessagesTable
          ORDER BY created_at DESC
          LIMIT $emergencyLimit
        )
      ''');

      // Clear old metadata
      final cutoffTime = DateTime.now()
          .subtract(const Duration(hours: 24))
          .millisecondsSinceEpoch;

      await db.delete(
        _metadataTable,
        where: 'updated_at < ?',
        whereArgs: [cutoffTime],
      );

      // Force vacuum to reclaim space immediately
      await db.execute('VACUUM');

      _memoryPressure = false; // Reset memory pressure flag
      debugPrint('Emergency memory cleanup completed');
    } catch (e) {
      debugPrint('Error in emergency memory cleanup: $e');
    }
  }

  Future<Map<String, int>> getCacheStatistics() async {
    final db = await database;
    final result = await db.query('cache_stats');

    final stats = <String, int>{};
    for (final row in result) {
      stats[row['stat_key'] as String] = row['stat_value'] as int;
    }

    return stats;
  }

  Future<void> optimizeDatabase() async {
    if (_isOptimizing) return;
    _isOptimizing = true;

    try {
      final db = await database;

      // Reindex all tables
      await db.execute('REINDEX');

      // Update table statistics
      await db.execute('ANALYZE');

      // Vacuum to reclaim space
      await db.execute('VACUUM');
    } catch (e) {
      debugPrint('Database optimization error: $e');
    } finally {
      _isOptimizing = false;
    }
  }

  /// Delete corrupted database file for recovery
  Future<void> _deleteCorruptedDatabase(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        if (kDebugMode) {
          print('SqliteMessageCache: Deleted corrupted database file: $path');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('SqliteMessageCache: Failed to delete database file: $e');
      }
      rethrow;
    }
  }

  /// Create in-memory database as fallback
  Future<Database> _createInMemoryDatabase() async {
    if (kDebugMode) {
      print('SqliteMessageCache: Creating in-memory database as fallback');
    }

    final db = await openDatabase(
      ':memory:',
      version: _databaseVersion,
      onCreate: _onCreate,
      onOpen: _onOpen,
    );

    if (kDebugMode) {
      print('SqliteMessageCache: In-memory database created successfully');
    }

    return db;
  }

  @override
  Future<void> dispose() async {
    _backgroundCleanupTimer?.cancel();
    await _database?.close();
    _database = null;
    super.dispose();
  }
}
