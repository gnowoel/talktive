# Talktive Codebase Structure

## Overview

The Talktive Flutter app has been migrated from a Firebase-based architecture to a Serverpod-based one. During the final stages of migration, the codebase maintains a strict separation between the new modern implementation and the legacy code.

1. **Modern Version** (Current) - Uses Serverpod + Riverpod + Duolingo-inspired UI.
2. **Legacy Version** (Maintenance) - Original Firebase + Provider implementation, now consolidated for eventual removal.

---

## Directory Structure

```
talktive_flutter/lib/
├── main.dart                      # [SHARED] Entry point & Global Client Init
├── version_selector.dart          # [SHARED] Dual-boot selector UI
├── serverpod_app.dart             # [MODERN] Serverpod app entry & Riverpod Root
├── serverpod_client.dart          # [MODERN] Serverpod client configuration
├── app.dart                       # [LEGACY] Firebase app entry
├── config/                        # [MODERN] Modern configuration (Theme, etc.)
├── providers/                     # [MODERN] Riverpod providers (State Management)
├── screens/                       # [MODERN] Feature-based UI screens
├── services/                      # [MODERN] Modern services (Media, Messaging)
├── widgets/                       # [MODERN] Modern component library (Duo widgets)
├── helpers/                       # [MODERN] Modern utility functions
├── utils/                         # [MODERN] Core utilities and formulas
└── legacy/                        # [LEGACY] Consolidated Firebase implementation
    ├── pages/                     # Old Firebase pages
    ├── models/                    # Old Data models (replaced by talktive_client)
    ├── services/                  # Old Firebase services (Firestore, Auth, etc.)
    ├── widgets/                   # Old UI components
    ├── wrappers/                  # Old initialization wrappers
    ├── helpers/                   # Old utility functions
    ├── router.dart                # Old GoRouter configuration
    └── theme.dart                 # Old legacy theme
```

---

## Architecture Components

### 🟢 Modern Implementation (Serverpod)

**Core Logic:**
- `serverpod_client.dart`: Manages the connection to the Serverpod backend.
- `providers/`: Reactive state management using Riverpod.
- `talktive_client`: Generated code from the Serverpod protocol (replaces manual models).

**UI & Experience:**
- `screens/`: Organized by feature (lounges, plaza, moments, profile).
- `widgets/duo/`: A comprehensive library of "Duolingo-styled" playful components.
- `wrappers/serverpod_initialize.dart`: Lean initialization specifically for the Serverpod path.

**Services:**
- `services/messaging.dart`: Unified FCM handler (handles both versions).
- `services/media_service.dart`: Image picking and Firebase Storage uploads (shared).
- `services/edge_to_edge_manager.dart`: Modern Android/iOS system UI management.

### 🔴 Legacy Implementation (Firebase)

All legacy code has been moved to the `lib/legacy/` directory to decouple it from the modern development path. This includes:
- **Services**: `Firestore`, `Fireauth`, `Firedata`, `ServiceLocator`, and `ErrorRecovery`.
- **Pages**: All original `*.dart` files from the former `lib/pages/` directory.
- **Models**: Manual JSON models (`User`, `Topic`, `Message`, etc.).
- **Wrappers**: Complex multi-layer initialization (`VerifyUser`, `Setup`, `CurrentUser`).

---

## Development Guidelines

### 1. Working with Data
Never create manual models in `lib/models/` (this directory has been removed). All data structures should be defined in the Serverpod protocol (`talktive_server/lib/src/protocol`) and generated into `talktive_client`.

### 2. State Management
Use Riverpod for all new features. Avoid using the legacy `ServiceLocator` or `Provider` (package:provider) unless maintaining legacy pages.

### 3. UI Standards
Follow the Duolingo-inspired design language. Use components from `lib/widgets/duo/` (DuoButton, DuoCard, DuoInput, etc.) to ensure visual consistency across the app.

### 4. Performance & Cleanliness
- **Parallelize Queries**: Use `Future.wait` in Serverpod endpoints and Flutter providers.
- **Batch Operations**: Prefer batch fetching (e.g., `_getBatchUserCounts` in AdminEndpoint) to avoid N+1 query problems.
- **Pruning**: When a legacy feature is fully replaced by a Serverpod equivalent, its corresponding files in `lib/legacy/` should be evaluated for deletion.

---

## Migration Status (March 2026)

The migration is in **Phase 8 (Polish & Refinement)**.
- The Serverpod version is the primary development target.
- The Firebase version is kept for reference and safety during transition.
- The codebase is "Legacy-Isolated," meaning the modern path is not dependent on legacy services (except for shared FCM/Media logic).
