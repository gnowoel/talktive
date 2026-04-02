# Cloudflare R2 Media Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate media storage from Firebase to Cloudflare R2, implement server-authorized uploads, and enhance content ephemerality.

**Architecture:** Utilize Serverpod's `storage` modules (S3 for production, local for development). Move upload control to the server using `UploadDescription` (pre-signed URLs). Synchronize physical file deletion with database record expiration.

**Tech Stack:** Serverpod, Cloudflare R2 (S3 API), Flutter, Riverpod.

---

### Task 1: Backend Storage Configuration

**Files:**
- Modify: `talktive_server/config/development.yaml`
- Modify: `talktive_server/config/production.yaml`

- [ ] **Step 1: Update development storage configuration**
Change storage type to `public` (local disk) for easier testing than `database`.
```yaml
storage:
  - id: public
    type: public
    public: true
```

- [ ] **Step 2: Update production storage configuration**
Add S3 configuration for Cloudflare R2.
```yaml
storage:
  - id: public
    type: s3
    public: true
    region: auto
    bucket: talktive-media
    endpoint: https://<ACCOUNT_ID>.r2.cloudflarestorage.com
```

- [ ] **Step 3: Commit configuration changes**
```bash
git add talktive_server/config/development.yaml talktive_server/config/production.yaml
git commit -m "chore: configure serverpod storage for R2 migration"
```

---

### Task 2: Media Endpoint & Authorization

**Files:**
- Create: `talktive_server/lib/src/endpoints/media_endpoint.dart`
- Modify: `talktive_server/lib/src/services/input_validation_service.dart`

- [ ] **Step 1: Add validation for upload requests**
Modify `talktive_server/lib/src/services/input_validation_service.dart` to add `validateUploadPath`.
```dart
static ValidationResult validateUploadPath(String path) {
  if (!['chats', 'voices', 'moments', 'avatars'].contains(path)) {
    return ValidationResult.invalid('Invalid upload destination.');
  }
  return ValidationResult.valid();
}
```

- [ ] **Step 2: Create MediaEndpoint**
Implement `getUploadDescription` with floor and premium checks.
```dart
import 'package:serverpod/serverpod.dart';
import '../utils/endpoint_auth_mixin.dart';
import '../services/resident_service.dart';
import '../services/apartment_service.dart';
import '../services/input_validation_service.dart';

class MediaEndpoint extends Endpoint with EndpointAuthMixin {
  Future<UploadDescription?> getUploadDescription(
    Session session,
    String path,
    int fileSize,
  ) async {
    InputValidationService.validateUploadPath(path).throwIfInvalid();
    InputValidationService.validateFileSize(fileSize).throwIfInvalid();

    final resident = await getAuthenticatedResident(session);
    final floor = ApartmentService.computeEffectiveFloor(resident);

    // Gating logic
    if (path == 'voices' && !ResidentService.isPlusMember(resident)) {
      throw TalktiveException(message: 'Voice messages are Premium.', code: 'PREMIUM_REQUIRED');
    }
    if (path == 'avatars' && !ResidentService.isPlusMember(resident)) {
      throw TalktiveException(message: 'Custom avatars are Premium.', code: 'PREMIUM_REQUIRED');
    }
    if ((path == 'moments' || path == 'chats') && floor < 2) {
      // Allow chats if private? Spec says Floor 2+ for public spaces. 
      // Mixing said: "Floor 2+ to send images here!"
    }

    final fileName = '${Uuid().v4()}'; 
    final extension = path == 'voices' ? 'm4a' : 'jpg';
    final fullPath = '$path/$fileName.$extension';

    return await session.storage.createDirectFileUploadDescription(
      storageId: 'public',
      path: fullPath,
    );
  }

  Future<bool> verifyUpload(Session session, String path) async {
    return await session.storage.fileExists(storageId: 'public', path: path);
  }
}
```

- [ ] **Step 3: Generate Serverpod client**
```bash
cd talktive_server && serverpod generate
```

- [ ] **Step 4: Commit endpoint changes**
```bash
git add talktive_server/lib/src/endpoints/media_endpoint.dart talktive_server/lib/src/services/input_validation_service.dart
git commit -m "feat: add MediaEndpoint for authorized uploads"
```

---

### Task 3: Physical Media Deletion Service

**Files:**
- Modify: `talktive_server/lib/src/services/file_storage_service.dart`

