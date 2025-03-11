import 'package:flutter/foundation.dart';

import '../models/chat.dart';

class ChatCache extends ChangeNotifier {
  final Map<String, Chat> _chats = {};

  ChatCache._();
  static final ChatCache _instance = ChatCache._();
  factory ChatCache() => _instance;

  List<Chat> get chats => _chats.values.toList();

  // TODO: Use this in the chat page
  Chat? getChat(String chatId) => _chats[chatId];

  List<Chat> get activeChats =>
      _chats.values.where((chat) => chat.isActive).toList();

  List<String> get activeChatIds =>
      _chats.entries
          .where((entry) => entry.value.isActive)
          .map((entry) => entry.key)
          .toList();

  void updateChats(List<Chat> chats) {
    _chats.clear();
    for (final chat in chats) {
      _chats[chat.id] = chat;
    }
    notifyListeners();
  }

  void updateChat(Chat chat) {
    _chats[chat.id] = chat;
    notifyListeners();
  }

  void removeChat(String chatId) {
    _chats.remove(chatId);
    notifyListeners();
  }

  bool hasChat(String chatId) => _chats.containsKey(chatId);
}
