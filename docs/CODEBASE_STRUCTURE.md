# Talktive Codebase Structure

## Overview

The Talktive Flutter app supports two versions side-by-side during the migration period:
1. **Firebase Version** (Legacy) - Uses Firebase + Provider
2. **Serverpod Version** (New) - Uses Serverpod + Riverpod

This document provides a clear map of which files belong to which version.

---

## Directory Structure

```
talktive_flutter/lib/
├── main.dart                      # [SHARED] Entry point
├── version_selector.dart          # [SHARED] Version selector UI
├── firebase_options.dart          # [FIREBASE] Firebase configuration
├── app.dart                       # [FIREBASE] Firebase app entry
├── router.dart                    # [FIREBASE] Firebase routing
├── theme.dart                     # [FIREBASE] Firebase theme
├── serverpod_app.dart             # [SERVERPOD] Serverpod app entry
├── serverpod_client.dart          # [SERVERPOD] Serverpod client setup
├── pages/                         # [FIREBASE] All Firebase pages
├── screens/                       # [SERVERPOD] All Serverpod screens
├── providers/                     # [SERVERPOD] Riverpod providers
├── services/                      # [MIXED] See breakdown below
├── wrappers/                      # [MIXED] See breakdown below
├── widgets/                       # [MIXED] See breakdown below
├── config/                        # [SHARED] Configuration files
├── models/                        # [SHARED] Data models
├── helpers/                       # [SHARED] Utility functions
└── debug/                         # [SHARED] Debug utilities
```

---

## File Categorization

### 🔴 Firebase Version Only

**Entry Points:**
- `app.dart` - Firebase app
- `router.dart` - Firebase routing with GoRouter
- `theme.dart` - Firebase theme
- `firebase_options.dart` - Firebase configuration

**Pages Directory** (all files):
- `pages/users.dart`
- `pages/topics.dart`
- `pages/chats.dart`
- `pages/friends.dart`
- `pages/profile.dart`
- `pages/topic.dart`
- `pages/two_person_topic.dart`
- `pages/normal_topic.dart`
- `pages/launch.dart`
- `pages/create_topic.dart`
- `pages/edit_profile.dart`
- `pages/backup_account.dart`
- `pages/privacy_settings_page.dart`
- `pages/reports.dart`
- `pages/admin_users.dart`
- `pages/shares.dart`
- `pages/empty.dart`
- `pages/error.dart`

**Services:**
- `services/fireauth.dart` - Firebase Authentication
- `services/firedata.dartMap` - Firebase Realtime Database
- `services/firestore.dart` - Firestore operations
- `services/storage.dart` - Firebase Storage

**Wrappers:**
- `wrappers/initialize.dart` - Firebase initialization
- `wrappers/verify_user.dart` - Firebase auth verification
- `wrappers/setup.dart` - Firebase setup flow
- `wrappers/setup/` (all files) - Setup steps

**Widgets:**
- `widgets/user_info_loader.dart` - Uses Firestore
- `widgets/two_person_topic_input.dart` - Uses Firebase
- `widgets/normal_topic_input.dart` - Uses Firebase

---

### 🟢 Serverpod Version Only

**Entry Points:**
- `serverpod_app.dart` - Serverpod app
- `serverpod_client.dart` - Serverpod client setup

**Screens Directory** (all files):
- `screens/splash_screen.dart`
- `screens/onboarding/` - Welcome and profile setup
- `screens/home/home_screen.dart` - Main navigation
- `screens/chat/chat_screen.dart` - Individual chat
- `screens/chats/` - Private chats
- `screens/groups/` - Group chats
- `screens/plaza/` - Public chat
- `screens/moments/` - Photo feed
- `screens/profile/` - User profile
- `screens/achievements/` - Achievements

**Providers Directory** (all files):
- `providers/client_provider.dart` - Serverpod client
- `providers/auth_provider.dart` - Serverpod auth
- `providers/chat_provider.dart` - Chat state
- `providers/private_chat_provider.dart` - Private chats
- `providers/group_provider.dart` - Groups
- `providers/current_resident_provider.dart` - Current user data
- `providers/realtime_chat_provider.dart` - Real-time messaging
- `providers/notification_provider.dart` - Notifications
- `providers/streak_provider.dart` - Streaks
- `providers/achievement_provider.dart` - Achievements
- `providers/user_likes_provider.dart` - User likes/vouches
- `providers/user_profile_provider.dart` - External user profiles

**Services:**
- `services/serverpod_notification_service.dart` - Serverpod notifications

**Widgets:**
- `widgets/duo/` (all files) - Duolingo-style components
  - `duo_keyboard_dismissible.dart` - Keyboard dismissal wrapper
  - `duo_chat_layout.dart` - Standardized chat screen structure
- `widgets/chat/` - Chat components (used by Serverpod screens)

---

### 🟡 Shared Between Both Versions

**Config:**
- `config/theme.dart` - Shared theme configuration
- `config/ad_config.dart` - Ad configuration
- `config/message_report_config.dart` - Report configuration

**Models:**
- All files in `models/` - Data structures used by both

**Helpers:**
- All files in `helpers/` - Utility functions

