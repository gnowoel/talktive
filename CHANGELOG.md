# Talktive Development Changelog

## April 8, 2026 - Backend Consolidation & Security Hardening 🏗️🛡️⚡

### Search & Security
- **SQL Injection Prevention**: Properly escaped raw query literals in `SearchService` (both resident and lounge filters) when using custom `Expression` and `ilike` patterns. This prevents potential syntax errors or injection via the search bar.
- **Activity Tracking Hardening**: Ensured `lastMessageDate` is updated synchronously in the primary message-send path. This guarantees that "Active Residents" discovery results are always fresh and reliable for real-time engagement.

### Architecture & Service Consolidation
- **Unified Lounge Membership**: Consolidated the lounge joining logic into `LoungeService._finalizeMembershipJoined`. This ensures that XP awards, capacity checks, and achievement tracking are handled consistently whether a user joins via direct invite or approved application.
- **Messaging Flow Optimization**: Streamlined `MessagingService.onMessagePostSave` by removing redundant database fetches in the background task. Leveraged the existing resident object to process side-effects (XP, streaks, achievements) with lower resource overhead.

### UI/UX Consistency
- **Plaza Design Refinement**: Refactored the `PlazaScreen` welcome banner to use the standardized `DuoCard` widget. This improves visual consistency with the rest of the app and ensures proper spacing and shadows across all device sizes.
- **Code Quality**: Performed a project-wide diagnostic and resolved minor inconsistencies in the Serverpod backend and Flutter frontend integration.

## April 6, 2026 - Compatibility Recovery & Migration Reconciliation 🛠️🧭

### Endpoint Compatibility Recovery
- **Client Surface Restored**: Reintroduced backward-compatible `privateChat` and `social` endpoints while keeping the service-delegated backend centered around `MessageEndpoint` and `ResidentEndpoint`.
- **Message API Parity**: Restored `subscribe`, `sendTypingIndicator`, `getPinnedMessage`, and the legacy `sendMessage` call shape so existing Flutter providers and generated clients continue to work during the refactor transition.
- **Compatibility Facade**: Added a thin `PrivateChatService` facade and preserved legacy test hooks such as `MessagingService.onMessageSaved` to keep integration coverage aligned while the residence backend remains consolidated.

### Search & Migration Hardening
- **Resident Search Safety**: Escaped raw search literals in `SearchService` and corrected the trigram migration to use `pg_trgm` with `gin_trgm_ops`.
- **Migration Bridge**: Added a no-op bridge migration for the previously untracked database-stamped version `20260403074810271`, allowing older databases to continue forward without manual repair.
- **Legacy Column Cleanup**: Added a follow-up migration to safely remove stale image-privacy columns from `resident` using `DROP COLUMN IF EXISTS`, eliminating schema drift warnings in tests and local environments.

### Validation
- **Targeted Verification**: Re-ran the social and recall integration suites successfully after reconciling the migration chain.

## April 4, 2026 - High-Performance Messaging Refactor 🏗️⚡💬

### Messaging Architecture & UI Performance
- **Immediate Broadcast Pattern**: Refactored `MessagingService.sendMessage` to prioritize real-time UI updates. Messages are now posted to the WebSocket stream immediately after persistence, before processing any heavy side-effects.
- **Asynchronous Side-Effects**: Offloaded XP rewards, streak updates, achievement tracking, and push notification triggers to `onMessagePostSave` using `TaskUtils.runBackground`. This significantly reduces the latency of the send request.
- **Unified Messaging Endpoint**: Renamed `ChatEndpoint` to `MessageEndpoint` and synchronized method names (`markChannelAsRead`, `listMessages`) to align with existing client-side expectations and fix Riverpod provider breaks.

### Privacy & Authorization Hardening
- **Centralized Block Validation**: Consolidated privacy gating into `ChannelService.validateNoBlockFlow`. This ensures consistent block-status enforcement across all messaging actions (send, pin, etc.).
- **Automatic Metadata Denormalization**: Ensured that `lastReadAt` updates and `lastMessage` previews are handled synchronously during message save to prevent race conditions in thread list sorting.

