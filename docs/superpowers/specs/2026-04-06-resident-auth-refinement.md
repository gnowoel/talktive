# Design Spec: Resident & Auth Refinement

This document outlines the refinements and bug fixes for the Talktive Serverpod codebase, focusing on Resident management, Privacy enforcement, and Auth consistency.

## 1. Resident Service & Endpoint Refinements

### 1.1 Partial Updates (`patchResident`)
**Problem:** The current `updateResident` method has many required parameters and lacks a clean way to handle optional fields without overwriting them with `null`.
**Solution:**
- Add `ResidentService.updateResidentFields` that takes a `Resident` object and applies optional updates using the `??` pattern.
- Consolidate `updateResident` and `updateCustomAvatar` logic into this service method.
- Update `ResidentEndpoint` to be even leaner.

### 1.2 Privacy Toggle Consolidation
**Problem:** `updatePrivacy` has repetitive logic for 8+ boolean toggles.
**Solution:**
- Create a `_setPlusToggles` helper in `ResidentService` that takes a map of toggles and applies them only if the resident has Plus status.
- Consolidate the "Plus Required" check in `ResidentEndpoint` using a simple `any` check on the provided toggles.

### 1.3 Optimized Mutual Lounges Count
**Problem:** `_supplementProfileWithSocialState` fetches all `ChannelMember` rows for both viewer and target to compute mutual lounges. This is inefficient for active users.
**Solution:**
- Use a targeted query to count mutual channels of type `lounge`.
- Implementation: Use a join or a specifically indexed query if possible, otherwise at least filter by `ChannelType.lounge`.

### 1.4 Profile View Gating (Bugs Fixed)
**Fixed:**
- `toUserSummary` now uses `gateResident` to correctly enforce custom avatar visibility (Premium only).
- `gateResident` correctly distinguishes between "Uploading" (Target status) and "Viewing" (Viewer preference) for custom avatars.

## 2. Privacy & Safety Enforcement (Bugs Fixed)

### 2.1 Blocking Awareness
**Fixed:**
- Added `ResidentService.getBlocksByUser`.
- `MessageEndpoint.listMessages` and `subscribe` now filter out messages from blocked users.
- `MomentService.listMoments` now filters out moments from blocked users.
- `SearchService` filters out blocked users from User and Lounge searches.

### 2.2 Advanced Search Gating
**Fixed:**
- Basic name search is now free for all residents (Universal Discovery).
- Advanced filters (gender, country, etc.) are strictly gated behind Talktive Plus.
- Fixed `searchAll` which was previously broken for non-Plus members.

## 3. Auth Consistency (Frontend)

### 3.1 User Name Sync Bug
**Problem:** `AuthProvider` prefers locally cached `user_name` or Firebase display name over the server-side `Resident.userName`.
**Solution:**
- Update `_refreshAuthState` to always prioritize `resident.userName` as the source of truth.
- Consolidate local state and `SharedPreferences` updates into a single private method `_updateLocalSession`.

## 4. Maintenance & Cleanup

### 4.1 Dependency Fixes
- Added `riverpod` as a direct dependency in `talktive_flutter` to satisfy lint rules.
- Restored necessary internal imports for `Override` type (Riverpod 3.0+ compatibility).

### 4.2 Code Health
- Fixed invalid syntax in `NotificationService.triggerMessageNotifications` (`?` conditional inclusion).
- Renamed all service constants to `lowerCamelCase` for consistent style.
- Removed obsolete `analyze.txt`, `errors.txt`, and `server_output.txt` files.
