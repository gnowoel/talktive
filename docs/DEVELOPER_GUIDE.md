# Talktive Developer Guide

## 🛠️ Essential Commands

### 1. Server Management

- **Start Server**: `dart bin/main.dart --apply-migrations`
- **Regenerate Code**: `serverpod generate`
- **Create Migration**: `serverpod create-migration --force`
- **Reset Database**: `./scripts/reset_db.sh` (Drops public schema)

### 2. Frontend Build

- **Code Gen**: `dart run build_runner build --delete-conflicting-outputs`
- **Run (Web)**: `flutter run -d web-server --web-port 8083 --web-hostname=localhost`

---

## 🏗️ Architectural Principles

### 1. Service-Delegated Architecture

To maintain a clean and testable codebase, we follow strict delegation:

- **Endpoints**: Lean controllers that handle authentication and argument parsing.
- **Services**: Contain all domain logic, validation, and side-effects.
- **Unified Validation**: All services use the `ValidationResult` utility for consistent `TalktiveException` responses.
- **Unified Channel Management**: The `ChannelService` acts as the central authority for all channel-related operations (Plaza, Lounges, Private Chats).
  - **Access Control**: Always use `ChannelService.validateMember(session, channelId, userId)` for authorization checks.
  - **Metadata Sync**: `ChannelService.updateLastMessage` ensures that last message previews and timestamps are consistently updated across all channel types for unread tracking.
  - **Status Management**: Membership transitions (joining, applying, inviting) are managed centrally to ensure consistent state and validation.

### 2. High-Performance Infrastructure

Target: **10,000 active users** on a single **2 vCPU / 4GB RAM VPS**.

- **Storage (Cloudflare R2)**: Standardized on S3-compatible storage with zero egress fees.
  - **Authorized Uploads**: Clients must request an `UploadDescription` via `MediaEndpoint` before uploading.
  - **Environment Parity**: Uses `public` (local disk) storage in development and `s3` (R2) in production.
- **Caching**: Multi-tier strategy (Local Session -> Global Redis -> DB).
- **Background Tasks**: Use `TaskUtils.runBackground` for all non-critical side-effects (Notifications, XP, Stats).
- **Batching**: Use batch queries for feeds and unread counts to eliminate N+1 issues.

### 3. High-Performance Messaging

Messaging is the heart of the residence and must be extremely responsive.

- **Immediate UI-Critical Broadcast**: Message posting to the real-time WebSocket stream (`session.messages.postMessage`) MUST occur immediately after the database save. Do not wait for side-effects like push notifications or XP awards to complete before broadcasting the message to the recipient's UI.
- **Background Offloading**: All non-UI-critical side effects (Gamification, Streak updates, Achievements, Push Notifications) MUST be offloaded to `TaskUtils.runBackground`. This ensures that even if FCM delivery is slow, the user experience remains snappy.
- **Privacy at the Source**: Block checks and permission validation are centralized in `ChannelService.validateNoBlockFlow` and `ChannelService.validateMember`. Always call these before performing any write operations.

### 3. Authentication & Identity

- **Provider**: Firebase Auth (Google) linked to Serverpod Auth Core.
- **User IDs**: Strictly **UUID-based** (`UuidValue`). Never use legacy integer IDs.
- **Persona Sync**: Resident `userName` is automatically synced to the `AuthUser` profile during creation/update.
- **Legacy Migration**: When a Firebase user links Google for the first time and does not yet have a `Resident`, the server performs a one-time lookup of legacy profile data from Firebase (Firestore first, RTDB fallback). The migration is server-authoritative and may restore persona fields, moderator/admin role, and XP-derived level from legacy message count.
- **Do Not Trust Client Migration Fields**: `xp`, `level`, and `role` must never be accepted from Flutter onboarding payloads. Those values are derived exclusively on the backend from trusted legacy data.
- **Auto-Login Rule**: Serverpod auto-login should only happen for Firebase sessions that already include `google.com`. Legacy email / anonymous Firebase sessions must pass through the Google-linking UX before entering the new onboarding flow.

---

## 📬 Notification Architecture

Talktive uses a self-healing, high-throughput notification system.

### 1. Registration

- Clients register FCM tokens via `NotificationEndpoint.registerDeviceToken`.
- Tokens are stored in the `device_token` table linked to the user's UUID.

### 2. Delivery Flow

- All notifications are triggered via `NotificationService` on the backend.
- Delivery is asynchronous (wrapped in `runBackground`) to prevent endpoint lag.
- **Parallel Delivery**: `FCMService` triggers calls to multiple devices in parallel via `Future.wait`.

### 3. Self-Healing (Purging)

- The server automatically detects `404 - UNREGISTERED` responses from FCM.
- Stale tokens are immediately deleted from the database to maintain performance.

---

## 🛡️ Safety System Implementation

### 1. Hybrid Floor

Access to public features is restricted by `min(level, trustCap)`.

- **Level**: Earned via XP.
- **Trust Score**: Starts at 100. Decreases by -30 per report, increases by +10 per vouch.

### 2. Privacy Hardening

- **Blocking**: Restricts both private messages and push notifications.
- **Peephole**: Provides a `UserProfileView` (including recent moments and top badges) for safe invite inspection.
- **Inbound Privacy Gating**: We use a "gate-at-the-boundary" pattern. All profile-returning methods must utilize `ResidentService.gateResident(viewer, resident)` to ensure sensitive fields (e.g., `lastSeen`) are only visible to authorized (Plus) members.
- **Real-Time Filtering**: WebSocket streams in `MessageEndpoint.subscribe` are programmatically filtered to strip `TypingIndicator` and `ReadReceiptEvent` objects for non-Plus subscribers.

---

## 🧪 Quality Assurance & TDD

We follow a **Test-Driven Development (TDD)** approach to ensure architectural stability.

### 1. Testing Tiers

- **Backend Unit Tests**: Pure logic in Service classes (e.g., `GamificationService` math).
- **Backend Integration Tests**: Full endpoint flows using `withServerpod` for real database interaction.
- **Frontend Provider Tests**: Verifying state changes in Riverpod providers.
- **Frontend Widget Tests**: UI consistency for the `Duo` component library.

### 2. TDD Workflow

Every new feature or bugfix should follow the **Red-Green-Refactor** cycle:

1. **RED**: Write a failing test defining the requirement.
2. **GREEN**: Write minimal code to pass the test.
3. **REFACTOR**: Optimize and align with architectural standards.

---

## 💡 Troubleshooting

- **Google Sign-In Errors**: Ensure you use `localhost` (not `127.0.0.1`) and port `8083`.
- **Account Recognition**: If an existing Google user is not recognized after clearing site data, use the **"I'm an Existing User" -> "Continue with Google"** flow. The system automatically handles cases where a Google account is already linked to a different Talktive identity by signing you into the existing account.
- **Migration Review**: If onboarding prefill appears incomplete for a legacy user, verify the legacy record under Firebase `users/{uid}` and confirm language / gender values use the expected legacy formats before changing conversion rules.
- **Debug Shortcuts**: In `kDebugMode`, the `VersionSelector` provides a **"Direct to Firebase (Debug Only)"** link to bypass version selection and account restoration steps during development.
- **Database Mismatch**: If you see `DatabaseQueryException`, run `serverpod generate` and create a new migration.
- **Redis Connection**: Backend logic gracefully degrades to DB-only if Redis is unavailable, but performance will suffer.
