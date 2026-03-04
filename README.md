# Talktive: Anonymous Chat

Talktive is a private and group chat application where users log in securely via Google but interact using custom, anonymous personas designed for privacy and authentic conversations.

## 🎯 Purpose

We built the **Talktive: Anonymous Chat** app for lonely modern people, especially young adults living in cities. They may not have many friends in real life, they crave communication, but they also value privacy and security.

Our goal is to provide a convenient, fun, and safe chat environment. We don't use AI; everyone you meet is a real person. 

Unlike traditional chat applications or social networking sites, chatting here is stress-free. Nobody knows who you are, we don't keep records, you can come and go as you please, and you don't need to care about others' opinions. Of course, if you repeatedly send inappropriate messages or harass others, our safety system will mute or suspend your account based on your Trust Score.

## 🎨 Design Philosophy

**The Apartment Building Metaphor**: Talktive is modeled after a digital apartment building housing single men and women looking to make connections. The app's structure mirrors this physical space:

- **Plaza (Lobby)**: A public space for casual, open encounters.
- **Moments (Bulletin Board)**: A place to showcase yourself and see what others are up to.
- **Chats (Private Units)**: Intimate, 1-on-1 private spaces with old friends.
- **Groups (Clubhouse)**: Semi-public spaces for community discussions and shared interests.
- **Profile (My Unit)**: Your personal space to showcase your personality (Interests, Languages, Achievements).

**Duolingo-Inspired UI/UX**: The app features a clean, dynamic, and playful design inspired by Duolingo's aesthetic. Moving away from the previous glassmorphism design, Talktive now embraces:

- **Playful & Friendly**: Emoji-first design, rounded corners, vibrant colors
- **Gamified Experience**: Streaks, XP, levels, achievements, and celebrations
- **Clear Visual Hierarchy**: Bold typography, generous spacing, obvious CTAs
- **Micro-interactions**: Haptic feedback, smooth animations, satisfying transitions
- **Celebration-Driven**: Confetti animations and positive reinforcement

The onboarding wizard established these Duolingo-style patterns (vibrant colors, emoji-centric design, smooth animations, gamification elements), and this design language has been extended across the entire app including the bottom navigation and all five main screens: Plaza, Moments, Chats, Groups, and Profile.

## 🚀 Project Status

**Current State:** ✅ Production Ready (10/10)

The application has been successfully migrated from **Firebase** to **Serverpod** with all essential features implemented and optimized for production launch.

### Key Features

**Core Functionality:**

- ✅ Duolingo-inspired UI/UX with gamification
- ✅ Private 1-on-1 messaging
- ✅ Group chats with member management
- ✅ Moments (photo feed) with likes and comments
- ✅ Achievements system (16 achievements)
- ✅ Daily streaks and rewards
- ✅ Push notifications (FCM)
- ✅ User profiles with stats and interests
- ✅ Interest-based user discovery
- ✅ Search & Discovery functionality
- ✅ Admin Dashboard with moderation tools
- ✅ **Privacy-First Data Collection:** Google Sign-In is strictly limited to authentication (OpenID scope). The backend automatically anonymizes the user by dropping real names, assigning placeholder emails (`anon-uuid@anonymous.talktive.com`), and refusing to fetch Google avatars. All avatars natively support image URLs for future expansion but exclusively enforce selected Emojis currently.

**Safety & Performance:**

- ✅ Image upload validation (magic bytes, size, dimensions)
- ✅ Input validation across all endpoints
- ✅ Centralized error handling
- ✅ Content filtering (profanity, spam)
- ✅ Trust Score system for abuse resilience (-30 reports, +10 vouches)
- ✅ Luxury High-Rise gamification (Exponential Base Floors up to Floor 50)
- ✅ Keycard Effective Floor Caps (Mutes/Limits based on Trust Score Tier)
- ✅ One-Vote Rule & Daily Report Caps (Anti-targeting abuse prevention)
- ✅ Rate limiting with Redis
- ✅ Community-driven moderation
- ✅ Data archival for cost optimization
- ✅ N+1 query optimization
- ✅ Batch endpoints for efficiency

**Cost Optimization:**

- Estimated monthly cost: $5-40 (VPS, database, Redis)
- Firebase FCM: FREE
- No ML services required
- Community-driven moderation
- Automatic data archival

### Documentation

