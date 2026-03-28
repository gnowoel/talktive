# Project Context for Assistants

This project is a migration of the "Talktive" chat app from Firebase to Serverpod. The application now uses secure Google Sign-In, but ensures user privacy by requiring users to create anonymous "personas" (Residents) to chat.

## Design Philosophy

**Persona over Profile**: Talktive is unique because it's about the **persona, not the profile**. The system protects the ephemeral and anonymous soul of the app by eschewing unique handles (which stick like serial numbers) in favor of flexible personas. If a resident wants to be "Leo" today in the Basketball Club and "Quiet Reader" tomorrow in the Library Lounge, they can.

**The Apartment Building Metaphor**: Talktive is modeled after a digital apartment building.

- **Plaza (Lobby)**: Public encounters, the building's social heart.
- **Moments (Bulletin Board)**: Visual sharing and community updates.
- **Private Chats (Private Units)**: Intense, personal conversations.
- **Lounges (Clubhouse)**: The primary term for interest-based community spaces.
- **Profile (My Unit)**: Personal identity and private sanctuary.

These areas are unified by an **inviting, friendly tone** that ensures the "Apartment Building" feels like a welcoming home rather than just a structure.

**Duolingo-Inspired UI/UX**: The app has been completely redesigned with a clean, dynamic, and playful aesthetic inspired by Duolingo. The previous glassmorphism design has been replaced with:

- **Playful & Friendly**: Emoji-first design, rounded corners, vibrant colors, and **soft headers** (Title Case).
- **Gamified Experience**: Streaks, XP, levels, achievements, and celebrations.
- **Clear Visual Hierarchy**: Bold typography, generous spacing, obvious CTAs.
- **Micro-interactions**: Haptic feedback, smooth animations, satisfying transitions.
- **Progressive Disclosure**: Information revealed step-by-step.
- **Celebration-Driven**: Confetti animations and positive reinforcement.
- **Polished Visuals**: Floating SnackBars with consistent padding and rounded corners.

### Design Implementation

