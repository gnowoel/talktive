# Talktive Development Changelog

This document tracks the major development milestones and changes made during the Talktive rebuild from Firebase to Serverpod.

---

## March 18, 2026 - Unified Discovery & Architectural Stabilization 🔍🏗️

### Unified Discovery System
- **DiscoveryScreen Implementation**: Created a new, comprehensive `DiscoveryScreen` that unifies searching for users, lounges, and moments into a single, cohesive experience. It features a personalized "Discovery Feed" with recommended lounges and trending content.
- **Personalized Recommendations**: Updated `SearchEndpoint.getDiscoveryFeed` to fetch the resident's interests and provide tailored lounge suggestions, falling back to global popularity if the resident is new or has no interests.
- **Search Consolidation**: Replaced the standalone `LoungeSearchScreen` with the new integrated `DiscoveryScreen` and updated the app's router to point all search entry points (Plaza, Moments, Lounges) to this unified destination.

### Architectural Stabilization & Fixes
- **Type Safety in Search**: Refactored the `SearchAllResults` and `DiscoveryFeed` protocols to be more robust and type-safe, ensuring consistent data structures for cross-category search results.
- **Admin CLI Migration**: Fully migrated `admin_bootstrap.dart` to use "Lounge" terminology and updated it for the new role-based permission system, fixing critical compilation errors in the server's maintenance tools.
- **Flutter Analysis Resolution**: Resolved a final batch of `flutter analyze` warnings, including deprecated member usage (`value` -> `initialValue` in forms, `activeColor` -> `activeTrackColor` in switches) and async gap stability improvements (`context.mounted` checks).
- **Service Layer Polish**: Refactored `LoungeService` and `ResidentService` to handle personalized data fetching more cleanly, reducing endpoint boilerplate.
- **Start-up Success**: Verified clean, warning-free initialization of the Serverpod backend, Flutter Web, and Flutter Android platforms.

---

## March 17, 2026 - Admin Performance, Safety & The Lounge Pivot 🛋️🛡️

### Admin & Analytics Improvements 🛡️
- **Optimized User Search**: Refactored `AdminEndpoint.searchUsers` to utilize batch database queries for user statistics (messages, moments, reports). This reduces the database round-trips from one-per-user to a constant 3 queries, significantly improving performance for large search results.
- **Enhanced Statistical Insights**: Updated `getStatistics` to compute active user counts (unique senders) for 24h, 7d, and 30d periods using optimized SQL queries.
- **Complete Activity Tracking**: Expanded activity reporting to include counts for messages, moments, and reports across all time-bound dashboard widgets.
- **Analytics UI Refresh**: Updated `AnalyticsScreen` in Flutter to show the new comparative metrics for all time periods.

### Safety & Engagement
- **Moderation Notifications**: Implemented automated "Safety" and "Warning" notifications for users who reach report thresholds (5 reports/7 days for mute, 10 reports/30 days for reputation reset).
- **Vouch Feedback**: Added real-time notifications when a resident receives a "Vouch" (like), reinforcing positive community behavior and providing immediate social feedback.
- **Admin Detail Polish**: Ensured `getUserDetails` fetches and displays correct consolidated counts using the optimized batch-query helper.

### Staff Role Refactoring
- **Consolidated Role Architecture**: Replaced separate `isAdmin` and `isModerator` boolean flags with a single, type-safe `role` field using the `ResidentRole` enum (`user`, `moderator`, `admin`).
- **Improved Performance**: Simplified database queries and object mapping by consolidating individual permission flags into a single indexed field.
- **Permission Tiering**: Refactored `AdminEndpoint` to distinguish between **Staff Actions** (accessible to both Admins and Moderators) and **Admin-only Actions** (promoting/demoting staff).
- **Staff Auth Mixin**: Updated `EndpointAuthMixin` to use the new role system for authorization checks, standardizing staff-level access throughout the backend.

