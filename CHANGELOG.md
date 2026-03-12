# Talktive Development Changelog

This document tracks the major development milestones and changes made during the Talktive rebuild from Firebase to Serverpod.

---

## March 12, 2026 - Code Review and Consolidation 🛠️

### Code Cleanup & Lint Fixes
- **Flutter Warnings Resolved**: Addressed all `flutter analyze` warnings across `talktive_flutter` by fixing async gap `context.mounted` checks, replacing `print` with `debugPrint`, updating deprecated `withOpacity` to `withValues`, and enclosing conditional bodies in blocks.
- **Client & Server Analysis**: Verified `talktive_server` codebase cleanliness using `dart analyze` and removed redundant imports in `talktive_client` generated files.
- **Initialization Robustness**: Ensured return types match requirements in Riverpod's error handlers during splash screen initialization.

---

## March 11, 2026 - Knock Edge-Cases & Code Cleanup 🧹

### Workflow & Edge-Cases
- **"Double-Knocking" Improvements**: Overwriting the previously sent Knock message if a new one is sent while the invite is still pending to avoid redundant messages.
- **Declined Invite Re-engagement**: Fixed an edge case where users who had previously declined an invite could not subsequently re-initiate a knock to resume the chat due to a stale 'declined' database status.

### UI & UX Polish
- **Groups Background Consistency**: Migrated the Groups tab away from the light `duoYellowGradient` towards the darker `duoBlueGradient` mapped specifically to ensure visually consistent dark headers with white textual overlay across all five primary tabs. Bottom navigation bar colors were reciprocally updated.
- **Web/Desktop Manual Refresh**: Created a conditional `DuoRefreshButton` injected into `AppBar` and `DuoPageScaffold` trailing headers universally on desktop and web targets to manually trigger data sync routines where native mobile pull-to-refresh gestures fail to translate natively.
- **Moments Feed Padding**: Added missing top margin to `MomentsScreen` and `UserMomentsScreen` for visual separation from the header.
- **Removed Floor Overlay**: Safely removed the explicit "Floor X" overlay from `DuoMomentCard` images since strict floor-based access restrictions have been lifted.

### Maintenance
- **Local Dev URL Translation**: Added reverse `10.0.2.2` -> `localhost` conversion in `UrlHelper` to allow Web/iOS clients to render Android Simulator uploaded images properly.
- **Lint Cleanup**: Applied `dart fix` globally across the Serverpod and Flutter directories to remove unused imports and redundant null-assertions.

### Notification System & Activity Hub 🔔
- **Renamed "Achievements" to "Activity"**: Updated the Profile tab to use the "Activity" label, broadening the scope from just badges to include notification history and social interactions.
- **In-App Notification Fixes**: Resolved issues preventing `DuoNotificationToast` from appearing for private and group chat messages.
- **FCM Reliability**: Fixed an invalid `priority` field in the FCM v1 payload that caused Android delivery failures.
- **Improved Life-cycle Management**: Ensured the `FCMManager` stays active by watching its provider in the root application widget.
- **Route Resolution**: Fixed an issue in the Plaza where message routes were not correctly identified, ensuring notifications are properly suppressed when the user is already on the relevant screen.
- **Debug Logging**: Added extensive `FCM DEBUG` logs to both client and server for precise troubleshooting of notification flows.

---

## March 10, 2026 - Serverpod Upgrade & Maintenance ⚙️

### Infrastructure
- **Serverpod Upgrade (Phase 8.23)**: Upgraded entire stack (server, client, flutter) to Serverpod **3.4.2**.
- **Database Migration**: Applied migration `20260310083913981` which includes the new `gen_random_uuid_v7()` function and support for Facebook/Microsoft auth IDPs.
- **Dependency Pinning**: Switched from caret ranges (`^3.4.2`) to exact versions (`3.4.2`) across all projects to ensure strict protocol compatibility.
- **CLI Update**: Activated latest `serverpod_cli` for improved generation and cloud storage features.
- **Protocol Synchronization**: Regenerated all client/server communication protocols to ensure compatibility with 3.4.2.

---

## March 9, 2026 - UX Refinement & Layout Consolidation ⌨️

### UX & Accessibility
- **Trust-Score Avatar Rings**: Implemented dynamic avatar ring coloring based on a resident's Trust Score (Green for friendly/high trust, Red for suspicious/low trust).
- **Avatar UI Refinement**: Streamlined resident avatars by moving Floor levels to a dedicated badge next to usernames, keeping only Mood emojis as overlays for a cleaner, more dynamic look.
- **DuoFloorBadge**: Introduced a new color-coded floor level badge for consistent status display across chat bubbles, headers, and comments.
- **Keyboard Dismissal**: Implemented "Tap Outside to Hide Keyboard" across all chat screens (Plaza, Private, Groups, Moments) and onboarding.
- **Consolidated Layouts**: Created `DuoChatLayout` and `DuoChatInputLayout` to standardize screen structure and reduce boilerplate.
- **Improved Focus Management**: Integrated automatic keyboard dismissal into the standard chat navigation flow and profile setup.

### Architectural Polish
- **Duo Component Expansion**: Added `DuoKeyboardDismissible` and `DuoChatLayout` widgets for rapid development of consistent chat-like screens.
- **Structural Consolidation**: Refactored `PlazaChatScreen`, `ChatThreadScreen`, `GroupChatScreen`, and `MomentDetailScreen` to use unified layouts.

---

## March 9, 2026 - Structural Consolidation & Start-up Success 🚀

