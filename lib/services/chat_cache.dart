import 'package:flutter/foundation.dart';

import '../models/private_chat.dart';
import 'server_clock.dart';

class ChatCache extends ChangeNotifier {
  final Map<String, PrivateChat> _chats = {};

  ChatCache._();
  static final ChatCache _instance = ChatCache._();
  factory ChatCache() => _instance;

  List<PrivateChat> get chats => _chats.values.toList();
  List<PrivateChat> get activeChats =>
      _chats.values.where((chat) => chat.isActive).toList();

  List<String> get activeChatIds =>
      _chats.entries
          .where((entry) => entry.value.isActive)
          .map((entry) => entry.key)
          .toList();

  // TODO: Use this in the chat page
  PrivateChat? getChat(String chatId) => _chats[chatId];

  void updateChats(List<PrivateChat> chats) {
    _chats.clear();
    for (final chat in chats) {
      _chats[chat.id] = chat;
    }
    notifyListeners();
  }

  void updateChat(PrivateChat chat) {
    _chats[chat.id] = chat;
    notifyListeners();
  }

  void removeChat(String chatId) {
    _chats.remove(chatId);
    notifyListeners();
  }

  bool hasChat(String chatId) => _chats.containsKey(chatId);

  int get unreadCount {
    return activeChats
        .map((chat) => chat.unreadCount)
        .fold<int>(0, (sum, count) => sum + count);
  }

  int? getTimeLeft({int? now}) {
    final chats = activeChats;
    if (chats.isEmpty) return null;

    now = now ?? ServerClock().now;
    final times = chats.map((chat) => chat.getTimeLeft(now: now)).toList();

    times.sort();
    return times.first;
  }
}
