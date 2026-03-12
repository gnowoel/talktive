# Project Context for Assistants

This project is a migration of the "Talktive" chat app from Firebase to Serverpod. The application now uses secure Google Sign-In, but ensures user privacy by requiring users to create anonymous "personas" (Residents) to chat.

## Design Philosophy

**The Apartment Building Metaphor**: Talktive is modeled after a digital apartment building.

- **Plaza (Lobby)**: Public encounters.
- **Moments (Bulletin Board)**: Visual sharing.
- **Chats (Private Units)**: Private conversations.
- **Groups (Clubhouse)**: Community discussions.
- **Profile (My Unit)**: Personal identity.

**Duolingo-Inspired UI/UX**: The app has been completely redesigned with a clean, dynamic, and playful aesthetic inspired by Duolingo. The previous glassmorphism design has been replaced with:

- **Playful & Friendly**: Emoji-first design, rounded corners, vibrant colors
- **Gamified Experience**: Streaks, XP, levels, achievements, and celebrations
- **Clear Visual Hierarchy**: Bold typography, generous spacing, obvious CTAs
- **Micro-interactions**: Haptic feedback, smooth animations, satisfying transitions
- **Progressive Disclosure**: Information revealed step-by-step
- **Celebration-Driven**: Confetti animations and positive reinforcement

### Design Implementation

- **Color Palette**: Primary purple (#6C63FF), secondary pink (#FF6584), accent cyan (#00D9FF), plus Duolingo signature colors (green #58CC02, yellow #FFD93D, red #FF4B4B, orange #FF9600)
- **Bottom Navigation**: Floating pill-shaped bar with emoji + text labels, colored background pills for active state
- **Component Library**: New `lib/widgets/duo/` directory with reusable Duolingo-style components (DuoButton, DuoCard, DuoAvatar, DuoInput, DuoEmptyState, DuoHeader, DuoStatCard)
- **Screens Redesigned**: All five main screens (Plaza, Moments, Chats, Groups, Profile) follow the Duolingo aesthetic
- **Animations**: Entrance animations, staggered list items, tap feedback, smooth transitions using flutter_animate

**The Interest Taxonomy**: To facilitate meaningful connections, we use a centralized interest system (`AppInterests`) that categorizes users and groups. This taxonomy is used for:
- **Discovery**: Ranking groups based on shared interests with the user.
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
- **Privacy & Safety**: Privacy-first "Doorbell & Peephole" invite system; interest-based group discovery.
- **Social & Engagement**: Immersive Moments feed with direct Firebase uploads and XP rewards.
- **Architectural Polish**: Query optimizations, batch database operations, and reactive profile providers.

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

- **500 Error (Feb 2026)**: Caused by `int` vs `UUID` mismatch in `Resident`. Fixed by:
  1. Migrating `Resident.userInfoId` to `UuidValue`.
  2. Updating `ResidentEndpoint` to use `AuthServices.instance.authUsers.create`.
  3. Configuring `MessageEndpoint` to use `authenticationInfo.userIdentifier` (String/UUID).
- **Message Send Error (Feb 2026)**: `DatabaseQueryException` due to missing `senderName` columns. Fixed by:
  1. Creating migration `20260213141911093` to add denormalized columns (`senderName`, `senderAvatar`, `senderFloor`) to `message` table.
  2. Applied migration to ensure schema matches protocol.
- **Notification Edge Case Fix (Mar 2026)**: Fixed FCM push notifications deep link exceptions by linking `sendMessageNotification` to correctly route group chats dynamically to `GroupChatLoader` with fallback if the cache is empty. Enabled missed trigger bindings to execute `sendAchievementNotification` and `sendGroupInviteNotification` systematically.
- **Notification Fix (Mar 2026)**: Fixed in-app popups by correcting FCM payload v1 (invalid `priority` field), triggering notifications in `MessageEndpoint`, and improving route resolution.
- **Activity Renaming (Mar 2026)**: Renamed "Achievements" to "Activity" hub for comprehensive notification-based interaction history.
- **Image Handling & Dev Visibility (Mar 2026)**: Fixed group image visibility by resolving platform-specific hostnames (`localhost` vs `10.0.2.2`) and implemented full-screen Hero animations for chat images. Unified routing under a top-level `/gallery` path.
- **Architectural Refinement (Mar 2026)**: Consolidated rate limiting into a unified Redis-based (Serverpod cache) service and removed redundant database-backed rate limit tables. Removed unused `ImageEndpoint` and `StorageEndpoint` to simplify server implementation.

## Useful Commands

- **Start Server**: `dart bin/main.dart --apply-migrations`
- **Kill Stalled Server**: `lsof -t -i:8080 -i:8081 -i:8082 | xargs kill -9`
- **Regenerate Code**: `serverpod generate`
- **Create Migration**: `serverpod create-migration --force`
- **Reset Database**: `./scripts/reset_db.sh` (Drops public schema and cleans local db for safe recreation)
