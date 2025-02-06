import 'package:flutter/foundation.dart';

import '../models/chat.dart';

class ChatCache extends ChangeNotifier {
  List<Chat> _chats = [];

  ChatCache._();
  static final ChatCache _instance = ChatCache._();
  factory ChatCache() => _instance;

  List<Chat> get chats => _chats;

  updateChats(List<Chat> chats) {
    _chats = chats;
    notifyListeners();
  }
}
