import 'package:flutter/foundation.dart';

import '../models/message.dart';

class ReportMessageCache extends ChangeNotifier {
  final Map<String, List<Message>> _cache = {};
  final Map<String, int> _lastTimestamps = {};

  ReportMessageCache._();
  static final ReportMessageCache _instance = ReportMessageCache._();
  factory ReportMessageCache() => _instance;

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

  void clear(List<String> chatIds) {
    for (final chatId in chatIds) {
      _cache.remove(chatId);
      _lastTimestamps.remove(chatId);
    }
    notifyListeners();
  }
}
