import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

  /// Uploads a file to Firebase Cloud Storage.
  /// Returns the public URL of the uploaded file.
  Future<String?> uploadFile(XFile file, String folder) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    final path = '$folder/$fileName';

    try {
      debugPrint('MediaService: Uploading to Firebase Storage at $path...');
      final storageRef = FirebaseStorage.instance.ref(path);
      
      // For cross-platform (Web & Mobile)
      final bytes = await file.readAsBytes();
      
      // Upload with metadata if needed
      final uploadTask = storageRef.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      debugPrint('MediaService: Upload successful. Download URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading file to Firebase: $e');
      rethrow;
    }
  }
}

final mediaServiceProvider = Provider((ref) => MediaService(ref));
