# Talktive

Talktive is an anonymous group chat application designed for ephemeral, private, and random conversations.

## 🚀 Migration Status

**Current State:** Hybrid / Migration in Progress

We are currently migrating the application's backend from **Firebase** to **Serverpod** (Dart backend with Postgres & Redis).

The application currently supports a dual-boot mode via a `VersionSelector` screen on startup:
*   **Firebase (Old):** The fully functional legacy version.
*   **Serverpod (New):** The work-in-progress version using the new backend.

## 📂 Project Structure

*   **`talktive_flutter/`**: The main Flutter application. It contains both the legacy Firebase logic and the new Serverpod integration.
*   **`talktive_server/`**: The Serverpod backend implementation (Dart).
*   **`talktive_client/`**: The generated Dart client library for communicating with the Serverpod backend.


## 🛠️ Prerequisites

*   [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.10+)
*   [Docker Desktop](https://www.docker.com/products/docker-desktop) (Required for Serverpod's Postgres & Redis)
*   [Serverpod CLI](https://serverpod.dev/): `dart pub global activate serverpod_cli`
*   [Firebase CLI](https://firebase.google.com/docs/cli): `npm install -g firebase-tools`

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
    *The server listens on port `8080`.*

### 2. Start Firebase Emulators (Legacy)

1.  Navigate to the app directory:
    ```bash
    cd talktive_flutter
    ```
2.  Start the emulators:
    ```bash
    firebase emulators:start
    ```
    *Note: Firestore is configured to run on port `8088` to avoid conflicts with Serverpod.*

### 3. Run the App

1.  From the `talktive_flutter` directory:
    ```bash
    flutter run
    ```
2.  On launch, you will see the **Start Screen**:
    *   Tap **"Start"** to use the existing Firebase version.
    *   Tap **"New safer version"** to preview the Serverpod integration.

## 🏗️ Architecture Notes

*   **Dependency Injection**: The app uses a `ServiceLocator` combined with `Provider`.
*   **Disposal Safety**: Special care has been taken to ensure singleton services (`UserCache`, `PaginatedMessageService`, `Firestore`) are properly reset and disposed when switching between the two versions to prevent memory leaks and "used after dispose" errors.
*   **Ports**:
    *   Serverpod API: `8080`
    *   Firestore Emulator: `8088`
    *   Auth Emulator: `9099`
*   **Authentication**: The Serverpod backend now uses **UUIDs** for User IDs (Modern Serverpod Auth) which creates JWT tokens. The `Resident` table links to `AuthUser` via these UUIDs. Be careful when mapping legacy `int` IDs.

## 🤝 Contributing

When adding new features, please target the **Serverpod** implementation path. The Firebase path is in maintenance mode.
