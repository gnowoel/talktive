import 'package:shared_preferences/shared_preferences.dart';

class Settings {
  Settings._();

  static final Settings _instance = Settings._();

  factory Settings() => _instance;

  bool _hasCompletedSetup = false;

  bool getHasCompletedSetup() {
    return _hasCompletedSetup;
  }

  void setHasCompletedSetup(bool value) {
    _hasCompletedSetup = value;
  }
}

class Prefs {
  static Future<bool> getBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false;
  }

  static Future<void> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }
}
