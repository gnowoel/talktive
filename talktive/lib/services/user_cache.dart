import 'package:flutter/foundation.dart';

import '../models/user.dart';

class UserCache extends ChangeNotifier {
  UserCache._();
  static UserCache? _instance;
  factory UserCache() => _instance ??= UserCache._();

  User? _user;
  User? get user => _user;

  void updateUser(User? user) {
    _user = user;
    notifyListeners();
  }

  @override
  void dispose() {
    _user = null;
    _instance = null;
    super.dispose();
  }
}
