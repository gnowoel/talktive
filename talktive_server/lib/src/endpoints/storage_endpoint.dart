import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart' as protocol;
import '../utils/endpoint_auth_mixin.dart';
import '../services/apartment_service.dart';

class StorageEndpoint extends Endpoint with EndpointAuthMixin {
  /// Generates a description for a direct file upload to the public storage.
  /// Only active residents (Floor 1+) can upload files.
  Future<String?> getUploadDescription(
    Session session,
    String path,
  ) async {
    final userId = await getUserId(session);
    final resident = await getResidentProfile(session, userId);

    // Safety: Users must be Floor 1+ to upload media
    final floor = ApartmentService.computeEffectiveFloor(resident);
    if (floor < 1) {
      throw protocol.TalktiveException(message: 'You must reach Floor 1 to upload media.');
    }

    // Check if muted
    if (ApartmentService.isMuted(resident)) {
      throw protocol.TalktiveException(message: ApartmentService.getMuteReason(resident));
    }

    // Basic path validation
    if (path.contains('..') || path.startsWith('/')) {
      throw protocol.TalktiveException(message: 'Invalid path');
    }

    return await session.storage.createDirectFileUploadDescription(
      path: path,
      storageId: 'public',
    );
  }

  /// Verifies if a file was successfully uploaded.
  Future<bool> verifyUpload(
    Session session,
    String path,
  ) async {
    return await session.storage.verifyDirectFileUpload(
      path: path,
      storageId: 'public',
    );
  }

  /// Gets the public URL for a file in the public storage.
  Future<Uri?> getPublicUrl(
    Session session,
    String path,
  ) async {
    return await session.storage.getPublicUrl(path: path, storageId: 'public');
  }
}
