# Project Context for Assistants

This project is a migration of the "Talktive" anonymous chat app from Firebase to Serverpod.

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

The onboarding wizard established these Duolingo-style patterns, and this design language has been extended across the entire app.

## Development Philosophy

**Optimization Over Backward Compatibility**: Since the Serverpod version is not yet deployed, we prioritize the **best secured architecture** over backward compatibility. We actively refactor and introduce breaking changes (e.g., protocol denormalization) to ensure the final product is efficient, robust, and scalable.

**Git Protocol**: When committing changes, please DO NOT run `git push`. Leave the pushing to the repository owner to do manually.

## Status

- **Backend**: Serverpod 3.2.3 (Postgres + Redis)
- **Frontend**: Flutter (Dual-boot Firebase/Serverpod)
- **Authentication**: **Firebase Auth** (Google) -> Serverpod Auth Core session (JWT/SAS).
  - Replaced native Serverpod Google Sign-In with Firebase to leverage existing infrastructure.
  - `AuthServices` (serverpod_auth_core_server) used for user creation.
  - `JwtTokenManager`/`ServerSideSessionsConfig` issue tokens.
  - `Resident` table links to `AuthUser` via `userInfoId` (UUID).
  - **Legacy Warning**: Do not use `int` for User IDs. The system is fully migrated to UUIDs.

## Current Phase

**Phase 8: Polish & Refinement (IN PROGRESS)**

**Completed:**

- Phase 1-5: Design foundation, core screens, backend stability, feature completion, polish & engagement
- Phase 6: Advanced Features (Notifications, Profiles, Search, Admin)
- Phase 7: Production Readiness (Performance, Security, Testing, Deployment)
- Phase 8.1: Navigation Refinement
  - Separated "Chats" and "Groups" into distinct tabs (Apartment metaphor: Private Rooms vs Lounge)
  - 5-tab structure: Plaza, Moments, Chats, Groups, Profile
- Phase 8.2: Profile & Matching Data
  - Added `interests` field to Resident model (Interest Tags)
  - Added `languages` field to Resident model (Language Matching)
  - Updated onboarding wizard with Language selection step
  - Displayed interest tags on user profiles
- Phase 8.3: Identity Consistency
  - Implemented `PrivateChatWithProfile` for rich chat lists
  - Refactored all chat screens to show real user avatars/names
- Phase 8.4: Optimization & Safety
  - Denormalized `Message` protocol (senderName/Avatar/Floor) for high performance
  - Implemented client-side filtering for blocked users in public chats (Plaza/Groups)
- Phase 8.5: Immersive UI Polish
  - Implemented "**Immersive Curve**" design across all main screens using `DuoPageScaffold`.
  - Added vibrant, screen-specific gradients:
    - **Plaza**: Primary Purple (Mystery & Magic)
    - **Moments**: Pink (Warmth & Social)
    - **Chats**: Orange (Communication)
    - **Groups**: Yellow (Community)
    - **Profile**: Green (Growth & Progress)
  - Polished input areas and card styling for maximum visual consistency.
  - Fixed `500 Error` logic in `MomentEndpoint` with graceful client-side handling.
- Phase 8.6: Code Quality & Architecture Improvements (Feb 2026)
  - **Shared Utilities**: Created reusable helpers to eliminate code duplication:
    - `date_formatter.dart`: Centralized timestamp formatting (~60 lines saved)
    - `snackbar_helper.dart`: Consistent SnackBar styling across all screens
    - `DuoLoadingIndicator`: Standardized loading states
  - **Provider Migration**: Migrated PlazaScreenModern from manual state to `currentResidentProvider`
  - **Responsive Design**: Replaced hardcoded bottom padding (100px) with responsive constants:
    - Added `AppTheme.bottomNavHeight`, `bottomNavMargin`, `contentBottomPadding`
    - Updated all 5 main screens for proper responsiveness
  - **Error Handling**: Standardized error states using `DuoEmptyState` with retry buttons
  - **Code Reduction**: Removed ~150+ lines of duplicate code across screens
  - **Future-Ready**: Created `MomentsProvider` for future state management migration
