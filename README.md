# Talktive

Talktive is an anonymous group chat application designed for ephemeral, private, and random conversations.

## 🎨 Design Philosophy

**Duolingo-Inspired UI/UX**: The app features a clean, dynamic, and playful design inspired by Duolingo's aesthetic. Moving away from the previous glassmorphism design, Talktive now embraces:

- **Playful & Friendly**: Emoji-first design, rounded corners, vibrant colors
- **Gamified Experience**: Streaks, XP, levels, achievements, and celebrations
- **Clear Visual Hierarchy**: Bold typography, generous spacing, obvious CTAs
- **Micro-interactions**: Haptic feedback, smooth animations, satisfying transitions
- **Celebration-Driven**: Confetti animations and positive reinforcement

The onboarding wizard established these Duolingo-style patterns (vibrant colors, emoji-centric design, smooth animations, gamification elements), and this design language has been extended across the entire app including the bottom navigation and all five main screens: Plaza, Moments, Chats, Groups, and Profile.

## 🚀 Migration Status

**Current State:** Hybrid / Migration in Progress

We are currently migrating the application's backend from **Firebase** to **Serverpod** (Dart backend with Postgres & Redis).

The application currently supports a dual-boot mode via a `VersionSelector` screen on startup:

- **Firebase (Old):** The fully functional legacy version (Firestore/RTDB).
- **Serverpod (New):** The new backend using Serverpod + Postgres. **Crucially, it uses Firebase Authentication** to handle Google Sign-In, bridging the two worlds via Serverpod Auth Core (JWT/SAS tokens).

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
    flutter run
    ```
2.  On launch, you will see the **Start Screen**:
    - Tap **"Start"** to use the existing Firebase version.
    - Tap **"New safer version"** to preview the Serverpod integration.

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
