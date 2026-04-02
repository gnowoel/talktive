# Design Doc: Cloudflare R2 Media Migration & Secure Ephemerality

This document outlines the migration of media storage from Firebase Storage to Cloudflare R2, the introduction of server-authorized uploads, and the enhancement of the content ephemerality system for the Talktive v3 (Serverpod) platform.

## 1. Problem Statement

The current implementation of image sending relies on client-side uploads to Firebase Storage with permissive security rules. This presents several issues:

- **Security:** Any authenticated user can write to any path in the storage bucket.
- **Cost:** Firebase/GCS egress fees are high for a growing user base (10k+ users).
- **Control:** The server "trusts" client-provided URLs without validating permissions (floor/premium) during the upload phase.
- **Maintenance:** Cleanup logic currently uses raw Google Cloud APIs which are separate from the Serverpod ecosystem.

## 2. Proposed Architecture

### 2.1. Serverpod Storage Integration (Abstraction)

We will utilize Serverpod's built-in `storage` modules to create an environment-aware storage layer.

- **Production:** Configure the `s3` storage module to point to Cloudflare R2.
- **Development/Staging:** Configure the `public` or `disk` storage module. This allows full testing of media features (upload/view/delete) on a local developer machine without cloud dependencies.
- **Storage Identity:** We will use the default `public` identity for most assets, ensuring high-performance delivery via CDN.

### 2.2. Pre-Signed Upload Workflow (The "Description" Pattern)

We will move to a server-authorized upload flow to ensure that only eligible residents can upload media.

1. **Request:** The client calls `MediaEndpoint.getUploadDescription(path, fileSize)`.
2. **Validation:**
   - **Floor Check:** Residents must be Floor 2+ to upload to "public" spaces (Plaza, Lounges, Moments).
   - **Premium (Plus) Check:** Residents must be Plus members to upload **Voice Messages** or **Custom Avatars**.
   - **Rate Limiting:** Prevent upload spam.
3. **Authorization:** The server generates a unique, unguessable path (e.g., `chats/<uuid>.jpg`) and returns an `UploadDescription` (containing a pre-signed PUT URL and headers).
4. **Execution:** The client performs a direct HTTP `PUT` to R2 using the provided description.
5. **Confirmation:** The client then sends the message/moment/profile update to the server using the finalized URL.

### 2.3. Physical Media Deletion

We will update `FileStorageService` to use the Serverpod `session.storage.deleteFile` API. This abstracts away the specific cloud provider and ensures consistent behavior across environments.

## 3. Ephemerality & Cleanup Logic

### 3.1. Message & Moment Content

The `ContentEphemeralityService` will be updated to ensure physical files are removed from R2 when their corresponding database records expire:

- **Plaza Messages:** 24 hours.
- **Lounge Messages:** 14 days (Lounges are not persistent).
- **Private Chat Messages:** 30 days (unless persistent).
- **Moments:** 7 days (including comments and likes).

### 3.2. Custom Avatar Lifecycle (New)

To avoid inefficient bucket scans, custom avatars will be managed during the profile update flow:

- **Logic:** When a user updates their profile (`ResidentService.updateResident` or similar):
  - If the user provides a **new** `customAvatarUrl`, the **previous** custom avatar file (if any) is immediately deleted from storage.
  - If the user switches from a custom photo back to an emoji, the previous custom avatar file is immediately deleted.
- **Cancel Safety:** The deletion only triggers at the **end** of the update process, once the database record is successfully committed.

### 3.3. Abandoned Thread Cleanup (Future Phase)

We will implement logic to delete entirely abandoned containers:

- **Private Chats:** If both users have "left" the chat and it is not marked as persistent.
- **Lounges:** If the lounge has 0 active members.

## 4. Coexistence with Legacy Systems

- **Firebase Storage:** The code for the older Firebase-based version will remain untouched. The Serverpod version will strictly use the Cloudflare R2 backend.
- **Separation:** Since these are different storage providers, filenames will be managed independently via Serverpod's UUID generation.

## 5. Security & Permissions

- **Read Access:** Assets are public by default for CDN performance, protected by random UUID filenames.
- **Write Access:** Strictly controlled by the Serverpod `MediaEndpoint` via pre-signed URLs.
- **Gating:** Voice messages and Custom Avatars remain gated behind the `isPlusMember` check.

## 6. Testing Strategy

- **Local Validation:** Use the Serverpod `disk` storage provider to verify that files are correctly saved to and deleted from the local `storage/` directory.
- **Integration Tests:** Verify that deleting a message record correctly triggers the `FileStorageService.deleteMedia` call.
- **Unit Tests:** Test the `ContentEphemeralityService` cutoff logic to ensure it identifies the correct records for deletion.
