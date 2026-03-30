# Project Context for Assistants

This project is a migration of the "Talktive" chat app from Firebase to Serverpod. The application uses secure Google Sign-In and ensures user privacy via anonymous "personas" (Residents).

## 🏛️ The Apartment Building Metaphor

Talktive is modeled after a digital residence. UI terminology and structure mirror this space:

- **Plaza (Lobby)**: Public, real-time heart of the building.
- **Moments (Bulletin Board)**: Visual sharing feed.
- **Chats (Private Units)**: Intimate 1-on-1 conversations.
- **Lounges (Clubhouse)**: Semi-public, interest-based spaces.
- **Profile (My Unit)**: Personal identity and sanctuary.

## 🎭 Live Residence & Privacy Philosophy

- **"Live First"**: Outbound privacy toggles are removed. Everyone contributes to the building's live status (Online, Typing, Receipts) to ensure a vibrant community.
- **Inbound Gating**: Only **Talktive Plus** members can _see_ others' live indicators. Non-paying residents see a static view.
- **Universal Discovery**: All residents are searchable and discoverable by default.
- **Persona over Profile**: The system focuses on flexible personas rather than permanent handles to protect resident privacy.

## 🎨 Duolingo-Inspired UI/UX

The app uses a playful, high-energy aesthetic:

- **Visuals**: Primary purple (#6C63FF), emoji-first design, rounded corners, and vibrant colors.
- **Gamification**: Floor levels (1-50), XP, streaks, and achievements.
- **Design Patterns**: Distinction between immersive "Places" (`DuoPageScaffold`) and lightweight "Utilities" (`AppBar`).

## 🛠️ Development Philosophy

- **Service-Delegated Architecture**: Lean Endpoints delegating all domain logic, validation, and side-effects to Service classes.
- **Optimization Priority**: Optimized for a single VPS target (2 vCPU / 4GB RAM) supporting 10,000 users.
- **Technical Standards**: UUID-based user IDs, aggressive multi-tier caching (Redis), and background side-effect delegation.

## 📂 Core Documentation

- 📋 **[PRODUCT_STRATEGY.md](docs/PRODUCT_STRATEGY.md)**: Product vision, safety, and monetization.
- 🛠️ **[DEVELOPER_GUIDE.md](docs/DEVELOPER_GUIDE.md)**: Technical setup, architecture, and notifications.
- 📈 **[CHANGELOG.md](CHANGELOG.md)**: Historical development milestones and phase history.

## 🚀 Key Commands

- **Backend**: `cd talktive_server && docker compose up -d && dart bin/main.dart --apply-migrations`
- **Frontend**: `cd talktive_flutter && dart run build_runner build --delete-conflicting-outputs`
- **Sync**: `serverpod generate`
