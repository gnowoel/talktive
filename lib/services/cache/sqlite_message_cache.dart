import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/message.dart';
import '../../models/image_message.dart';
import '../../models/text_message.dart';
import '../../models/topic_message.dart';

class SqliteMessageCache extends ChangeNotifier {
  static const String _databaseName = 'talktive_cache.db';
  static const int _databaseVersion = 2;

  // Table names
  static const String _chatMessagesTable = 'chat_messages';
  static const String _topicMessagesTable = 'topic_messages';
  static const String _metadataTable = 'cache_metadata';

  // Performance constants
  static const int _maxBatchSize = 100;
  static const int _compressionThreshold = 1000; // Characters
  static const int _maxCacheSize = 50000; // Maximum messages per chat/topic
  static const Duration _backgroundCleanupInterval = Duration(hours: 6);

  // Connection pool settings (for future implementation)
  // static const int _maxConnections = 3;
  // static const Duration _connectionTimeout = Duration(seconds: 30);

  Database? _database;
  Timer? _backgroundCleanupTimer;
  bool _isOptimizing = false;

  // Connection management (for future implementation)
  final List<Database> _connectionPool = [];

  // Singleton pattern
  SqliteMessageCache._();
  static final SqliteMessageCache _instance = SqliteMessageCache._();
  factory SqliteMessageCache() => _instance;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    final db = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
    );

    // Initialize background cleanup
    _startBackgroundCleanup();

    return db;
  }

  Future<void> _onOpen(Database db) async {
    // Enable WAL mode for better concurrent access
    await db.execute('PRAGMA journal_mode=WAL');
    // Optimize for performance
    await db.execute('PRAGMA synchronous=NORMAL');
    await db.execute('PRAGMA cache_size=10000');
    await db.execute('PRAGMA temp_store=MEMORY');
    // Enable foreign keys
    await db.execute('PRAGMA foreign_keys=ON');
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

    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Process messages in batches for better performance
    final batches = _createBatches(messages, _maxBatchSize);

    for (final messageBatch in batches) {
      final batch = db.batch();

      for (final message in messageBatch) {
        final content = message.content;
        final contentSize = content.length;
        final shouldCompress = contentSize > _compressionThreshold;

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

    // Update last sync timestamp
    await _updateLastSyncTimestamp('chat_$chatId', now);

    // Update cache statistics
    await _updateCacheStats('cache_hits', messages.length);

    // Check if we need to cleanup old messages
    await _checkAndCleanupOldMessages(chatId, _chatMessagesTable);

    notifyListeners();
  }

  List<List<T>> _createBatches<T>(List<T> items, int batchSize) {
    final batches = <List<T>>[];
    for (int i = 0; i < items.length; i += batchSize) {
      final end = (i + batchSize < items.length) ? i + batchSize : items.length;
      batches.add(items.sublist(i, end));
    }
    return batches;
  }

  List<int> _compressString(String text) {
    try {
      return GZipCodec().encode(text.codeUnits);
    } catch (e) {
      // Fallback to original text if compression fails
      return text.codeUnits;
    }
  }

  String _decompressString(List<int> compressed) {
    try {
      final decompressed = GZipCodec().decode(compressed);
      return String.fromCharCodes(decompressed);
    } catch (e) {
      // Fallback to treat as uncompressed
      return String.fromCharCodes(compressed);
    }
  }

  Future<List<Message>> getChatMessages(
    String chatId, {
    int? limit,
    int? offset,
    int? minCreatedAt,
  }) async {
    final db = await database;

    String whereClause = 'chat_id = ?';
    List<dynamic> whereArgs = [chatId];

    if (minCreatedAt != null) {
      whereClause += ' AND created_at >= ?';
      whereArgs.add(minCreatedAt);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      _chatMessagesTable,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at ASC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => _chatMessageFromMap(map)).toList();
  }

  Future<int> getChatMessageCount(String chatId, {int? minCreatedAt}) async {
    final db = await database;

    String whereClause = 'chat_id = ?';
    List<dynamic> whereArgs = [chatId];

    if (minCreatedAt != null) {
      whereClause += ' AND created_at >= ?';
      whereArgs.add(minCreatedAt);
    }

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_chatMessagesTable WHERE $whereClause',
      whereArgs,
    );

    return result.first['count'] as int;
  }

  Future<Message?> getLatestChatMessage(String chatId) async {
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
  }

  Future<int?> getLastChatMessageTimestamp(String chatId) async {
    final message = await getLatestChatMessage(chatId);
    return message?.createdAt;
  }

  // Topic Messages Methods

  Future<void> storeTopicMessages(
      String topicId, List<TopicMessage> messages) async {
    if (messages.isEmpty) return;

    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final message in messages) {
      batch.insert(
        _topicMessagesTable,
        {
          'id': message.id,
          'topic_id': topicId,
          'type': message.runtimeType == TopicImageMessage ? 'image' : 'text',
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

    // Update last sync timestamp
    await _updateLastSyncTimestamp('topic_$topicId', now);

    notifyListeners();
  }

  Future<List<TopicMessage>> getTopicMessages(
    String topicId, {
    int? limit,
    int? offset,
  }) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      _topicMessagesTable,
      where: 'topic_id = ?',
      whereArgs: [topicId],
      orderBy: 'created_at ASC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => _topicMessageFromMap(map)).toList();
  }

  Future<int> getTopicMessageCount(String topicId) async {
    final db = await database;

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_topicMessagesTable WHERE topic_id = ?',
      [topicId],
    );

    return result.first['count'] as int;
  }

  Future<TopicMessage?> getLatestTopicMessage(String topicId) async {
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
  }

  Future<int?> getLastTopicMessageTimestamp(String topicId) async {
    final message = await getLatestTopicMessage(topicId);
    return message?.createdAt.millisecondsSinceEpoch;
  }

  // Cache Management Methods

  Future<void> cleanupOldMessages({int maxAgeInDays = 30}) async {
    final db = await database;
    final cutoffTime = DateTime.now()
        .subtract(Duration(days: maxAgeInDays))
        .millisecondsSinceEpoch;

    await db.delete(
      _chatMessagesTable,
      where: 'cached_at < ?',
      whereArgs: [cutoffTime],
    );

    await db.delete(
      _topicMessagesTable,
      where: 'cached_at < ?',
      whereArgs: [cutoffTime],
    );

    notifyListeners();
  }

  Future<void> clearChatMessages(String chatId) async {
    final db = await database;
    await db.delete(
      _chatMessagesTable,
      where: 'chat_id = ?',
      whereArgs: [chatId],
    );

    await _removeLastSyncTimestamp('chat_$chatId');
    notifyListeners();
  }

  Future<void> clearTopicMessages(String topicId) async {
    final db = await database;
    await db.delete(
      _topicMessagesTable,
      where: 'topic_id = ?',
      whereArgs: [topicId],
    );

    await _removeLastSyncTimestamp('topic_$topicId');
    notifyListeners();
  }

  Future<void> clearAllCache() async {
    final db = await database;
    await db.delete(_chatMessagesTable);
    await db.delete(_topicMessagesTable);
    await db.delete(_metadataTable);
    notifyListeners();
  }

  // Metadata Management

  Future<void> _updateLastSyncTimestamp(String key, int timestamp) async {
    final db = await database;
    await db.insert(
      _metadataTable,
      {
        'key': 'last_sync_$key',
        'value': timestamp.toString(),
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int?> getLastSyncTimestamp(String key) async {
    final db = await database;
    final result = await db.query(
      _metadataTable,
      where: 'key = ?',
      whereArgs: ['last_sync_$key'],
    );

    if (result.isEmpty) return null;
    return int.tryParse(result.first['value'] as String);
  }

  Future<void> _removeLastSyncTimestamp(String key) async {
    final db = await database;
    await db.delete(
      _metadataTable,
      where: 'key = ?',
      whereArgs: ['last_sync_$key'],
    );
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
        userId: map['user_id'],
        userDisplayName: map['user_display_name'],
        userPhotoURL: map['user_photo_url'],
        content: content,
        uri: map['uri'] ?? '',
        createdAt: map['created_at'],
        recalled: map['recalled'] == 1,
      );
    } else {
      return TextMessage(
        id: map['id'],
        userId: map['user_id'],
        userDisplayName: map['user_display_name'],
        userPhotoURL: map['user_photo_url'],
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
        userId: map['user_id'],
        userDisplayName: map['user_display_name'],
        userPhotoURL: map['user_photo_url'],
        content: content,
        uri: map['uri'] ?? '',
        createdAt: createdAt,
      );
    } else {
      return TopicTextMessage(
        id: map['id'],
        userId: map['user_id'],
        userDisplayName: map['user_display_name'],
        userPhotoURL: map['user_photo_url'],
        content: content,
        createdAt: createdAt,
      );
    }
  }

  Future<void> _startBackgroundCleanup() async {
    _backgroundCleanupTimer?.cancel();
    _backgroundCleanupTimer =
        Timer.periodic(_backgroundCleanupInterval, (timer) async {
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

      // Vacuum database to reclaim space
      await db.execute('VACUUM');

      // Analyze tables for query optimization
      await db.execute('ANALYZE');

      // Clean up old metadata entries
      final oldMetadataCutoff = DateTime.now()
          .subtract(const Duration(days: 7))
          .millisecondsSinceEpoch;
      await db.delete(
        _metadataTable,
        where: 'updated_at < ?',
        whereArgs: [oldMetadataCutoff],
      );
    } catch (e) {
      debugPrint('Background maintenance error: $e');
    } finally {
      _isOptimizing = false;
    }
  }

  Future<void> _checkAndCleanupOldMessages(
      String entityId, String table) async {
    final db = await database;

    // Count messages for this entity
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $table WHERE ${table == _chatMessagesTable ? 'chat_id' : 'topic_id'} = ?',
      [entityId],
    );

    final messageCount = countResult.first['count'] as int;

    if (messageCount > _maxCacheSize) {
      // Remove oldest messages beyond the limit
      final deleteCount = messageCount - _maxCacheSize;
      await db.rawDelete('''
        DELETE FROM $table
        WHERE ${table == _chatMessagesTable ? 'chat_id' : 'topic_id'} = ?
        AND id IN (
          SELECT id FROM $table
          WHERE ${table == _chatMessagesTable ? 'chat_id' : 'topic_id'} = ?
          ORDER BY created_at ASC
          LIMIT ?
        )
      ''', [entityId, entityId, deleteCount]);
    }
  }

  Future<void> _updateCacheStats(String statKey, int increment) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.rawUpdate('''
      UPDATE cache_stats
      SET stat_value = stat_value + ?, last_updated = ?
      WHERE stat_key = ?
    ''', [increment, now, statKey]);
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

  @override
  Future<void> dispose() async {
    _backgroundCleanupTimer?.cancel();

    // Close all connections in pool
    for (final connection in _connectionPool) {
      await connection.close();
    }
    _connectionPool.clear();

    await _database?.close();
    _database = null;
    super.dispose();
  }
}
