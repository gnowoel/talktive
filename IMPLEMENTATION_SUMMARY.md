# Talktive Rebuild - Implementation Summary

## ✅ Completed Features

### 1. Smart Rate Limiting System
**File:** `talktive_server/lib/src/services/rate_limit_service.dart`

Floor-based rate limits (not overly restrictive as requested):
- **Floor 0:** 5 msg/min, 100 msg/hour, 2 sec between messages
- **Floor 1:** 10 msg/min, 300 msg/hour, 1 sec between messages  
- **Floor 2:** 15 msg/min, 500 msg/hour, no delay
- **Floor 3+:** Virtually unlimited (1000 msg/min, 10000 msg/hour)

Tracks per-user, per-channel limits in database with helpful error messages.

### 2. Enhanced Safety & Report System
**File:** `talktive_server/lib/src/endpoints/report_endpoint.dart`

**Report Abuse Prevention:**
- Floor 0 users cannot report (prevents new account abuse)
- Max 5 reports per day per user
- 30-minute cooldown between reports
- Cannot report same user twice in 24 hours
- Report penalty scales with reporter's floor level
- Admin-only moderation endpoints

**Credit Restoration:**
- Changed from 1 point/hour to **2 points/hour** (50 hours max recovery)
- Credit score capped at 100
- Users with score ≤ 0 are muted

### 3. Image Upload System
**File:** `talktive_server/lib/src/endpoints/image_endpoint.dart`

- **Storage:** Local `uploads/` directory (Docker volume mountable)
- **Restrictions:** Max 5MB, JPEG/PNG/WebP only
- **Security:** Filenames include user UUID, ownership verification
- **Access:** Served via `/uploads/{filename}`

**Docker Volume Setup:**
```bash
# In docker-compose.yml or docker run:
-v ./uploads:/app/uploads
```

### 4. Floor-Based Content Restrictions

**Plaza (Floor 0):**
- Text-only messages (no images)
- Rate-limited for new users

**Moments:**
- Only Floor 2+ can post moments
- Prevents spam from new accounts
- Credit score check before posting

### 5. Modern UI Components

**Plaza Screen:** `talktive_flutter/lib/screens/plaza/plaza_screen.dart`
- Glassmorphism design matching onboarding
- Shows user's floor and credit score
- Pull-to-refresh support
- Disabled input when muted

**Reusable Widgets:**
- `MessageBubble`: Modern chat bubbles with gradients
- `MessageInput`: Sleek input field with send button

### 6. Database Updates

**New Models:**
- `RateLimit`: Tracks message rate limits per user/channel
- Updated `Report`: Now uses UUIDs, added indexes

**Schema Changes:**
- Removed relation fields (Serverpod 3.x compatibility)
- Added `channelId` fields explicitly
- Migration created: `migrations/20260210110902404/`

---

## ⚠️ Known Issues & TODO

### 1. Message Endpoint Not Generating
**Issue:** The MessageEndpoint is not being included in the generated client code.

**Cause:** Likely related to Serverpod 3.x code generation changes or the `protocol` prefix usage.

**Temporary Workaround:** WebSocket streaming methods were removed to allow basic functionality.

**Fix Required:**
1. Debug why `EndpointMessage` is not in `talktive_client/lib/src/protocol/client.dart`
2. May need to revert to simpler import style or update Serverpod version
3. Check Serverpod 3.x documentation for endpoint naming conventions

### 2. Real-Time Streaming Disabled
**Status:** Commented out in `message_endpoint.dart`

**Reason:** Serverpod 3.x changed the streaming API:
- `session.sendStreamMessage()` method doesn't exist
- `session.messages.postMessage()` API changed
- Need to research new streaming approach

**Files Affected:**
- `talktive_server/lib/src/endpoints/message_endpoint.dart` (lines 108-111, 127-129)
- `talktive_flutter/lib/providers/realtime_chat_provider.dart` (needs update)

**Next Steps:**
1. Review Serverpod 3.x streaming documentation
2. Update to new WebSocket/streaming API
3. Test real-time message delivery

### 3. Flutter App Compilation Errors
**Errors Found:**
```
- client.message endpoint not found (due to issue #1)
- AppTheme.backgroundColor not defined
- PlazaScreen onExit parameter issue
```

**Fix Required:**
1. Add `backgroundColor` to `AppTheme` class
2. Fix PlazaScreen constructor
3. Update providers to use polling until streaming is fixed

---

## 📁 File Structure