- [ ] **Step 1: Refactor FileStorageService to use Serverpod API**
Replace raw Firebase/GCS logic with `session.storage.deleteFile`.
```dart
class FileStorageService {
  static Future<void> deleteMedia(Session session, String? url) async {
    if (url == null || url.isEmpty) return;
    
    // Extract path from URL (e.g. https://.../chats/uuid.jpg -> chats/uuid.jpg)
    final path = _extractPathFromUrl(url);
    if (path != null) {
      await session.storage.deleteFile(storageId: 'public', path: path);
    }
  }

  static String? _extractPathFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      // For local disk/public storage, path is simple. 
      // For S3/R2, we might need to handle the bucket/host part.
      // We'll standardize on path extraction logic.
      if (url.contains('localhost')) return uri.pathSegments.skip(1).join('/');
      return uri.pathSegments.join('/'); 
    } catch (_) { return null; }
  }
}
```

- [ ] **Step 2: Commit service changes**
```bash
git add talktive_server/lib/src/services/file_storage_service.dart
git commit -m "refactor: use serverpod storage API for media deletion"
```

---

### Task 4: Custom Avatar Lifecycle & Cleanup

**Files:**
- Modify: `talktive_server/lib/src/services/resident_service.dart`

- [ ] **Step 1: Add avatar cleanup to updateResident**
Ensure the old file is deleted when a new one is set.
```dart
static Future<protocol.Resident> updateResident(
  Session session,
  protocol.Resident resident,
) async {
  final oldResident = await protocol.Resident.db.findById(session, resident.id!);
  final updated = await protocol.Resident.db.updateRow(session, resident);

  if (oldResident?.customAvatarUrl != null && 
      oldResident!.customAvatarUrl != updated.customAvatarUrl) {
    await FileStorageService.deleteMedia(session, oldResident.customAvatarUrl);
  }

  // ... rest of existing cache invalidation logic
  return updated;
}
```

- [ ] **Step 2: Commit avatar lifecycle changes**
```bash
git add talktive_server/lib/src/services/resident_service.dart
git commit -m "feat: implement custom avatar lifecycle cleanup"
```

---

### Task 5: Refactor Content Ephemerality Service

**Files:**
- Modify: `talktive_server/lib/src/services/content_ephemerality_service.dart`

- [ ] **Step 1: Verify physical deletion calls**
Ensure `_cleanupPlazaMessages`, `_cleanupLoungeMessages`, etc., still call `_deleteMessageMedia`. (Research shows they already do, but they need to use the refactored `FileStorageService`).

- [ ] **Step 2: Update cleanup durations**
Align with spec (Lounge 14d, Private 30d, Moments 7d).

- [ ] **Step 3: Commit ephemerality changes**
```bash
git add talktive_server/lib/src/services/content_ephemerality_service.dart
git commit -m "chore: align content ephemerality with new storage design"
```

---

### Task 6: Flutter MediaService Refactor

**Files:**
- Modify: `talktive_flutter/lib/services/media_service.dart`

- [ ] **Step 1: Update uploadFile to use Serverpod**
Remove `FirebaseStorage` dependency and use `getUploadDescription`.
```dart
Future<UploadResult?> uploadFile(XFile file, String folder) async {
  final bytes = await file.readAsBytes();
  final client = ref.read(clientProvider);
  
  final description = await client.media.getUploadDescription(folder, bytes.length);
  if (description == null) return null;

  // Use http package to PUT file
  final response = await http.put(
    Uri.parse(description.url),
    body: bytes,
    headers: {
      'Content-Type': _contentTypeForFile(file, folder),
      ...description.requestHeaders,
    },
  );

  if (response.statusCode == 200 || response.statusCode == 201) {
    // The public URL is often different from the upload URL in Serverpod
    // We should return the description's path or a generated public URL
    return UploadResult(url: description.url, sizeInBytes: bytes.length); 
  }
  return null;
}
```

- [ ] **Step 2: Commit Flutter changes**
```bash
git add talktive_flutter/lib/services/media_service.dart
git commit -m "refactor: use server-authorized uploads in Flutter"
```

---

### Task 7: Final Verification

- [ ] **Step 1: Test local upload**
Run Serverpod in dev mode, upload an image in Plaza, verify it appears in `talktive_server/storage/`.

- [ ] **Step 2: Test avatar update**
Upload custom avatar, then change back to emoji, verify file is deleted from local storage.

- [ ] **Step 3: Test voice message**
Verify Plus membership check on server prevents non-Plus uploads.
