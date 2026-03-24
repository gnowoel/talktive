import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  /// Uploads a file to Firebase Cloud Storage.
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

    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    final path = '$folder/$fileName';
    final contentType = _contentTypeForFile(file, folder);

    try {
      final storage = FirebaseStorage.instance;
      debugPrint('MediaService: Starting upload to bucket: ${storage.bucket}');
      debugPrint('MediaService: Destination path: $path');

      final storageRef = storage.ref(path);
      final metadata = SettableMetadata(contentType: contentType);

      TaskSnapshot snapshot;

      if (kIsWeb) {
        debugPrint('MediaService: Using putData for Web upload...');
        snapshot = await storageRef.putData(bytes, metadata);
      } else {
        debugPrint(
          'MediaService: Using putFile for Mobile upload. Path: ${file.path}',
        );
        // On mobile, putFile is more efficient and reliable
        snapshot = await storageRef.putFile(File(file.path), metadata);
      }

      debugPrint(
        'MediaService: Upload task completed. Status: ${snapshot.state}',
      );
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint(
        'MediaService: Successfully generated Download URL: $downloadUrl',
      );
      return UploadResult(url: downloadUrl, sizeInBytes: sizeInBytes);
    } catch (e, stack) {
      debugPrint('MediaService: CRITICAL ERROR during upload: $e');
      debugPrint('MediaService: Stack trace: $stack');
      rethrow;
    }
  }

  String _contentTypeForFile(XFile file, String folder) {
    final name = file.name.toLowerCase();

    if (folder == 'voices' || name.endsWith('.m4a')) {
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