### Technical Quality & Diagnostics
- **Clean Analysis**: Resolved all lint errors in both `talktive_server` and `talktive_flutter` related to the new messaging architecture.
- **Protocol Synchronization**: Performed full stack synchronization via `serverpod generate` to reflect the endpoint renames.



## April 4, 2026 - R2 Storage & Legacy Migration Bug Fixes 🐛🔧☁️

### Cloudflare R2 Storage Fixes

- **Staging Environment Parity**: Added the missing `storage:` block to `config/staging.yaml`. Without it, `R2CloudStorage` (registered for all non-development run modes) could not authenticate and every upload in staging would fail.
- **Single-Responsibility Avatar Cleanup**: Removed redundant `FileStorageService.deleteMedia` calls from both `ResidentEndpoint.updateResident` and `ResidentEndpoint.updateCustomAvatar`. `ResidentService.updateResident` already handles old-avatar deletion internally; calling it twice from the endpoint caused a spurious second round-trip to R2 and misleading log warnings.

### Legacy Migration Fixes

- **Project ID Read Caching**: `LegacyMigrationService._projectId` previously re-read and JSON-parsed `config/firebase_service_account_key.json` on every invocation. Combined with `_authorizedClient` doing the same, a single migration attempt opened the file three times. Added `_cachedProjectId` so the file is opened exactly once per server lifetime.
- **`hasUsefulData` Language Guard**: Tightened the migration trigger so that a resident with only an unsupported or empty Firebase `languageCode` (which normalises to the default `['en']`) does not falsely trip the migration flow. Languages are now counted as meaningful only if at least one non-English code is present.
- **Google Photo URL Avatar Slot**: Firebase `photoURL` is typically a `https://lh3.googleusercontent.com/…` URL, not an emoji. The `profile_setup_screen.dart` initialisation now detects the `://` scheme and routes the value to `_customAvatarUrl` (the photo upload slot) rather than `_selectedAvatar` (the emoji picker slot), preventing a raw URL from appearing where an emoji is expected.

### Test Coverage

- **Updated `legacy_migration_service_test.dart`**: Fixed the 'falls back to English' test (now correctly expects `null` for a solo unsupported language code), and added 5 new cases: known non-English language triggers migration, all-null/blank fields return null, Google photo URL stored verbatim in avatar field, `zh-CN` alias handling, and `nb` → `no` alias handling.
- **105/105** unit tests passing.

---

## April 3, 2026 - Secure Legacy Google-Link Migration Hardening 🔐🔄

### Migration Security & Correctness
- **Server-Authoritative Migration**: Moved legacy profile lookup out of Flutter and into the backend so first-link migration is derived from trusted Firebase data instead of client-provided onboarding values.
- **Privilege Escalation Fix**: Closed a security issue where `xp`, `level`, and `role` could be supplied by the client during resident initialization. Those values are now resolved only from trusted legacy records on the server.
- **Legacy Source Fallback**: Added Firestore-first lookup with Realtime Database fallback to handle users whose old records have not fully synced.
- **Value Normalization**: Standardized legacy gender and language conversion and kept English in the migrated language set.

### UX & Regression Coverage
- **Onboarding Handoff Fix**: Preserved `migrationData` when navigating from the welcome flow into profile setup.
- **Targeted Tests**: Added conversion tests for legacy payloads and an integration test proving privileged client migration fields are ignored.

## April 2, 2026 - Unified Channel & Membership Refactoring (Phase 9.0) 🏗️🎭🔄

### Centralized Channel Management
- **Unified ChannelService**: Established `ChannelService` as the single source of truth for all channel types (Plaza, Lounges, Private Chats).
- **Standardized Access Control**: Refactored `validateMember` to provide consistent, reusable authorization checks across the entire backend, reducing boilerplate in `MessagingService` and `LoungeEndpoint`.
- **Atomic Metadata Updates**: Centralized `updateLastMessage` in `ChannelService`, ensuring last message previews and timestamps are synchronized across specialized tables (Lounge, PrivateChat) and the core Channel registry.

