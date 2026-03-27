# Talktive Monetization and Ads

## 💰 Ad Strategy

Talktive uses a balanced monetization strategy that provides value to advertisers while ensuring a smooth, premium experience for residents.

### 1. Interstitial Ads (Exit-Driven)

Interstitial ads are full-screen advertisements displayed at natural transition points in the application.

- **Trigger**: Ads are triggered when a resident **exits** a chat thread (Private Chat, Lounge Chat, or Plaza Lobby).
- **Navigation Integration**: The navigation helper `context.popWithAd(ref)` is used to ensure ads are displayed before the screen is popped.
- **Gesture Support**: Chat screens incorporate `PopScope` to intercept hardware back buttons and swipe-to-dismiss gestures, ensuring ads are triggered regardless of the exit method.

### 2. Frequency & User Experience

To maintain a friendly "Apartment Building" atmosphere, we strictly limit ad frequency:

- **Cooldown Period**: A mandatory **2-minute cooldown** is enforced between interstitial ads.
- **Policy**: `AdService` tracks the `lastAdShowTime` to ensure residents are not overwhelmed by frequent interruptions.

### 3. Compliance & Consent

Talktive adheres to the latest privacy and advertising standards:

- **User Messaging Platform (UMP)**: We use the Google UMP SDK to manage user consent (GDPR/CCPA/ATT).
- **Consent Service**: The `ConsentService` handles initialization and consent gathering before any ads are loaded or displayed.

### 4. Premium Benefits (Talktive Plus)

Residents who subscribe to **Talktive Plus** receive an ad-free experience:

- **Ad Exemption**: Users with `isPremium` status are automatically exempted from all interstitial ads.
- **Visual Gating**: Ad-related UI elements are hidden or disabled for premium subscribers.

---

## 🛠️ Technical Implementation

### Core Services (`lib/services/ad/`)

- **`AdService`**: The primary coordinator for loading and showing ads. It manages unit IDs (Test vs. Production), cooldown states, and admin exemptions.
- **`ConsentService`**: Manages the UMP consent flow and initialization state.

### Utilities

- **`AdNavigationExtensions`**: Provides `context.popWithAd(ref)` and `context.pushNamedWithAd(ref, ...)` to easily integrate ad logic into GoRouter and Navigator flows.

### Admin & Debug Mode

- **Admin Exemption**: Verified Administrators (`isAdmin`) automatically receive test ads to prevent invalid production traffic during testing.
- **Debug Mode**: The `kDebugMode` flag ensures that test unit IDs are used during development.

---

## 📋 AdMob Configuration

Ad unit IDs are managed in `lib/config/ad_config.dart`. Ensure these are updated with production IDs before release:

- **Android App ID**: `ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX`
- **iOS App ID**: `ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX`
- **Interstitial ID**: `ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX`

---

## 💎 Features & Benefits

For a complete breakdown of free vs. premium features, see [PLATFORM_FEATURES.md](./PLATFORM_FEATURES.md).
