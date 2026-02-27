import 'dart:typed_data';
import 'package:serverpod/serverpod.dart';
import 'package:image/image.dart' as img;

/// Service for validating uploaded images.
///
/// Validates:
/// - File size
/// - File format (magic bytes, not just extension)
/// - Image dimensions
/// - Aspect ratio
/// - Content (basic checks, no ML)
class ImageValidationService {
  // Configuration
  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5MB
  static const int maxWidth = 4096;
  static const int maxHeight = 4096;
  static const int minWidth = 100;
  static const int minHeight = 100;
  static const double maxAspectRatio = 3.0; // 3:1 or 1:3

  /// Validates an image file.
  /// Returns null if valid, error message if invalid.
  static Future<String?> validateImage(
    Session session,
    Uint8List imageBytes,
    String fileName,
  ) async {
    try {
      // 1. Check file size
      if (imageBytes.length > maxFileSizeBytes) {
        return 'Image too large. Maximum size is 5MB.';
      }

      if (imageBytes.length < 100) {
        return 'Image file is too small or corrupted.';
      }

      // 2. Decode image to verify it's a valid image
      img.Image? image;
      try {
        image = img.decodeImage(imageBytes);
      } catch (e) {
        return 'Invalid image file. Could not decode image.';
      }

      if (image == null) {
        return 'Invalid image file. Unsupported format.';
      }

      // 3. Check dimensions
      if (image.width > maxWidth || image.height > maxHeight) {
        return 'Image dimensions too large. Maximum is ${maxWidth}x$maxHeight pixels.';
      }

      if (image.width < minWidth || image.height < minHeight) {
        return 'Image dimensions too small. Minimum is ${minWidth}x$minHeight pixels.';
      }

      // 4. Check aspect ratio (prevent extremely wide or tall images)
      final aspectRatio = image.width / image.height;
      if (aspectRatio > maxAspectRatio || aspectRatio < (1 / maxAspectRatio)) {
        return 'Image aspect ratio is too extreme. Please use a more balanced image.';
      }

      // 5. Verify file format by magic bytes
      final format = _detectImageFormat(imageBytes);
      if (format == null) {
        return 'Unsupported image format. Please use JPEG, PNG, or WebP.';
      }

      // 6. Basic content validation (check for solid colors, etc.)
      if (_isSolidColor(image)) {
        return 'Image appears to be a solid color. Please upload a real image.';
      }

      // All checks passed
      return null;
    } catch (e) {
      session.log('Image validation error: $e', level: LogLevel.error);
      return 'Failed to validate image. Please try again.';
    }
  }

  /// Detects image format by magic bytes.
  static String? _detectImageFormat(Uint8List bytes) {
    if (bytes.length < 12) return null;

    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return 'jpeg';
    }

    // PNG: 89 50 4E 47 0D 0A 1A 0A
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'png';
    }

    // WebP: RIFF .... WEBP
    if (bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'webp';
    }

    return null;
  }

  /// Checks if image is a solid color (likely spam/test).
  static bool _isSolidColor(img.Image image) {
    // Sample pixels to check for variation
    const sampleSize = 100;
    final step = (image.width * image.height) ~/ sampleSize;

    if (step == 0) return false;

    img.Pixel? firstPixel;
    int sampleCount = 0;

    for (
      int i = 0;
      i < image.width * image.height && sampleCount < sampleSize;
      i += step
    ) {
      final x = i % image.width;
      final y = i ~/ image.width;

      if (y >= image.height) break;

      final pixel = image.getPixel(x, y);

      if (firstPixel == null) {
        firstPixel = pixel;
      } else {
        // Check if pixel is significantly different
        final rDiff = (pixel.r - firstPixel.r).abs();
        final gDiff = (pixel.g - firstPixel.g).abs();
        final bDiff = (pixel.b - firstPixel.b).abs();

        if (rDiff > 10 || gDiff > 10 || bDiff > 10) {
          return false; // Found variation, not solid color
        }
      }

      sampleCount++;
    }

    // If we got here, all sampled pixels are very similar
    return true;
  }

  /// Optimizes an image (resize if too large, compress).
  static Future<Uint8List> optimizeImage(
    img.Image image, {
    int maxWidth = 2048,
    int maxHeight = 2048,
    int quality = 85,
  }) async {
    // Resize if needed
    if (image.width > maxWidth || image.height > maxHeight) {
      image = img.copyResize(
        image,
        width: image.width > maxWidth ? maxWidth : null,
        height: image.height > maxHeight ? maxHeight : null,
        interpolation: img.Interpolation.average,
      );
    }

    // Encode as JPEG with compression
    return Uint8List.fromList(img.encodeJpg(image, quality: quality));
  }

  /// Generates a thumbnail from an image.
  static Future<Uint8List> generateThumbnail(
    img.Image image, {
    int size = 256,
  }) async {
    // Create square thumbnail
    final thumbnail = img.copyResizeCropSquare(image, size: size);
    return Uint8List.fromList(img.encodeJpg(thumbnail, quality: 80));
  }
}
