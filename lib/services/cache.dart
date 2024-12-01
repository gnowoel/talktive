import 'package:flutter/foundation.dart';

import '../models/chat.dart';
import '../models/user.dart';

class Cache extends ChangeNotifier {
  int _now = 0;
  User? _user;
  List<Chat> _chats = [];

  Cache._();
  static final Cache _instance = Cache._();
  factory Cache() => _instance;

  int get now => _now;
  User? get user => _user;
  List<Chat> get chats => _chats;

  updateNow(int now) {
    _now = now;
    // No need to notify listeners.
  }

  updateUser(User? user) {
    _user = user;
    notifyListeners();
  }

  updateChats(List<Chat> chats) {
    _chats = chats;
    notifyListeners();
  }
}
