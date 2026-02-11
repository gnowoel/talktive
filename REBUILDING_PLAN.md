# Talktive Rebuilding Plan

## 🎯 Vision

Transform Talktive into a highly engaging, gamified anonymous chat platform with a Duolingo-inspired aesthetic that encourages positive behavior through floor progression, achievements, streaks, and celebration-driven interactions.

---

## 📊 Current Status (February 11, 2026)

### ✅ Phase 1: Design Foundation (COMPLETED)

**Goal:** Establish Duolingo-inspired design system across the entire app

**Completed:**

- [x] Created comprehensive design system with Duolingo colors
- [x] Built reusable component library (`lib/widgets/duo/`)
- [x] Redesigned bottom navigation with floating pill bar
- [x] Implemented haptic feedback and animations
- [x] Updated theme with design constants

**Components Created:**

- DuoButton, DuoCard, DuoAvatar, DuoInput
- DuoEmptyState, DuoHeader, DuoStatCard
- DuoBadge, DuoStreakCard

**Commits:** 534b102, 45bd71e, f1b0eaf

---

### ✅ Phase 2: Core Screen Redesigns (COMPLETED)

**Goal:** Apply Duolingo aesthetic to all main screens

**Completed:**

- [x] Plaza screen - Public chat with emoji header, clean bubbles
- [x] Profile screen - Gradient header, stat cards grid, streaks, achievements
- [x] Moments screen - Card-based feed, likes, comments
- [x] Chats screen - Private 1-on-1 messaging
- [x] Groups screen - Group chat with member management

**Preserved Functionality:**

- Real-time messaging via chatProvider
- Credit score validation
- Optimistic updates
- Pull-to-refresh
- Image uploads

**Commits:** 534b102, 45bd71e

---

### ✅ Phase 3: Backend Stability (COMPLETED)

**Goal:** Ensure all backend endpoints work correctly with Serverpod 3.x

**Status:** ✅ All Complete

- [x] Message endpoint with real-time streaming
- [x] Moment endpoint with floor restrictions, likes, comments
- [x] Resident endpoint with UUID support
- [x] Image upload endpoint
- [x] Report system with abuse prevention
- [x] Rate limiting service
- [x] Real-time WebSocket streaming (Serverpod 3.x API)
- [x] Private chat endpoint
- [x] Group endpoint
- [x] Achievement endpoint
- [x] Streak endpoint

**Resolution:**

- Updated Plaza screen to use `realtimeChatProvider`
- Confirmed Serverpod 3.x streaming API working correctly
- `session.messages.postMessage()` and `session.messages.createStream()` functional
- Real-time message delivery tested and working

**Commits:** 935b118

---

## 🚀 Phase 4: Feature Completion (COMPLETED)

### ✅ 4.1 Private Chats (COMPLETED)

**Goal:** Enable 1-on-1 private messaging between users

**Status:** ✅ All Complete

**Completed Tasks:**

- [x] Design chat list UI with Duolingo style
- [x] Implement chat creation endpoint
- [x] Build message thread view
- [x] Add real-time messaging
- [x] Implement credit score validation
- [x] Create empty states with CTAs
- [x] Add pull-to-refresh support
- [x] Implement haptic feedback

**Files Created:**

- `talktive_server/lib/src/endpoints/private_chat_endpoint.dart`
- `talktive_server/lib/src/protocol/private_chat.spy.yaml`
- `talktive_flutter/lib/screens/chats/chats_screen_modern.dart`
- `talktive_flutter/lib/screens/chats/chat_thread_screen.dart`
- `talktive_flutter/lib/providers/private_chat_provider.dart`
- `talktive_flutter/lib/providers/current_resident_provider.dart`

**Features Implemented:**

- Chat list with last message timestamps
- Real-time message delivery via WebSocket
- Empty states with CTAs to Plaza
- Message bubbles with gradients
- Credit score validation for sending
- Seamless chat creation with `getOrCreatePrivateChat`

**Commits:** d3a4aa1

---

### ✅ 4.2 Group Chats (COMPLETED)

**Goal:** Enable community-based group conversations

