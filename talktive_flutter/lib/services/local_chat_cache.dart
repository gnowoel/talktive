import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talktive_client/talktive_client.dart';

class LocalChatCache {
  static const String _prefix = 'chat_cache_';
  static const String _metaPrefix = 'chat_meta_';
  static const int _maxCachedChannels = 20;
  static const Duration _maxAge = Duration(days: 7);

  static Future<void> cacheMessages(
    int channelId,
    List<Message> messages,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    // Cache only the latest 50 messages to keep prefs fast
    final toCache = messages.take(50).toList();
    final jsonList = toCache.map((m) => m.toJson()).toList();

    // Write message data
    await prefs.setString('$_prefix$channelId', json.encode(jsonList));

    // Write access metadata
    await prefs.setInt(
      '$_metaPrefix$channelId',
      DateTime.now().millisecondsSinceEpoch,
    );

    // Write last message timestamp if available
    if (messages.isNotEmpty) {
      await prefs.setString(
        '$_prefix${channelId}_last_at',
        messages.first.createdAt.toIso8601String(),
      );
    }

    // Trigger lazy trimming (don't block the caller)
    _trimOldCaches(prefs);
  }

  static Future<DateTime?> getLastMessageAt(int channelId) async {
    final prefs = await SharedPreferences.getInstance();
    final isoStr = prefs.getString('$_prefix${channelId}_last_at');
    if (isoStr == null) return null;
    return DateTime.tryParse(isoStr);
  }

  static Future<List<Message>> getCachedMessages(int channelId) async {
    final prefs = await SharedPreferences.getInstance();

    // Refresh access timestamp
    await prefs.setInt(
      '$_metaPrefix$channelId',
      DateTime.now().millisecondsSinceEpoch,
    );

    final jsonStr = prefs.getString('$_prefix$channelId');
    if (jsonStr == null) return [];

    try {
      final List<dynamic> jsonList = json.decode(jsonStr);
      return jsonList.map((j) => Message.fromJson(j)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _trimOldCaches(SharedPreferences prefs) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final keys = prefs
        .getKeys()
        .where((k) => k.startsWith(_metaPrefix))
        .toList();

    final List<({String channelId, int timestamp})> meta = [];
    for (final key in keys) {
      final ts = prefs.getInt(key);
      if (ts != null) {
        meta.add((channelId: key.replaceFirst(_metaPrefix, ''), timestamp: ts));
      }
    }

    // 1. Remove expired caches (> 7 days)
    for (final entry in meta) {
      if (now - entry.timestamp > _maxAge.inMilliseconds) {
        await _removeChannelCache(prefs, entry.channelId);
        keys.removeWhere((k) => k.contains(entry.channelId));
      }
    }

    // 2. enforce capacity limit (keep only the newest _maxCachedChannels)
    if (keys.length > _maxCachedChannels) {
      // Refresh meta after expiration removal
      final remainingMeta = meta
          .where((e) => keys.any((k) => k.contains(e.channelId)))
          .toList();
      remainingMeta.sort(
        (a, b) => b.timestamp.compareTo(a.timestamp),
      ); // Newest first

      final toRemove = remainingMeta.skip(_maxCachedChannels);
      for (final entry in toRemove) {
        await _removeChannelCache(prefs, entry.channelId);
      }
    }
  }

  static Future<void> _removeChannelCache(
    SharedPreferences prefs,
    String channelId,
  ) async {
    await prefs.remove('$_prefix$channelId');
    await prefs.remove('$_metaPrefix$channelId');
  }

  static Future<void> clearCache(int channelId) async {
    final prefs = await SharedPreferences.getInstance();
    await _removeChannelCache(prefs, channelId.toString());
  }
}
