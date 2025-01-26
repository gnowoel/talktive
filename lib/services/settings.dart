import 'package:shared_preferences/shared_preferences.dart';

final wizardVersion = '3.0.4+28';

class Settings {
  Settings._();
  static final Settings _instance = Settings._();
  factory Settings() => _instance;

  String? _completedSetupVersion;

  Future<void> load() async {
    final value = await Prefs.getString('completedSetupVersion');
    _completedSetupVersion = value;
  }

  Future<void> markSetupComplete() async {
    await Prefs.setString('completedSetupVersion', wizardVersion);
    _completedSetupVersion = wizardVersion;
  }

  bool get hasCompletedSetup => _completedSetupVersion == wizardVersion;
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

  static Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }
}
