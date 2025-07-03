import 'package:shared_preferences/shared_preferences.dart';

final whatsNewVersion = '4.3.0+58';
final setupWizardVersion = '3.0.4+28';
final usersPageNoticeVersion = 'true'; // Next time will use verion number
final chatsPageNoticeVersion = '4.3.0+58';

class Settings {
  Settings._();
  static final Settings _instance = Settings._();
  factory Settings() => _instance;

  String? _savedWhatsNewVersion;
  String? _savedSetupWizardVersion;
  String? _savedUsersPageNoticeVersion;
  String? _savedChatsPageNoticeVersion;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    _savedWhatsNewVersion =
        await Prefs.getString('whatsNewVersion', prefs: prefs);
    _savedSetupWizardVersion =
        await Prefs.getString('setupWizardVersion', prefs: prefs);
    _savedUsersPageNoticeVersion =
        await Prefs.getString('usersPageNoticeVersion', prefs: prefs);
    _savedChatsPageNoticeVersion =
        await Prefs.getString('chatsPageNoticeVersion', prefs: prefs);

    // For migration, will delete

    if (_savedWhatsNewVersion == null) {
      _savedWhatsNewVersion =
          await Prefs.getString('seenWhatsNewVersion', prefs: prefs);
      if (_savedWhatsNewVersion != null) {
        await Prefs.setString('_savedWhatsNewVersion', _savedWhatsNewVersion!,
            prefs: prefs);
        await Prefs.remove('seenWhatsNewVersion', prefs: prefs);
      }
    }

    if (_savedSetupWizardVersion == null) {
      _savedSetupWizardVersion =
          await Prefs.getString('completedSetupVersion', prefs: prefs);
      if (_savedSetupWizardVersion != null) {
        await Prefs.setString(
            'savedSetupWizardVersion', _savedSetupWizardVersion!,
            prefs: prefs);
        await Prefs.remove('completedSetupVersion', prefs: prefs);
      }
    }

    if (_savedUsersPageNoticeVersion == null) {
      final oldValue =
          await Prefs.getBool('hasHiddenUsersNotice', prefs: prefs);
      if (oldValue) {
        _savedUsersPageNoticeVersion = oldValue.toString(); // 'true'
        await Prefs.setString('usersPageNoticeVersion', oldValue.toString(),
            prefs: prefs); // 'true'
        await Prefs.remove('hasHiddenUsersNotice', prefs: prefs);
      }
    }

    if (_savedChatsPageNoticeVersion == null) {
      final oldValue =
          await Prefs.getBool('hasHiddenChatsNotice', prefs: prefs);
      if (oldValue) {
        _savedChatsPageNoticeVersion = oldValue.toString(); // 'true'
        await Prefs.setString('chatsPageNoticeVersion', oldValue.toString(),
            prefs: prefs); // 'true'
        await Prefs.remove('hasHiddenChatsNotice', prefs: prefs);
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
  static Future<bool> getBool(String key, {SharedPreferences? prefs}) async {
    prefs = prefs ?? await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false;
  }

  static Future<void> setBool(String key, bool value,
      {SharedPreferences? prefs}) async {
    prefs = prefs ?? await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  static Future<String?> getString(String key,
      {SharedPreferences? prefs}) async {
    prefs = prefs ?? await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<void> setString(String key, String value,
      {SharedPreferences? prefs}) async {
    prefs = prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<void> remove(String key, {SharedPreferences? prefs}) async {
    prefs = prefs ?? await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
