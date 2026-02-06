# Talktive Project Context

## Overview

Talktive is an anonymous group chat application designed for ephemeral, private, and random conversations. It allows users to join chat rooms without login, ensuring privacy and anonymity.

### Tech Stack

*   **Frontend:** Flutter (Dart)
*   **Backend:** Firebase (Cloud Functions, Firestore, Realtime Database, Storage, Authentication)
*   **Language (Backend):** TypeScript (Node.js)
*   **Language (Frontend):** Dart

## Architecture

### Frontend (Flutter)

*   **Entry Point:** `lib/main.dart` initializes Firebase and runs the app.
*   **App Structure:** `lib/app.dart` sets up the provider chain (`Initialize`, `Providers`, `VerifyUser`, etc.) and the `MaterialApp` with `go_router`.
*   **Navigation:** Managed by `go_router` defined in `lib/router.dart`. It uses `StatefulShellRoute` for the main tab navigation (`/users`, `/topics`, `/chats`, `/friends`, `/profile`).
*   **State Management:** Uses `provider` package.
*   **Services:** Backend interactions are encapsulated in `lib/services/`.
    *   `Firestore`: Handles Firestore data fetching, caching (manual implementation), and subscription management.
    *   `Messaging`: Handles Firebase Cloud Messaging.
*   **Models:** Data models are located in `lib/models/` (e.g., `User`, `Chat`, `Topic`). They are typically immutable classes with `toJson` and factory constructors like `fromJson` or `fromStub`.

### Backend (Firebase Functions)

*   **Location:** `functions/` directory.
*   **Entry Point:** `functions/src/index.ts` exports individual functions.
*   **Logic:**
    *   **Triggers:** Background functions triggered by Firestore events (e.g., `onUserRegistered`, `onMessageCreated`).
    *   **Callables:** HTTPS callable functions for direct client interactions (e.g., `createTopic`, `joinTopic`, `follow`).

## Building and Running

### Prerequisites

*   Flutter SDK (`>=3.3.4 <4.0.0`)
*   Firebase CLI
*   Node.js (v20 for Functions)

### Local Development (Emulators)

The project is configured to use Firebase Emulators by default (`useEmulators = true` in `lib/app.dart`).

1.  **Start Backend (Emulators):**
    ```bash
    # In the functions/ directory
    npm run build:watch  # Watch and compile TypeScript
    
    # In the project root
    firebase emulators:start
    ```

2.  **Start Frontend (Flutter):**
    ```bash
    flutter run
    ```

### Production Build

*   **Deploy Functions:**
    ```bash
    firebase deploy --only functions
    ```
*   **Deploy Rules:**
    ```bash
    firebase deploy --only database,firestore,storage
    ```
*   **Build Web:**
    ```bash
    flutter build web
    ```

## Development Conventions

*   **Data Access:** Do not access Firebase directly in UI widgets. Use the specialized service classes in `lib/services/`.
*   **Caching:** The `Firestore` service implements manual caching strategies (e.g., `_cachedUsers`, `_userCache`). Be mindful of stale data and cache invalidation logic when modifying data fetching.
*   **Navigation:** Use `context.go()` or `context.push()` matching the routes defined in `lib/router.dart`.
*   **Formatting/Linting:**
    *   **Dart:** Follows `flutter_lints`. Run `flutter analyze`.
    *   **TypeScript:** Follows `eslint`. Run `npm run lint` in `functions/`.
*   **Emulators:** Always verify changes using the local emulator suite to avoid affecting production data.

## Key Files

*   `lib/main.dart`: App entry point.
*   `lib/app.dart`: Root widget and provider setup.
*   `lib/router.dart`: Navigation configuration.
*   `lib/services/firestore.dart`: Core service for database interactions.
*   `functions/src/index.ts`: Cloud Functions entry point.
*   `firebase.json`: Firebase configuration (implied).
*   `firestore.rules`: Firestore security rules.
