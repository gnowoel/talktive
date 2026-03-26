import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talktive_client/talktive_client.dart';

class LocalChatCache {
  static const String _prefix = 'chat_cache_';

  static Future<void> cacheMessages(int channelId, List<Message> messages) async {
    final prefs = await SharedPreferences.getInstance();
    // Cache only the latest 50 messages to keep prefs fast
    final toCache = messages.take(50).toList();
    final jsonList = toCache.map((m) => m.toJson()).toList();
    await prefs.setString('${_prefix}$channelId', json.encode(jsonList));
  }

  static Future<List<Message>> getCachedMessages(int channelId) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('${_prefix}$channelId');
    if (jsonStr == null) return [];

    try {
      final List<dynamic> jsonList = json.decode(jsonStr);
      return jsonList.map((j) => Message.fromJson(j)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> clearCache(int channelId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_prefix}$channelId');
  }
}