- **[CHANGELOG.md](CHANGELOG.md)** - Development history and milestones
- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Production deployment guide
- **[GEMINI.md](GEMINI.md)** - Project context for AI assistants
- **[docs/LAUNCH_IMPROVEMENTS.md](docs/LAUNCH_IMPROVEMENTS.md)** - Latest production improvements
- **[docs/SERVERPOD_REVIEW.md](docs/SERVERPOD_REVIEW.md)** - Production readiness review
- **[docs/CODEBASE_STRUCTURE.md](docs/CODEBASE_STRUCTURE.md)** - Code organization
- **[docs/NOTIFICATION_ARCHITECTURE.md](docs/NOTIFICATION_ARCHITECTURE.md)** - Notification system design

## 📂 Project Structure

- **`talktive_flutter/`**: The main Flutter application. It contains both the legacy Firebase logic and the new Serverpod integration.
- **`talktive_server/`**: The Serverpod backend implementation (Dart).
- **`talktive_client/`**: The generated Dart client library for communicating with the Serverpod backend.

## 🛠️ Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.10+)
- [Docker Desktop](https://www.docker.com/products/docker-desktop) (Required for Serverpod's Postgres & Redis)
- [Serverpod CLI](https://serverpod.dev/): `dart pub global activate serverpod_cli`
- [Firebase CLI](https://firebase.google.com/docs/cli): `npm install -g firebase-tools`

## 🏁 Getting Started

To run the application locally with full functionality, you need to start both the Serverpod backend and the Firebase Emulators.

### 1. Start Serverpod Backend (New)

1.  Navigate to the server directory:
    ```bash
    cd talktive_server
    ```
2.  Start the database containers (Postgres & Redis):
    ```bash
    docker compose up --build --detach
    ```
3.  Start the server (applying migrations):
    ```bash
    dart run bin/main.dart --apply-migrations
    ```
    _The server listens on port `8080`._

### 2. Start Firebase Emulators (Legacy + Auth)

Even for the new Serverpod version, we use **Firebase Authentication**.

1.  Navigate to the app directory:
    ```bash
    cd talktive_flutter
    ```
2.  Start the emulators:
    ```bash
    firebase emulators:start
    ```
    _Note: Firestore is configured to run on port `8088` to avoid conflicts with Serverpod._

### 3. Run the App

1.  From the `talktive_flutter` directory:
    ```bash
    flutter run -d web-server --web-port 8083 --web-hostname=localhost
    ```
    > **⚠️ IMPORTANT FOR GOOGLE SIGN-IN**
    > Only `localhost:8083` is registered with Google Cloud OAuth. You must explicitly start the server using `--web-hostname=localhost` and access it via `http://localhost:8083`. Do not use `127.0.0.1`, otherwise Google Sign-In will fail with origin errors.

2.  On launch, you will see the **Start Screen**:
    - Tap **"Start"** to use the existing Firebase version.
    - Tap **"New safer version"** to preview the Serverpod integration.
    
    > **⚠️ IMPORTANT FOR TESTING**
    > We run the old Firebase version along with the new Serverpod version. For testing the new Serverpod version, please tap **"New safer version"** instead of "Start" on app start.

## 🧠 Development Philosophy

**Underlying Structural Changes Over Quick Patches**: To ensure the codebase remains simple and robust, we consistently prioritize making deep structural or database-level optimizations rather than relying on brittle surface-level UI patches or workarounds.

## 🏗️ Architecture Notes

- **Dependency Injection**: The app uses a `ServiceLocator` combined with `Provider`.
- **Disposal Safety**: Special care has been taken to ensure singleton services (`UserCache`, `PaginatedMessageService`, `Firestore`) are properly reset and disposed when switching between the two versions to prevent memory leaks and "used after dispose" errors.
- **Ports**:
  - Serverpod API: `8080`
  - Firestore Emulator: `8088`
  - Auth Emulator: `9099`
- **Authentication**: The Serverpod backend uses **UUIDs** for User IDs (Serverpod Auth Core). The `Resident` table links to `AuthUser` via these UUIDs. Firebase ID tokens are exchanged for Serverpod Auth Core sessions (JWT/SAS). Be careful when mapping legacy `int` IDs.

## 🤝 Contributing

When adding new features, please target the **Serverpod** implementation path. The Firebase path is in maintenance mode.
