import 'package:shared_preferences/shared_preferences.dart';

final wizardVersion = '3.0.4+28';

class Settings {
  Settings._();
  static final Settings _instance = Settings._();
  factory Settings() => _instance;

  String? _completedSetupVersion;
  bool _hasHiddenUsersNotice = false;
  bool _hasHiddenChatsNotice = false;

  Future<void> load() async {
    final setupVersion = await Prefs.getString('completedSetupVersion');
    final usersNotice = await Prefs.getBool('hasHiddenUsersNotice');
    final chatsNotice = await Prefs.getBool('hasHiddenChatsNotice');

    _completedSetupVersion = setupVersion;
    _hasHiddenUsersNotice = usersNotice;
    _hasHiddenChatsNotice = chatsNotice;
  }

  Future<void> markSetupComplete() async {
    await Prefs.setString('completedSetupVersion', wizardVersion);
    _completedSetupVersion = wizardVersion;
  }

  Future<void> hideUsersNotice() async {
    await Prefs.setBool('hasHiddenUsersNotice', true);
    _hasHiddenUsersNotice = true;
  }

  Future<void> hideChatsNotice() async {
    await Prefs.setBool('hasHiddenChatsNotice', true);
    _hasHiddenChatsNotice = true;
  }

  bool get hasCompletedSetup => _completedSetupVersion == wizardVersion;
  bool get hasHiddenUsersNotice => _hasHiddenUsersNotice;
  bool get hasHiddenChatsNotice => _hasHiddenChatsNotice;
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