### Service Layer Consolidation
- **Thin Endpoints**: Further reduced `LoungeEndpoint` and `PrivateChatEndpoint` to lean wrappers, delegating all domain validation and membership state Transitions to the service layer.
- **Messaging Refinement**: Integrated unified membership validation into `MessagingService`, ensuring consistent blocked-user checks and participation requirements for all message types.
- **Membership Lifecycle**: Streamlined joining, applying, and inviting flows by utilizing centralized status validation and atomic persistence through `ChannelService`.

### Technical Quality & Synchronization
- **Strict Typing**: Hardened `validateMember` signature to return a non-nullable `ChannelMember`, utilizing `TalktiveException` for clear, standard-compliant error signaling.
- **Full Stack Sync**: Performed zero-error synchronization of Serverpod and Flutter codebases via `serverpod generate` and `build_runner`.
- **Regression Testing**: Successfully verified all refactored flows with a 100% pass rate in specialization-level integration tests (`lounge_service_test.dart`, `messaging_service_test.dart`).

### Documentation Update
- **Developer Guide**: Updated `docs/DEVELOPER_GUIDE.md` with guidelines on utilizing the unified `ChannelService` for access control and metadata synchronization.

## April 2, 2026 - Cloudflare R2 Migration & Secure Media Lifecycle (Phase 8.99) 🏗️📸☁️

### Cloudflare R2 Media Migration

- **S3-Compatible Storage**: Successfully migrated the media backend from Firebase Storage to Cloudflare R2 to eliminate egress fees and improve global delivery performance.
- **Server-Authorized Uploads**: Implemented a secure upload workflow around `MediaEndpoint`. Clients now request a server-issued upload description, complete the raw binary upload, and explicitly verify the upload before the public URL is used.
- **Environment Parity**: Configured environment-aware storage. Production uses Cloudflare R2, while development uses Serverpod's database-backed public storage, enabling full local testing of media authorization and verification.

### Secure Media Ephemerality & Lifecycle

- **Automated Physical Deletion**: Refactored `FileStorageService` to use the Serverpod Storage API. The system now automatically deletes physical files from R2/Disk when their corresponding database records (Messages, Moments) expire.
- **Custom Avatar Lifecycle**: Implemented a "Delete-on-Update" strategy for custom avatars. Outdated or removed custom avatar files are now immediately purged from storage upon profile update.
- **Permission Gating**:
  - **Floor Restriction**: Enforced Floor 2+ requirements for uploading media to public spaces (Plaza, Lounges, Moments) at the endpoint level.
  - **Premium Gating**: Restricted **Voice Messages** and **Custom Avatars** to Talktive Plus members via server-side validation during the upload authorization phase.

### Technical Quality Assurance

- **New Integration Tests**:
  - `media_upload_test.dart`: Verifies the gating logic for different media types and user tiers.
  - `resident_avatar_test.dart`: Validates the physical deletion of old avatars during profile updates.
- **Unit Test Coverage**: Added `file_storage_service_test.dart` to verify robust path extraction from various URL formats (Localhost, R2, CDN).
- **Full Verification**: Successfully ran the complete suite of 185 integration and unit tests.

## March 31, 2026 - Notification & Unread Count Verification (Phase 8.98) 🏗️🔔✅

### Notification & Deep Linking Verification

- **Comprehensive Route Audit**: Verified that all push notification payloads (`route` field) correctly match the `GoRouter` configuration in the Flutter app.
- **Deep Link Reliability**: Confirmed that `FCMManager` on the client handles notification taps correctly, including from a terminated state, ensuring users land on the intended screen (e.g., `/chats/thread/:id`).
- **In-App Toast Logic**: Validated that foreground notifications trigger a consistent `DuoNotificationToast` while respecting the user's current location to avoid redundant popups.