### Staff-Enforced Moderation
- **Staff-Enforced Locking**: Renamed `isAdminLocked` to `isStaffLocked` in the `Lounge` model to explicitly reflect that both Moderators and Admins can now lock a lounge's visibility.
- **User Moderation**: Integrated "Mute" and "Suspend" actions directly into the `UserProfileViewScreen` for staff members, featuring professional double-confirmation dialogs.
- **Lounge Oversight**: Expanded the "Gavel" menu in Lounge Chats and Profiles to allow any Staff member to "Force Private" or disband problematic lounges.
- **Message Deletion**: Enabled long-press message deletion for staff members in the chat UI, providing immediate content moderation capabilities.

### Admin CLI Utility
- **Role System Migration**: Updated `admin_bootstrap.dart` to support the new enum-based role field for all administrative commands (`promote`, `demote`, `promote-mod`, `demote-mod`).
- **Enhanced Visibility**: Updated `list-users` and `list-lounges` to use the unified role indicators and the renamed `isStaffLocked` property.

### The Lounge Pivot: Terminology & Metaphor Realignment 🛋️
- **Unified Lounge Terminology**: Successfully refactored the entire codebase (backend, client, and frontend) to replace all instances of "Lounges" and "Clubs" with "Lounges". This aligns with the "Apartment Building" metaphor, where community spaces are seen as relaxed clubhouses within the building.
- **Protocol Migration**: Updated all Serverpod models (`Lounge`, `LoungeMemberWithProfile`, `LoungeWithMembership`) and regenerated the communication layer.
- **Frontend Realignment**: Renamed all lounge-related screens, providers, and widgets (e.g., `LoungeChatScreen` -> `LoungeChatScreen`, `loungeListProvider` -> `loungeListProvider`).
- **Global Lounge & Public Chat**: Re-established consistent terminology for the Plaza lobby as the "Global Lounge" for "Public Chat", reinforcing the idea that the Plaza is a special, shared community lounge.
- **Inviting & Friendly Tone**: Systematic review of UI copy to ensure all labels, empty states, and error messages use a more welcoming tone (e.g., "Join the community clubhouse", "Slip a flyer under the door").
- **Iconography Update**: Harmonized icons for lounges, using `Icons.meeting_room` and building-centric symbols to represent the clubhouse entrance.

---

## March 16, 2026 - Resident Profile Consolidation & Gamification Reliability 🏗️

### Backend Architectural Refinement
- **Consolidated Profile View**: Centralized the computation of `UserProfileView` (stats, social states, computed floor) into `ResidentService.getResidentProfileView`. This removes redundant code from `ResidentEndpoint` and `AdminEndpoint`.
- **Unified Social State**: Added `isLiked` status directly to the `UserProfileView` protocol, allowing the frontend to determine vouching status in a single request.
- **Improved Vouch Logic**: Centralized trust score adjustments for vouches in `ApartmentService` (added `removeVouch`) and updated `ResidentEndpoint` to ensure consistent state management.

### Gamification & Reliability
- **Trust Score Fix**: Fixed a critical bug in `claimDailyReward` where trust score was incorrectly clamped to 100 instead of 1000, which potentially penalized high-trust users.
- **Consolidated Achievement Tracking**: Refactored `GamificationService` to use a single `trackMultipleProgress` core for all achievement updates, improving maintainability and ensuring consistent notification triggering.
- **Streak Optimization**: Simplified the internal streak update logic to be more efficient and easier to verify.

### Frontend Reactive Polish
- **Reactive User Profiles**: Refactored the `UserProfile` provider using `riverpod_annotation` to be fully reactive to block/like events.
- **Unified Profile UI**: Re-implemented `ProfileScreen` and `UserProfileViewScreen` to use the same reactive `UserProfile` provider, ensuring message/moment counts and social buttons are always in sync.
- **Refresh Synchronization**: Updated `CurrentResident` manual refresh to automatically invalidate and reload the associated profile view stats.

### Polish & Refinement Fixes
- **Import Consolidation**: Resolved ambiguous `Message` import conflicts in `ResidentService` by hiding them from `serverpod`.
- **Duo Display Helpers**: Consolidated trust score color computation into `DuoFloorHelper` for universal branding across all profile screens.
- **Provider Reliability**: Fixed missing dependencies in `CurrentResident` provider to ensure real-time synchronization of shared profile stats.
- **Auto-Syncing User Profiles**: Enabled fully-generated Riverpod providers for consistent state management across deep-linked profile views.

