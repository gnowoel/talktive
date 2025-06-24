// Stub file for mobile builds - provides placeholder for web-only symbols
// This file is used when building for mobile platforms (Android/iOS)
// to prevent compilation errors from undefined web-specific symbols

import 'package:sqflite/sqflite.dart';

// Placeholder for web-specific database factory
// This will never be used on mobile platforms, but prevents compilation errors
final DatabaseFactory databaseFactoryFfiWeb = databaseFactory;
