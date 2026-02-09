# Serverpod Development Learnings

## 1. Authentication: Int vs UUID
Serverpod 3.2 defaults to **UUID-based** `AuthUser` and JWT tokens, using the `serverpod_auth_core_server` package.
However, many legacy examples (and internal logic like `Resident` in this project) might use `int` IDs.

**The Mismatch**:
- Legacy: `Resident` used `userInfoId: int`.
- Modern: `AuthServices` creates users with `UuidValue`.
- Result: `ResidentEndpoint` fails to insert rows, or `MessageEndpoint` fails to lookup residents (`int` vs `String` type error), leading to 500 errors.

**The Fix**:
Always use `UuidValue` for foreign keys linking to `UserInfo` or `AuthUser`.
- `resident.spy.yaml`: `userInfoId: UuidValue`
- `MessageEndpoint`: Parse `authenticationInfo.userIdentifier` (String) into `UuidValue`.

## 2. Serverpod Generate & Migrations
- **Syntax Errors**: `serverpod generate` halts if *any* file has syntax errors. You must fix dart errors before regenerating code.
- **Force Migration**: When changing a column type (e.g., int -> uuid), `serverpod create-migration` will warn about data loss. Use `--force` to proceed.
- **Applying Migrations**: `dart bin/apply_migrations.dart` is the standard tool, often aliased in `bin/main.dart` args.

## 3. Debugging Endpoints
- **Try-Catch**: Serverpod endpoints don't always surface distinct errors in the console. Wrapping endpoint logic in a global `try-catch` block (and printing the stack trace) is essential for finding the root cause of 500 errors.
- **Verification Scripts**: Creating small CLI scripts in `tools/` (like `check_channels.dart` or `reproduce_bug.dart`) is faster than running the full Flutter app for backend verification.

## 4. Environment & Ports
- **Stuck Ports**: If the server fails to start with "Address already in use", use `lsof -t -i:8080 | xargs kill -9` to clear the ports.
- **Docker**: Postgres and Redis are critical. Ensure `docker compose up` is running before starting the server.

## 5. Firebase Auth & Client Initialization
- **SessionManager**: When using `serverpod_auth_firebase_flutter`, the `SessionManager` is not automatically initialized in the same way as standard Serverpod auth.
- **Initialization Order**:
  1. Initialize `Client` with `FlutterAuthenticationKeyManager()`.
  2. Instantiate `SessionManager` using `SessionManager(caller: client.modules.auth)`.
  3. Await `sessionManager.initialize()`.
  4. Only *then* call `initializeClient(client)`.
- **Runtime Errors**: Failing to follow this order leads to `AssertionError` or `SessionManager.instance` being null/uninitialized.
- **Sign Out**: `sessionManager.signOut()` might not be available or behave as expected if not strictly using the `serverpod_auth_email` flow. We rely on `FirebaseAuth.instance.signOut()` and `GoogleSignIn().signOut()` for the actual provider logic.
