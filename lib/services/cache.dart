import 'package:flutter/foundation.dart';

class Cache extends ChangeNotifier {
  int _clockSkew = 0;

  Cache._();
  static final Cache _instance = Cache._();
  factory Cache() => _instance;

  int get now {
    return DateTime.now().millisecondsSinceEpoch + _clockSkew;
  }

  updateClockSkew(int clockSkew) {
    _clockSkew = clockSkew;
    // No need to notify listeners.
  }
}
