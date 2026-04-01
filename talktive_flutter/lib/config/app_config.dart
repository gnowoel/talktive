import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppConfig {
  AppConfig._({
    required this.serverpodUrl,
    required this.useFirebaseEmulators,
    required this.firebaseEmulatorHost,
  });

  final String serverpodUrl;
  final bool useFirebaseEmulators;
  final String firebaseEmulatorHost;

  static AppConfig? _instance;

  static AppConfig get instance {
    final config = _instance;
    if (config == null) {
      throw StateError('AppConfig has not been initialized.');
    }
    return config;
  }

  static Future<void> initialize() async {
    if (_instance != null) return;

    const serverpodUrlOverride = String.fromEnvironment('SERVERPOD_URL');
    const useFirebaseEmulatorsOverride = bool.fromEnvironment(
      'USE_FIREBASE_EMULATORS',
      defaultValue: kDebugMode,
    );

    final assetConfig = await _loadAssetConfig();
    final fallbackLocalUrl = kIsWeb
        ? 'http://localhost:8080'
        : 'http://10.0.2.2:8080';
    final assetUrl = (assetConfig['apiUrl'] as String?)?.trim();
    final configuredUrl = serverpodUrlOverride.isNotEmpty
        ? serverpodUrlOverride
        : kDebugMode
        ? fallbackLocalUrl
        : assetUrl;

    _instance = AppConfig._(
      serverpodUrl: configuredUrl == null || configuredUrl.isEmpty
          ? fallbackLocalUrl
          : configuredUrl,
      useFirebaseEmulators: useFirebaseEmulatorsOverride,
      firebaseEmulatorHost: kIsWeb ? 'localhost' : '10.0.2.2',
    );
  }

  static Future<Map<String, dynamic>> _loadAssetConfig() async {
    try {
      final jsonString = await rootBundle.loadString('assets/config.json');
      final decoded = json.decode(jsonString);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      // Ignore missing or malformed local config and fall back to defaults.
    }
    return const <String, dynamic>{};
  }
}
