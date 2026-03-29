# Developer Guide & Troubleshooting

## 🛠️ Essential Commands

### Server Management
- **Start Server**: `dart bin/main.dart --apply-migrations`
- **Kill Stalled Server**: `lsof -t -i:8080 -i:8081 -i:8082 | xargs kill -9`
- **Regenerate Code**: `serverpod generate`
- **Create Migration**: `serverpod create-migration --force`
- **Reset Database**: `./scripts/reset_db.sh` (Drops public schema for clean recreation)

### Database Cleanup
- **Clear Chats Only**: `./scripts/clear_chats.sh`
- **Clear Moments Only**: `./scripts/clear_moments.sh`

---

## 💡 Serverpod Learnings

### 1. Authentication: Int vs UUID
Serverpod 3.3.1 defaults to **UUID-based** `AuthUser`. Always use `UuidValue` for foreign keys linking to `UserInfo` or `AuthUser`.
- `resident.spy.yaml`: `userInfoId: UuidValue`
- `MessageEndpoint`: Parse `authenticationInfo.userIdentifier` (String) into `UuidValue`.

### 2. Code Generation & Migrations
- **Syntax Errors**: `serverpod generate` halts if _any_ file has syntax errors. Fix Dart errors first.
- **Force Migration**: Use `--force` when changing column types to bypass data loss warnings.

### 3. Debugging Endpoints
- **Try-Catch**: Wrap endpoint logic in `try-catch` blocks and print stack traces to debug 500 errors.
- **TalktiveException**: Use `protocol.TalktiveException` for user-facing errors (Lounge not found, access denied, etc.). These are automatically parsed by the frontend's `SnackBarHelper`.

### 4. Client-Side Auth Initialization
Order of operations for Firebase + Serverpod Auth:
1. Instantiate `Client`.
2. Create `FlutterAuthSessionManager()`.
3. Assign `client.authSessionManager = sessionManager`.
4. Await `sessionManager.initialize()`.
5. Call `client.firebaseIdp.login(idToken: ...)` after Google Sign-In.

### 4.1 Environment Selection
- `AppConfig` centralizes runtime environment settings for both the legacy Firebase app path and the Serverpod app path.
- Debug builds default to localhost / emulator endpoints.
- Release builds default to the production Serverpod URL from `talktive_flutter/assets/config.json`.
- Firebase Emulator Suite usage is controlled centrally and should remain a development-only feature.
- Optional overrides:
  - `--dart-define=SERVERPOD_URL=https://api.talktive.app`
  - `--dart-define=USE_FIREBASE_EMULATORS=false`

### 5. Background Tasks & Performance
- **TaskUtils.runBackground**: For any side-effect that is not critical to the immediate response (Notifications, Achievements, Stats), use `TaskUtils.runBackground(session, (...) async { ... })`. This prevents UI hanging while external network calls (FCM) or secondary database writes are performed.
- **Session Lifecycle**: Never use a closed request `session` inside a background task. `TaskUtils` correctly creates a temporary `backgroundSession` to handle this safely.

---

## 🚀 Performance & Resource Optimization

This project targets a **10,000 user capacity** on a single **2 vCPU / 4GB RAM VPS**. To ensure stability under high load, follow these architectural principles:

### 1. Server-Side (High Throughput)
- **Zero N+1 Queries**: Every profile load or list view must be a single efficient query. Use `include` clauses in Serverpod models.
- **Service-Level Caching**: All high-traffic data (Resident profiles, Lounge members) must flow through service methods that implement the **Redis-Database** caching pattern.
- **Background Delegation**: All non-critical side effects (Gamification XP, Notifications, Statistics) MUST use `TaskUtils.runBackground`.

### 2. Client-Side (Dynamic UX & Efficiency)
- **Fluid Animations**: Use `flutter_animate` and haptic feedback to create an interactive, premium experience.
- **Data Efficiency**: Use the denormalized fields (`senderName`, `senderAvatar`) provided in the message protocol to ensure the UI remains snappy during rapid scrolling.
- **Asset Compliance**: Adhere to the **5MB image** and **60s voice** limits. This ensures high throughput for all users and maintains server responsiveness during peak hours.

