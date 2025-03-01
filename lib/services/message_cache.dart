import 'package:flutter/foundation.dart';

import '../models/message.dart';

class MessageCache extends ChangeNotifier {
  final Map<String, List<Message>> _cache = {};
  final Map<String, int> _lastTimestamps = {};

  void addMessages(String chatId, List<Message> messages) {
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
    _lastTimestamps[chatId] = existingMessages.last.createdAt;

    notifyListeners();
  }

  List<Message> getMessages(String chatId) {
    return List.unmodifiable(_cache[chatId] ?? []);
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

class ChatMessageCache extends MessageCache {
  ChatMessageCache._();
  static final ChatMessageCache _instance = ChatMessageCache._();
  factory ChatMessageCache() => _instance;
}

class ReportMessageCache extends MessageCache {
  ReportMessageCache._();
  static final ReportMessageCache _instance = ReportMessageCache._();
  factory ReportMessageCache() => _instance;
}
