# Push Notification Preferences Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a server-side preference for push notifications and a UI in Settings to manage it and diagnose system permissions.

**Architecture:** Update the `Resident` model with a new field, extend the `updatePrivacy` endpoint, and add a new section to the Flutter `SettingsScreen`.

**Tech Stack:** Serverpod, Flutter, Firebase Messaging, App Settings.

---

### Task 1: Backend Data Model Update

**Files:**
- Modify: `talktive_server/lib/src/protocol/resident.spy.yaml`

- [ ] **Step 1: Add `allowPushNotifications` field**
Add the field to the `fields` section of `Resident`.

```yaml
  # Global Notification Setting
  allowPushNotifications: bool, default=true
```

- [ ] **Step 2: Generate Serverpod code**
Run: `cd talktive_server && serverpod generate`
Expected: Code generated successfully in `talktive_server/lib/src/protocol/resident.dart` and `talktive_client`.

- [ ] **Step 3: Commit**
```bash
git add talktive_server/lib/src/protocol/resident.spy.yaml
git commit -m "feat(server): add allowPushNotifications to Resident model"
```

---

### Task 2: Backend Service & Endpoint Update

**Files:**
- Modify: `talktive_server/lib/src/services/resident_service.dart`
- Modify: `talktive_server/lib/src/endpoints/resident_endpoint.dart`

- [ ] **Step 1: Update `ResidentService.updatePrivacy`**
Update the signature and implementation to handle `allowPushNotifications`.

```dart
  static Future<protocol.Resident> updatePrivacy(
    Session session, {
    required protocol.Resident resident,
    bool? hideAds,
    bool? allowPushNotifications, // Add this
    // ... rest of parameters
  }) async {
    // ... 
    if (allowPushNotifications != null) {
      resident.allowPushNotifications = allowPushNotifications;
    }
    // ...
  }
```

- [ ] **Step 2: Update `ResidentEndpoint.updatePrivacy`**
Update the endpoint to accept the new parameter.

```dart
  Future<protocol.Resident> updatePrivacy(
    Session session, {
    bool? hideAds,
    bool? allowPushNotifications, // Add this
    // ...
  }) async {
    // ...
    return await ResidentService.updatePrivacy(
      session,
      resident: resident,
      hideAds: hideAds,
      allowPushNotifications: allowPushNotifications, // Pass it here
      // ...
    );
  }
```

- [ ] **Step 3: Commit**
```bash
git add talktive_server/lib/src/services/resident_service.dart talktive_server/lib/src/endpoints/resident_endpoint.dart
git commit -m "feat(server): update updatePrivacy endpoint for notifications"
```

---

### Task 3: Flutter Dependencies & Client Sync

**Files:**
- Modify: `talktive_flutter/pubspec.yaml`

- [ ] **Step 1: Add `app_settings` dependency**
Run: `cd talktive_flutter && flutter pub add app_settings`
Expected: `app_settings` added to `pubspec.yaml`.

- [ ] **Step 2: Sync client code**
Run: `cd talktive_server && serverpod generate` (just to be sure client is perfectly synced).
Expected: `talktive_flutter/lib/serverpod_client.dart` (and generated client files) updated.

- [ ] **Step 3: Commit**
```bash
git add talktive_flutter/pubspec.yaml
git commit -m "chore(flutter): add app_settings dependency"
```

---

### Task 4: Flutter UI - Settings Screen

**Files:**
- Modify: `talktive_flutter/lib/screens/activity/settings_screen.dart`

- [ ] **Step 1: Update `_updatePrivacySettings` signature**
Add `allowPushNotifications` to the helper method.

```dart
  Future<void> _updatePrivacySettings(
    BuildContext context,
    WidgetRef ref, {
    bool? hideAds,
    bool? allowPushNotifications, // Add this
    // ...
  }) async {
    // ...
    try {
      await client.resident.updatePrivacy(
        hideAds: hideAds ?? resident.hideAds,
        allowPushNotifications: allowPushNotifications ?? resident.allowPushNotifications,
        // ...
      );
      // ...
    }
  }
```

- [ ] **Step 2: Add Notification Preferences section**
Add the new UI elements between Premium Features and Ad Preferences.

```dart
  // Inside build method's ListView:
  const SizedBox(height: AppTheme.duoSpacingLarge),
  _buildSectionHeader(context, 'Notification Preferences'),
  _buildFeatureRow(
    context,
    icon: Icons.notifications_active,
    title: 'Push Notifications',
    description: 'Get instant alerts for messages, moments, and plaza activity.',
    isLocked: false,
    value: resident.allowPushNotifications,
    onChanged: (val) => _updatePrivacySettings(context, ref, allowPushNotifications: val),
  ),
  const SizedBox(height: AppTheme.duoSpacingMedium),
  DuoCard(
    onTap: () => _diagnoseNotifications(context),
    child: const ListTile(
      leading: Icon(Icons.settings_suggest, size: 28, color: AppTheme.duoPurple),
      title: Text('System Permission Status', style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('Check if your phone allows Talktive to send notifications.'),
      trailing: Icon(Icons.chevron_right, size: 24, color: AppTheme.textSecondary),
    ),
  ),
```

- [ ] **Step 3: Implement `_diagnoseNotifications`**
Add the diagnostic logic to the `SettingsScreen` class.

```dart
  Future<void> _diagnoseNotifications(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.getNotificationSettings();

    if (!context.mounted) return;

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      DuoSnackBarHelper.showSuccess(context, 'All systems go! 🚀');
    } else if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      await messaging.requestPermission(alert: true, badge: true, sound: true);
    } else {
      // Show bottom sheet or dialog to open settings
      _showPermissionDeniedDialog(context);
    }
  }

  void _showPermissionDeniedDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔔', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text('Notifications are Blocked', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            const Text('To receive pings, you need to enable notifications in your phone\'s system settings.', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            DuoButton(
              text: 'Open Phone Settings',
              onPressed: () {
                Navigator.pop(context);
                import 'package:app_settings/app_settings.dart'; // Ensure import
                AppSettings.openAppSettings(type: AppSettingsType.notification);
              },
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
```

- [ ] **Step 4: Commit**
```bash
git add talktive_flutter/lib/screens/activity/settings_screen.dart
git commit -m "feat(flutter): implement notification preferences and diagnostics"
```

---

### Task 5: Verification

- [ ] **Step 1: Verify server generation**
Run: `cd talktive_server && serverpod generate`
Expected: No errors, all models updated.

- [ ] **Step 2: Verify Flutter compilation**
Run: `cd talktive_flutter && flutter build web` (or any other platform check)
Expected: Success.

- [ ] **Step 3: Manual check (optional)**
Run the app and server locally if possible to confirm the toggle works and updates the DB.