---

## March 15, 2026 - Structural Layout Harmonization & Design System Update 🎨

### UI/UX Refinement: Destinations vs. Utilities
- **Lightweight Layout Refactor**: Migrated all functional sub-screens and utility pages from the immersive `DuoPageScaffold` to a focused `Scaffold` + `AppBar` architecture. This improves clarity, reduces visual clutter, and provides more room for content.
- **Harmonized Profiles**: Realigned the `UserProfileViewScreen` (Others) to match the `ProfileScreen` (Self), ensuring a consistent "Resident Identity" experience with centered Poppins titles and clean white backgrounds.
- **Utility Screen Optimization**: Applied the lightweight layout to `LoungeSearchScreen` (Discovery), `LoungeMembersScreen`, `LoungeProfileScreen` (Lounges), and `BlockedUsersScreen`.
- **Navigation Polish**: Standardized navigation depth indicators, replacing generic back arrows with `close_rounded` on top-level sub-discovery pages for a more "modal-like" feel that respects the app's hierarchy.

### Design System & Documentation
- **Updated `DESIGN_SYSTEM.md`**: Formalized the distinction between **Immersive Destinations** (Main tabs like Plaza, Moments, etc., which retain vibrant gradients) and **Focused Utility Screens** (Profiles, Search, Management, which use clean white layouts).
- **Consistency Audit**: Verified that all list-based and detail-oriented sub-screens follow the new focused layout pattern, while keeping primary entry points high-energy and brand-immersive.

---

## March 14, 2026 - Endpoint Consolidation & Unified Gamification 🛠️

### Consolidation & Simplification
- **Centralized Gamification**: Merged `AchievementService` and `StreakService` into a unified `GamificationService`. Consolidated `AchievementEndpoint` and `StreakEndpoint` into `GamificationEndpoint`.
- **Integrated Resident Profile**: Merged `UserProfileEndpoint` and `UserLikeEndpoint` into `ResidentEndpoint`, centralizing all user-centric logic (profile viewing, blocking, liking, and initialization).
- **Backend Code Cleanup**: Removed redundant `UserStreak` protocol and simplified logic in `ResidentService`, reducing architectural complexity and database overhead.
- **Frontend Provider Consolidation**: Created `GamificationProvider` to manage all rewards, achievements, and streaks in a single reactive state. Merged `NotificationProvider` and `UserNotificationsProvider` into a unified notification management system.
- **Dead Code Removal**: Removed unused `achievements` folder and redundant providers (`AchievementProvider`, `StreakProvider`, `UserNotificationsProvider`) from the Flutter codebase.

### Robustness & Design
- **Improved Type Safety**: Refactored `ResidentEndpoint` to use explicit `protocol.` prefixes for disambiguation and fixed ambiguous imports.
- **Unified Activity Feed**: Standardized the use of `ActivityHistoryProvider` across the Home, Activity, and Unread Count components for consistent state management.
- **Consolidated Snippets**: Updated `ProfileScreen`, `HomeScreen`, and `ActivityScreen` to work with the newly consolidated provider architecture.

---

## March 13, 2026 - Image Handling & Architectural Refinement 🖼️
 
### Image Handling & UI
- **Dev Environment Visibility**: Fixed an issue where images uploaded from Android emulators (`10.0.2.2`) were not visible on other platforms (`localhost`) by implemented an automated URL resolution helper in `MessageBubble`.
- **Full-Screen Chat Gallery**: Added `Hero` animations and `GestureDetector` to chat image messages, allowing users to tap and view images in a full-screen gallery.
- **Unified Routing**: Refactored the `/moments/gallery` route into a top-level `/gallery` path, enabling shared use across both Moments and Chat views.
 
