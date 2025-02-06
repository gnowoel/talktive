class ServerClock {
  int _clockSkew = 0;

  ServerClock._();
  static final ServerClock _instance = ServerClock._();
  factory ServerClock() => _instance;

  int get now {
    return DateTime.now().millisecondsSinceEpoch + _clockSkew;
  }

  updateClockSkew(int clockSkew) {
    _clockSkew = clockSkew;
  }
}
