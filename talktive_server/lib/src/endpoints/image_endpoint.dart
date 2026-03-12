import 'dart:io';
import 'dart:typed_data';
import 'package:serverpod/serverpod.dart';
import 'package:path/path.dart' as path;
import '../generated/protocol.dart';
import '../services/image_validation_service.dart';
import '../services/apartment_service.dart';

class ImageEndpoint extends Endpoint {
  /// Uploads an image file to the server's local storage.
  /// Returns the URL path to access the uploaded image.
  ///
  /// Images are stored in: /var/talktive/uploads/
  /// Accessible via: /uploads/{filename}
  ///
  /// Restrictions:
  /// - Max file size: 5MB
  /// - Allowed formats: JPEG, PNG, WebP
  /// - Only authenticated users can upload
  Future<String> uploadImage(
    Session session,
    ByteData imageData,
    String fileName,
  ) async {
    final authenticationInfo = session.authenticated;
    final userIdentifier = authenticationInfo?.userIdentifier;

    if (userIdentifier == null) {
      throw TalktiveException(message: 'Not authenticated');
    }

    final userUuid = UuidValue.fromString(userIdentifier);

    // Fetch resident to check permissions
    final resident = await Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(userUuid),
    );

    if (resident == null) {
      throw TalktiveException(message: 'Resident not found');
    }

    // Check if user is muted
    if (ApartmentService.isMuted(resident)) {
      throw TalktiveException(message: ApartmentService.getMuteReason(resident));
    }

    // Convert ByteData to Uint8List
    final imageBytes = imageData.buffer.asUint8List(
      imageData.offsetInBytes,
      imageData.lengthInBytes,
    );

    // Validate image
    final validationError = await ImageValidationService.validateImage(
      session,
      imageBytes,
      fileName,
    );

    if (validationError != null) {
      throw TalktiveException(message: validationError);
    }

    // Generate unique filename
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ext = path.extension(fileName).toLowerCase();
    final uniqueFileName = '${userUuid}_$timestamp$ext';

    // Define upload directory (relative path for Docker volume mounting)
    final uploadDir = Directory('uploads');
    if (!await uploadDir.exists()) {
      await uploadDir.create(recursive: true);
    }

    // Save file
    final filePath = path.join(uploadDir.path, uniqueFileName);
    final file = File(filePath);
    await file.writeAsBytes(imageBytes);

    // Return URL path
    final imageUrl = '/uploads/$uniqueFileName';
    session.log('Image uploaded: $imageUrl');

    return imageUrl;
  }

  /// Deletes an image from the server (user can only delete their own images).
  Future<void> deleteImage(
    Session session,
    String imageUrl,
  ) async {
    final authenticationInfo = session.authenticated;
    final userIdentifier = authenticationInfo?.userIdentifier;

    if (userIdentifier == null) {
      throw TalktiveException(message: 'Not authenticated');
    }

    final userUuid = UuidValue.fromString(userIdentifier);

    // Extract filename from URL
    final fileName = path.basename(imageUrl);

    // Check if user owns this image (filename starts with their UUID)
    if (!fileName.startsWith(userUuid.toString())) {
      throw TalktiveException(message: 'You can only delete your own images.');
    }

    // Delete file
    final filePath = path.join('uploads', fileName);
    final file = File(filePath);

    if (await file.exists()) {
      await file.delete();
      session.log('Image deleted: $imageUrl');
    } else {
      throw TalktiveException(message: 'Image not found');
    }
  }
}
