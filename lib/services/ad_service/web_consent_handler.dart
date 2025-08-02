import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:shared_preferences/shared_preferences.dart';

/// Web-specific consent handler for platforms where UMP SDK is not fully supported
/// Provides graceful fallback with basic consent management functionality
class WebConsentHandler {
  static WebConsentHandler? _instance;
  static WebConsentHandler get instance => _instance ??= WebConsentHandler._();

  WebConsentHandler._();

  // State management
  bool _isInitialized = false;
  WebConsentStatus _consentStatus = WebConsentStatus.unknown;
  bool _personalizedAdsAllowed = false;
  bool _nonPersonalizedAdsAllowed = true;
  DateTime? _lastUpdateTime;

  // Cache keys
  static const String _cachePrefix = 'web_consent_';
  static const String _statusKey = '${_cachePrefix}status';
  static const String _personalizedKey = '${_cachePrefix}personalized';
  static const String _nonPersonalizedKey = '${_cachePrefix}non_personalized';
  static const String _lastUpdateKey = '${_cachePrefix}last_update';
  static const String _userChoiceKey = '${_cachePrefix}user_choice_made';

  /// Initialize web consent handler
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _log('Initializing web consent handler...');

      // Load cached preferences
      await _loadCachedPreferences();

      // Set appropriate defaults based on mode and cached values
      _setWebDefaults();

