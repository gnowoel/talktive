import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:serverpod_client/serverpod_client.dart';
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
          MediaService.extractUploadPath(uploadUrl);
      final publicUrl = MediaService.resolvePublicUrlFromDescription(
        description,
      );

      if (uploadUrl.isEmpty || uploadPath == null || uploadPath.isEmpty) {
        debugPrint(
          'MediaService: Invalid upload description: $uploadDescriptionJson',
        );
        throw Exception('Server provided an incomplete upload authorization.');
      }

      debugPrint('MediaService: Starting direct upload to storage: $uploadUrl');

      final uploadType = description['type'] as String? ?? 'binary';
      if (uploadType == 'binary') {
        description['headers'] = {
          ...(description['headers'] as Map? ?? {}).cast<String, String>(),
          'Content-Type':
              ((description['headers'] as Map?)
                  ?.cast<String, String>()['Content-Type'] ??
              _contentTypeForFile(file, folder)),
        };
      }

      // 3. Perform the direct upload using Serverpod's production-safe uploader.
      final uploadSucceeded = await FileUploader(jsonEncode(description))
          .uploadByteData(ByteData.sublistView(bytes))
          .timeout(
            const Duration(seconds: 60),
            onTimeout: () => throw Exception('Storage upload timed out.'),
          );

      if (!uploadSucceeded) {
        throw Exception('Storage upload failed.');
      }

      // 4. Confirm the upload with the server so it becomes publicly visible.
      final verified = await client.media.verifyUpload(uploadPath);
      if (!verified) {
        throw Exception('Server could not verify the uploaded file.');
      }

      final resolvedPublicUrl = publicUrl.isNotEmpty
          ? publicUrl
          : MediaService.derivePublicUrl(
              uploadUrl: uploadUrl,
              uploadPath: uploadPath,
            );
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

  @visibleForTesting
  static String? extractUploadPath(String uploadUrl) {
    final uri = Uri.tryParse(uploadUrl);
    return uri?.queryParameters['path'];
  }

  @visibleForTesting
  static String resolvePublicUrlFromDescription(
    Map<String, dynamic> description,
  ) {
    final publicUrl = description['publicUrl'] as String? ?? '';
    if (publicUrl.isNotEmpty) return publicUrl;

    final uploadUrl = description['url'] as String? ?? '';
    final uploadPath =
        description['path'] as String? ?? extractUploadPath(uploadUrl);
    if (uploadPath == null || uploadPath.isEmpty) return '';

    return derivePublicUrl(uploadUrl: uploadUrl, uploadPath: uploadPath);
  }

  @visibleForTesting
  static String derivePublicUrl({
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

    final normalizedUploadPath = uploadPath.startsWith('/')
        ? uploadPath.substring(1)
        : uploadPath;
    final currentPath = uri.path;
    final currentSegments = currentPath.split('/').where((s) => s.isNotEmpty);
    final uploadSegments = normalizedUploadPath
        .split('/')
        .where((s) => s.isNotEmpty);

    final resolvedPath = currentPath.isEmpty || currentPath == '/'
        ? '/$normalizedUploadPath'
        : currentSegments.join('/') == uploadSegments.join('/')
        ? '/${currentSegments.join('/')}'
        : currentPath.endsWith('/')
        ? '$currentPath$normalizedUploadPath'
        : '$currentPath/$normalizedUploadPath';

    return Uri(
      scheme: uri.scheme,
      userInfo: uri.userInfo,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
      path: resolvedPath,
    ).toString();
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