### Server (talktive_server)
```
lib/src/
├── endpoints/
│   ├── image_endpoint.dart          ✅ NEW: Image upload
│   ├── message_endpoint.dart        ⚠️  MODIFIED: Streaming disabled
│   ├── moment_endpoint.dart         ✅ MODIFIED: Floor restrictions
│   ├── report_endpoint.dart         ✅ NEW: Report system
│   └── resident_endpoint.dart       
├── services/
│   ├── apartment_service.dart       ✅ MODIFIED: 2pts/hour restoration
│   └── rate_limit_service.dart      ✅ NEW: Smart rate limiting
└── protocol/
    ├── rate_limit.spy.yaml          ✅ NEW
    ├── report.spy.yaml              ✅ MODIFIED: UUIDs, indexes
    ├── channel_member.spy.yaml      ✅ MODIFIED: Removed relation
    └── message.spy.yaml             ✅ MODIFIED: Removed relation
```

### Client (talktive_flutter)
```
lib/
├── providers/
│   └── realtime_chat_provider.dart  ✅ NEW: Real-time chat (needs fix)
├── screens/
│   └── plaza/plaza_screen.dart      ✅ MODIFIED: Modern UI
└── widgets/chat/
    ├── message_bubble.dart          ✅ NEW: Chat bubbles
    └── message_input.dart           ✅ NEW: Input field
```

---

## 🚀 Next Steps to Complete

### Immediate (Critical)
1. **Fix Message Endpoint Generation**
   - Debug Serverpod code generation
   - Ensure `client.message` is available
   - May need to simplify imports or update Serverpod

2. **Fix Flutter Compilation Errors**
   - Add missing `AppTheme.backgroundColor`
   - Fix PlazaScreen constructor
   - Update providers temporarily to use polling

3. **Implement Real-Time Streaming**
   - Research Serverpod 3.x streaming API
   - Update message broadcasting
   - Test WebSocket connections

### Short Term (Important)
4. **Complete Plaza Screen**
   - Connect to message endpoint
   - Implement message sending
   - Add pull-to-refresh

5. **Build Moments Feed**
   - Create Moments screen UI
   - Implement image picker
   - Connect to image upload endpoint

6. **Private Chat Invitations**
   - Build invitation UI
   - Implement floor-based invite rules
   - Add accept/decline functionality

### Medium Term (Nice to Have)
7. **Push Notifications**
   - Integrate FCM
   - Add notification handlers
   - Implement deep linking

8. **User Profiles**
   - View other users' profiles
   - Show floor, credit score, stats
   - Add block/unblock UI

9. **Admin Dashboard**
   - Report moderation interface
   - User management
   - Analytics

---

## 🐳 Docker Setup for Image Uploads

Since you're using Docker for PostgreSQL and Redis, add this to your docker-compose.yml:

```yaml
services:
  serverpod:
    image: your-serverpod-image
    volumes:
      - ./uploads:/app/uploads  # Mount uploads directory
    ports:
      - "8080:8080"
```

Or when running manually:
```bash
docker run -v $(pwd)/uploads:/app/uploads your-serverpod-image
```

The `uploads/` directory will be created automatically on first image upload.

---

## 🔧 How to Resume Development

1. **Fix the message endpoint issue:**
   ```bash
   cd talktive_server
   # Try removing the protocol prefix and using simple imports
   # Or update Serverpod to latest version
   serverpod generate
   ```

2. **Fix Flutter errors:**
   ```dart
   // In lib/config/theme.dart
   static const Color backgroundColor = Color(0xFFF5F5F5);
   ```

3. **Test basic messaging:**
   ```bash
   cd talktive_server
   dart bin/main.dart
   
   # In another terminal
   cd talktive_flutter
   flutter run -d emulator-5554
   ```

4. **Implement polling as temporary solution:**
   ```dart
   // In plaza_screen.dart
   Timer.periodic(Duration(seconds: 2), (timer) {
     ref.read(chatProvider(1).notifier).refresh();
   });
   ```

---

## 📝 Notes

- **Image Storage:** Currently using local VPS storage. For production with 1000+ users, consider migrating to Backblaze B2 (~10x cheaper than AWS S3)
- **Rate Limiting:** Adjust limits in `rate_limit_service.dart` based on real usage patterns
- **Credit Restoration:** 2 points/hour means 50 hours to fully recover from 0 to 100
- **Serverpod Version:** 3.2.3 - some APIs have changed from 2.x
- **Provider vs Riverpod:** Both are kept for now to support legacy Firebase code during migration

---

## 🎯 Architecture Decisions Made

1. **No Relations in Protocol:** Removed to fix Serverpod 3.x generation issues
2. **Local Image Storage:** Simpler for development, easy to migrate later
3. **Floor-Based Permissions:** Prevents spam while allowing active users freedom
4. **Smart Rate Limiting:** Scales with user trust level
5. **Report Cooldowns:** Prevents report bombing while allowing legitimate reports

---

**Commit:** `871ec92` - feat: implement core safety features and image upload
**Branch:** `v8`
**Date:** February 10, 2026