### Unread Count Integrity

- **Server-Side Accuracy**: Verified the `batchGetUnreadCounts` SQL logic, ensuring it correctly calculates unread messages based on the `lastReadAt` timestamp and sender exclusion.
- **Client-Side Reactivity**: Confirmed that `TotalUnreadCounts` provider correctly aggregates counts for both private chats and lounges, while respecting muted status.
- **Real-Time Synchronization**: Validated that `markChannelAsRead` properly resets unread counts and broadcasts read receipts to other participants.

### Technical Quality Assurance

- **New Integration Test**: Implemented `notification_and_unread_test.dart` to verify the end-to-end flow of unread count increments, resets, and notification payload generation.
- **Test Environment Stabilization**: Fixed UUID validation issues and updated test models to match the latest schema requirements (e.g., `isSystem`, `senderFloor`).

## March 31, 2026 - Advanced Privacy Gating & Inbound Security (Phase 8.97) 🏗️🛡️💎

### Server-Side Privacy Hardening

- **Inbound Online Status Gating**: Implemented `ResidentService.gateResident` to strictly filter sensitive profile data (like `lastSeen`) based on the viewer's Talktive Plus status.
- **Real-Time Stream Security**: Hardened `MessageEndpoint` to filter WebSocket broadcasts. `TypingIndicator` and `ReadReceiptEvent` objects are now stripped from the stream for non-Plus members to ensure zero data leakage.
- **Comprehensive API Filtering**:
  - **Search & Discovery**: Integrated viewer context into `SearchService` to hide online status in search results.
  - **Private Chats**: Gated resident profiles in chat listings and detail views.
  - **Lounge Members**: Applied privacy gating to lounge member lists and pending application views.
  - **Profile Deep Links**: Secured `getResidentById` to prevent direct online status leaks via raw IDs.

### Technical Integrity

- **Centralized Gating Logic**: Moved all profile filtering into a reusable `ResidentService` utility, ensuring consistent results across all endpoints.
- **Improved View Models**: Updated `UserProfileView` to consistently handle the `isOnline` and `lastSeen` fields based on inbound permissions.
- **Consistent Entitlement Checks**: Centralized all Plus-member permission checks (`canSeeOthersOnlineStatus`, etc.) within `ResidentService`.

## March 30, 2026 - Resident Model Polish & Technical Debt Cleanup (Phase 8.96) 🏗️🧹💎

### Resident Model Refinement

- **Legacy Field Removal**: Excised `experienceMessageCount` and `isTalktivePlus` from the core `Resident` protocol (`resident.spy.yaml`).
- **Subscription Entitlement Centralization**: Transitioned from a persisted database flag to a dynamic entitlement check based on active membership and trial status.
- **Database Synchronization**: Successfully applied migrations to drop deprecated columns from the production and test database schemas.

### Test Environment Stabilization

- **Unit Test Fixes**: Resolved compilation errors in `ContentFilterService` tests by correctly importing `ValidationResult` and updating field references (`error` instead of `reason`).
- **Integration Test Cleanliness**: Removed all stale references to legacy fields in `resident_endpoint_test.dart` and `gamification_service_test.dart`.

## March 30, 2026 - Consolidated Social & Privacy Overhaul (Phase 8.95) 🏗️🛡️💎

### Backend Architectural Consolidation

- **Social Domain Unification**: Created a centralized `SocialEndpoint` for peer-to-peer interactions (Likes, Blocks, Reports), eliminating the redundant `ReportEndpoint` and slimming down `ResidentEndpoint`.
- **Service Layer Streamlining**:
  - **ChannelService**: Added generic membership management methods, eliminating duplicated logic in `LoungeService` and `PrivateChatService`.
  - **LoungeService**: Decentralized discovery by moving search and recommendation methods to `SearchService`.
- **Unified Validation System**: Introduced a centralized `ValidationResult` utility class across all services for consistent error handling.
- **Dry Caching**: Refactored `ResidentService` to use a unified batch-caching pattern for resident fetching.

