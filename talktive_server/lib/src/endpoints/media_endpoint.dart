import 'dart:convert';
import 'dart:io';
import 'package:serverpod/serverpod.dart';
import '../utils/endpoint_auth_mixin.dart';
import '../services/resident_service.dart';
import '../services/apartment_service.dart';
import '../services/input_validation_service.dart';
import 'package:talktive_server/src/generated/protocol.dart';

class MediaEndpoint extends Endpoint with EndpointAuthMixin {
  /// Generates an upload description for a file.
  /// Validates permissions (floor level, premium status) based on the destination path.
  Future<String?> getUploadDescription(
    Session session,
    String path,
    int fileSize,
    String? fileExtension,
  ) async {
    // 1. Basic validation
    InputValidationService.validateUploadPath(path).throwIfInvalid();
    InputValidationService.validateFileSize(fileSize).throwIfInvalid();

    // 2. Auth & Resident Fetch
    final resident = await getAuthenticatedResident(session);
    final floor = ApartmentService.computeEffectiveFloor(resident);

    // 3. Permission Gating

    // Voice messages: Premium only
    if (path == 'voices' && !ResidentService.isPlusMember(resident)) {
      throw TalktiveException(
        message:
            'Voice messages are a Premium feature. 🎙️ Upgrade in Settings!',
        code: 'PREMIUM_REQUIRED',
      );
    }

    // Custom Avatars: Premium only
    if (path == 'avatars' && !ResidentService.isPlusMember(resident)) {
      throw TalktiveException(
        message: 'Custom avatars are a Premium feature. ✨ Upgrade in Settings!',
        code: 'PREMIUM_REQUIRED',
      );
    }

    // Moments & Public Chat images: Floor 2+
    if ((path == 'moments' || path == 'chats') && floor < 2) {
      throw TalktiveException(
        message: 'You must reach Floor 2 to upload media in public spaces. 🏢',
        code: 'FLOOR_RESTRICTION',
      );
    }

    // 4. Generate unique path
    final extension = _resolveFileExtension(path, fileExtension);
    final fileName = Uuid().v4();
    final fullPath = '$path/$fileName.$extension';

    // 5. Create description
    final uploadDescription = await session.storage
        .createDirectFileUploadDescription(
          storageId: 'public',
          path: fullPath,
        );

    if (uploadDescription == null) return null;

    // 6. Enrich description with stable metadata the client needs to finish
    // the upload flow.
    try {
      final map = jsonDecode(uploadDescription) as Map<String, dynamic>;
      map['path'] = fullPath;

      // If storage provider didn't return a public URL, infer it.
      if ((map['publicUrl'] as String?)?.isEmpty ?? true) {
        final publicUri =
            await session.storage.getPublicUrl(
              storageId: 'public',
              path: fullPath,
            ) ??
            _inferPublicUri(
              storagePath: fullPath,
              uploadUrl: map['url'] as String?,
            );
        if (publicUri != null) {
          map['publicUrl'] = publicUri.toString();
        }
      }

      return jsonEncode(map);
    } catch (_) {
      return uploadDescription;
    }
  }

  String _resolveFileExtension(String path, String? requestedExtension) {
    // 1. Determine a safe default based on the path
    final defaultExtension = path == 'voices' ? 'm4a' : 'jpg';

    // 2. Normalize and validate requested extension
    var ext = (requestedExtension ?? defaultExtension)
        .trim()
        .toLowerCase()
        .replaceAll('.', '');

    // 3. Handle common alias
    if (ext == 'jpeg') ext = 'jpg';

    // 4. Validate against allowed extensions for the given destination
    InputValidationService.validateUploadExtension(
      path,
      ext,
    ).throwIfInvalid();

    return ext;
  }

  /// Verifies if a file exists in storage.
  Future<bool> verifyUpload(Session session, String path) async {
    return await session.storage.verifyDirectFileUpload(
      storageId: 'public',
      path: path,
    );
  }

  Uri? _inferPublicUri({
    required String storagePath,
    required String? uploadUrl,
  }) {
    if (uploadUrl == null) return null;
    final uploadUri = Uri.tryParse(uploadUrl);
    if (uploadUri == null) return null;

    // Handle Serverpod Database Storage (Local Development)
    if (uploadUri.path == '/serverpod_cloud_storage') {
      return uploadUri.replace(
        queryParameters: {
          'method': 'file',
          'path': storagePath,
        },
      );
    }

    // Handle Cloudflare R2 (S3-compatible)
    // R2 direct upload URLs are typically: https://<bucket>.<account>.r2.cloudflarestorage.com/<path>?<auth_params>
    // We want to return the public URL which might be a custom domain or the public R2 domain.

    // Check if we should use a custom public host from environment or default to the upload host.
    final publicHost = Platform.environment['CLOUDFLARE_PUBLIC_HOST'];

    if (publicHost != null && publicHost.isNotEmpty) {
      return Uri(
        scheme: 'https',
        host: publicHost,
        path: storagePath.startsWith('/') ? storagePath : '/$storagePath',
      );
    }

    // Fallback: Strip query parameters from the upload URI to get the base file URI.
    return uploadUri.replace(queryParameters: {});
  }
}
