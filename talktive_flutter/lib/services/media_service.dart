import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:serverpod_client/serverpod_client.dart';
import '../providers/client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MediaService {
  final Ref ref;
  final _picker = ImagePicker();

  MediaService(this.ref);

  /// Picks an image from the gallery or camera.
  Future<XFile?> pickImage({ImageSource source = ImageSource.gallery}) async {
    return await _picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1200,
    );
  }

  /// Uploads a file to Serverpod's public storage.
  /// Returns the public URL of the uploaded file.
  Future<String?> uploadFile(XFile file, String folder) async {
    final client = ref.read(clientProvider);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    final path = '$folder/$fileName';

    try {
      debugPrint('MediaService: Getting upload description for $path...');
      var uploadDescriptionJson = await client.storage.getUploadDescription(path);
      if (uploadDescriptionJson == null) return null;

      // Fix for Android emulator to reach localhost on host machine
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android && uploadDescriptionJson.contains('localhost')) {
        uploadDescriptionJson = uploadDescriptionJson.replaceAll('localhost', '10.0.2.2');
        debugPrint('MediaService: Adjusted Upload Description for Android Emulator');
      }
      
      // 2. Upload the file using Serverpod's FileUploader
      // This handles the correct HTTP method and headers automatically
      final fileBytes = await file.readAsBytes();
      debugPrint('MediaService: File size: ${fileBytes.length} bytes. Platform: ${kIsWeb ? "Web" : "Mobile"}');
      debugPrint('MediaService: Starting upload using FileUploader...');
      
      final uploader = FileUploader(uploadDescriptionJson);
      final success = await uploader.uploadByteData(fileBytes.buffer.asByteData());

      if (!success) {
        throw Exception('File upload failed (FileUploader returned false).');
      }

      // 3. Verify upload on server (important for database storage)
      debugPrint('MediaService: Verifying upload for path: $path');
      final verified = await client.storage.verifyUpload(path);
      if (!verified) {
        throw Exception('File verification failed on server.');
      }

      // 4. Get public URL
      final publicUrl = await client.storage.getPublicUrl(path);
      debugPrint('MediaService: Public URL: $publicUrl');
      return publicUrl?.toString();
    } catch (e) {
      debugPrint('Error uploading file: $e');
      rethrow;
    }
  }
}

final mediaServiceProvider = Provider((ref) => MediaService(ref));
