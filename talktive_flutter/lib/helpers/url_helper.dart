import 'package:flutter/foundation.dart';

class UrlHelper {
  /// Transforms a URL to be reachable from the current device.
  /// Specifically, replaces 'localhost' with '10.0.2.2' for Android Emulators.
  static String resolve(String url) {
    if (url.isEmpty) return url;
    
    // For Android emulators, localhost refers to the emulator itself.
    // They need to use 10.0.2.2 to access the host machine.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android && url.contains('localhost')) {
      return url.replaceAll('localhost', '10.0.2.2');
    }
    
    return url;
  }
}
