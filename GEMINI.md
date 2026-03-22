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
- **Privacy & Premium Control**: Restored universal privacy toggles and granular premium feature switches.

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
- **Message Send Error (Feb 2026)**: `DatabaseQueryException` due to missing `senderName` columns. Fixed by:
  1. Creating migration `20260213141911093` to add denormalized columns (`senderName`, `senderAvatar`, `senderFloor`) to `message` table.
  2. Applied migration to ensure schema matches protocol.
- **Notification Edge Case Fix (Mar 2026)**: Fixed FCM push notifications deep link exceptions by linking `sendMessageNotification` to correctly route lounge chats dynamically to `LoungeChatLoader` with fallback if the cache is empty. Enabled missed trigger bindings to execute `sendAchievementNotification` and `sendLoungeInviteNotification` systematically.
- **Notification Fix (Mar 2026)**: Fixed in-app popups by correcting FCM payload v1 (invalid `priority` field), triggering notifications in `MessageEndpoint`, and improving route resolution.
- **Activity Renaming (Mar 2026)**: Renamed "Achievements" to "Activity" hub for comprehensive notification-based interaction history.
- **Search & Navigation Refinement (Mar 2026)**: Separated people and lounge discovery into dedicated screens (`PeopleSearchScreen`, `LoungeSearchScreen`). Moved people search to the Chats tab and lounge search to the Lounges tab. Removed the unified "Wormhole" discovery screen to simplify navigation.
- **Privacy & Premium UX (Mar 2026)**: Restored a dedicated "Privacy Settings" section for all users (Online, Read Receipts, Typing). Implemented a "Benefits List" for unpaid users in Settings, showcasing icons and descriptions for all 6 Plus features with locked toggles. Unlocked Lounge Search for all users while maintaining Resident Search as a premium benefit. Reordered premium features to prioritize identity (Avatar) and utility (Voice).
- **Image Handling & Dev Visibility (Mar 2026)**: Fixed lounge image visibility by resolving platform-specific hostnames (`localhost` vs `10.0.2.2`) and implemented full-screen Hero animations for chat images. Unified routing under a top-level `/gallery` path.
- **Account Migration Workflow (Mar 2026)**: Implemented a comprehensive migration flow for moving users from the legacy Firebase backend to Serverpod. Added a `VersionSelector` state machine that handles New vs. Existing user routes, validates Recovery Tokens for signed-out existing users, and caches app version preferences.
  - **Account Linking**: Updated `AuthProvider` to link new Google Sign-In credentials to existing anonymous/email Firebase accounts via `FirebaseAuth.instance.currentUser?.linkWithCredential(credential)`, ensuring users retain their legacy `userInfoId` and chat histories.
- **Seamless Authentication Workflow (Mar 2026)**: Optimized the application entry point to automatically detect persistent Google Sign-In sessions. Residents who are already logged in now bypass the `VersionSelector` and are automatically authenticated with the Serverpod backend, providing a zero-click "Welcome back" experience.

## Useful Commands

- **Start Server**: `dart bin/main.dart --apply-migrations`
- **Kill Stalled Server**: `lsof -t -i:8080 -i:8081 -i:8082 | xargs kill -9`
- **Regenerate Code**: `serverpod generate`
- **Create Migration**: `serverpod create-migration --force`
- **Reset Database**: `./scripts/reset_db.sh` (Drops public schema and cleans local db for safe recreation)
