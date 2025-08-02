import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Improved consent manager that ensures non-blocking initialization
/// and proper handling of both personalized and non-personalized ads
class ImprovedConsentManager {
  static ImprovedConsentManager? _instance;
  static ImprovedConsentManager get instance =>
      _instance ??= ImprovedConsentManager._();

  ImprovedConsentManager._();

  // State management
  bool _isInitialized = false;
  bool _isInitializing = false;
  ConsentStatus _currentStatus = ConsentStatus.unknown;
  bool _canRequestAds = false;
  DateTime? _lastUpdateTime;

  // Retry configuration
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  static const Duration _initTimeout = Duration(seconds: 5);

  // Cache keys
  static const String _cachePrefix = 'improved_consent_';
  static const String _statusKey = '${_cachePrefix}status';
  static const String _canRequestKey = '${_cachePrefix}can_request';
  static const String _lastUpdateKey = '${_cachePrefix}last_update';

  // Debug configuration
  static const bool _bypassConsentInDebug = true;

  // Platform-specific configuration
  bool get _isWebPlatform => kIsWeb;

  /// Initialize consent manager without blocking app startup
  /// Returns immediately and initializes in background
  void initializeAsync() {
    if (_isInitialized || _isInitializing) return;

    // Start initialization in background
    _initializeInBackground();
  }

  /// Background initialization with retry logic
  Future<void> _initializeInBackground() async {
    _isInitializing = true;

    try {
      // First, load cached values for immediate availability
      await _loadCachedValues();

      // Check if we're on web platform
      if (_isWebPlatform) {
        _log('Web platform detected - using web-safe consent handling');
        _setWebSafeDefaults();
        _isInitialized = true;
        return;
      }

      // Then update from UMP SDK with retries (mobile platforms only)
      bool success = false;
      for (int retry = 0; retry < _maxRetries && !success; retry++) {
        if (retry > 0) {
          _log(
              'Retrying consent initialization (attempt ${retry + 1}/$_maxRetries)');
          await Future.delayed(_retryDelay);
        }

        success = await _updateConsentInfo();
      }

      if (!success) {
        _logError('Failed to update consent after $_maxRetries attempts');
        // Fall back to cached values or safe defaults
        _setFallbackValues();
      }

      _isInitialized = true;
      _log('Consent manager initialized (success: $success)');
    } catch (e) {
      _logError('Critical error in initialization: $e');
      _setFallbackValues();
      _isInitialized = true;
    } finally {
      _isInitializing = false;
    }
  }

  /// Load cached consent values for immediate use
  Future<void> _loadCachedValues() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load cached status
      final statusIndex = prefs.getInt(_statusKey);
      if (statusIndex != null) {
        _currentStatus = ConsentStatus.values[statusIndex];
      }

      // Load cached can request ads
      _canRequestAds = prefs.getBool(_canRequestKey) ?? false;

      // Load last update time
      final updateTimestamp = prefs.getInt(_lastUpdateKey);
      if (updateTimestamp != null) {
        _lastUpdateTime = DateTime.fromMillisecondsSinceEpoch(updateTimestamp);
      }

