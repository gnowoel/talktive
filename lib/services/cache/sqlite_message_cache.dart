import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/message.dart';
import '../../models/topic_message.dart';

class SqliteMessageCache extends ChangeNotifier {
  static const String _databaseName = 'talktive_cache.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String _chatMessagesTable = 'chat_messages';
  static const String _topicMessagesTable = 'topic_messages';
  static const String _metadataTable = 'cache_metadata';

  Database? _database;

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

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Chat messages table
    await db.execute('''
      CREATE TABLE $_chatMessagesTable (
        id TEXT PRIMARY KEY,
        chat_id TEXT NOT NULL,
        type TEXT NOT NULL,
        user_id TEXT NOT NULL,
        user_display_name TEXT NOT NULL,
        user_photo_url TEXT,
        content TEXT NOT NULL,
        uri TEXT,
        created_at INTEGER NOT NULL,
        recalled INTEGER DEFAULT 0,
        cached_at INTEGER NOT NULL,
        INDEX(chat_id, created_at),
        INDEX(chat_id, cached_at)
      )
    ''');

    // Topic messages table
    await db.execute('''
      CREATE TABLE $_topicMessagesTable (
        id TEXT PRIMARY KEY,
        topic_id TEXT NOT NULL,
        type TEXT NOT NULL,
        user_id TEXT NOT NULL,
        user_display_name TEXT NOT NULL,
        user_photo_url TEXT,
        content TEXT NOT NULL,
        uri TEXT,
        created_at INTEGER NOT NULL,
        cached_at INTEGER NOT NULL,
        INDEX(topic_id, created_at),
        INDEX(topic_id, cached_at)
      )
    ''');

    // Metadata table for tracking cache state
    await db.execute('''
      CREATE TABLE $_metadataTable (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database schema upgrades here
    if (oldVersion < newVersion) {
      // For now, just recreate tables
      await db.execute('DROP TABLE IF EXISTS $_chatMessagesTable');
      await db.execute('DROP TABLE IF EXISTS $_topicMessagesTable');
      await db.execute('DROP TABLE IF EXISTS $_metadataTable');
      await _onCreate(db, newVersion);
    }
  }

  // Chat Messages Methods

  Future<void> storeChatMessages(String chatId, List<Message> messages) async {
    if (messages.isEmpty) return;

    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final message in messages) {
      batch.insert(
        _chatMessagesTable,
        {
          'id': message.id,
          'chat_id': chatId,
          'type': message.runtimeType == ImageMessage ? 'image' : 'text',
          'user_id': message.userId,
          'user_display_name': message.userDisplayName,
          'user_photo_url': message.userPhotoURL,
          'content': message.content,
          'uri': message is ImageMessage ? message.uri : null,
          'created_at': message.createdAt,
          'recalled': message.recalled ? 1 : 0,
          'cached_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);

    // Update last sync timestamp
    await _updateLastSyncTimestamp('chat_$chatId', now);

    notifyListeners();
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

    if (isImage) {
      return ImageMessage(
        id: map['id'],
        userId: map['user_id'],
        userDisplayName: map['user_display_name'],
        userPhotoURL: map['user_photo_url'],
        content: map['content'],
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
        content: map['content'],
        createdAt: map['created_at'],
        recalled: map['recalled'] == 1,
      );
    }
  }

  TopicMessage _topicMessageFromMap(Map<String, dynamic> map) {
    final isImage = map['type'] == 'image';
    final createdAt = DateTime.fromMillisecondsSinceEpoch(map['created_at']);

    if (isImage) {
      return TopicImageMessage(
        id: map['id'],
        userId: map['user_id'],
        userDisplayName: map['user_display_name'],
        userPhotoURL: map['user_photo_url'],
        content: map['content'],
        uri: map['uri'] ?? '',
        createdAt: createdAt,
      );
    } else {
      return TopicTextMessage(
        id: map['id'],
        userId: map['user_id'],
        userDisplayName: map['user_display_name'],
        userPhotoURL: map['user_photo_url'],
        content: map['content'],
        createdAt: createdAt,
      );
    }
  }

  Future<void> dispose() async {
    await _database?.close();
    _database = null;
  }
}
