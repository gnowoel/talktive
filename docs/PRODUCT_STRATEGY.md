# Talktive: Product Strategy & Architecture

## 🏛️ Core Philosophy: The Apartment Building Metaphor

Talktive is a digital residence where privacy and community coexist. Every UI decision is guided by this metaphor:

- **Plaza (Lobby)**: Public, bustling, and open. The building's social heart.
- **Moments (Bulletin Board)**: Visual, community-driven, and shared snapshots.
- **Chats (Private Units)**: Intimate, secure, and personal 1-on-1 spaces.
- **Lounges (Clubhouse)**: Semi-public, interest-based community spaces.
- **Profile (My Unit)**: Personal identity, sanctuary, and achievements.

---

## 🎭 Live & Transparent Discovery

Talktive follows a **"Live First"** philosophy to ensure the building feels vibrant and provides maximum value to paid users:

- **Universal Visibility**: Outbound privacy toggles (hiding your own status) are removed. Every resident contributes to the "Live" feel of the building.
- **Universal Discovery**: All residents are searchable and discoverable by default to encourage community engagement.
- **Inbound Premium Controls**: While visibility is universal, **Talktive Plus** members have the exclusive ability to control their _own_ view of the building (e.g., toggling their visibility of others' online status, read receipts, and typing indicators).

---

## 🛡️ Safety & Moderation (The Floor System)

### 1. Hybrid Floor Formula

`EffectiveFloor = min(BaseFloor, TrustTier)`

- **Base Floor**: Earned via XP/Leveling curve (`floor(sqrt(xp / 50)) + 1`).
- **Trust Tier**: Based on community Trust Score (-30 for reports, +10 for likes).
- **Impact**: Determines access to features like posting Moments or media.

### 2. Doorbell & Peephole System

To protect personal units, strangers must "Knock" and be accepted via the "Peephole" (profile preview) before sending private messages.

### 3. Community Moderation

- **One-Vote Rule**: Residents can like/report a unique target only once.
- **Staff Roles**: Tiered moderation (Admins & Moderators) with powers to mute, suspend, and manage lounges.
- **Administrative Transparency**: All staff actions are logged for accountability.

---

## 🎮 Gamification & Engagement

- **XP Awards**: Earned through messaging, posting moments, and daily logins.
- **Streaks**: Tracking daily commitment with visual rewards and XP bonuses.
- **Interest Taxonomy**: Centralized interest system used for personalized discovery and profile badges.
- **Achievements**: Unlockable badges for platform milestones (e.g., "Social Butterfly").

---

## 💰 Monetization: Talktive Plus

Talktive uses a balanced strategy that provides value to supporters while keeping the core experience free.

### 1. Premium Benefits (Talktive Plus)

| Feature               | Icon | Description                               | Requirement        |
| :-------------------- | :--: | :---------------------------------------- | :----------------- |
| **No Ads**            |  🚫  | Ad-free experience during navigation.     | **Paid Plus Only** |
| **Custom Avatar**     |  🖼️  | Upload custom images for your persona.    | Plus (Trial/Paid)  |
| **Voice Messages**    |  🎙️  | Record and send audio in any chat.        | Plus (Trial/Paid)  |
| **Advanced Search**   |  🔍  | Filter neighbors and lounges by criteria. | Plus (Trial/Paid)  |
| **Online Indicator**  |  🟢  | See real-time activity status of others.  | Plus (Trial/Paid)  |
| **Read Receipts**     |  ✔️  | See when neighbors read your messages.    | Plus (Trial/Paid)  |
| **Typing Indicators** |  ✍️  | See real-time reply status.               | Plus (Trial/Paid)  |
| **Chat Persistence**  |  🕒  | Keep private chats past 30-day cleanup.   | Plus (Trial/Paid)  |

---

## 🚀 Runtime Configuration

The app uses a centralized `AppConfig` to manage environment settings:

- **Automatic Selection**: Debug builds default to local dev endpoints; release builds use production URLs from `assets/config.json`.
- **Overrides**: Use `--dart-define=SERVERPOD_URL=...` to override at build time.
- **Emulators**: Firebase Emulator Suite is automatically enabled in debug mode for Auth and Storage.

### 2. Premium Trials

- **24-Hour Trial**: Residents can periodically explore all Plus features for free.
- **Ad-Supported**: Interstitial ads remain active during the trial to support the community.

### 3. Interstitial Ads

- **Exit-Driven**: Displayed at natural transition points (e.g., exiting a chat thread).
- **Capped frequency**: Mandatory 2-minute cooldown between ads to preserve the atmosphere.

---

## 📊 Performance & Scalability

- **Single VPS Target**: Optimized to support 10,000 active users on 2 vCPUs / 4GB RAM.
- **Aggressive Caching**: Multi-tier strategy (Local -> Redis -> Database).
- **Denormalization**: High-frequency data (names, avatars) stored directly on message protocols.
- **Content Ephemerality**: Tiered lifespan (Plaza: 24h, Lounges: 14d, Private: 30d, Moments: 7d).