### Architectural Consolidation
- **Consolidated Rate Limiting**: Merged the redundant database-backed and Redis-backed rate limiters into a single, high-performance `RateLimitService` using Serverpod's global cache.
- **Dead Code Removal**: Removed unused `ImageEndpoint` and `StorageEndpoint` along with their associated services and protocol definitions to simplify the server implementation and reduce maintenance overhead.
- **Protocol Cleanup**: Regenerated Serverpod code and removed obsolete `rate_limit` database tables.
 
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
- **Lounges Background Consistency**: Migrated the Lounges tab away from the light `duoYellowGradient` towards the darker `duoBlueGradient` mapped specifically to ensure visually consistent dark headers with white textual overlay across all five primary tabs. Bottom navigation bar colors were reciprocally updated.
- **Web/Desktop Manual Refresh**: Created a conditional `DuoRefreshButton` injected into `AppBar` and `DuoPageScaffold` trailing headers universally on desktop and web targets to manually trigger data sync routines where native mobile pull-to-refresh gestures fail to translate natively.
- **Moments Feed Padding**: Added missing top margin to `MomentsScreen` and `UserMomentsScreen` for visual separation from the header.
- **Removed Floor Overlay**: Safely removed the explicit "Floor X" overlay from `DuoMomentCard` images since strict floor-based access restrictions have been lifted.

### Maintenance
- **Local Dev URL Translation**: Added reverse `10.0.2.2` -> `localhost` conversion in `UrlHelper` to allow Web/iOS clients to render Android Simulator uploaded images properly.
- **Lint Cleanup**: Applied `dart fix` globally across the Serverpod and Flutter directories to remove unused imports and redundant null-assertions.

### Notification System & Activity Hub 🔔
- **Renamed "Achievements" to "Activity"**: Updated the Profile tab to use the "Activity" label, broadening the scope from just badges to include notification history and social interactions.
- **In-App Notification Fixes**: Resolved issues preventing `DuoNotificationToast` from appearing for private and lounge chat messages.
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
- **Keyboard Dismissal**: Implemented "Tap Outside to Hide Keyboard" across all chat screens (Plaza, Private, Lounges, Moments) and onboarding.
- **Consolidated Layouts**: Created `DuoChatLayout` and `DuoChatInputLayout` to standardize screen structure and reduce boilerplate.
- **Improved Focus Management**: Integrated automatic keyboard dismissal into the standard chat navigation flow and profile setup.

### Architectural Polish
- **Duo Component Expansion**: Added `DuoKeyboardDismissible` and `DuoChatLayout` widgets for rapid development of consistent chat-like screens.
- **Structural Consolidation**: Refactored `PlazaChatScreen`, `ChatThreadScreen`, `LoungeChatScreen`, and `MomentDetailScreen` to use unified layouts.

---

## March 9, 2026 - Structural Consolidation & Start-up Success 🚀

### Architectural Polish
- **Duo Component Expansion**: Added `DuoFloorRequirementDialog` to centralize and standardize "High-Rise Access" restrictions.
- **Structural Consolidation**: Refactored `MomentsScreen` and `LoungesScreen` to use unified permission gates, reducing code duplication.
- **Client Synchronization**: Fixed missing imports and provider references in `MomentsScreen` and `UserProfileViewScreen` for stable compilation.

### Operational Success
- **Multimodal Deployment**: Successfully running Serverpod, Flutter Web, and Flutter Android (Emulator) concurrently.
- **Clean Start-up**: Optimized server initialization to ensure FCM services and database migrations apply cleanly on boot.

---

## March 7-8, 2026 - Standardized Error Handling & UI Polish 💎

### Standardization & Resilience
- **Protocol Error Handling**: Replaced generic 500 errors with `TalktiveException` across all endpoints (`Moment`, `Lounge`, `Chat`, `Resident`).
- **SnackBar Architecture**: Upgraded frontend to intelligently parse and display descriptive server exceptions.
- **Input Validation**: Integrated `InputValidationService` into all core endpoints for strict data integrity.
- **UI Consistency**: Migrated all standard buttons to `DuoButton` (Onboarding, Profiles, Admin, Lounges).
- **Reactive States**: Migrated user and lounge profiles to Riverpod providers for real-time UI updates.

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
- **Personalized Discovery**: Interest-based lounge ranking and "Suggested for You" sorting.
- **Lounge Creation**: Added animated interest tag selection to the creation dialog.

### Core Optimizations (Phase 8.12-8.13)
- **Query Reduction**: Eliminated N+1 overhead in chat messages and lounge member listings.
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