**Status:** ✅ All Complete

**Completed Tasks:**

- [x] Design group creation flow
- [x] Implement group endpoint (create, join, leave)
- [x] Build group list UI
- [x] Create group chat view
- [x] Add member management (invite, kick, promote)
- [x] Implement group settings
- [x] Add group icons/emojis
- [x] Create member list view

**Files Created:**

- `talktive_server/lib/src/endpoints/group_endpoint.dart`
- `talktive_server/lib/src/protocol/group.spy.yaml`
- `talktive_flutter/lib/screens/groups/groups_screen_modern.dart`
- `talktive_flutter/lib/screens/groups/create_group_dialog.dart`
- `talktive_flutter/lib/screens/groups/group_chat_screen.dart`
- `talktive_flutter/lib/screens/groups/group_members_screen.dart`
- `talktive_flutter/lib/providers/group_provider.dart`

**Features Implemented:**

- Create groups with custom emoji and description
- Public/private group visibility toggle
- Configurable max members (2-500)
- Join/leave groups with member count tracking
- Real-time group messaging via WebSocket
- Member list with floor levels and stats
- Admin-only group updates
- Creator-only group deletion
- Floating action button for quick creation

**Commits:** 757ec3d

---

## 🎨 Phase 5: Polish & Engagement (COMPLETED)

### ✅ 5.1 Achievements System (COMPLETED)

**Goal:** Gamify user progression with unlockable achievements

**Status:** ✅ All Complete

**Completed Tasks:**

- [x] Design achievement badge system
- [x] Create achievement definitions (15 achievements)
- [x] Implement unlock logic on backend
- [x] Build achievements screen UI
- [x] Add confetti animations for unlocks
- [x] Create notification system for new achievements
- [x] Add achievement progress tracking
- [x] Integrate into profile screen

**Files Created:**

- `talktive_server/lib/src/protocol/achievement.spy.yaml`
- `talktive_server/lib/src/protocol/user_achievement.spy.yaml`
- `talktive_server/lib/src/services/achievement_service.dart`
- `talktive_server/lib/src/endpoints/achievement_endpoint.dart`
- `talktive_flutter/lib/screens/achievements/achievements_screen.dart`
- `talktive_flutter/lib/widgets/duo/duo_badge.dart`
- `talktive_flutter/lib/providers/achievement_provider.dart`

**Achievement Categories:**

- **Social:** first_message, conversationalist, chatterbox, social_butterfly, community_builder, private_chat
- **Moments:** first_moment, photographer, influencer
- **Progression:** rising_star, high_rise, penthouse
- **Behavior:** helpful, trusted
- **Special:** night_owl, early_bird

**Features Implemented:**

- 15 predefined achievements across 5 categories
- Progress tracking for incremental achievements
- Confetti animation on unlock
- "New" indicator with pulsing animation
- Achievement detail dialog with progress display
- Grouped by category with emoji headers
- Stats card showing unlocked count and total points
- Automatic tracking on message, moment, group, and chat actions

**Commits:** 3089e6e

---

### ✅ 5.2 Enhanced Moments (COMPLETED)

**Goal:** Make moments more interactive and engaging

**Status:** ✅ All Complete

**Completed Tasks:**

- [x] Implement like functionality
- [x] Add comment system
- [x] Create moment detail view (comments sheet)
- [x] Add comment deletion (own comments only)
- [x] Implement optimistic UI updates
- [x] Add like/comment count display
- [x] Track liked state per user

**Files Created:**

- `talktive_server/lib/src/protocol/moment_like.spy.yaml`
- `talktive_server/lib/src/protocol/moment_comment.spy.yaml`

**Files Modified:**

- `talktive_server/lib/src/endpoints/moment_endpoint.dart` (added like/comment methods)
- `talktive_flutter/lib/screens/moments/moments_screen_modern.dart` (added UI)

**Features Implemented:**

- Like/unlike moments with heart icon
- Real-time like count updates
- Optimistic UI updates for better UX
- Comments bottom sheet with scrollable list
- Add comments with text input
- Comment author info with avatar and floor level
- Delete own comments (author-only)
- Automatic comment count updates
- Tracked liked state per user with `hasLikedMoment` endpoint

