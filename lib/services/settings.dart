import 'package:shared_preferences/shared_preferences.dart' as prefs;

class Settings {
  static const hasCompletedSetup = 'hasCompletedSetup';

  static Future<String?> getString(String key) async {
    final preferences = await prefs.SharedPreferences.getInstance();
    return preferences.getString(key);
  }

  static Future<void> setString(String key, String value) async {
    final preferences = await prefs.SharedPreferences.getInstance();
    await preferences.setString(key, value);
  }

  static Future<bool> getBool(String key) async {
    final preferences = await prefs.SharedPreferences.getInstance();
    return preferences.getBool(key) ?? false;
  }

  static Future<void> setBool(String key, bool value) async {
    final preferences = await prefs.SharedPreferences.getInstance();
    await preferences.setBool(key, value);
  }
}
