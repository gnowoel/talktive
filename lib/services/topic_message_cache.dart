import 'package:flutter/foundation.dart';

import '../models/topic_message.dart';

class TopicMessageCache extends ChangeNotifier {
  TopicMessageCache._();
  static final TopicMessageCache _instance = TopicMessageCache._();
  factory TopicMessageCache() => _instance;

  final Map<String, List<TopicMessage>> _cache = {};
  final Map<String, int> _lastTimestamps = {};

  void addMessages(String chatId, List<TopicMessage> messages) {
    if (messages.isEmpty) return;

    _cache[chatId] ??= [];
    var existingMessages = _cache[chatId]!;

    // Add new messages and update existing ones
    for (var message in messages) {
      int index = existingMessages.indexWhere((m) => m.id == message.id);
      if (index >= 0) {
        existingMessages[index] = message;
      } else {
        existingMessages.add(message);
      }
    }

    existingMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    _lastTimestamps[chatId] =
        existingMessages.last.createdAt.millisecondsSinceEpoch;

    notifyListeners();
  }

  List<TopicMessage> getMessages(String topicId) {
    return List.unmodifiable(_cache[topicId] ?? []);
  }

  int? getLastTimestamp(String chatId) {
    return _lastTimestamps[chatId];
  }

  void cleanup(List<String> activeChatIds) {
    final activeIds = Set<String>.from(activeChatIds);
    _cache.removeWhere((chatId, _) => !activeIds.contains(chatId));
    _lastTimestamps.removeWhere((chatId, _) => !activeIds.contains(chatId));
    notifyListeners();
  }

  void clear(List<String> inactiveChatIds) {
    for (final chatId in inactiveChatIds) {
      _cache.remove(chatId);
      _lastTimestamps.remove(chatId);
    }
    notifyListeners();
  }
}
