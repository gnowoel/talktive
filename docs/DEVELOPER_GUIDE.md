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

### 2. High-Performance Infrastructure

Target: **10,000 active users** on a single **2 vCPU / 4GB RAM VPS**.

- **Caching**: Multi-tier strategy (Local Session -> Global Redis -> DB).
- **Background Tasks**: Use `TaskUtils.runBackground` for all non-critical side-effects (Notifications, XP, Stats).
- **Batching**: Use batch queries for feeds and unread counts to eliminate N+1 issues.

### 3. Authentication & Identity

- **Provider**: Firebase Auth (Google) linked to Serverpod Auth Core.
- **User IDs**: Strictly **UUID-based** (`UuidValue`). Never use legacy integer IDs.
- **Persona Sync**: Resident `userName` is automatically synced to the `AuthUser` profile during creation/update.

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
- **Database Mismatch**: If you see `DatabaseQueryException`, run `serverpod generate` and create a new migration.
- **Redis Connection**: Backend logic gracefully degrades to DB-only if Redis is unavailable, but performance will suffer.