**Services (Shared):**
- `services/messaging.dart` - FCM for Firebase version
- `services/avatar.dart` - Avatar utilities
- `services/settings.dart` - App settings
- `services/service_locator.dart` - Service locator
- `services/logging_service.dart` - Logging
- `services/error_recovery_service.dart` - Error handling
- `services/server_clock.dart` - Time sync
- `services/ad_service/` - Ad management
- `services/paginated_message_service.dart` - Pagination
- `services/user_cache.dart` - User caching
- `services/topic_cache.dart` - Topic caching
- `services/tribe_cache.dart` - Tribe caching
- `services/follow_cache.dart` - Follow caching
- `services/topic_followers_cache.dart` - Followers caching
- `services/message_meta_cache.dart` - Message metadata
- `services/moment_prompts.dart` - Moment prompts
- `services/edge_to_edge_manager.dart` - Edge-to-edge display

**Wrappers (Shared):**
- `wrappers/providers.dart` - Provider setup
- `wrappers/current_user.dart` - Current user wrapper
- `wrappers/subscribe.dart` - Subscription wrapper
- `wrappers/whats_new.dart` - What's new dialog

**Widgets (Shared):**
- Most widgets except those explicitly marked as Firebase or Serverpod
- `widgets/navigation.dart` - Navigation components
- `widgets/edge_to_edge_wrapper.dart` - Edge-to-edge wrapper
- `widgets/auth/` - Authentication widgets

---

## Import Guidelines

### For Firebase Version Files

```dart
// Firebase-specific imports
import '../services/fireauth.dart';
import '../services/firestore.dart';
import '../pages/users.dart';
import '../router.dart';
import '../theme.dart';

// Shared imports
import '../config/theme.dart';
import '../models/user.dart';
import '../helpers/helpers.dart';
import '../services/messaging.dart';
```

### For Serverpod Version Files

```dart
// Serverpod-specific imports
import '../serverpod_client.dart';
import '../providers/auth_provider.dart';
import '../screens/home/home_screen.dart';
import '../services/serverpod_notification_service.dart';

// Shared imports
import '../config/theme.dart';
import '../models/user.dart';
import '../helpers/helpers.dart';
import '../widgets/duo/duo_button.dart';
```

### For Shared Files

```dart
// Can import from either version based on context
// Or use conditional imports if needed
import '../config/theme.dart';
import '../models/user.dart';
import '../helpers/helpers.dart';
```

---

## Migration Strategy

### Current State (February 2026)
- Both versions coexist in the same codebase
- Users select version via `version_selector.dart`
- No file conflicts due to clear separation

### Phase 1: Parallel Development
- Continue developing both versions
- Firebase version: Maintenance only
- Serverpod version: Active development

### Phase 2: User Migration
- Gradually migrate users to Serverpod version
- Monitor metrics and feedback
- Keep Firebase version as fallback

### Phase 3: Deprecation
- Once Serverpod version is stable and adopted
- Remove Firebase version files:
  - Delete `app.dart`, `router.dart`, `theme.dart`
  - Delete `pages/` directory
  - Delete Firebase services
  - Delete Firebase wrappers
- Update `version_selector.dart` to launch Serverpod directly
- Clean up unused dependencies

### Phase 4: Reorganization (Optional)
- Move `serverpod_app.dart` → `app.dart`
- Move `screens/` → `pages/` (if desired)
- Flatten directory structure
- Remove version-specific naming

---

## Development Guidelines

### Adding New Features

**For Firebase Version:**
1. Add files to `pages/` directory
2. Use Firebase services (`fireauth`, `firestore`, etc.)
3. Use Provider for state management
4. Update `router.dart` with new routes

**For Serverpod Version:**
1. Add files to `screens/` directory
2. Use Serverpod client and providers
3. Use Riverpod for state management
4. Update `serverpod_app.dart` with new routes

**For Shared Features:**
1. Add to appropriate shared directory (`helpers/`, `models/`, etc.)
2. Ensure compatibility with both versions
3. Avoid version-specific dependencies

### Testing

**Firebase Version:**
```bash
# Select Firebase in version selector
# Test all pages and features
# Verify Firebase services work
```

**Serverpod Version:**
```bash
# Select Serverpod in version selector
# Test all screens and features
# Verify Serverpod backend integration
```

---

## Quick Reference

### "Which version does this file belong to?"

**Check the directory:**
- `pages/` → Firebase
- `screens/` → Serverpod
- `providers/` → Serverpod
- Everything else → Check imports

**Check the imports:**
- Imports `fireauth`, `firestore`, `firedata` → Firebase
- Imports `serverpod_client`, `talktive_client` → Serverpod
- Imports only from `config/`, `models/`, `helpers/` → Shared

**Check the file name:**
- `*_screen.dart` → Usually Serverpod
- `*_page.dart` → Usually Firebase
- `duo_*.dart` → Serverpod (Duolingo-style components)

---

## Summary

✅ **Clear separation** between Firebase and Serverpod versions  
✅ **No file conflicts** - different directories for version-specific code  
✅ **Shared utilities** - common code in `config/`, `models/`, `helpers/`  
✅ **Easy migration** - can remove Firebase files when ready  
✅ **Maintainable** - clear guidelines for where to add new code  

This structure allows both versions to coexist peacefully during the migration period while maintaining code clarity and preventing conflicts.