      _log(
          'Loaded cached values - Status: $_currentStatus, CanRequest: $_canRequestAds');
    } catch (e) {
      _logError('Failed to load cached values: $e');
    }
  }

  /// Update consent information from UMP SDK
  Future<bool> _updateConsentInfo() async {
    try {
      // Skip UMP SDK on web platforms
      if (_isWebPlatform) {
        _log('Skipping UMP SDK update on web platform');
        return true;
      }

      final completer = Completer<bool>();

      // Configure debug settings
      ConsentDebugSettings? debugSettings;
      if (kDebugMode && !_bypassConsentInDebug) {
        debugSettings = ConsentDebugSettings(
          debugGeography: DebugGeography.debugGeographyEea,
          testIdentifiers: [],
        );
      }

      final params = ConsentRequestParameters(
        consentDebugSettings: debugSettings,
      );

      // Request consent info update with timeout
      ConsentInformation.instance.requestConsentInfoUpdate(
        params,
        () async {
          // Success callback
          await _onConsentInfoUpdated();
          if (!completer.isCompleted) {
            completer.complete(true);
          }
        },
        (FormError error) {
          // Error callback
          _logError('UMP update error: ${error.message}');
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
      );

      // Apply timeout to prevent indefinite waiting
      return await completer.future.timeout(
        _initTimeout,
        onTimeout: () {
          _logError('Consent info update timed out');
          if (!completer.isCompleted) {
            return false;
          }
          return completer.future;
        },
      );
    } catch (e) {
      _logError('Exception updating consent info: $e');
      return false;
    }
  }

  /// Handle successful consent info update
  Future<void> _onConsentInfoUpdated() async {
    try {
      // Get updated values
      _currentStatus = await ConsentInformation.instance.getConsentStatus();
      _canRequestAds = await ConsentInformation.instance.canRequestAds();
      _lastUpdateTime = DateTime.now();

      // Cache the values
      await _cacheValues();

      _log(
          'Consent info updated - Status: $_currentStatus, CanRequest: $_canRequestAds');

      // Check if we need to show consent form
      if (_shouldAutoShowConsentForm()) {
        // Show form asynchronously without blocking
        _showConsentFormAsync();
      }
    } catch (e) {
      _logError('Error processing consent update: $e');
    }
  }

  /// Cache current values for offline use
  Future<void> _cacheValues() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_statusKey, _currentStatus.index);
      await prefs.setBool(_canRequestKey, _canRequestAds);
      if (_lastUpdateTime != null) {
        await prefs.setInt(
            _lastUpdateKey, _lastUpdateTime!.millisecondsSinceEpoch);
      }
    } catch (e) {
      _logError('Failed to cache values: $e');
    }
  }

  /// Set fallback values when initialization fails
  void _setFallbackValues() {
    if (kDebugMode && _bypassConsentInDebug) {
      // In debug mode with bypass, allow all ads
      _currentStatus = ConsentStatus.obtained;
      _canRequestAds = true;
      _log('Debug mode: Using permissive fallback values');
    } else {
      // In production or without bypass, use conservative defaults
      // Allow non-personalized ads only
      _currentStatus = ConsentStatus.required;
      _canRequestAds = true; // Still allow non-personalized ads
      _log('Using conservative fallback values');
    }
  }

  /// Set web-safe default values for web platforms
  void _setWebSafeDefaults() {
    if (kDebugMode) {
      // In debug mode on web, allow all ads for testing
      _currentStatus = ConsentStatus.obtained;
      _canRequestAds = true;
      _log('Web platform debug mode: Using permissive values');
    } else {
      // In production on web, use safe defaults
      // Since UMP SDK is not fully supported on web, assume consent not required
      // but only allow non-personalized ads to be safe
      _currentStatus = ConsentStatus.notRequired;
      _canRequestAds = true;
      _log('Web platform: Using web-safe default values');
    }
    _lastUpdateTime = DateTime.now();
  }

  /// Check if consent form should be shown automatically
  bool _shouldAutoShowConsentForm() {
    return _currentStatus == ConsentStatus.required ||
        _currentStatus == ConsentStatus.unknown;
  }

  /// Show consent form asynchronously
  void _showConsentFormAsync() {
    // Don't await - let it run in background
    _showConsentForm().catchError((e) {
      _logError('Background consent form error: $e');
      return false;
    });
  }

  /// Show consent form with proper error handling
  Future<bool> _showConsentForm() async {
    try {
      // Skip consent form on web platforms
      if (_isWebPlatform) {
        _log('Consent form not supported on web platform');
        return false;
      }

      // Check if form is available
      final isAvailable =
          await ConsentInformation.instance.isConsentFormAvailable();
      if (!isAvailable) {
        _log('Consent form not available');
        return false;
      }

      final completer = Completer<bool>();

      // Load consent form
      ConsentForm.loadConsentForm(
        (ConsentForm consentForm) {
          // Form loaded, now show it
          consentForm.show((FormError? error) async {
            if (error != null) {
              _logError('Error showing form: ${error.message}');
              if (!completer.isCompleted) {
                completer.complete(false);
              }
            } else {
              _log('Consent form closed by user');
              // Update consent status after form
              await _onConsentInfoUpdated();
              if (!completer.isCompleted) {
                completer.complete(true);
              }
            }
          });
        },
        (FormError error) {
          _logError('Failed to load form: ${error.message}');
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
      );

      return await completer.future;
    } catch (e) {
      _logError('Exception showing consent form: $e');
      return false;
    }
  }

  /// Get current consent status (immediate, non-blocking)
  ConsentStatus get consentStatus => _currentStatus;

  /// Check if ads can be requested (immediate, non-blocking)
  bool get canRequestAds {
    if (kDebugMode && _bypassConsentInDebug) {
      return true;
    }
    if (_isWebPlatform) {
      // On web, always allow non-personalized ads
      return true;
    }
    return _canRequestAds;
  }

  /// Check if personalized ads can be shown
  bool get canShowPersonalizedAds {
    if (kDebugMode && _bypassConsentInDebug) {
      return true;
    }
    if (_isWebPlatform) {
      // On web, be conservative and only allow personalized ads in debug mode
      return kDebugMode;
    }
    return _currentStatus == ConsentStatus.obtained ||
        _currentStatus == ConsentStatus.notRequired;
  }

  /// Check if non-personalized ads can be shown
  bool get canShowNonPersonalizedAds {
    if (kDebugMode && _bypassConsentInDebug) {
      return true;
    }
    if (_isWebPlatform) {
      // On web, always allow non-personalized ads
      return true;
    }
    // Always allow non-personalized ads if we can request ads at all
    return _canRequestAds;
  }

  /// Create ad request with appropriate parameters
  AdRequest createAdRequest({
    List<String>? keywords,
    String? contentUrl,
    Map<String, String>? customTargeting,
  }) {
    final Map<String, String> extras = {...?customTargeting};

    // Add non-personalized ads flag if needed
    if (!canShowPersonalizedAds && canShowNonPersonalizedAds) {
      extras['npa'] = '1';
      _log('Creating non-personalized ad request');
    } else {
      _log('Creating personalized ad request');
    }

    return AdRequest(
      keywords: keywords,
      contentUrl: contentUrl,
      extras: extras,
    );
  }

  /// Request consent manually (e.g., from privacy settings)
  Future<ConsentResult> requestConsentManually() async {
    try {
      // Ensure we're initialized
      if (!_isInitialized) {
        await _waitForInitialization();
      }

      // Update consent info first
      await _updateConsentInfo();

      // Show consent form
      final success = await _showConsentForm();

      return ConsentResult(
        success: success,
        status: _currentStatus,
        canRequestAds: _canRequestAds,
        canShowPersonalizedAds: canShowPersonalizedAds,
        canShowNonPersonalizedAds: canShowNonPersonalizedAds,
      );
    } catch (e) {
      _logError('Failed to request consent manually: $e');
      return ConsentResult(
        success: false,
        status: _currentStatus,
        canRequestAds: _canRequestAds,
        canShowPersonalizedAds: canShowPersonalizedAds,
        canShowNonPersonalizedAds: canShowNonPersonalizedAds,
      );
    }
  }

  /// Show privacy options form
  Future<bool> showPrivacyOptions() async {
    try {
      // Skip privacy options on web platforms
      if (_isWebPlatform) {
        _log('Privacy options form not supported on web platform');
        return false;
      }

      // Ensure we're initialized
      if (!_isInitialized) {
        await _waitForInitialization();
      }

      final completer = Completer<bool>();

      ConsentForm.showPrivacyOptionsForm((FormError? error) async {
        if (error != null) {
          _logError('Privacy options error: ${error.message}');
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        } else {
          // Update consent status after form
          await _onConsentInfoUpdated();
          if (!completer.isCompleted) {
            completer.complete(true);
          }
        }
      });

      return await completer.future;
    } catch (e) {
      _logError('Failed to show privacy options: $e');
      return false;
    }
  }

  /// Wait for initialization to complete
  Future<void> _waitForInitialization() async {
    if (_isInitialized) return;

    // Give it up to 10 seconds to initialize
    for (int i = 0; i < 100 && !_isInitialized; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (!_isInitialized) {
      _logError('Initialization timeout - using current values');
    }
  }

  /// Reset consent (for testing)
  Future<void> resetConsent() async {
    try {
      // Only reset UMP SDK on mobile platforms
      if (!_isWebPlatform) {
        ConsentInformation.instance.reset();
      }

      // Clear cached values
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_statusKey);
      await prefs.remove(_canRequestKey);
      await prefs.remove(_lastUpdateKey);

      // Reset state
      _currentStatus = ConsentStatus.unknown;
      _canRequestAds = false;
      _lastUpdateTime = null;
      _isInitialized = false;

      _log('Consent reset complete');

      // Re-initialize
      initializeAsync();
    } catch (e) {
      _logError('Failed to reset consent: $e');
    }
  }

  /// Get debug information
  Map<String, dynamic> getDebugInfo() {
    return {
      'initialized': _isInitialized,
      'initializing': _isInitializing,
      'platform': _isWebPlatform ? 'web' : 'mobile',
      'consentStatus': _currentStatus.toString(),
      'canRequestAds': _canRequestAds,
      'canShowPersonalizedAds': canShowPersonalizedAds,
      'canShowNonPersonalizedAds': canShowNonPersonalizedAds,
      'lastUpdate': _lastUpdateTime?.toIso8601String() ?? 'never',
      'debugMode': kDebugMode,
      'bypassInDebug': _bypassConsentInDebug,
    };
  }

  /// Logging helpers
  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[ImprovedConsent] $message');
    }
  }

  void _logError(String message) {
    debugPrint('[ImprovedConsent ERROR] $message');
  }
}

/// Result of consent request
class ConsentResult {
  final bool success;
  final ConsentStatus status;
  final bool canRequestAds;
  final bool canShowPersonalizedAds;
  final bool canShowNonPersonalizedAds;

  ConsentResult({
    required this.success,
    required this.status,
    required this.canRequestAds,
    required this.canShowPersonalizedAds,
    required this.canShowNonPersonalizedAds,
  });
}
