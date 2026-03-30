# Talktive: Anonymous Chat

Talktive is a private and lounge chat application where users log in securely via Google but interact using custom, anonymous personas designed for privacy and authentic conversations.

## 🏛️ The Apartment Building Metaphor

Talktive is modeled after a digital residence. The app's structure mirrors this physical space:

- **Plaza (Lobby)**: A public space for casual, open encounters.
- **Moments (Bulletin Board)**: Visual sharing and community updates.
- **Chats (Private Units)**: Intimate, 1-on-1 private spaces.
- **Lounges (Clubhouse)**: Semi-public, interest-based community spaces.
- **Profile (My Unit)**: Your personal identity and achievements.

---

## 🎨 Design Philosophy

**Persona over Profile**: Talktive focuses on the **persona, not the profile**. The system protects the anonymous soul of the app by eschewing unique handles in favor of flexible personas.

**Duolingo-Inspired UI/UX**: A playful, high-energy aesthetic that makes interaction feel like a game.

- **Playful & Friendly**: Emoji-first design and vibrant colors.
- **Gamified Experience**: Streaks, XP, and level-up celebrations.
- **Micro-interactions**: Haptic feedback and smooth animations.

**"Live First" Philosophy**: Outbound privacy is removed to ensure a vibrant community. All residents contribute to the building's live status, while Talktive Plus members enjoy exclusive control over their own view of the building.

---

## 🚀 Project Status: Production Ready

The application is fully migrated from **Firebase** to **Serverpod** and optimized for a 10,000-user launch.

### Documentation

- 📋 **[PRODUCT_STRATEGY.md](docs/PRODUCT_STRATEGY.md)** - Vision, monetization, and safety spec.
- 🎨 **[DESIGN_SYSTEM.md](docs/DESIGN_SYSTEM.md)** - Visual identity and UI/UX patterns.
- 🛠️ **[DEVELOPER_GUIDE.md](docs/DEVELOPER_GUIDE.md)** - Technical setup and architecture.
- 🚀 **[DEPLOYMENT.md](DEPLOYMENT.md)** - Production deployment guide.
- 📈 **[CHANGELOG.md](CHANGELOG.md)** - Historical development milestones.

---

## 📂 Project Structure

- **`talktive_flutter/`**: The main Flutter application (Riverpod + Duo UI).
- **`talktive_server/`**: The Serverpod backend implementation (Dart + Postgres).
- **`talktive_client/`**: The generated Dart client library.

## 🏁 Getting Started (Local Dev)

1.  **Server**: `cd talktive_server`, `docker compose up -d`, `dart run bin/main.dart --apply-migrations`.
2.  **Emulators**: `cd talktive_flutter`, `firebase emulators:start` (for Auth).
3.  **App**: `flutter run -d web-server --web-port 8083 --web-hostname=localhost`.

_See [DEVELOPER_GUIDE.md](docs/DEVELOPER_GUIDE.md) for detailed instructions._
