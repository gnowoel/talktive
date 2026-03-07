import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
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
      // 1. Get upload description from server
      final uploadDescriptionJson = await client.storage.getUploadDescription(path);
      if (uploadDescriptionJson == null) return null;

      final uploadDescription = jsonDecode(uploadDescriptionJson);
      var uploadUrl = uploadDescription['url'] as String;
      
      // Fix for Android emulator to reach localhost on host machine
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android && uploadUrl.contains('localhost')) {
        uploadUrl = uploadUrl.replaceFirst('localhost', '10.0.2.2');
      }
      debugPrint('MediaService: Adjusted Upload URL: $uploadUrl');
      
      // 2. Upload the file using HTTP PUT
      final fileBytes = await file.readAsBytes();
      debugPrint('MediaService: File size: ${fileBytes.length} bytes');
      
      // Build headers from the description
      final headers = <String, String>{};
      if (uploadDescription['headers'] != null) {
        final descHeaders = uploadDescription['headers'] as Map<String, dynamic>;
        descHeaders.forEach((key, value) {
          headers[key] = value.toString();
        });
      }
      debugPrint('MediaService: Headers: $headers');

      final response = await http.put(
        Uri.parse(uploadUrl),
        headers: headers,
        body: fileBytes,
      );

      debugPrint('MediaService: Response status: ${response.statusCode}');
      if (response.statusCode != 200 && response.statusCode != 201 && response.statusCode != 204) {
        debugPrint('MediaService: Error body: ${response.body}');
        throw Exception('Failed to upload file: ${response.statusCode} - ${response.body}');
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
