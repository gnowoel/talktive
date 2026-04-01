# Spec: Consistent Authentication Mapping and "Existing User" Google Sign-In

## 1. Overview
This specification addresses an issue where existing Google users are not recognized after clearing local site data. This occurs because:
1. The "Existing User" flow in the UI currently only supports Recovery Tokens (email/password), forcing Google users to select "New User".
2. The server-side authentication handshake creates a new user identity (UUID) for existing Google accounts because it fails to link the incoming Google email to existing records that use synthetic "privacy" emails (e.g., `anon-...@anonymous.talktive.com`).

## 2. Goals
- Provide a clear "Sign in with Google" path for existing users in the `VersionSelector`.
- Ensure that Google/Firebase accounts are strictly mapped to their original Serverpod identity (UUID) based on their unique Firebase UID, bypassing email discrepancies.
- Prevent accidental "Floor 1" resets by returning existing `Resident` profiles during initialization.

## 3. Architecture & Data Flow

### 3.1 Frontend: `VersionSelector` UI Enhancement
We will introduce an intermediate selection state for existing users.

**States:**
- `SelectorState.chooseExistingMethod`: New state showing two buttons.
- `SelectorState.runAppServerpod`: Existing state, now also reached via "Existing User -> Google".

**Logic:**
- "Existing User" -> `SelectorState.chooseExistingMethod`.
- `chooseExistingMethod` UI:
    - Button: "Continue with Google" -> Triggers Google Sign-In.
    - Button: "Use Recovery Token" -> Goes to `SelectorState.enterRecoveryToken`.
    - Button: "Back" -> Returns to `SelectorState.chooseUserType`.

### 3.2 Backend: Identity Anchoring
The primary fix is to ensure the **Firebase UID** is the source of truth for identity mapping.

#### `EmulatorFirebaseIdp.login` (and standard `FirebaseIdp`)
We will modify the login handshake to prioritize the `userIdentifier` (Firebase UID):
1. Extract the `userIdentifier` from the verified token.
2. Query `FirebaseAccount.db.findFirstRow` for a record matching this `userIdentifier`.
3. If found: Use the existing `authUserId` (UUID) for the session.
4. If not found: Proceed with standard `utils.authenticate` (which may look up by email as a fallback).

#### `ResidentEndpoint.initializeResident`
Add a safety check to prevent overwriting/creating duplicates:
1. Before creating a new `Resident`, perform `ResidentService.getResident(session, senderUuid)`.
2. If a record is found, return it immediately with a success status.
3. This ensures that even if a user goes through the "New User" flow, they are reunited with their existing progress if their identity was recognized.

## 4. Implementation Plan

### Phase 1: Frontend (Flutter)
- Update `version_selector.dart`:
    - Add `chooseExistingMethod` to `SelectorState`.
    - Implement `_buildChooseExistingMethod()` widget.
    - Update `_selectExistingUser()` to transition to the new state.
    - Add `_loginWithGoogle()` handler to `VersionSelector`.

### Phase 2: Backend (Serverpod)
- Update `emulator_auth_service.dart`:
    - In `login`, add a manual lookup for `FirebaseAccount` by `userIdentifier`.
    - Ensure the session is issued for the existing `authUserId` if found.
- Update `resident_endpoint.dart`:
    - In `initializeResident`, verify if a resident already exists for the session's user ID before proceeding with creation.

## 5. Verification & Testing
- **Test Case 1 (Recognition)**: 
    1. Sign in with Google.
    2. Reach Floor 1+.
    3. Clear site data.
    4. Go to "Existing User" -> "Continue with Google".
    5. **Expectation**: User is immediately logged in and sees their existing progress.
- **Test Case 2 (Fallback Recognition)**:
    1. Clear site data.
    2. Go to "New User" -> Sign in with same Google account.
    3. **Expectation**: User completes Google Sign-In, and `initializeResident` returns their existing profile instead of creating a new one.
