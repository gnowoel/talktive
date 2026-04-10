# Design Spec: Push Notification Preferences

## Background
Talktive residents are asked for push notification consent during onboarding. If they skip or deny this, they currently have no way to enable it later within the app. This feature adds a dedicated section in the Settings screen to manage notification preferences and diagnose/fix OS-level permissions.

## Goals
- Add a server-side preference to globally enable/disable push notifications for a resident.
- Provide a clear UI in the Settings screen to toggle this preference.
- Implement a "Diagnostic" action to help users resolve missing or denied OS permissions.
- Ensure the feature is available to all residents (not locked behind Talktive Plus).

## Design

### 1. Data Model & Backend (Server-Side Preference)
We will treat notification consent as a persistent resident preference.

- **Resident Model (`resident.spy.yaml`):**
    - Add `allowPushNotifications: bool, default=true`.
- **API (`resident_endpoint.dart`):**
    - Update the `updatePrivacy` method to accept and persist the `allowPushNotifications` field.
- **Service Logic:**
    - The backend notification service must check `resident.allowPushNotifications` before attempting to send any FCM payload.

### 2. User Interface (Frontend)
A new section will be added to `SettingsScreen` (`lib/screens/activity/settings_screen.dart`).

#### **Section: NOTIFICATION PREFERENCES**
Located between "Premium Features" and "Ad Preferences".

- **Global Toggle (`DuoSwitch`):**
    - **Icon:** `Icons.notifications_active`
    - **Title:** `Push Notifications`
    - **Description:** `Get instant alerts for messages, moments, and plaza activity.`
    - **Behavior:** Toggles the server-side `allowPushNotifications` preference.
- **Diagnostic Card (`DuoCard`):**
    - **Icon:** `Icons.settings_suggest`
    - **Title:** `System Permission Status`
    - **Subtitle:** `Check if your phone allows Talktive to send notifications.`
    - **Behavior:**
        - Checks the current `FirebaseMessaging` authorization status.
        - If **Authorized**: Shows a success snackbar ("All systems go! 🚀").
        - If **Not Determined**: Re-triggers the system permission dialog.
        - If **Denied**: Shows a bottom sheet explaining that permissions must be enabled in System Settings, with a button to "Open Phone Settings" (using a package like `app_settings`).

## Architecture & Components
- **State Management:** Uses the existing `currentResidentProvider` (Riverpod) to reflect and update the server-side state.
- **Permissions:** Uses `firebase_messaging` for status checks and permission requests.
- **Styling:** Adheres to the "Duo" design system (purple accents, rounded cards, high-energy visuals).

## Testing Strategy
- **Unit Tests:** Verify the `updatePrivacy` endpoint correctly persists the new field.
- **UI Tests:** Ensure the toggle reflects the resident's state and calls the update method.
- **Manual Verification:** 
    - Test toggling the switch and confirming the server update.
    - Test the diagnostic button with permissions allowed, not requested, and denied.