- Phase 8.7: Safety & Gamification System Redesign (Feb 2026)
  - **Separated Systems**: Split safety (reputation) from gamification (XP/levels/streaks)
  - **Safety System**:
    - Replaced `creditScore` with `reputation` (0-100, starts at 100)
    - Passive restoration: 2pts/hour
    - Muting: Users with reputation ≤ 0 cannot send messages
    - Auto-escalation: 3/5/10 reports trigger warnings/mutes
    - Added `mutedUntil` and `suspended` fields
  - **Gamification System**:
    - Added `xp`, `level`, `currentStreak`, `longestStreak` fields
    - XP awards: 10pts/message, 50pts/moment
    - Level progression: 100 XP per level
    - Daily login bonuses and streak tracking
    - `floor` field now aliases `level` (apartment metaphor)
  - **Backend Changes**:
    - Created `GamificationService` for XP/level/streak management
    - Refactored `ApartmentService` to handle only reputation/safety
    - Updated all endpoints (Message, Moment, Report, Resident, Admin)
    - Database migration applied with new fields
  - **Frontend Changes**:
    - Updated profile screen with reputation (⭐), XP, level, streak stats
    - Changed reputation icon from 💰 to ⭐ with color coding
    - Updated all mute checks from `creditScore > 0` to `reputation > 0`
    - Updated Plaza, chat, group, and admin screens

- Phase 8.8: Hybrid Floor System & Safety Hardening (Feb 2026)
  - **Hybrid Floor Formula**: `EffectiveFloor = min(XPLevel, ReputationTier)`
    - Prevents spammers from farming XP to reach high floors and target users
    - ReputationTier: rep 90-100→10, 75-89→7, 50-74→5, 25-49→3, 10-24→1, 0-9→0
    - `floor` field **removed** from `Resident` schema — it is now purely computed
    - Migration `20260219152503943` drops the `floor` column from the DB
  - **Backend Hardening**:
    - `ApartmentService.canInvite()`: now rejects muted/suspended senders
    - `GroupEndpoint`: mute/suspend checks added to `createGroup` + `joinGroup`
    - `ReportEndpoint`: floor guard uses `effectiveFloor` (not raw XP level)
    - All endpoints (`message`, `moment`, `search`, `admin`, `user_profile`) use `effectiveFloor`
  - **Client Updates**:
    - New `lib/utils/floor_utils.dart`: client-side `effectiveFloor()`, `isMuted()`, `getMuteInputHint()`, `floorCapMessage()`
    - All avatar badges, floor displays, and mute checks updated across the app
    - `UserProfileViewScreen`: Block/Unblock menu with confirmation dialog
    - Private chat + group chat: contextual mute hint shows time remaining

- Phase 8.9: Luxury High-Rise Gamification, Trust Score Caps, and One-Vote Rule (Feb 2026)
  - **Unified Trust Score System**: Conceptually merged Likes and Reports into a single, uncapped `-30` to `+max` **Trust Score**.
    - Replaced the previous dynamic 0-100 `reputation` system.
    - Base passive restoration set to `+5` points per hour up to 100.
    - Each Report penalizes `-30`. Each Vouch/Like adds `+10`.
  - **Abuse Prevention**:
    - **One-Vote Rule**: Created `UserLike` schema to restrict users to a single lifetime Like or Report per unique user.
    - **Daily Report Cap**: Restricted reports to a maximum of 3 per day.
    - **Minimum Floor Gate**: Users must be at least Floor 1 to report others.
  - **Exponential Base Floor Generation**: Replaced linear `XP/100` formula with an exponential curve (`floor = 1 + floor(sqrt(xp) / 7.07)`), capping at **Floor 50**.
  - **Keycard Effective Floor**: `EffectiveFloor = min(BaseFloor, TrustTier)`.
    - Trust >= 100 -> Max Floor 50
    - Trust >= 75 -> Max Floor 10
    - Trust >= 50 -> Max Floor 5
    - Trust >= 25 -> Max Floor 2
    - Trust >= 10 -> Max Floor 1
    - Trust < 10 -> Floor 0 (Muted)
  - **UI/Terminology Updates**:
    - Renamed internal `Reputation` terminology back to **Floor** globally.
    - Added ❤️ **Vouch/Like** icon to `UserProfileViewScreen` via a new Riverpod Provider.

**Status:** 🏗️ In Progress

**Next:**

- Enhanced Discovery based on interests
- Production launch

## Key Components

### Server (`talktive_server`)

- `ResidentEndpoint`: Creates anonymous users, generates UserProfile, inserts Resident, returns JWT.
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

## Useful Commands

- **Start Server**: `dart bin/main.dart --apply-migrations`
- **Kill Stalled Server**: `lsof -t -i:8080 -i:8081 -i:8082 | xargs kill -9`
- **Regenerate Code**: `serverpod generate`
- **Create Migration**: `serverpod create-migration --force`
