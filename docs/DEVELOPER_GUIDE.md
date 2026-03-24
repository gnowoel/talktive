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

### 5. Background Tasks & Performance
- **TaskUtils.runBackground**: For any side-effect that is not critical to the immediate response (Notifications, Achievements, Stats), use `TaskUtils.runBackground(session, (...) async { ... })`. This prevents UI hanging while external network calls (FCM) or secondary database writes are performed.
- **Session Lifecycle**: Never use a closed request `session` inside a background task. `TaskUtils` correctly creates a temporary `backgroundSession` to handle this safely.

---

## 🧹 Maintenance & Best Practices
- **No `int` for User IDs**: All user identification must use UUIDs.
- **Denormalization**: Always carry `senderName` and `senderAvatar` on message protocols to avoid expensive multi-table joins during feed rendering.
- **Input Validation**: Never trust client input. Use `InputValidationService` on the server for all data mutation.
