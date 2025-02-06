import 'package:flutter/foundation.dart';

import '../models/user.dart';

class UserCache extends ChangeNotifier {
  UserCache._();
  static final UserCache _instance = UserCache._();
  factory UserCache() => _instance;

  User? _user;
  User? get user => _user;

  updateUser(User? user) {
    _user = user;
    notifyListeners();
  }
}
