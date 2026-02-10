import 'dart:io';
import 'dart:typed_data';
import 'package:serverpod/serverpod.dart';
import 'package:path/path.dart' as path;
import '../generated/protocol.dart';

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
      throw Exception('Not authenticated');
    }

    final userUuid = UuidValue.fromString(userIdentifier);

    // Fetch resident to check permissions
    final resident = await Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(userUuid),
    );

    if (resident == null) {
      throw Exception('Resident not found');
    }

    // Check credit score
    if (resident.creditScore <= 0) {
      throw Exception('You are muted due to low credit score.');
    }

    // Validate file size (5MB max)
    const maxSizeBytes = 5 * 1024 * 1024; // 5MB
    if (imageData.lengthInBytes > maxSizeBytes) {
      throw Exception('Image too large. Maximum size is 5MB.');
    }

    // Validate file extension
    final ext = path.extension(fileName).toLowerCase();
    const allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
    if (!allowedExtensions.contains(ext)) {
      throw Exception(
        'Invalid file format. Allowed formats: JPEG, PNG, WebP',
      );
    }

    // Generate unique filename
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uniqueFileName = '${userUuid}_${timestamp}$ext';

    // Define upload directory (relative path for Docker volume mounting)
    final uploadDir = Directory('uploads');
    if (!await uploadDir.exists()) {
      await uploadDir.create(recursive: true);
    }

    // Save file
    final filePath = path.join(uploadDir.path, uniqueFileName);
    final file = File(filePath);
    await file.writeAsBytes(
      imageData.buffer.asUint8List(
        imageData.offsetInBytes,
        imageData.lengthInBytes,
      ),
    );

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
      throw Exception('Not authenticated');
    }

    final userUuid = UuidValue.fromString(userIdentifier);

    // Extract filename from URL
    final fileName = path.basename(imageUrl);

    // Check if user owns this image (filename starts with their UUID)
    if (!fileName.startsWith(userUuid.toString())) {
      throw Exception('You can only delete your own images.');
    }

    // Delete file
    final filePath = path.join('uploads', fileName);
    final file = File(filePath);

    if (await file.exists()) {
      await file.delete();
      session.log('Image deleted: $imageUrl');
    } else {
      throw Exception('Image not found');
    }
  }
}
