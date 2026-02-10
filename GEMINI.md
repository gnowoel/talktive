# Project Context for Assistants

This project is a migration of the "Talktive" anonymous chat app from Firebase to Serverpod.

## Status

- **Backend**: Serverpod 3.2.3 (Postgres + Redis)
- **Frontend**: Flutter (Dual-boot Firebase/Serverpod)
- **Authentication**: **Firebase Auth** (Google) -> Serverpod Auth Core session (JWT/SAS).
  - Replaced native Serverpod Google Sign-In with Firebase to leverage existing infrastructure.
  - `AuthServices` (serverpod_auth_core_server) used for user creation.
  - `JwtTokenManager`/`ServerSideSessionsConfig` issue tokens.
  - `Resident` table links to `AuthUser` via `userInfoId` (UUID).
  - **Legacy Warning**: Do not use `int` for User IDs. The system is fully migrated to UUIDs.

## Key Components

### Server (`talktive_server`)

- `ResidentEndpoint`: Creates anonymous users, generates UserProfile, inserts Resident, returns JWT.
- `MessageEndpoint`: Handles sending messages to channels (Plaza, etc.). Enforces credit score & floor rules.
- `Channel`: `ChannelType.plaza` (ID 1) is the default public channel.

### Client (`talktive_flutter`)

- `AuthProvider`: Handles Firebase Google sign-in, exchanges Firebase ID token for Auth Core session via `firebaseIdp`.
- `ChatScreen`: Displays messages. Uses `MessageEndpoint` for sending.

## Recent Fixes

- **500 Error (Feb 2026)**: Caused by `int` vs `UUID` mismatch in `Resident`. Fixed by:
  1. Migrating `Resident.userInfoId` to `UuidValue`.
  2. Updating `ResidentEndpoint` to use `AuthServices.instance.authUsers.create`.
  3. Configuring `MessageEndpoint` to use `authenticationInfo.userIdentifier` (String/UUID).

## Useful Commands

- **Start Server**: `dart bin/main.dart --apply-migrations`
- **Kill Stalled Server**: `lsof -t -i:8080 -i:8081 -i:8082 | xargs kill -9`
- **Regenerate Code**: `serverpod generate`
- **Create Migration**: `serverpod create-migration --force`
