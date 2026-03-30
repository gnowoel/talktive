# Talktive Settings & Configuration System

This document explains how user preferences, premium features, and runtime environments are managed in Talktive.

---

## 🛠️ User Settings (The Settings Screen)

The **Settings Screen** is located in the **Activity** hub (accessed via the settings gear ⚙️ icon in the top header). It follows a **"Benefit Visibility"** design philosophy—making premium features visible to all users to showcase value, while restricting activation to **Talktive Plus** members.

### 1. Talktive Plus & Trial Toggles
Talktive uses a simplified subscription model. Features are either available to all or gated behind a **Plus** status.

- **Plus Status**: Includes both paid subscribers (`isPremium = true`) and active trial users (`isTrialActive = true`).
- **Trial System**: New residents can activate a **24-hour Premium Trial** once. This unlocks all software-gated features (Voice, Search, etc.).
- **Visual Gating**: For free users, premium feature rows are displayed with a "Lock" icon. Tapping them triggers an upgrade prompt (`DuoUpgradePrompt`).

### 2. Available Feature Toggles
| Feature | Icon | Description | Requirement |
|:---|:---:|:---|:---|
| **No Ads** | 🚫 | Ad-free experience during navigation. | **Paid Plus Only** |
| **Custom Avatar** | 🖼️ | Upload custom images for your persona. | Talktive Plus (Trial/Paid) |
| **Voice Messages** | 🎙️ | Record and send audio in any chat. | Talktive Plus (Trial/Paid) |
| **Advanced Search** | 🔍 | Filter neighbors and lounges by criteria. | Talktive Plus (Trial/Paid) |
| **Online Indicator** | 🟢 | See real-time activity status of others. | Talktive Plus (Trial/Paid) |
| **Read Receipts** | ✔️ | See when neighbors read your messages. | Talktive Plus (Trial/Paid) |
| **Typing Indicators** | ✍️ | See real-time reply status. | Talktive Plus (Trial/Paid) |
| **Chat Persistence** | 🕒 | Keep private chats past 30-day cleanup. | Talktive Plus (Trial/Paid) |

> [!NOTE]
> **Ad Persistence**: While trials unlock all functional features, interstitial ads remain active during trials. Only a verified **Paid Plus** subscription removes all advertisements.

---

## 🛡️ Privacy & Safety Control

Talktive prioritizes resident privacy over persistent profiles.

- **Privacy as a Right**: Tools for **Blocking** and **Reporting** are always free and accessible on every profile view.
- **Simplified UI**: Previous separate "Privacy" sections have been consolidated into the Feature Toggles listed above.
- **Backend Defaults**: For premium tiers, privacy-enhancing indicators (Online Status, Read Receipts) default to `true` to ensure immediate utility upon subscription.

---

## 🚀 Runtime Configuration (`AppConfig`)

Developers and production environments use `AppConfig` to manage connection settings without re-compiling the app.

### 1. Environment Selection
The app determines its backend URL based on a priority list:
1. **Environment Variables**: Passing `--dart-define=SERVERPOD_URL=https://...` at build time.
2. **Local Debug Mode**: If running in debug, it defaults to `localhost:8080` (Web) or `10.0.2.2:8080` (Android Emulator).
3. **Asset Configuration**: Reads `assets/config.json` for the `apiUrl` field (used for release builds).

### 2. Firebase Emulators
- **`USE_FIREBASE_EMULATORS`**: Defaults to `true` in debug mode.
- Shuts off production Firebase Auth/Analytics and routes traffic to the local emulator suite (Auth, Storage).

---

## 🏗️ Technical Implementation

### Backend Persistence
Settings are stored directly in the `Resident` model on the Serverpod backend. The protocol supports:
- `isPremium` (bool)
- `premiumTrialExpires` (DateTime)
- `trialCount` (int)
- Individual feature flags (e.g., `showVoiceMessages`)

### Service Layer
- **Client**: `ResidentService` handles the logic for updating settings and invalidating the `currentResidentProvider` to ensure the UI is reactive.
- **Server**: `ResidentService` orchestrates database updates and ensures distributed cache consistency via Redis.

---

## 🏢 Staff Settings

Residents with the `ResidentRole.admin` or `ResidentRole.moderator` role see a dedicated **Admin Dashboard** card in their settings screen. This provides access to:
- **Community Reports**: Reviewing user reports.
- **Resident Management**: Muting, suspending, or kicking residents.
- **Infrastructure Stats**: Real-time server and database health metrics.
