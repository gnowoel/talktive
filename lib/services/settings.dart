import 'package:shared_preferences/shared_preferences.dart';

final whatsNewVersion = '3.9.1+54';
final wizardVersion = '3.0.4+28';

class Settings {
  Settings._();
  static final Settings _instance = Settings._();
  factory Settings() => _instance;

  String? _seenWhatsNewVersion;
  String? _completedSetupVersion;
  bool _hasHiddenUsersNotice = false;
  bool _hasHiddenChatsNotice = false;
  String? _selectedGender;
  String? _selectedLanguage;

  Future<void> load() async {
    _seenWhatsNewVersion = await Prefs.getString('seenWhatsNewVersion');

    final setupVersion = await Prefs.getString('completedSetupVersion');
    final usersNotice = await Prefs.getBool('hasHiddenUsersNotice');
    final chatsNotice = await Prefs.getBool('hasHiddenChatsNotice');
    final selectedGender = await Prefs.getString('selectedGender');
    final selectedLanguage = await Prefs.getString('selectedLanguage');

    _completedSetupVersion = setupVersion;
    _hasHiddenUsersNotice = usersNotice;
    _hasHiddenChatsNotice = chatsNotice;
    _selectedGender = selectedGender;
    _selectedLanguage = selectedLanguage;
  }

  Future<void> setSeenWhatsNewVersion() async {
    await Prefs.setString('seenWhatsNewVersion', whatsNewVersion);
    _seenWhatsNewVersion = whatsNewVersion;
  }

  Future<void> markSetupComplete() async {
    await Prefs.setString('completedSetupVersion', wizardVersion);
    _completedSetupVersion = wizardVersion;
  }

  Future<void> clearSetupCompletion() async {
    await Prefs.remove('completedSetupVersion');
    _completedSetupVersion = null;
  }

  Future<void> hideUsersNotice() async {
    await Prefs.setBool('hasHiddenUsersNotice', true);
    _hasHiddenUsersNotice = true;
  }

  Future<void> hideChatsNotice() async {
    await Prefs.setBool('hasHiddenChatsNotice', true);
    _hasHiddenChatsNotice = true;
  }

  Future<void> setSelectedGender(String? value) async {
    if (value == null) {
      await Prefs.remove('selectedGender');
      _selectedGender = null;
    } else {
      await Prefs.setString('selectedGender', value);
      _selectedGender = value;
    }
  }

  Future<void> setSelectedLanguage(String? value) async {
    if (value == null) {
      await Prefs.remove('selectedLanguage');
      _selectedLanguage = null;
    } else {
      await Prefs.setString('selectedLanguage', value);
      _selectedLanguage = value;
    }
  }

  Future<void> resetFilters() async {
    await Prefs.remove('selectedGender');
    _selectedGender = null;
    await Prefs.remove('selectedLanguage');
    _selectedLanguage = null;
  }

  bool get hasSeenWhatsNew => _seenWhatsNewVersion == whatsNewVersion;
  bool get hasCompletedSetup => _completedSetupVersion == wizardVersion;
  bool get hasHiddenUsersNotice => _hasHiddenUsersNotice;
  bool get hasHiddenChatsNotice => _hasHiddenChatsNotice;
  String? get selectedGender => _selectedGender;
  String? get selectedLanguage => _selectedLanguage;
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

  static Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
