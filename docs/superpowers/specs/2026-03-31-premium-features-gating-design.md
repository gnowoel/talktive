# Design Spec: Premium Features Gating & Grace Period

**Date:** 2026-03-31
**Topic:** Subscription Tier Enforcement, Feature Toggles, and 14-Day Data Grace Period

## 1. Overview
This design ensures that Talktive's premium features (voice messages, custom avatars, neighbor discovery, etc.) are correctly gated by subscription tier (Paid, Trial, or Regular) while allowing users to toggle these features on/off to clearly see their subscription value. It also implements a 14-day grace period for data retention (e.g., kept private chats, custom avatars) after a subscription expires.

## 2. Requirements

### 2.1 Feature Access by Tier
- **Paid Users:** Access to all premium features. Can toggle all settings, including "No Ads" (default: ON).
- **Trial Users:** Access to all premium features EXCEPT "No Ads". Can toggle premium settings but cannot enable "No Ads" (default: ON for features, OFF for No Ads).
- **Regular Users:** No access to premium features. Cannot toggle any premium settings to ON (default: OFF).

### 2.2 Image Sending (Universal)
- Anyone meeting the minimum floor requirement (Floor 2+) can send images in Plaza, Chat, or Lounge threads.
- Image sending is NOT exclusive to paying users.

### 2.3 Premium Settings (The "Value Menu")
The following 8 toggles must be respected:
1. `showVoiceMessages`
2. `showCustomAvatar`
3. `showNeighborsDiscovery` (Universal Discovery policy applies, but toggle allows opting out)
4. `keepPrivateChats`
5. `hideAds` (Paid only)
6. `showOthersOnlineStatus`
7. `showOthersReadReceipts`
8. `showOthersTypingIndicators`

### 2.4 14-Day Grace Period
- Applies to both Trial and Paid subscription expirations.
- **Active Features:** Lost immediately upon expiration (e.g., cannot send new voice messages).
- **Data Retention:** "Kept" private chats and custom avatars are retained for 14 days. Toggles are not flipped to `false` until the grace period ends.

## 3. Architecture

### 3.1 Backend (Serverpod)

#### Resident Model Update
- Ensure `premiumTrialExpires` correctly tracks expiration for both trials and paid subscriptions.
- Add/Repurpose logic to track when a subscription transitioned to "Expired" to calculate the 14-day window.

#### ResidentService Enhancements
- `isPlusMember(Resident resident)`: Returns true if `isPremium` OR `premiumTrialExpires` is in the future.
- `isPaidMember(Resident resident)`: Returns true if `isPremium`.
- `isWithinGracePeriod(Resident resident)`: Checks if expiration was within the last 14 days.
- `applyTierDefaults(Resident resident, Tier tier)`: Sets initial toggle states when a user upgrades or starts a trial.
- `canUseFeature(Resident resident, String feature)`: Centralized permission check combining tier check + toggle status.

#### MessagingService
- Update `validateMessage` to use `ResidentService.isPlusMember` for voice message checks (fixing the trial user bug).
- Ensure floor-based image restrictions remain tier-agnostic.

#### ResidentEndpoint
- Update `updateResident` and `updateCustomAvatar` to enforce `isPlusMember` for custom avatar uploads.
- Update `updatePrivacy` to prevent Trial/Regular users from enabling restricted toggles (e.g., `hideAds`).

#### ContentEphemeralityService (Grace Period)
- Update `_cleanupPrivateMessages` to respect the 14-day grace period for channel members before deleting non-persistent chats.

### 3.2 Frontend (Flutter)

#### Settings Screen
- Greying out/Disabling toggles based on tier.
- Adding "Paid Only" or "Premium" badges to toggles restricted to specific tiers.
- Clear visual feedback when a user tries to enable a restricted feature.

#### Chat UI
- Floor-level warnings for images in public spaces.
- Premium upgrade prompts for voice messages if the user is Regular.

## 4. Testing Strategy

### 4.1 Unit Tests
- Test `applyTierDefaults` for all three tiers.
- Test `canUseFeature` with various combinations of tier and toggle state.
- Test grace period calculation logic.

### 4.2 Integration Tests
- Verify that a Trial user cannot enable `hideAds` via API.
- Verify that a Regular user can send images if they are Floor 2+.
- Verify that voice messages are blocked for Regular users but allowed for Trial users (with toggle ON).

### 4.3 Manual Verification
- Upgrade a user to Trial and verify default toggles.
- Let a Trial expire and verify that "kept" chats are not deleted for 14 days.
