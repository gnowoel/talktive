import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// Conditional imports for different platforms
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart'
    if (dart.library.io) 'package:sqflite/sqflite.dart';

/// Platform-agnostic database initializer
class DatabaseInit {
  static bool _initialized = false;

  /// Initialize the database factory for the current platform
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (kIsWeb) {
        // For web platform, use the web-specific factory
        databaseFactory = databaseFactoryFfiWeb;
        if (kDebugMode) {
          print('DatabaseInit: Web database factory initialized');
        }
      } else {
        // For mobile platforms, the default sqflite factory is already set
        // No additional setup required
        if (kDebugMode) {
          print('DatabaseInit: Using default mobile database factory');
        }
      }

      _initialized = true;

      if (kDebugMode) {
        print('DatabaseInit: Database factory initialization completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('DatabaseInit: Failed to initialize database factory: $e');
      }

      // For web, provide a more helpful error message
      if (kIsWeb) {
        throw Exception(
            'Failed to initialize web database. Make sure sqflite_common_ffi_web is properly configured. '
            'You may need to run: dart run sqflite_common_ffi_web:setup\n'
            'Original error: $e');
      }

      rethrow;
    }
  }

  /// Check if the database factory has been initialized
  static bool get isInitialized => _initialized;

  /// Reset initialization state (mainly for testing)
  static void reset() {
    _initialized = false;
  }

  /// Get platform-specific database path
  static Future<String> getDatabasePath(String databaseName) async {
    if (kIsWeb) {
      // For web, just use the database name
      return databaseName;
    } else {
      // For mobile, use the standard databases directory
      final databasesPath = await getDatabasesPath();
      return join(databasesPath, databaseName);
    }
  }
}
