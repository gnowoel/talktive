import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../providers/client_provider.dart';

class UploadResult {
  final String url;
  final int sizeInBytes;

  UploadResult({required this.url, required this.sizeInBytes});
}

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

  /// Uploads a file using server-authorized upload descriptions.
  /// Returns the public URL of the uploaded file and its size.
  Future<UploadResult?> uploadFile(
    XFile file,
    String folder, {
    int maxSizeMb = 5,
  }) async {
    final bytes = await file.readAsBytes();
    final sizeInBytes = bytes.length;
    final sizeInMb = sizeInBytes / (1024 * 1024);

    if (sizeInMb > maxSizeMb) {
      throw Exception(
        'Image is too large (${sizeInMb.toStringAsFixed(1)}MB). Max size is ${maxSizeMb}MB! 📸',
      );
    }

    try {
      debugPrint('MediaService: Requesting upload description for $folder...');
      final client = ref.read(clientProvider);

      // 1. Get authorized upload description from Serverpod
      final uploadDescriptionJson = await client.media.getUploadDescription(
        folder,
        sizeInBytes,
      );

      if (uploadDescriptionJson == null) {
        throw Exception('Server denied upload authorization.');
      }

      // 2. Parse the description (Serverpod's internal format)
      final description = jsonDecode(uploadDescriptionJson);
      final uploadUrl = description['url'] as String;
      final publicUrl = description['publicUrl'] as String;
      final headers = Map<String, String>.from(description['headers'] ?? {});

      debugPrint('MediaService: Starting direct upload to storage...');

      // 3. Perform the actual PUT request
      final response = await http.put(
        Uri.parse(uploadUrl),
        body: bytes,
        headers: {
          'Content-Type': _contentTypeForFile(file, folder),
          ...headers,
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          'Upload failed with status: ${response.statusCode}\n${response.body}',
        );
      }

      debugPrint('MediaService: Upload successful! Public URL: $publicUrl');
      return UploadResult(url: publicUrl, sizeInBytes: sizeInBytes);
    } catch (e, stack) {
      debugPrint('MediaService: CRITICAL ERROR during upload: $e');
      debugPrint('MediaService: Stack trace: $stack');
      rethrow;
    }
  }

  String _contentTypeForFile(XFile file, String folder) {
    final name = file.name.toLowerCase();

    if (name.endsWith('.m4a')) {
      return 'audio/mp4';
    }
    if (name.endsWith('.webm') || (folder == 'voices' && kIsWeb)) {
      return 'audio/webm';
    }
    if (folder == 'voices') {
      return 'audio/mp4';
    }
    if (name.endsWith('.png')) {
      return 'image/png';
    }
    if (name.endsWith('.webp')) {
      return 'image/webp';
    }
    if (name.endsWith('.gif')) {
      return 'image/gif';
    }

    return 'image/jpeg';
  }
}

final mediaServiceProvider = Provider((ref) => MediaService(ref));
