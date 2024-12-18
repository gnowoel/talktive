import 'package:shared_preferences/shared_preferences.dart' as prefs;

class Settings {
  static const _notificationKey = 'notification_permission_requested';

  static Future<bool> hasRequestedNotificationPermission() async {
    final preferences = await prefs.SharedPreferences.getInstance();
    return preferences.getBool(_notificationKey) ?? false;
  }

  static Future<void> markNotificationPermissionRequested() async {
    final preferences = await prefs.SharedPreferences.getInstance();
    await preferences.setBool(_notificationKey, true);
  }
}