### Live Residence & Privacy Model

- **Always Visible**: Removed all outbound privacy toggles (`showOnlineStatus`, `showReadReceipts`, `showTypingIndicator`, `allowDiscovery`). Every resident now contributes to the building's live atmosphere.
- **Inbound Premium Gating**: Strictly restricted visibility of live indicators (online dots, receipts, typing bubbles) to **Talktive Plus** members.
- **Premium Value Hardening**: Restored inbound premium toggles as user-controlled choices for paid members.
- **Subscription Model Simplification**: Removed the redundant persisted `isTalktivePlus` flag and centralized entitlement checks around paid-or-trial membership plus per-feature settings.
- **Universal Discovery**: Enabled universal searchability for all residents.

### Frontend & UI Polish

- **Social Relationship Provider**: Consolidated `blockedUsersProvider` and `userLikesProvider` into a single, reactive `socialRelationshipsStateProvider`.
- **UI Reactivity**: Updated `DuoAvatar` and `RealtimeChat` to strictly respect Plus membership status before showing live indicators.
- **Google Sign-In Web Stability**: Fixed a initialization race condition in the GIS 7.2.0 client.
- **Ad Service Stabilization**: Improved initialization flow and updated `ConsentService` to use `testIdentifiers` for development testing.

### Documentation Streamlining

- **Consolidated Strategy**: Merged specs, features, and monetization into `docs/PRODUCT_STRATEGY.md`.
- **Unified Technical Guide**: Folded notification architecture and service delegation into `docs/DEVELOPER_GUIDE.md`.
- **Cleaned Context**: Purged historical fix logs from `GEMINI.md` to maintain AI context efficiency.

---

## March 29, 2026 - Settings Polish & Privacy Hardening (Phase 8.91) 🏗️⚡💎

### UI/UX & Settings Polish

- **Settings Screen Cleanup**: Resolved a critical `RenderFlex` overflow on the Settings screen.
- **Privacy Control Simplification**: Removed the "Privacy Control" section from the UI.
- **Iconography Consistency**: Replaced "Upgrade Now" with "Try It Out" globally.

### Backend Privacy & Subscription Hardening

- **Forced Privacy Defaults**: Hardened the backend by forcing core privacy flags to `true`.
- **Trial Unlimited Access**: Maintained 24-hour trial duration with repeatable activation.

---

## Historical Phase 8 Archives (March 2026)

### Phase 8.90: Full-Stack Consolidation & Orchestration

- **Messaging Service**: Centralized message construction and post-save lifecycle.
- **ChatScreenMixin**: Unified all chat screens (Plaza, Lounges, Private) under a single mixin, eliminating 600+ lines of duplicate code.

### Phase 8.24: GIS 7.2.0 API Migration & Auth Hardening

- **Google Sign-In Overhaul**: Migrated to the singleton `GoogleSignIn.instance` pattern.
- **Web Stability**: Resolved GIS initialization errors and stabilized session restoration.

### Phase 8.87: Message Recall & Content Retraction

- **Features**: Implemented message retraction across all channels.
- **Real-time**: Integrated WebSocket broadcasts for instant "Message recalled" updates.

### Phase 8.77: Interstitial Ad System

- **AdMob**: Implemented exit-triggered ads with mandatory 2-minute cooldowns.
- **Compliance**: Integrated Google UMP for GDPR/CCPA consent.

### Phase 8.37: Robust Content Ephemerality

- **Policies**: Plaza (24h), Lounges (14d), Private (30d), Moments (7d).
- **Automation**: Implemented daily `FutureCall` cycles for autonomous cleanup.

---

## Earlier Development Highlights

- **Phase 8.7-8.10**: Implemented the Hybrid Floor Formula (`min(level, trustCap)`).
- **Phase 8.1-8.5**: Migrated from Firebase to Serverpod with real-time WebSockets.
- **Phase 1-5**: Initial rebuild with Duolingo-inspired UI and Apartment metaphor.