**Commits:** 8a65836

---

### ✅ 5.3 Streaks & Daily Rewards (COMPLETED)

**Goal:** Encourage daily engagement with streak tracking and rewards

**Status:** ✅ All Complete

**Completed Tasks:**

- [x] Design streak card UI
- [x] Implement streak tracking logic
- [x] Create daily reward system
- [x] Add streak display to profile
- [x] Implement reward claim functionality
- [x] Add animated flame icon
- [x] Integrate streak tracking into activities

**Files Created:**

- `talktive_server/lib/src/protocol/user_streak.spy.yaml`
- `talktive_server/lib/src/protocol/daily_reward.spy.yaml`
- `talktive_server/lib/src/services/streak_service.dart`
- `talktive_server/lib/src/endpoints/streak_endpoint.dart`
- `talktive_flutter/lib/widgets/duo/duo_streak_card.dart`
- `talktive_flutter/lib/providers/streak_provider.dart`

**Files Modified:**

- `talktive_server/lib/src/endpoints/message_endpoint.dart` (streak tracking)
- `talktive_server/lib/src/endpoints/moment_endpoint.dart` (streak tracking)
- `talktive_flutter/lib/screens/profile/profile_screen_modern.dart` (streak display)

**Streak Tracking:**

- Tracks current streak, longest streak, and total active days
- Consecutive day detection (resets if missed a day)
- Automatic updates on user activity (messages, moments)

**Reward System:**

- Base reward: 10 credits
- Bonus: +2 credits per streak day (up to 7 days)
- Max reward: 24 credits at 7+ day streak
- One reward claim per day
- Rewards automatically added to resident credit score

**Features Implemented:**

- Animated flame icon with pulsing effect
- Gradient orange/yellow card design
- Current streak and longest streak display
- Claimable reward indicator
- Shimmer animation for unclaimed rewards
- Haptic feedback on claim
- Toast notification with reward amount
- Automatic refresh of resident data after claim

**Commits:** a331a54, e93d9c6 (compilation fixes)

---

## 🚀 Phase 6: Advanced Features (IN PROGRESS)

### ✅ 6.1 Push Notifications (COMPLETED)

**Goal:** Keep users engaged with timely notifications

**Status:** ✅ All Complete

**Completed Tasks:**

- [x] Integrated Firebase Cloud Messaging (FCM)
- [x] Created notification backend infrastructure
- [x] Implemented notification handlers for all types
- [x] Added deep linking to specific screens
- [x] Updated messaging service with backend integration
- [x] Automatic token registration and refresh

**Backend Implementation:**

- Created `UserNotification` and `DeviceToken` protocols
- Implemented `NotificationService` for all notification types
- Created `NotificationEndpoint` for API access
- Integrated notifications into moment endpoint
- Database migration: `20260211100938725`

**Frontend Implementation:**

- Created `ServerpodNotificationService` for Serverpod version only
- Initialized in `SplashScreen` for Serverpod app
- Pending notification handling in `HomeScreen`
- FCM token registration on app start
- Token refresh handling
- Unified notification tap handling
- Deep linking routes for all screens
- `HomeScreen` accepts `initialIndex` for tab navigation

**Important:** The old Firebase version (`messaging.dart`) remains **unchanged** to maintain compatibility during migration. The Serverpod version uses a separate `ServerpodNotificationService`.

**Notification Types Implemented:**

- New message in Plaza (type: `message`)
- Someone liked your moment (type: `moment_like`)
- Someone commented on your moment (type: `moment_comment`)
- Achievement unlocked (type: `achievement`)
- Streak milestone (type: `streak`)
- Group invite (type: `group_invite`)

**Remaining Tasks:**

- [ ] Add badge counts for unread messages
- [ ] Create notification preferences screen
- [ ] Implement notification grouping
- [ ] Add sound and vibration customization
- [ ] Test on iOS devices

**Commits:** 318f03b, 1cc1350 (version separation fix), 3edb170 (Firebase init fix)

---

### 6.2 User Profiles View (High Priority)

