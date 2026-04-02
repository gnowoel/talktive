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
    final fileName = Uuid().v4();
    final extension = path == 'voices' ? 'm4a' : 'jpg';
    final fullPath = '$path/$fileName.$extension';

    // 5. Create description
    return await session.storage.createDirectFileUploadDescription(
      storageId: 'public',
      path: fullPath,
    );
  }

  /// Verifies if a file exists in storage.
  Future<bool> verifyUpload(Session session, String path) async {
    return await session.storage.fileExists(storageId: 'public', path: path);
  }
}
