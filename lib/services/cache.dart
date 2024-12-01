import 'package:flutter/foundation.dart';

import '../models/chat.dart';
import '../models/user.dart';

class Cache extends ChangeNotifier {
  int _clockSkew = 0;
  User? _user;
  List<Chat> _chats = [];

  Cache._();
  static final Cache _instance = Cache._();
  factory Cache() => _instance;

  int get now {
    return DateTime.now().millisecondsSinceEpoch + _clockSkew;
  }

  User? get user => _user;

  List<Chat> get chats => _chats;

  updateClockSkew(int clockSkew) {
    _clockSkew = clockSkew;
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
