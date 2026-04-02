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

      // 2. Parse the description and localize URLs for emulators.
      final description =
          jsonDecode(uploadDescriptionJson) as Map<String, dynamic>;
      description['url'] = _localizeUrl(description['url'] as String? ?? '');
      if ((description['publicUrl'] as String?)?.isNotEmpty == true) {
        description['publicUrl'] = _localizeUrl(
          description['publicUrl'] as String,
        );
      }

      final uploadUrl = description['url'] as String? ?? '';
      final uploadPath =
          description['path'] as String? ??
          _extractPathFromUploadUrl(uploadUrl);
      final publicUrl = _resolvePublicUrl(description);

      if (uploadUrl.isEmpty || uploadPath == null || uploadPath.isEmpty) {
        debugPrint(
          'MediaService: Invalid upload description: $uploadDescriptionJson',
        );
        throw Exception('Server provided an incomplete upload authorization.');
      }

      debugPrint('MediaService: Starting direct upload to storage: $uploadUrl');

      // 3. Perform the direct upload using Serverpod's binary upload format.
      final uploadMethod = (description['method'] as String? ?? 'POST')
          .toUpperCase();
      final request = http.Request(uploadMethod, Uri.parse(uploadUrl));
      request.headers.addAll({
        'Content-Type': _contentTypeForFile(file, folder),
        'Accept': '*/*',
        ...(description['headers'] as Map? ?? {}).cast<String, String>(),
      });
      request.bodyBytes = bytes;

      final httpClient = http.Client();
      try {
        final response = await httpClient
            .send(request)
            .timeout(
              const Duration(seconds: 20),
              onTimeout: () => throw Exception('Storage upload timed out.'),
            );
        debugPrint(
          'MediaService: Storage upload response status: ${response.statusCode}',
        );
        await response.stream.drain();
        final uploadSucceeded =
            response.statusCode == 200 ||
            response.statusCode == 201 ||
            response.statusCode == 204;

        if (!uploadSucceeded) {
          throw Exception('Storage upload failed.');
        }
      } finally {
        httpClient.close();
      }

      // 4. Confirm the upload with the server so it becomes publicly visible.
      final verified = await client.media.verifyUpload(uploadPath);
      if (!verified) {
        throw Exception('Server could not verify the uploaded file.');
      }

      final resolvedPublicUrl = publicUrl.isNotEmpty
          ? publicUrl
          : _derivePublicUrl(uploadUrl: uploadUrl, uploadPath: uploadPath);
      if (resolvedPublicUrl.isEmpty) {
        throw Exception('Server did not provide a usable public media URL.');
      }

      debugPrint(
        'MediaService: Upload successful! Public URL: $resolvedPublicUrl',
      );
      return UploadResult(url: resolvedPublicUrl, sizeInBytes: sizeInBytes);
    } catch (e, stack) {
      debugPrint('MediaService: CRITICAL ERROR during upload: $e');
      debugPrint('MediaService: Stack trace: $stack');
      rethrow;
    }
  }

  /// Fixes 'localhost' to '10.0.2.2' for Android emulators in debug mode.
  String _localizeUrl(String url) {
    if (kDebugMode && !kIsWeb) {
      if (defaultTargetPlatform == TargetPlatform.android &&
          url.contains('localhost')) {
        return url.replaceAll('localhost', '10.0.2.2');
      }
    }
    return url;
  }

  String? _extractPathFromUploadUrl(String uploadUrl) {
    final uri = Uri.tryParse(uploadUrl);
    return uri?.queryParameters['path'];
  }

  String _resolvePublicUrl(Map<String, dynamic> description) {
    final publicUrl = description['publicUrl'] as String? ?? '';
    if (publicUrl.isNotEmpty) return publicUrl;

    final uploadUrl = description['url'] as String? ?? '';
    final uploadPath =
        description['path'] as String? ?? _extractPathFromUploadUrl(uploadUrl);
    if (uploadPath == null || uploadPath.isEmpty) return '';

    return _derivePublicUrl(uploadUrl: uploadUrl, uploadPath: uploadPath);
  }

  String _derivePublicUrl({
    required String uploadUrl,
    required String uploadPath,
  }) {
    final uri = Uri.tryParse(uploadUrl);
    if (uri == null) return '';

    if (uri.path == '/serverpod_cloud_storage') {
      return uri
          .replace(queryParameters: {'method': 'file', 'path': uploadPath})
          .toString();
    }

    return uri.replace(query: '', queryParameters: {}).toString();
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