### Architectural Polish
- **Duo Component Expansion**: Added `DuoFloorRequirementDialog` to centralize and standardize "High-Rise Access" restrictions.
- **Structural Consolidation**: Refactored `MomentsScreen` and `GroupsScreen` to use unified permission gates, reducing code duplication.
- **Client Synchronization**: Fixed missing imports and provider references in `MomentsScreen` and `UserProfileViewScreen` for stable compilation.

### Operational Success
- **Multimodal Deployment**: Successfully running Serverpod, Flutter Web, and Flutter Android (Emulator) concurrently.
- **Clean Start-up**: Optimized server initialization to ensure FCM services and database migrations apply cleanly on boot.

---

## March 7-8, 2026 - Standardized Error Handling & UI Polish 💎

### Standardization & Resilience
- **Protocol Error Handling**: Replaced generic 500 errors with `TalktiveException` across all endpoints (`Moment`, `Group`, `Chat`, `Resident`).
- **SnackBar Architecture**: Upgraded frontend to intelligently parse and display descriptive server exceptions.
- **Input Validation**: Integrated `InputValidationService` into all core endpoints for strict data integrity.
- **UI Consistency**: Migrated all standard buttons to `DuoButton` (Onboarding, Profiles, Admin, Groups).
- **Reactive States**: Migrated user and group profiles to Riverpod providers for real-time UI updates.

### Safety & Privacy (Phase 8.22)
- **Universal Knocking**: Removed Floor restrictions for "Knocking". Anyone can knock on any door if not muted, relying on the **Peephole system** for mutual consent and safety.
- **Peephole Screen**: Immersive vignette review screen for inspecting strangers before accepting private chat invites.
- **Abuse Prevention**: Implemented One-Vote Rule for user likes/reports and daily report caps.

---

## March 1-6, 2026 - Social Features & Gamification 🎮

### Moments Feed (Phase 8.20-8.21)
- **Direct Firebase Uploads**: Standardized on Client -> Storage for high-performance media handling.
- **Immersive Viewing**: Built `MomentDetailScreen` with comments and full-screen gallery with pinch-to-zoom.
- **Engagement Rewards**: Social interactions (Likes) now award XP (+20) and Trust Score bonuses (+10).
- **Web Compatibility**: Fixed cross-platform image preview issues and Android emulator networking (`10.0.2.2`).

### Clubhouse Mechanics (Phase 8.14-8.16)
- **Apply/Invite Flow**: Replaced generic joining with application and approval flows.
- **Personalized Discovery**: Interest-based group ranking and "Suggested for You" sorting.
- **Group Creation**: Added animated interest tag selection to the creation dialog.

### Core Optimizations (Phase 8.12-8.13)
- **Query Reduction**: Eliminated N+1 overhead in chat messages and group member listings.
- **Name Denormalization**: Added `userName` directly to `Resident` model to reduce database lookups.
- **Achievement Batching**: Coalesced progress updates into single transactions for high performance.

---

## February 2026 - Luxury High-Rise Gamification 🏙️

### Hybrid Floor System (Phase 8.7-8.10)
- **The Formula**: `EffectiveFloor = min(BaseFloor, TrustTier)`.
- **Trust Score System**: Unified likes/reports into a single uncapped Trust Score (-30 to +max).
- **Exponential Leveling**: Implemented `floor(sqrt(xp) / 7.07)` curve for Base Floor generation (Capped at 50).
- **Data Integrity**: Migrated "Mood" to a native field and fixed edit profile reseeding issues.

---

## Earlier Development Phases

### Phase 1-5: Core Rebuild
- Migrated from Firebase to Serverpod
- Rebuilt authentication system
- Implemented real-time messaging with WebSockets
- Created Duolingo-inspired UI/UX
- Implemented "Apartment Building" metaphor
- Built credit system for spam prevention
- Added content filtering and rate limiting

### Key Architectural Decisions
- Serverpod 3.2.3 for backend
- PostgreSQL 16+ for database
- Redis 7+ for caching and rate limits
- Firebase Auth + Serverpod Auth Core
- UUID-based user identification
- Denormalized data for performance

---

## Development Statistics

- **Total Commits:** 90+
- **Lines of Code:** 50,000+
- **Test Coverage:** 320+ test cases
- **Development Time:** 3 months
- **Team Size:** 1 developer + AI assistant

---

## Architecture Highlights

### Database
- Proper indexes on all tables
- Denormalized data for performance
- UUID-based user identification
- Composite indexes for common queries

### API
- Pagination on all list endpoints
- Rate limiting with Redis
- Content filtering (profanity, spam)
- Credit system for spam prevention
- Batch endpoints for efficiency
- Input validation on all endpoints

### Security
- Firebase Authentication → Serverpod session
- JWT/SAS token-based auth
- Rate limiting (Redis-based)
- Content filtering
- Credit system (anti-spam)
- Floor-based permissions
- Channel membership validation
- Image validation (magic bytes, dimensions)

### Performance
- N+1 query problem fixed
- Batch endpoints
- Denormalized data
- Redis caching for rate limits
- Streaming for real-time updates
- Proper indexing
- Data archival for old content

---

## References

- **Launch Details:** `docs/LAUNCH_IMPROVEMENTS.md`
- **Production Review:** `docs/SERVERPOD_REVIEW.md`
- **Codebase Structure:** `docs/CODEBASE_STRUCTURE.md`
- **Notification Architecture:** `docs/NOTIFICATION_ARCHITECTURE.md`
- **Deployment Guide:** `DEPLOYMENT.md`
- **Project Context:** `GEMINI.md`
