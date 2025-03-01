import 'package:flutter/foundation.dart';

import '../models/chat.dart';

class ChatCache extends ChangeNotifier {
  List<Chat> _chats = [];

  ChatCache._();
  static final ChatCache _instance = ChatCache._();
  factory ChatCache() => _instance;

  List<Chat> get chats => _chats;

  List<Chat> get activeChats => _chats.where((chat) => chat.isActive).toList();

  List<String> get activeChatIds => activeChats.map((chat) => chat.id).toList();

  updateChats(List<Chat> chats) {
    _chats = List<Chat>.from(chats);
    notifyListeners();
  }
}
