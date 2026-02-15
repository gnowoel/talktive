# Notification Architecture

## Overview

The Talktive app supports two versions side-by-side during the migration period:
1. **Firebase Version** (Old) - Uses Firebase + Provider
2. **Serverpod Version** (New) - Uses Serverpod + Riverpod

Each version has its own notification service implementation to maintain compatibility.

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     main.dart                                │
│                         │                                    │
│                         ▼                                    │
│                 version_selector.dart                        │
│                    /          \                              │
│                   /            \                             │
│                  ▼              ▼                            │
│           app.dart         serverpod_app.dart                │
│        (Firebase)           (Serverpod)                      │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                  Notification Services                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Firebase Version              Serverpod Version            │
│  ┌──────────────────┐          ┌──────────────────────┐    │
│  │  messaging.dart  │          │ serverpod_           │    │
│  │                  │          │ notification_        │    │
│  │  - FCM setup     │          │ service.dart         │    │
│  │  - Local notifs  │          │                      │    │
│  │  - Legacy routes │          │ - FCM setup          │    │
│  │  - No backend    │          │ - Backend token reg  │    │
│  │    integration   │          │ - New notification   │    │
│  │                  │          │   types              │    │
│  │  UNCHANGED       │          │ - Deep linking       │    │
│  └──────────────────┘          └──────────────────────┘    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Firebase Version (Old)

### Files
- `lib/app.dart` - Main app entry point
- `lib/services/messaging.dart` - Original notification service
- `lib/router.dart` - GoRouter configuration

### Notification Service: `messaging.dart`

**Features:**
- Firebase Cloud Messaging (FCM) setup
- Local notifications with flutter_local_notifications
- Notification tap handling for legacy routes
- No backend integration

**Notification Types:**
- `chat` - Private chat messages
- `topic` - Topic/room messages (legacy)

**Routes:**
- `/chats` - Chat list
- `/topics/:id` - Specific topic

**Status:** ✅ **UNCHANGED** - Fully functional, no modifications made

---

## Serverpod Version (New)

### Files
- `lib/serverpod_app.dart` - Main app entry point
- `lib/services/serverpod_notification_service.dart` - New notification service
- `lib/screens/splash_screen.dart` - Initializes notifications
- `lib/screens/home/home_screen.dart` - Handles pending notifications

### Notification Service: `serverpod_notification_service.dart`

**Features:**
- Firebase Cloud Messaging (FCM) setup
- Backend token registration via `client.notification.registerDeviceToken()`
- Automatic token refresh and re-registration
- Local notifications with flutter_local_notifications
- Deep linking to all main screens
- Pending notification handling

**Notification Types:**
- `message` - New messages in Plaza
- `moment_like` - Someone liked your moment
- `moment_comment` - Someone commented on your moment
- `achievement` - Achievement unlocked
- `streak` - Streak milestone or reminder
- `group_invite` - Invited to a group

**Routes:**
- `/plaza` - Public chat (HomeScreen index 0)
- `/moments` - Moments feed (HomeScreen index 1)
- `/chats` - Private chats (HomeScreen index 2)
- `/groups` - Group chats (HomeScreen index 3)
- `/profile` - User profile (HomeScreen index 4)
- `/achievements` - Achievements screen

**Backend Integration:**
- Registers FCM tokens with Serverpod backend
- Tokens stored in `device_token` table
- Notifications sent via `NotificationService` on server
- Supports Android and iOS platforms

**Status:** ✅ **COMPLETE** - Fully functional with backend integration

---

## Backend (Serverpod)

### Protocols
- `user_notification.spy.yaml` - Notification data structure
- `device_token.spy.yaml` - FCM token storage

### Services
- `NotificationService` - Sends notifications to users
  - `sendMessageNotification()`
  - `sendMomentLikeNotification()`
  - `sendMomentCommentNotification()`
  - `sendAchievementNotification()`
  - `sendStreakReminderNotification()`
  - `sendGroupInviteNotification()`

### Endpoints
- `NotificationEndpoint`
  - `registerDeviceToken(token, platform)` - Register FCM token
  - `unregisterDeviceToken(token)` - Remove FCM token
  - `getUserNotifications(limit, offset)` - Get user's notifications
  - `markAsRead(notificationId)` - Mark notification as read
  - `getUnreadCount()` - Get unread notification count

### Database Tables
- `user_notification` - Stores notification history
- `device_token` - Stores FCM tokens per user

### Migration
- `20260211100938725` - Creates notification tables

---

## Key Design Decisions

### 1. Separate Services
**Why:** Maintain compatibility during migration period. The Firebase version must continue working without any changes.

**Benefit:** Zero risk of breaking the old version while developing the new one.

### 2. Backend Token Registration
**Why:** Serverpod backend needs to know which devices to send notifications to.

**How:** On app start and token refresh, the Serverpod version registers the FCM token with the backend via `client.notification.registerDeviceToken()`.

### 3. Deep Linking
**Why:** Users should navigate directly to relevant content when tapping notifications.

**How:** 
- Routes defined in `serverpod_app.dart`
- `HomeScreen` accepts `initialIndex` to show specific tab
- `ServerpodNotificationService.navigateFromNotification()` handles routing

### 4. Pending Notifications
**Why:** Handle notifications that arrive when app is terminated.

**How:**
- Service stores notification data in `_pendingNotificationData`
- `HomeScreen` checks for pending notifications on mount
- Navigates to appropriate screen after app initialization

---

## Testing

### Firebase Version
1. Launch app via `version_selector.dart`
2. Select "Firebase" version
3. Verify notifications work with legacy routes
4. Confirm no errors or crashes

### Serverpod Version
1. Launch app via `version_selector.dart`
2. Select "Serverpod" version
3. Verify FCM token registration in backend logs
4. Test notification types:
   - Like a moment → Receive notification → Tap → Navigate to moments
   - Comment on moment → Receive notification → Tap → Navigate to moments
   - Unlock achievement → Receive notification → Tap → Navigate to achievements
5. Test foreground and background notifications
6. Test app launch from terminated state via notification

---

## Future Enhancements

### Phase 6.1 Remaining Tasks
- [ ] Add badge counts for unread messages
- [ ] Create notification preferences screen
- [ ] Implement notification grouping
- [ ] Add sound and vibration customization
- [ ] Test on iOS devices

### Migration Path
1. Keep both versions running in parallel
2. Gradually migrate users to Serverpod version
3. Monitor notification delivery rates
4. Once migration complete, remove Firebase version
5. Delete `messaging.dart` and `app.dart`
6. Make `serverpod_app.dart` the default

---

## Troubleshooting

### Firebase Version Not Receiving Notifications
- Check Firebase console configuration
- Verify `google-services.json` is up to date
- Check FCM token generation in logs

### Serverpod Version Not Receiving Notifications
- Check backend logs for token registration
- Verify `NotificationService` is sending notifications
- Check device token in database: `SELECT * FROM device_token WHERE user_id = ?`
- Verify notification creation: `SELECT * FROM user_notification WHERE user_id = ?`
- Check FCM token is valid and not expired

### Deep Linking Not Working
- Verify routes are defined in `serverpod_app.dart`
- Check notification data structure matches expected format
- Ensure `HomeScreen` is checking for pending notifications
- Verify `navigateFromNotification()` is being called

---

## Summary

✅ **Firebase version remains unchanged and functional**  
✅ **Serverpod version has full notification support**  
✅ **Backend integration complete**  
✅ **Deep linking implemented**  
✅ **Both versions can coexist during migration**

The notification architecture is designed for a smooth migration from Firebase to Serverpod while maintaining backward compatibility and zero downtime.
