import 'package:flutter/foundation.dart';

import '../models/chat.dart';

class Cache extends ChangeNotifier {
  int _clockSkew = 0;
  List<Chat> _chats = [];

  Cache._();
  static final Cache _instance = Cache._();
  factory Cache() => _instance;

  int get now {
    return DateTime.now().millisecondsSinceEpoch + _clockSkew;
  }

  List<Chat> get chats => _chats;

  updateClockSkew(int clockSkew) {
    _clockSkew = clockSkew;
    // No need to notify listeners.
  }

  updateChats(List<Chat> chats) {
    _chats = chats;
    notifyListeners();
  }
}