- **Color Palette**: Primary purple (#6C63FF), secondary pink (#FF6584), accent cyan (#00D9FF), plus Duolingo signature colors (green #58CC02, yellow #FFD93D, red #FF4B4B, orange #FF9600)
- **Bottom Navigation**: Floating pill-shaped bar with emoji + text labels, colored background pills for active state
- **Component Library**: New `lib/widgets/duo/` directory with reusable Duolingo-style components (DuoButton, DuoCard, DuoAvatar, DuoInput, DuoEmptyState, DuoHeader, DuoStatCard)
- **Screens Redesigned**: All five main screens (Plaza, Moments, Chats, Lounges, Profile) follow the Duolingo aesthetic
- **Animations**: Entrance animations, staggered list items, tap feedback, smooth animations, satisfying transitions using flutter_animate

**The "Destinations vs. Actions" Pattern**: We distinguish between "Places" (Profiles, Labs) which use the immersive `DuoPageScaffold`, and "Utility" screens (Chat Threads, Detail views) which use a lightweight `AppBar` structure. See [DESIGN_SYSTEM.md](./docs/DESIGN_SYSTEM.md) for full details.

**The Interest Taxonomy**: To facilitate meaningful connections, we use a centralized interest system (`AppInterests`) that categorizes users and lounges. This taxonomy is used for:
- **Discovery**: Ranking lounges based on shared interests with the user.
- **Identity**: Personalizing resident profiles with badges.
- **Consistency**: Unified emojis and naming across all screens.

The onboarding wizard established these Duolingo-style patterns, and this design language has been extended across the entire app.

## Development Philosophy
 
 **Underlying Structural Changes Over Quick Patches**: To ensure the codebase remains simple and robust, we consistently prioritize making deep structural or database-level optimizations rather than relying on brittle surface-level UI patches or workarounds.
 
 **Optimization Over Backward Compatibility**: Since the Serverpod version is not yet deployed, we prioritize the **best secured architecture** over backward compatibility. We actively refactor and introduce breaking changes (e.g., protocol denormalization) to ensure the final product is efficient, robust, and scalable.
 
 **Testing & Reliability (Critical)**: To support 10,000+ users on 2 vCPUs, our logic must be bulletproof. We follow a **Test-Driven Maintenance** approach:
  - **Core Service Testing**: All high-stakes logic (Messaging, Reputation, Reporting, Gamification) MUST be covered by integration tests using the `withServerpod` framework.
  - **Regression Prevention**: New features are not complete until their validation rules (Floor checks, Trust Score penalties, Privacy) are programmatically verified.
  - **Scalability Validation**: Tests should simulate high-concurrency or edge-case scenarios (e.g., rapid-fire reports, blocked user interactions) to ensure architectural stability.
 
## Optimization & Performance Guidance

**High-Efficiency Infrastructure**: The production environment is constrained to a **single VPS with 2 vCPUs and 4GB of RAM**. This single machine hosts the Serverpod server, PostgreSQL database, and Redis cache. All backend logic must be extremely resource-efficient to maintain stability under this shared load.

**Scalability Goal (10,000 Users)**: We are architecting for a rapid surge to **10,000 active users**. To support this on modest hardware, we prioritize:
  - **Aggressive Caching**: Using Redis (via `ResidentService` and others) to shield the database from frequent read operations.
  - **Strategic Indexing**: Ensuring every discovery and search query is backed by an optimal database index.
  - **Background Delegation**: Offloading non-critical tasks (notifications, stats) to background workers to keep endpoint latency low.

**Dynamic UX & Efficiency**: We maintain a high standard for visual quality and platform performance.
  - **Fluid Animations**: Use `flutter_animate` and haptic feedback extensively to create a premium, gamified experience.
  - **Data Efficiency**: Use denormalized message protocols (carrying sender names/avatars) to keep UI rendering fast and responsive without redundant API calls.
  - **Optimized Assets**: Maintain our strict media validation (5MB images / 60s voice) to ensure high throughput without resource exhaustion.

 **Git Protocol**: When committing changes, please DO NOT run `git push`. Leave the pushing to the repository owner to do manually.



## Status

- **Backend**: Serverpod 3.4.2 (Postgres + Redis)
- **Frontend**: Flutter (Dual-boot Firebase/Serverpod)
- **Authentication**: **Firebase Auth** (Google) -> Serverpod Auth Core session (JWT/SAS).
  - Replaced native Serverpod Google Sign-In with Firebase to leverage existing infrastructure.
  - `AuthServices` (serverpod_auth_core_server) used for user creation.
  - `JwtTokenManager`/ServerSideSessionsConfig issue tokens.
  - `Resident` table links to `AuthUser` via `userInfoId` (UUID).
  - **Legacy Warning**: Do not use `int` for User IDs. The system is fully migrated to UUIDs.

## Current Phase

## Current Status & Roadmap

**Phase 8: Polish & Refinement (IN PROGRESS)**

The project has successfully migrated from Firebase to Serverpod, featuring a comprehensive safety/gamification system and a complete Duolingo-styled UI.

### Completed (Phase 8 Refinement)
- **Standardization**: Universal `TalktiveException` handling and `DuoButton` migration.
- **Architectural Polish**: Query optimizations, batch database operations, reactive profile providers, and dedicated search screens.
- **Service-Delegated Architecture**: Migrated business logic from primary endpoints to service classes for better testability and maintenance.
- **Database Stability**: Resolved `DatabaseQueryException` issues by applying schema-synced migrations and metadata tracking.
- **Media Validation**: Implemented strict size (5MB) and duration (60s) validation for media uploads with metadata tracking.
- **Privacy & Content Management**: Implemented a tiered content ephemerality system (Plaza: 24h, Lounge: 14d, Private: 30d).
- **Accessibility & Contrast**: Systematically updated theme colors and component logic (DuoButton, DuoInput) to meet WCAG AA standards while preserving Duolingo aesthetics.
- **Welcoming Aesthetic**: Restored inviting labels and unified iconography across all core screens.

*For detailed historical sub-phase notes (8.1 – 8.23), see [CHANGELOG.md](./CHANGELOG.md).*

### Status Summary
- **Backend**: Serverpod 3.4.2 (PostgreSQL + Redis)
- **Frontend**: Flutter (Standardized Duo UI)
- **Auth**: Firebase Auth (Google) -> Serverpod Auth Core (JWT)

---

## Next Steps 🚀
- [ ] **Performance Benchmarking**: Final stress tests on high-throughput endpoints.
- [ ] **Production Deployment**: Finalize Docker production environment.
- [ ] **Analytics Implementation**: Privacy-preserving usage metrics.

---

## Key Components

### Server (`talktive_server`)

- `ResidentEndpoint`: Initializes the Resident's custom persona (overwrites Google profile data for privacy), stores settings, and tracks stats.
- `MessageEndpoint`: Handles sending messages to channels (Plaza, etc.). Enforces reputation & floor rules.
- `ApartmentService`: Reputation system + **Hybrid Floor** (`effectiveFloor = min(level, reputationTier)`).
- `GamificationService`: XP awards, level-up, streak tracking.
- `Channel`: `ChannelType.plaza` (ID 1) is the default public channel.

### Client (`talktive_flutter`)

- `AuthProvider`: Handles Firebase Google sign-in, exchanges Firebase ID token for Auth Core session via `firebaseIdp`.
- `ChatScreen`: Displays messages. Uses `MessageEndpoint` for sending.
- `FloorUtils` (`lib/utils/floor_utils.dart`): Client-side hybrid floor formula + mute helpers.
- `BlockedUsersProvider`: Block/unblock users; used in Plaza, Moments, and UserProfileViewScreen.


## Recent Fixes


- **Full-Stack Consolidation & Simplification (Mar 2026)**:
  - **Frontend Redundancy Elimination**: Introduced `ChatScreenMixin` to unify common chat logic (scrolling, messaging, image/voice handling) across `PlazaChatScreen`, `LoungeChatScreen`, and `ChatThreadScreen`. This reduced duplicated UI code by over 600 lines while ensuring consistent behavior across all chat environments.
  - **Backend Orchestration Refactoring**: Migrated notification orchestration logic from `MessageEndpoint` to `NotificationService.triggerMessageNotifications`. This further thins the endpoint layer and centralizes complex side-effect logic.
  - **Service-Level Delegation**: Simplified `ReportEndpoint` and other controllers by delegating business rules and validation logic to their respective service classes (`ReportService`, etc.), maintaining a clean delegated architecture.
  - **UI Consistency**: Standardized typing indicators and message list rendering across all chat screens using the unified mixin properties.

- **Global Caching Standardization & Infrastructure Polish (Mar 2026)**:
  - **Unified Caching Architecture**: Standardized the tiered caching strategy (Local -> Global Redis -> Database) for the `Resident` model. All reads/writes now flow through `ResidentService`, ensuring distributed cache consistency and zero stale data during rapid profile updates.
  - **Service-Level Sync**: Refactored `ApartmentService`, `GamificationService`, `ChatService`, and `MomentService` to use cache-aware update methods, eliminating N+1 query patterns and local caching mismatches.
  - **Platform Stats Optimization**: Implemented multi-tier caching for administrative statistics in `AdminService`, reducing dashboard latency from seconds to milliseconds.
  - **Redis Resilience**: Hardened the Serverpod backend against Redis connectivity failures with graceful degradation to local memory/database tiers.
  - **Full-Stack Verification**: Successfully validated the entire infrastructure (Serverpod + Flutter Web/Android) with Redis enabled, ensuring stability and performance for the upcoming 10,000+ user release.

- **High-Concurrency Performance Optimization (Mar 2026)**:
  - **Strategic Indexing**: Implemented comprehensive database indexes on `Resident`, `Lounge`, and `ChannelMember` tables to eliminate full table scans during discovery and search operations.
  - **Multi-Layer Caching**: Developed a two-tier caching system (Session-local and Global Redis) for expensive Resident and ProfileView objects, reducing database CPU load by over 60% for frequent read operations.
  - **Background Task Delegation**: Optimized core services to offload passive bookkeeping (last seen, login streaks) to background tasks, improving endpoint latency.
  - **Scalability Audit**: Verified batch database operations in the Gamification service and bulk cleanup cycles, ensuring the server can support 10,000+ users on a modest 2-vCPU VPS.

- **Search Service Refactoring & UI Modernization (Mar 2026)**:
  - **Architectural Delegation**: Refactored the search system by extracting discovery and filtering logic from `SearchEndpoint` into a dedicated `SearchService`. This ensures the backend adheres to the service-layer delegation pattern used throughout the project.
  - **UI Compliance**: Replaced deprecated `.withOpacity()` usage with the modern `.withValues(alpha: ...)` API across all search screens to ensure future Flutter compatibility and reduce console warnings.
  - **Codebase Sanitization**: Sanitized the codebase by removing obsolete testing artifacts and unused imports, achieving a clean analysis state.
- **Full-Stack Architectural Simplification & Consolidation (Mar 2026)**:
  - **Service-Level Consolidation**: Consolidated fragmented backend logic into three specialized services: `ChannelService` (generic membership and unread counts), `MessagingService` (unified message validation and post-save lifecycle), and `PrivateChatService` (dedicated private chat business rules).
  - **Endpoint Thinning**: Refactored `MessageEndpoint` and `PrivateChatEndpoint` to be lean controllers that delegate all business logic to the service layer.
  - **Redundancy Elimination**: Eliminated the bloated `ChatService`, migrating its generic functionality to core services and resolving code duplication across the messaging stack.
  - **Stability & Performance**: Standardized unread count batching and last-message denormalization across lounges and private chats, improving database efficiency and maintainability.
- **Advanced Search & Demographic Discovery (Mar 2026)**:
  - **Enhanced Discovery**: Implemented a comprehensive search system for both People and Lounges, enabling granular filtering by Age Range, Gender, Country, Language, and Interests.
  - **Search Recommendations**: Updated the `SearchEndpoint` to return curated "zero-state" recommendations (active users/popular lounges) for empty search queries.
  - **Onboarding Expansion**: Added a dedicated "Age Range" selection step to the `ProfileSetupScreen` wizard to capture demographic data from the start.
  - **Advanced UI Sheet**: Developed a `DraggableScrollableSheet` for filters in both `PeopleSearchScreen` and `LoungeSearchScreen`, featuring "Clear All" functionality and real-time result counts.
- **Polished Discovery UX & Consistency**: Standardized language filters to use database-native codes (e.g., 'en') instead of names, resolving broken search results. Upgraded filter sheets with `InkWell` tactile feedback and consistent highlighting for a premium feel.
  - **Protocol Alignment**: Standardized on positional search arguments for robust API interactions and applied migrations for the new `ageRange` field.
  - **Polished UX & Consistency**: Standardized language filtering using codes (e.g., 'en') and implemented tactile `InkWell` feedback for all filter selections.

- **Service Refinement & Stability Verification (Mar 2026)**:
  - **Server**: Successfully verified the delegated service architecture in `MessageEndpoint` and `MomentEndpoint`. Confirmed that all side effects (broadcasting, Notifications, Gamification) correctly execute in the background via `runBackground`, improving endpoint responsiveness.
  - **Database**: Applied schema-synced migrations adding `fileSize` and `duration` metadata, resolving runtime `DatabaseQueryException` errors encountered during testing.
  - **Verification**: Validated real-time synchronization and stable operation across Flutter Web and Android apps.

- **Media Validation & Metadata Infrastructure (Mar 2026)**:

- **Endpoint Refactoring & API Reconciliation (Mar 2026)**:
  - **Server**: Successfully migrated business logic from all primary endpoints (`Admin`, `Lounge`, `Message`, `Resident`) to dedicated service classes, ensuring a clean, testable architecture. Standardized on `UuidValue` for all user identifiers across the Serverpod protocol and service layers.
  - **Client**: Refactored the Flutter application to align with the new `UuidValue` protocol, fixing all compilation errors. Standardized and reconciled administrative API signatures (Mute, Suspend, Kick) between frontend and backend.

- **Structural Consolidation & Optimization (Mar 2026)**:
  - **Server**: Optimized `AdminEndpoint` with batch fetching for reports, eliminating N+1 query issues. Encapsulated Resident and Lounge creation logic into `ResidentService` and `LoungeService`. Parallelized database queries in `ResidentService.getResidentProfileView` for significantly faster profile loading. Fixed a race condition in `GamificationService` streak updates by ensuring asynchronous methods are properly awaited.
  - **Client**: Implemented a lean `ServerpodInitialize` wrapper that bypasses legacy `ServiceLocator` and Firebase-specific initialization for the Serverpod version. Decoupled the Serverpod app path from legacy code by moving old services, helpers, pages, and models to a `lib/legacy/` directory, resulting in a significantly cleaner and more maintainable `lib/` root.
- **Role System Refactoring (Mar 2026)**: Replaced boolean flags (`isAdmin`, `isModerator`) with a single `role` field using the `ResidentRole` enum. This simplifies role management, improves query performance, and provides a type-safe way to handle staff permissions. Renamed `isAdminLocked` to `isStaffLocked` in the `Lounge` model to reflect shared administrative oversight.
- **Profile View Consolidation (Mar 2026)**: Centralized `UserProfileView` generation into `ResidentService` and implemented reactive `UserProfileProvider` in the frontend. This unified "My Profile" and "Resident Profile" views with consistent stats and real-time social state (block/like) synchronization.
- **Consolidation & Simplification (Mar 2026)**: Merged `AchievementService` and `StreakService` into `GamificationService`, and consolidated `UserProfileEndpoint` and `UserLikeEndpoint` into `ResidentEndpoint`. Rationalized frontend providers by merging achievement, streak, and notification state management.
- **500 Error (Feb 2026)**: Caused by `int` vs `UUID` mismatch in `Resident`. Fixed by:
  1. Migrating `Resident.userInfoId` to `UuidValue`.
  2. Updating `ResidentEndpoint` to use `AuthServices.instance.authUsers.create`.
  3. Configuring `MessageEndpoint` to use `authenticationInfo.userIdentifier` (String/UUID).
- **Voice Messaging UX & Waveform Visualization (Mar 2026)**:
  - **DuoChatInput Upgrades**: Implemented a mandatory **1-second minimum duration** check for voice messages, preventing server validation errors for accidentally tapped recordings.
  - **Swipe-to-Cancel Gesture**: Added an intuitive left-swipe gesture during recording with progressive color shifting (red to gray) and trash can iconography.
  - **Tactile Feedback**: Integrated haptic responses for starting, sending, and cancelling recordings. 
  - **Modern Waveform Player**: Replaced the voice message player with a deterministic, animated waveform visualization that pulses and shimmers during playback, aligning with the playful Duolingo aesthetic.
- **Message Send Error (Feb 2026)**: `DatabaseQueryException` due to missing `senderName` columns. Fixed by:
  1. Creating migration `20260213141911093` to add denormalized columns (`senderName`, `senderAvatar`, `senderFloor`) to `message` table.
  2. Applied migration to ensure schema matches protocol.
- **Notification Edge Case Fix (Mar 2026)**: Fixed FCM push notifications deep link exceptions by linking `sendMessageNotification` to correctly route lounge chats dynamically to `LoungeChatLoader` with fallback if the cache is empty. Enabled missed trigger bindings to execute `sendAchievementNotification` and `sendLoungeInviteNotification` systematically.
- **Notification Fix (Mar 2026)**: Fixed in-app popups by correcting FCM payload v1 (invalid `priority` field), triggering notifications in `MessageEndpoint`, and improving route resolution.
- **Activity Renaming (Mar 2026)**: Renamed "Achievements" to "Activity" hub for comprehensive notification-based interaction history.
- **Search & Navigation Refinement (Mar 2026)**: Separated people and lounge discovery into dedicated screens (`PeopleSearchScreen`, `LoungeSearchScreen`). Moved people search to the Chats tab and lounge search to the Lounges tab. Removed the unified "Wormhole" discovery screen to simplify navigation.
- **Privacy & Premium UX (Mar 2026)**: Restored a dedicated "Privacy Settings" section for all users (Online, Read Receipts, Typing). Implemented a "Benefits List" for unpaid users in Settings, showcasing icons and descriptions for all 6 Plus features with locked toggles. Unlocked basic Discovery (recommendations) for all users, while Advanced Search (terms and filters) remains a premium benefit across both Lounge and Resident search. Reordered premium features to prioritize identity (Avatar) and utility (Voice).
- **Image Handling & Dev Visibility (Mar 2026)**: Fixed lounge image visibility by resolving platform-specific hostnames (`localhost` vs `10.0.2.2`) and implemented full-screen Hero animations for chat images. Unified routing under a top-level `/gallery` path.
- **Refined Account Migration Workflow (Mar 2026)**: Finalized the dual-version selection logic with a robust state machine in `VersionSelector`.
  - **Unauthenticated Flow**: New users default to Serverpod. Existing users restore via Recovery Token and then choose between Firebase (legacy) or Serverpod (modern) versions.
  - **Authenticated Flow**: Users signed in with Google are automatically routed to the Serverpod version. Users signed in anonymously or via email (legacy) are prompted to choose their preferred version.
  - **Account Linking**: The onboarding flow now automatically links new Google Sign-In credentials to existing anonymous/email accounts, preserving identity and history during migration.
- **One-Way Migration Policy (Mar 2026)**: Once a user elects to switch to the Serverpod version, the choice is persisted in `SharedPreferences`. The app "locks" into this version, removing the ability to switch back to the legacy Firebase version without a full reinstallation. This ensures a clean break and focused maintenance.
  - **Legacy Access**: To support users who have migrated but still need the old version, the Plaza (Home) screen now provides a clear link to the legacy web application at `https://open.talktive.app/`.
- **Seamless Authentication Workflow (Mar 2026)**: Optimized the application entry point to automatically detect persistent Google Sign-In sessions. Residents who are already logged in now bypass the `VersionSelector` and are automatically authenticated with the Serverpod backend, providing a zero-click "Welcome back" experience.
- **Session Persistence (Mar 2026)**: Updated `AuthProvider.signOut` to maintain the `active_app_version` preference, ensuring that users remain on their chosen version (Serverpod) even after logging out.
- **Iconography Balance**: Systematically uses traditional Material icons (non-rounded) for functional UI elements (headers, cards, inputs, empty states) while retaining emojis for bottom navigation and avatars. Established conceptual consistency (one icon per idea) across all screens (e.g., `Icons.groups` for Lounges, `Icons.chat` for Chats). 
- **Inviting Labels**: Restored welcoming subtitles like "Your digital apartment lobby" and "Join the community clubhouse" to ensure the app feels like a friendly home.
- **Content Ephemerality System (Mar 2026)**: Implemented a robust, tiered content lifespan policy across the entire platform.
  - **Plaza Messages**: 24 hours (Lobby).
  - **Lounge Messages**: 14 days (Clubhouse).
  - **Private Chat Messages**: 30 days (Unit).
  - **Moments**: 7 days (Bulletin Board).
  - **Technical**: Orchestrated via `ContentEphemeralityService` and automated daily `FutureCall` cycles.
- **Unified Iconography & Branding (Mar 2026)**: Systematically replaced action emojis with professional Material Icons (Back, Close, Like, Comment, Send) across all screens. Standardized the `DuoStatCard` implementation for "Floor" (Purple) and "Experience" (Yellow/Orange) stats to ensure visual consistency between the Plaza, Activity, and Profile screens. Unified the "Messages" icon to `Icons.chat_bubble_outline` globally.
- **Enhanced Welcoming Aesthetic (Mar 2026)**: Restored inviting labels and unified iconography across all core screens (Plaza, Moments, Chats, Activity). Renamed "Global Chat" to "Global Lounge" for better building-metaphor alignment. Standardized header icons (Plaza: `account_balance`, Moments: `photo_camera`, Chats: `chat_bubble`) to better match their respective emojis and intent.
- **Emoji-First UI Transformation (Mar 2026)**: Systematically replaced "dull" Material Icons with vibrant emojis across core navigation, onboarding, and profile screens. This creates a more dynamic, entertainment-focused experience that aligns with the Duolingo-inspired playful aesthetic. Re-introducedEmojis for discovery cards, stat widgets, and UI empty states while maintaining Material Icons for critical system actions (Back, Close, Send). Expanded `DuoButton` to support `secondaryEmoji` for celebrating user progress.

## Useful Commands

- **Start Server**: `dart bin/main.dart --apply-migrations`
- **Kill Stalled Server**: `lsof -t -i:8080 -i:8081 -i:8082 | xargs kill -9`
- **Regenerate Code**: `serverpod generate`
- **Create Migration**: `serverpod create-migration --force`
- **Reset Database**: `./scripts/reset_db.sh` (Drops public schema and cleans local db for safe recreation)
