import 'package:shared_preferences/shared_preferences.dart';

final whatsNewVersion = '4.1.0+56';
final setupWizardVersion = '3.0.4+28';
final usersPageNoticeVersion = 'true'; // Next time will use verion number
final chatsPageNoticeVersion = 'true'; // Next time will use verion number

class Settings {
  Settings._();
  static final Settings _instance = Settings._();
  factory Settings() => _instance;

  String? _savedWhatsNewVersion;
  String? _savedSetupWizardVersion;
  String? _savedUsersPageNoticeVersion;
  String? _savedChatsPageNoticeVersion;

  Future<void> load() async {
    _savedWhatsNewVersion = await Prefs.getString('whatsNewVersion');
    _savedSetupWizardVersion = await Prefs.getString('setupWizardVersion');
    _savedUsersPageNoticeVersion =
        await Prefs.getString('usersPageNoticeVersion');
    _savedChatsPageNoticeVersion =
        await Prefs.getString('chatsPageNoticeVersion');

    // For migration, will delete

    if (_savedWhatsNewVersion == null) {
      _savedWhatsNewVersion = await Prefs.getString('seenWhatsNewVersion');
      if (_savedWhatsNewVersion != null) {
        await Prefs.setString('_savedWhatsNewVersion', _savedWhatsNewVersion!);
        await Prefs.remove('seenWhatsNewVersion');
      }
    }

    if (_savedSetupWizardVersion == null) {
      _savedSetupWizardVersion = await Prefs.getString('completedSetupVersion');
      if (_savedSetupWizardVersion != null) {
        await Prefs.setString(
            'savedSetupWizardVersion', _savedSetupWizardVersion!);
        await Prefs.remove('completedSetupVersion');
      }
    }

    if (_savedUsersPageNoticeVersion == null) {
      final oldValue = await Prefs.getBool('hasHiddenUsersNotice');
      if (oldValue) {
        _savedUsersPageNoticeVersion = oldValue.toString(); // 'true'
        await Prefs.setString(
            'usersPageNoticeVersion', oldValue.toString()); // 'true'
        await Prefs.remove('hasHiddenUsersNotice');
      }
    }

    if (_savedChatsPageNoticeVersion == null) {
      final oldValue = await Prefs.getBool('hasHiddenChatsNotice');
      if (oldValue) {
        _savedChatsPageNoticeVersion = oldValue.toString(); // 'true'
        await Prefs.setString(
            'chatsPageNoticeVersion', oldValue.toString()); // 'true'
        await Prefs.remove('hasHiddenChatsNotice');
      }
    }
  }

  Future<void> saveWhatsNewVersion() async {
    await Prefs.setString('whatsNewVersion', whatsNewVersion);
    _savedWhatsNewVersion = whatsNewVersion;
  }

  Future<void> saveSetupWizardVersion() async {
    await Prefs.setString('setupWizardVersion', setupWizardVersion);
    _savedSetupWizardVersion = setupWizardVersion;
  }

  Future<void> saveUsersPageNoticeVersion() async {
    await Prefs.setString('usersPageNoticeVersion', usersPageNoticeVersion);
    _savedUsersPageNoticeVersion = usersPageNoticeVersion;
  }

  Future<void> saveChatsPageVersion() async {
    await Prefs.setString('chatsPageNoticeVersion', chatsPageNoticeVersion);
    _savedChatsPageNoticeVersion = chatsPageNoticeVersion;
  }

  Future<void> removeSetupWizardVersion() async {
    await Prefs.remove('setupWizardVerions');
    _savedSetupWizardVersion = null;
  }

  bool get shouldShowWhatnew => _savedWhatsNewVersion != whatsNewVersion;
  bool get shouldShowSetupWizard =>
      _savedSetupWizardVersion != setupWizardVersion;
  bool get shouldShowUsersPageNotice =>
      _savedUsersPageNoticeVersion != usersPageNoticeVersion;
  bool get shouldShowChatsPageNotice =>
      _savedChatsPageNoticeVersion != chatsPageNoticeVersion;

  bool get shouldHideSetupWizard => !shouldShowSetupWizard;
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
