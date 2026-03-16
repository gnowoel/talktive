# Talktive Product Specifications & Architecture

## Core Concept: The Apartment Building
Talktive is a digital apartment building where privacy and community coexist. Users are **Residents** with anonymous personas.

### Main Areas (Lobby Layout)
- **Plaza (Lobby)**: Public, real-time global chat. Highly moderated.
- **Moments (Bulletin Board)**: Visual social feed for photo sharing.
- **Chats (Private Units)**: Secure 1-on-1 conversations with "Doorbell" safety.
- **Groups (Clubhouse)**: Community-managed interest hubs.
- **Profile (My Unit)**: Personal identity, stats, and achievements.

---

## 🏗️ Technical Architecture

### Backend: Serverpod 3.4.2
- **Database**: PostgreSQL with UUID identification. Fully migrated from legacy integer IDs.
- **Caching**: Redis for rate limiting and temporary session storage.
- **Authentication**: Firebase Auth (Google) linked to Serverpod Auth Core via `firebaseIdp`.
- **Media**: Direct client-side uploads to Firebase Storage for high performance.

### Frontend: Flutter (Standardized Duo UI)
- **Aesthetic**: Duolingo-inspired playfulness (vibrant colors, rounded corners, emoji-first).
- **State Management**: Riverpod (Reactive providers for all domains).
- **Navigation**: Pill-shaped bottom bar with high-rise immersive transitions.
- **Components**: `DuoButton`, `DuoAvatar`, `DuoCard`, `DuoInput`, `DuoFloorRequirementDialog` - shared visual language.

---

## 🛡️ Safety & Moderation (The Floor System)

### Hybrid Floor Formula
`EffectiveFloor = min(BaseFloor, TrustTier)`
- **Base Floor**: Generated via XP/Leveling curve (`floor(sqrt(xp) / 7.07)`).
- **Trust Tier**: Based on global Trust Score (-30 for reports, +10 for vouches/likes).
- **Impact**: Effective floor determines access to premium features (e.g., posting Moments).

### One-Vote Rule & Abuse Prevention
- Users can Like/Report a unique target only **once**.
- Daily report caps (3 per day) to prevent targeting.
- **Doorbell System**: strangers must "Knock" and be accepted via the "Peephole" before sending messages.
- **Privacy Hardening**: Blocking a user immediately restricts their ability to send private messages or trigger notifications, even in existing threads.

### 🛡️ Advanced Moderation (The Admin Role)
- **Moderation Powers**: Admins can manually mute users (temporary), suspend accounts (permanent), and disband inappropriate groups.
- **Administrative Transparency**: All admin actions are logged to the platform logs with reasons for accountability.
- **Group Governance**: Admins can force public groups to become private if they are found to be niche or borderline inappropriate, maintaining the public "Plaza" safety.
- **Report Resolution**: Admins review and resolve reports from the community, with the ability to reset trustScores upon successful appeals.

---

## 🎮 Gamification & Engagement

### XP & Levels
- **XP Awards**: Messaging (+10), Posting Moments (+50), Social Likes (+20).
- **Streaks**: Daily activity tracking with visual rewards.
- **Achievements**: batch-tracked milestones (e.g., "Social Butterfly", "High-Rise Resident").

### Interest Taxonomy
- Centralized `AppInterests` system for both users and groups.
- Personalized discovery ranking based on shared interest overlap.

---

## 📊 Performance & Scalability
- **N+1 Query Resolution**: Batch endpoints for feeds and membership lists.
- **Denormalization**: `senderName`, `avatar`, and `floor` stored directly on protocols for zero-join reads.
- **Data Archival**: Automatic background cleanup of old messages/notifications to maintain DB performance.
- **Input Validation**: Centralized `InputValidationService` applied to all data-modifying endpoints.
