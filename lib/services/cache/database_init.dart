import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// Conditional import - only available when building for web
// When building for mobile, this will import a stub that doesn't define databaseFactoryFfiWeb
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart'
    if (dart.library.io) '_database_factory_stub.dart';

/// Platform-agnostic database initializer
class DatabaseInit {
  static bool _initialized = false;

  /// Initialize the database factory for the current platform
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (kIsWeb) {
        await _initializeWeb();
      } else {
        await _initializeMobile();
      }

      _initialized = true;

      if (kDebugMode) {
        print('DatabaseInit: Database factory initialization completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DatabaseInit: Failed to initialize database factory: $e');
      }
      rethrow;
    }
  }

  /// Initialize web-specific database factory
  static Future<void> _initializeWeb() async {
    try {
      // This code will only run on web platforms
      // The databaseFactoryFfiWeb will only be available when building for web
      databaseFactory = databaseFactoryFfiWeb;
      if (kDebugMode) {
        print('DatabaseInit: Web database factory initialized');
      }
    } catch (e) {
      throw Exception(
          'Failed to initialize web database. Make sure sqflite_common_ffi_web is properly configured. '
          'You may need to run: dart run sqflite_common_ffi_web:setup\n'
          'Original error: $e');
    }
  }

  /// Initialize mobile-specific database factory
  static Future<void> _initializeMobile() async {
    // For mobile platforms (Android/iOS), the default sqflite factory is already set
    // No additional setup required
    if (kDebugMode) {
      print('DatabaseInit: Using default mobile database factory');
    }
  }

  /// Get platform-specific database path
  static Future<String> getDatabasePath(String databaseName) async {
    if (kIsWeb) {
      // For web platforms, just use the database name
      return databaseName;
    } else {
      // For mobile platforms, use the standard databases directory
      final databasesPath = await getDatabasesPath();
      return join(databasesPath, databaseName);
    }
  }

  /// Check if the database factory has been initialized
  static bool get isInitialized => _initialized;

  /// Reset initialization state (mainly for testing)
  static void reset() {
    _initialized = false;
  }
}