**Goal:** Allow users to view other users' profiles

**Tasks:**

- [ ] Design user profile view screen
- [ ] Implement profile endpoint (get user by ID)
- [ ] Display user stats (floor, credit score, achievements)
- [ ] Show user's recent moments
- [ ] Add block/unblock functionality
- [ ] Implement report user from profile
- [ ] Add "Start Chat" button
- [ ] Show mutual groups

**Estimated Effort:** 1 week

**Files to Create:**

- `talktive_flutter/lib/screens/profile/user_profile_screen.dart`
- `talktive_server/lib/src/endpoints/user_profile_endpoint.dart`
- `talktive_server/lib/src/protocol/user_block.spy.yaml`

**Design Specs:**

- Similar to own profile but read-only
- Gradient header with avatar
- Stats grid (floor, achievements, moments)
- Recent moments feed
- Action buttons (Chat, Block, Report)

---

### 6.3 Search & Discovery (Medium Priority)

**Goal:** Help users find content and people

**Tasks:**

- [ ] Implement user search by name
- [ ] Add group search by name/description
- [ ] Create trending moments feed
- [ ] Build popular groups list
- [ ] Add search history
- [ ] Implement search filters
- [ ] Add search suggestions
- [ ] Create discovery tab

**Estimated Effort:** 2 weeks

**Files to Create:**

- `talktive_flutter/lib/screens/search/search_screen.dart`
- `talktive_flutter/lib/screens/discover/discover_screen.dart`
- `talktive_server/lib/src/endpoints/search_endpoint.dart`

**Features:**

- Search bar with autocomplete
- Recent searches
- Trending hashtags (if implemented)
- Popular groups by member count
- Active users list

---

### 6.4 Admin Dashboard (Medium Priority)

**Goal:** Provide moderation and management tools

**Tasks:**

- [ ] Design admin dashboard UI
- [ ] Implement report moderation interface
- [ ] Add user management (ban, mute, promote)
- [ ] Create analytics dashboard
- [ ] Add content moderation tools
- [ ] Implement bulk actions
- [ ] Add audit log
- [ ] Create admin roles system

**Estimated Effort:** 2-3 weeks

**Files to Create:**

- `talktive_flutter/lib/screens/admin/admin_dashboard_screen.dart`
- `talktive_flutter/lib/screens/admin/reports_screen.dart`
- `talktive_flutter/lib/screens/admin/users_screen.dart`
- `talktive_flutter/lib/screens/admin/analytics_screen.dart`
- `talktive_server/lib/src/endpoints/admin_endpoint.dart`

**Features:**

- Report queue with filtering
- User search and management
- Analytics charts (users, messages, moments)
- Content moderation (delete messages, moments)
- Ban/mute users with duration
- Promote users to admin

---

### 6.5 Enhanced Notifications (Low Priority)

**Goal:** Improve in-app notification experience

**Tasks:**

- [ ] Create in-app notification center
- [ ] Add notification badges
- [ ] Implement notification grouping
- [ ] Add mark as read functionality
- [ ] Create notification preferences
- [ ] Add notification sounds
- [ ] Implement notification history
- [ ] Add notification filters

**Estimated Effort:** 1 week

**Files to Create:**

- `talktive_flutter/lib/screens/notifications/notifications_screen.dart`
- `talktive_server/lib/src/protocol/notification.spy.yaml`
- `talktive_server/lib/src/endpoints/notification_endpoint.dart`

---

## 🎯 Phase 7: Production Readiness (FUTURE)

### 7.1 Performance Optimization

**Tasks:**

- [ ] Implement image caching and optimization
- [ ] Add lazy loading for feeds
- [ ] Optimize database queries with indexes
- [ ] Implement WebSocket connection pooling
- [ ] Add pagination for all lists
- [ ] Optimize bundle size
- [ ] Implement code splitting
- [ ] Add performance monitoring

**Estimated Effort:** 2 weeks

---

### 7.2 Security Enhancements

**Tasks:**

