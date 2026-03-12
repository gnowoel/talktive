import 'package:flutter/foundation.dart';

class UrlHelper {
  /// Transforms a URL to be reachable from the current device.
  /// Replaces 'localhost' with '10.0.2.2' for Android Emulators.
  /// Replaces '10.0.2.2' with 'localhost' for Web and other platforms.
  static String resolve(String url) {
    if (url.isEmpty) return url;

    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

    if (isAndroid && url.contains('localhost')) {
      return url.replaceAll('localhost', '10.0.2.2');
    }

    if (!isAndroid && url.contains('10.0.2.2')) {
      return url.replaceAll('10.0.2.2', 'localhost');
    }

    return url;
  }
}
