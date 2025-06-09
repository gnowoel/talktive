import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReportCacheService {
  ReportCacheService._();
  static final ReportCacheService _instance = ReportCacheService._();
  factory ReportCacheService() => _instance;

  static const String _cacheKey = 'reported_messages_cache';
  static const Duration _cacheExpiration = Duration(hours: 24);

  Map<String, DateTime> _reportedMessages = {};
  bool _initialized = false;

  /// Initialize the cache by loading from SharedPreferences
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = prefs.getString(_cacheKey);
      
      if (cacheJson != null) {
        final Map<String, dynamic> cacheData = jsonDecode(cacheJson);
        _reportedMessages = cacheData.map(
          (key, value) => MapEntry(key, DateTime.parse(value as String)),
        );
      }

      // Clean up expired entries after loading
      await _cleanupExpiredEntries();
      _initialized = true;
    } catch (e) {
      debugPrint('Error initializing ReportCacheService: $e');
      _reportedMessages = {};
      _initialized = true;
    }
  }

  /// Add a reported message ID to the cache
  Future<void> addReportedMessage(String messageId) async {
    await _ensureInitialized();

    _reportedMessages[messageId] = DateTime.now();
    await _saveToPreferences();
  }

  /// Check if a message ID has been reported recently (within 24 hours)
  Future<bool> isRecentlyReported(String messageId) async {
    await _ensureInitialized();
    await _cleanupExpiredEntries();

    return _reportedMessages.containsKey(messageId);
  }

  /// Get the timestamp when a message was reported
  Future<DateTime?> getReportTimestamp(String messageId) async {
    await _ensureInitialized();
    await _cleanupExpiredEntries();

    return _reportedMessages[messageId];
  }

  /// Get the number of currently cached reported messages
  Future<int> getCachedReportsCount() async {
    await _ensureInitialized();
    await _cleanupExpiredEntries();

    return _reportedMessages.length;
  }

  /// Clear all cached reported messages
  Future<void> clearCache() async {
    await _ensureInitialized();

    _reportedMessages.clear();
    await _saveToPreferences();
  }

  /// Remove expired entries from the cache
  Future<void> _cleanupExpiredEntries() async {
    final now = DateTime.now();
    final expiredIds = <String>[];

    for (final entry in _reportedMessages.entries) {
      if (now.difference(entry.value) > _cacheExpiration) {
        expiredIds.add(entry.key);
      }
    }

    if (expiredIds.isNotEmpty) {
      for (final id in expiredIds) {
        _reportedMessages.remove(id);
      }
      await _saveToPreferences();
      debugPrint('Cleaned up ${expiredIds.length} expired report cache entries');
    }
  }

  /// Save the current cache to SharedPreferences
  Future<void> _saveToPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = _reportedMessages.map(
        (key, value) => MapEntry(key, value.toIso8601String()),
      );
      await prefs.setString(_cacheKey, jsonEncode(cacheData));
    } catch (e) {
      debugPrint('Error saving report cache: $e');
    }
  }

  /// Ensure the service is initialized before use
  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await initialize();
    }
  }

  /// Get all currently cached message IDs for debugging
  @visibleForTesting
  Future<Map<String, DateTime>> getAllCachedReports() async {
    await _ensureInitialized();
    await _cleanupExpiredEntries();

    return Map.unmodifiable(_reportedMessages);
  }
}
