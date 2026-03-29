# Talktive: Anonymous Chat

Talktive is a private and lounge chat application where users log in securely via Google but interact using custom, anonymous personas designed for privacy and authentic conversations.

## 🎯 Purpose

We built the **Talktive: Anonymous Chat** app for lonely modern people, especially young adults living in cities. They may not have many friends in real life, they crave communication, but they also value privacy and security.

Our goal is to provide a convenient, fun, and safe chat environment. We don't use AI; everyone you meet is a real person. 

Unlike traditional chat applications or social networking sites, chatting here is stress-free. Nobody knows who you are, we don't keep records, you can come and go as you please, and you don't need to care about others' opinions. Of course, if you repeatedly send inappropriate messages or harass others, our safety system will mute or suspend your account based on your Trust Score.

## 🎨 Design Philosophy

**Persona over Profile**: Talktive is unique because it's about the **persona, not the profile**. The system protects the ephemeral and anonymous soul of the app by eschewing unique handles (which stick like serial numbers) in favor of flexible personas. If a resident wants to be "Leo" today in the Basketball Club and "Quiet Reader" tomorrow in the Library Lounge, they can.

**The Apartment Building Metaphor**: Talktive is modeled after a digital apartment building housing single men and women looking to make connections. The app's structure mirrors this physical space:

- **Plaza (Lobby)**: A public space for casual, open encounters.
- **Moments (Bulletin Board)**: A place to showcase yourself and see what others are up to.
- **Chats (Private Units)**: Intimate, 1-on-1 private spaces with old friends.
- **Lounges (Clubhouse)**: Semi-public spaces for community discussions and shared interests.
- **Profile (My Unit)**: Your personal space to showcase your personality (Interests, Languages, Achievements).

**Duolingo-Inspired UI/UX**: The app features a clean, dynamic, and playful design inspired by Duolingo's aesthetic. Moving away from the previous glassmorphism design, Talktive now embraces:

- **Playful & Friendly**: Emoji-first design, rounded corners, vibrant colors
- **Gamified Experience**: Streaks, XP, levels, achievements, and celebrations
- **Clear Visual Hierarchy**: Bold typography, generous spacing, obvious CTAs
- **Micro-interactions**: Haptic feedback, smooth animations, satisfying transitions
- **Celebration-Driven**: Confetti animations and positive reinforcement

**The "Ephemeral First" Philosophy**: Talktive prioritizes the "now" over the "archive". Shared moments are snapshots to be experienced in the feed, not searched or archived centrally. This protects resident privacy and ensures the building feels alive with current activity rather than stale records.

The onboarding wizard established these Duolingo-style patterns (vibrant colors, emoji-centric design, smooth animations, gamification elements), and this design language has been extended across the entire app including the bottom navigation and all five main screens: Plaza, Moments, Chats, Lounges, and Profile.

## 🚀 Project Status

**Current State:** ✅ Production Ready (10/10)

The application has been successfully migrated from **Firebase** to **Serverpod** with all essential features implemented and optimized for production launch.

### Key Features

**Core Functionality:**
- 🏰 **Apartment Metaphor**: Navigate the building from the Plaza (Lobby) to your Profile (My Unit).
- 🎨 **Duolingo UI**: Clean, playful, and high-contrast design using the `Duo` component library.
- 📬 **Secure Messaging**: 1-on-1 chats with a privacy-first "Doorbell" invite system.
- 📸 **Moments**: A localized photo feed for residents to share snapshots and earn XP.
- 🛋️ **Lounges**: Join or create interest-based communities with admin approval flows.
- 💎 **Gamified Socials**: Streaks, achievements, and level-up celebrations (Floor 1 to 50).

**Safety & Safety Engineering:**
- 🛡️ **Peephole Privacy**: Inspect stranger profiles before accepting private chat invites.
- ⚖️ **Hybrid Floor System**: Access restricted by both reputation (Trust Score) and experience.
- 👮 **Community Moderation**: Floor level-gated reporting with daily caps and anti-targeting rules.
- 🧹 **Data Integrity**: Automatic archival of old data and centralized input validation.

**Cost Optimization:**

- Estimated monthly cost: $5-40 (VPS, database, Redis)
- Firebase FCM: FREE
- No ML services required
- Community-driven moderation
- Automatic data archival

### Documentation
- 📜 **[docs/DESIGN_SYSTEM.md](docs/DESIGN_SYSTEM.md)** - Visual identity, typography, and structural patterns.
- 📜 **[docs/PRODUCT_SPECS.md](docs/PRODUCT_SPECS.md)** - Full feature spec and architecture overview.
- 📈 **[CHANGELOG.md](CHANGELOG.md)** - Historical development milestones and phase history.
- 🚀 **[DEPLOYMENT.md](DEPLOYMENT.md)** - Production and development deployment guide.
- 🧠 **[GEMINI.md](GEMINI.md)** - Persistent context and roadmap for AI assistants.
- 🌐 **[docs/NOTIFICATION_ARCHITECTURE.md](docs/NOTIFICATION_ARCHITECTURE.md)** - Deep dive into FCM and Serverpod notifications.
- 🏗️ **[docs/CODEBASE_STRUCTURE.md](docs/CODEBASE_STRUCTURE.md)** - Technical directory and logic organization.

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

2.  On launch, established users with persistent Google Sign-In will automatically skip the choice and enter the **Serverpod** version. First-time or signed-out users will see the **Start Screen**:
    - Tap **"New safer version"** to access the Serverpod integration.
    - Tap **"Start"** for the legacy Firebase path.
    
    > **⚠️ SEAMLESS DISCOVERY**
    > Returning residents are automatically logged into the Serverpod backend. For testing the legacy version while signed in, a "Switch App Version" option should be added to settings or the cache cleared via a sign-out event.

### Environment Behavior

- **Debug builds** default to local development services:
  - Serverpod: `http://localhost:8080` on Web, `http://10.0.2.2:8080` on Android emulator
  - Firebase Emulator Suite: enabled by default
- **Release builds** default to the production Serverpod API URL from `talktive_flutter/assets/config.json`
- You can override either behavior at build/run time with Dart defines:
  - `--dart-define=SERVERPOD_URL=https://api.talktive.app`
  - `--dart-define=USE_FIREBASE_EMULATORS=false`

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