- [ ] Improve rate limiting with Redis
- [ ] Add content filtering (profanity, spam)
- [ ] Implement spam detection algorithms
- [ ] Add IP-based restrictions
- [ ] Implement CAPTCHA for suspicious activity
- [ ] Add two-factor authentication
- [ ] Implement session management
- [ ] Add security headers

**Estimated Effort:** 2 weeks

---

### 7.3 Accessibility

**Tasks:**

- [ ] Add screen reader support
- [ ] Implement high contrast mode
- [ ] Add font size adjustments
- [ ] Implement keyboard navigation
- [ ] Add alt text for images
- [ ] Test with accessibility tools
- [ ] Add voice commands
- [ ] Implement color blind modes

**Estimated Effort:** 1-2 weeks

---

### 7.4 Testing

**Tasks:**

- [ ] Write unit tests for services
- [ ] Add integration tests for endpoints
- [ ] Create widget tests for UI components
- [ ] Implement E2E tests for critical flows
- [ ] Add performance tests
- [ ] Create load tests
- [ ] Implement security tests
- [ ] Add regression tests

**Estimated Effort:** 3-4 weeks

---

### 7.5 Deployment

**Tasks:**

- [ ] Set up production server infrastructure
- [ ] Configure CI/CD pipeline
- [ ] Implement monitoring and logging
- [ ] Set up backup and recovery
- [ ] Configure CDN for images
- [ ] Set up SSL certificates
- [ ] Implement blue-green deployment
- [ ] Create deployment documentation

**Estimated Effort:** 2-3 weeks

---

## 📋 Feature Roadmap

### Immediate (Next 2-4 weeks)

1. **Push Notifications** - Keep users engaged
2. **User Profiles View** - Social discovery
3. **Search & Discovery** - Find content and people

### Short Term (1-2 months)

4. **Admin Dashboard** - Moderation tools
5. **Enhanced Notifications** - Better UX
6. **Performance Optimization** - Faster app

### Medium Term (2-4 months)

7. **Security Enhancements** - Safer platform
8. **Accessibility** - Inclusive design
9. **Testing** - Quality assurance

### Long Term (4-6 months)

10. **Deployment** - Production launch
11. **Marketing Features** - User growth
12. **Monetization** - Revenue streams

---

## 🎨 Design System

### Color Palette

**Primary Colors:**

- Purple: `#6C63FF`
- Pink: `#FF6584`
- Cyan: `#00D9FF`

**Duolingo Signature Colors:**

- Green: `#58CC02`
- Yellow: `#FFD93D`
- Red: `#FF4B4B`
- Orange: `#FF9600`

**Backgrounds:**

- Light: `#F7F9FC`
- Card: `#FFFFFF`

### Typography

- **Headers:** Poppins (Bold, 20-28px)
- **Body:** Rubik (Regular, 14-16px)
- **Buttons:** Rubik (Semi-Bold, 14-16px)

### Spacing

- Small: 8px
- Medium: 16px
- Large: 24px
- XLarge: 32px

### Border Radius

- Small: 8px
- Medium: 16px
- Large: 24px

### Animations

- Duration: 200-300ms
- Curve: easeInOut
- Stagger: 50ms per item

---

## 🔧 Technical Stack

### Backend

- **Framework:** Serverpod 3.2.3
- **Database:** PostgreSQL
- **Cache:** Redis
- **Auth:** Firebase Auth
- **Storage:** Local (VPS) / Backblaze B2 (future)

### Frontend

- **Framework:** Flutter 3.x
- **State Management:** Riverpod
- **Animations:** flutter_animate
- **Navigation:** go_router
- **Auth:** firebase_auth

### DevOps

- **Containerization:** Docker
- **CI/CD:** GitHub Actions (future)
- **Monitoring:** Sentry (future)
- **Analytics:** Firebase Analytics (future)

---

## 📝 Notes

- All phases 1-5 are complete with full Duolingo-inspired redesign
- App compiles successfully with no errors
- Real-time messaging working via WebSocket
- Gamification features (achievements, streaks) fully implemented
- Private chats and group chats fully functional
- Ready to move to Phase 6 (Advanced Features)

---

**Branch:** `v8`
**Last Updated:** February 11, 2026
