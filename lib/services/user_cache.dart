import 'package:flutter/foundation.dart';

import '../models/user.dart';

class UserCache extends ChangeNotifier {
  UserCache._();
  static final UserCache _instance = UserCache._();
  factory UserCache() => _instance;

  User? _user;
  User? get user => _user;

  void updateUser(User? user) {
    _user = user;
    notifyListeners();
  }

  @override
  void dispose() {
    _user = null;
    super.dispose();
  }
}