      _isInitialized = true;
      _log('Web consent handler initialized successfully');
    } catch (e) {
      _logError('Failed to initialize web consent handler: $e');
      _setFallbackDefaults();
      _isInitialized = true;
    }
  }

  /// Load cached consent preferences
  Future<void> _loadCachedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load consent status
      final statusIndex = prefs.getInt(_statusKey);
      if (statusIndex != null && statusIndex < WebConsentStatus.values.length) {
        _consentStatus = WebConsentStatus.values[statusIndex];
      }

      // Load ad preferences
      _personalizedAdsAllowed = prefs.getBool(_personalizedKey) ?? false;
      _nonPersonalizedAdsAllowed = prefs.getBool(_nonPersonalizedKey) ?? true;

      // Load last update time
      final updateTimestamp = prefs.getInt(_lastUpdateKey);
      if (updateTimestamp != null) {
        _lastUpdateTime = DateTime.fromMillisecondsSinceEpoch(updateTimestamp);
      }

      _log(
          'Loaded cached preferences - Status: $_consentStatus, Personalized: $_personalizedAdsAllowed, Non-personalized: $_nonPersonalizedAdsAllowed');
    } catch (e) {
      _logError('Failed to load cached preferences: $e');
    }
  }

  /// Set web-appropriate defaults
  void _setWebDefaults() {
    if (kDebugMode) {
      // In debug mode, allow all ads for testing
      _consentStatus = WebConsentStatus.granted;
      _personalizedAdsAllowed = true;
      _nonPersonalizedAdsAllowed = true;
      _log('Debug mode: Using permissive consent defaults');
    } else if (_consentStatus == WebConsentStatus.unknown) {
      // In production, default to safe settings if no user choice has been made
      _consentStatus = WebConsentStatus.notRequired;
      _personalizedAdsAllowed = false;
      _nonPersonalizedAdsAllowed = true;
      _log('Production mode: Using safe consent defaults');
    }
    // If we have cached values from user choice, keep them

    _lastUpdateTime = DateTime.now();
  }

  /// Set fallback defaults when everything fails
  void _setFallbackDefaults() {
    _consentStatus = WebConsentStatus.notRequired;
    _personalizedAdsAllowed = kDebugMode;
    _nonPersonalizedAdsAllowed = true;
    _lastUpdateTime = DateTime.now();
    _log('Using fallback defaults due to initialization failure');
  }

  /// Cache current preferences
  Future<void> _cachePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_statusKey, _consentStatus.index);
      await prefs.setBool(_personalizedKey, _personalizedAdsAllowed);
      await prefs.setBool(_nonPersonalizedKey, _nonPersonalizedAdsAllowed);
      await prefs.setBool(_userChoiceKey, true);
      if (_lastUpdateTime != null) {
        await prefs.setInt(
            _lastUpdateKey, _lastUpdateTime!.millisecondsSinceEpoch);
      }
      _log('Preferences cached successfully');
    } catch (e) {
      _logError('Failed to cache preferences: $e');
    }
  }

  /// Update consent preferences (simulated user choice)
  Future<bool> updateConsentPreferences({
    required bool allowPersonalizedAds,
    required bool allowNonPersonalizedAds,
  }) async {
    try {
      _personalizedAdsAllowed = allowPersonalizedAds;
      _nonPersonalizedAdsAllowed = allowNonPersonalizedAds;

      if (allowPersonalizedAds) {
        _consentStatus = WebConsentStatus.granted;
      } else if (allowNonPersonalizedAds) {
        _consentStatus = WebConsentStatus.limitedGranted;
      } else {
        _consentStatus = WebConsentStatus.denied;
      }

      _lastUpdateTime = DateTime.now();
      await _cachePreferences();

      _log(
          'Consent preferences updated - Personalized: $allowPersonalizedAds, Non-personalized: $allowNonPersonalizedAds');
      return true;
    } catch (e) {
      _logError('Failed to update consent preferences: $e');
      return false;
    }
  }

  /// Reset consent preferences
  Future<void> resetConsent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_statusKey);
      await prefs.remove(_personalizedKey);
      await prefs.remove(_nonPersonalizedKey);
      await prefs.remove(_userChoiceKey);
      await prefs.remove(_lastUpdateKey);

      _consentStatus = WebConsentStatus.unknown;
      _personalizedAdsAllowed = false;
      _nonPersonalizedAdsAllowed = true;
      _lastUpdateTime = null;

      _log('Consent preferences reset');

      // Re-initialize with defaults
      _setWebDefaults();
      await _cachePreferences();
    } catch (e) {
      _logError('Failed to reset consent: $e');
    }
  }

  /// Check if ads can be requested
  bool get canRequestAds {
    return _personalizedAdsAllowed || _nonPersonalizedAdsAllowed;
  }

  /// Check if personalized ads can be shown
  bool get canShowPersonalizedAds {
    return _personalizedAdsAllowed;
  }

  /// Check if non-personalized ads can be shown
  bool get canShowNonPersonalizedAds {
    return _nonPersonalizedAdsAllowed;
  }

  /// Get current consent status
  WebConsentStatus get consentStatus => _consentStatus;

  /// Check if user has made a choice
  Future<bool> get hasUserMadeChoice async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_userChoiceKey) ?? false;
    } catch (e) {
      _logError('Failed to check user choice status: $e');
      return false;
    }
  }

  /// Create ad request parameters
  Map<String, String> createAdRequestExtras() {
    final Map<String, String> extras = {};

    // Add non-personalized ads flag if needed
    if (!canShowPersonalizedAds && canShowNonPersonalizedAds) {
      extras['npa'] = '1';
      _log('Creating non-personalized ad request');
    } else if (canShowPersonalizedAds) {
      _log('Creating personalized ad request');
    }

    return extras;
  }

  /// Get debug information
  Map<String, dynamic> getDebugInfo() {
    return {
      'platform': 'web',
      'initialized': _isInitialized,
      'consentStatus': _consentStatus.toString(),
      'canRequestAds': canRequestAds,
      'canShowPersonalizedAds': canShowPersonalizedAds,
      'canShowNonPersonalizedAds': canShowNonPersonalizedAds,
      'lastUpdate': _lastUpdateTime?.toIso8601String() ?? 'never',
      'debugMode': kDebugMode,
      'hasUserChoice': true, // We'll check this async when needed
    };
  }

  /// Get user-friendly status message
  String getStatusMessage() {
    switch (_consentStatus) {
      case WebConsentStatus.unknown:
        return 'Consent preferences not set';
      case WebConsentStatus.granted:
        return 'Personalized ads allowed';
      case WebConsentStatus.limitedGranted:
        return 'Non-personalized ads only';
      case WebConsentStatus.denied:
        return 'Ads blocked by user';
      case WebConsentStatus.notRequired:
        return 'Consent not required (web platform)';
    }
  }

  /// Show a simple consent dialog (web-friendly)
  Future<bool> showConsentDialog() async {
    // This is a placeholder for a web-friendly consent mechanism
    // In a real implementation, you might show a custom dialog
    // or redirect to a consent page
    _log('Showing web consent dialog (placeholder)');

    // For now, just update to safe defaults
    return await updateConsentPreferences(
      allowPersonalizedAds: kDebugMode,
      allowNonPersonalizedAds: true,
    );
  }

  /// Logging helpers
  void _log(String message) {
    if (kDebugMode) {
      print('[WebConsentHandler] $message');
    }
  }

  void _logError(String message) {
    print('[WebConsentHandler ERROR] $message');
  }
}

/// Web-specific consent status enum
enum WebConsentStatus {
  unknown,
  granted,
  limitedGranted,
  denied,
  notRequired,
}

/// Extension to get user-friendly names
extension WebConsentStatusExtension on WebConsentStatus {
  String get displayName {
    switch (this) {
      case WebConsentStatus.unknown:
        return 'Unknown';
      case WebConsentStatus.granted:
        return 'Granted';
      case WebConsentStatus.limitedGranted:
        return 'Limited';
      case WebConsentStatus.denied:
        return 'Denied';
      case WebConsentStatus.notRequired:
        return 'Not Required';
    }
  }
}
