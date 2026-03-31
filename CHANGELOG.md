# Talktive Development Changelog

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
