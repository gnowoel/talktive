class Clock {
  Clock._();

  static final Clock _instance = Clock._();

  factory Clock() => _instance;

  int _clockSkew = 0;

  int serverNow() {
    return DateTime.now().millisecondsSinceEpoch + _clockSkew;
  }

  void updateClockSkew(int clockSkew) {
    _clockSkew = clockSkew;
  }
}
