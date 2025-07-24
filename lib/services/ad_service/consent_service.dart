import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admob_compliance.dart';

/// Simplified Consent Management Service for GDPR compliance
///
/// This service handles user consent for personalized ads using Google's UMP SDK.
/// It's designed to be robust, simple, and fail gracefully without breaking ads.
class ConsentService {
  static ConsentService? _instance;
  static ConsentService get instance => _instance ??= ConsentService._();

  ConsentService._();

  // Storage keys
  static const String _consentStatusKey = 'consent_status';
  static const String _lastConsentRequestKey = 'last_consent_request';
  static const String _userRegionKey = 'user_region';

  // Configuration
  static const bool _forceEeaTesting =
      false; // Set to true ONLY for GDPR testing
  static const bool _disableConsentInDebug =
      true; // Disable consent requirements in debug mode for easier testing

  // Simple state management
  bool _isInitialized = false;
  bool _isInitializing = false;
  String? _initializationError;

  /// Initialize the consent service
  /// Returns true if successful, false if failed (but ads can still work)
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    if (_isInitializing) {
      // Wait for ongoing initialization
      while (_isInitializing && !_isInitialized) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _isInitialized;
    }

    _isInitializing = true;
    _initializationError = null;

    try {
      await _updateConsentInformation();
      _isInitialized = true;
      _log('Consent service initialized successfully');
      return true;
    } catch (e) {
      _initializationError = e.toString();
      _logError('Consent service initialization failed: $e');
      return false;
    } finally {
      _isInitializing = false;
    }
  }

  /// Update consent information from Google UMP
  Future<void> _updateConsentInformation() async {
    final completer = Completer<void>();

    // Configure debug settings if needed
    ConsentDebugSettings? debugSettings;
    if (kDebugMode) {
      if (_forceEeaTesting) {
        debugSettings = ConsentDebugSettings(
          debugGeography: DebugGeography.debugGeographyEea,
          testIdentifiers: [], // Add test device IDs if needed
        );
        _log('Debug mode: Forcing EEA geography for testing');
      } else if (_disableConsentInDebug) {
        debugSettings = ConsentDebugSettings(
          debugGeography: DebugGeography.debugGeographyNotEea,
          testIdentifiers: [], // Add test device IDs if needed
        );
        _log('Debug mode: Disabling consent requirements for easier testing');
      }
    }

    final params = ConsentRequestParameters(
      consentDebugSettings: debugSettings,
    );

    // Request consent info update
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        try {
          await _cacheRegionInfo();
          _log('Consent information updated successfully');
          completer.complete();
        } catch (e) {
          _logError('Failed to cache region info: $e');
          completer.complete(); // Complete anyway
        }
      },
      (FormError error) {
        _logError('UMP consent info update failed: ${error.message}');
        completer.complete(); // Complete anyway to not block
      },
    );

    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _logError('Consent info update timed out');
        // Don't throw - just continue
      },
    );
  }

  /// Cache region information for faster access
  Future<void> _cacheRegionInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final status = await ConsentInformation.instance.getConsentStatus();

      String region = 'unknown';
      switch (status) {
        case ConsentStatus.notRequired:
          region = 'non_eea';
          break;
        case ConsentStatus.required:
        case ConsentStatus.obtained:
          region = 'eea';
          break;
        case ConsentStatus.unknown:
          region = 'unknown';
          break;
      }

      await prefs.setString(_userRegionKey, region);
      await prefs.setInt(
          _lastConsentRequestKey, DateTime.now().millisecondsSinceEpoch);
      _log('Cached region info: $region');
    } catch (e) {
      _logError('Failed to cache region info: $e');
      // Don't rethrow - not critical
    }
  }

  /// Get current consent status
  Future<ConsentStatus> getConsentStatus() async {
    try {
      if (!_isInitialized) {
        final success = await initialize();
        if (!success) return ConsentStatus.unknown;
      }
      return await ConsentInformation.instance.getConsentStatus();
    } catch (e) {
      _logError('Failed to get consent status: $e');
      return ConsentStatus.unknown;
    }
  }

  /// Check if user is in a region that requires consent
  Future<bool> isInConsentRegion() async {
    try {
      final status = await getConsentStatus();
      return status == ConsentStatus.required ||
          status == ConsentStatus.obtained;
    } catch (e) {
      _logError('Failed to check consent region: $e');
      return false; // Default to not requiring consent
    }
  }

  /// Check if consent form is available
  Future<bool> isConsentFormAvailable() async {
    try {
      if (!_isInitialized) {
        final success = await initialize();
        if (!success) return false;
      }
      return await ConsentInformation.instance.isConsentFormAvailable();
    } catch (e) {
      _logError('Failed to check consent form availability: $e');
      return false;
    }
  }

  /// Request consent from user if needed
  Future<ConsentStatus> requestConsent() async {
    try {
      final currentStatus = await getConsentStatus();

      // Don't show form if not needed
      if (currentStatus == ConsentStatus.notRequired ||
          currentStatus == ConsentStatus.obtained) {
        _log('Consent not needed, current status: $currentStatus');
        return currentStatus;
      }

      // Check if form is available
      final formAvailable = await isConsentFormAvailable();
      if (!formAvailable) {
        _log(
            'Consent form not available, using current status: $currentStatus');
        return currentStatus;
      }

      // Show consent form
      final completer = Completer<ConsentStatus>();

      ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) async {
        if (error != null) {
          _logError('Consent form error: ${error.message}');
        }

        try {
          final newStatus =
              await ConsentInformation.instance.getConsentStatus();
          await _cacheRegionInfo();
          _log('Consent request completed with status: $newStatus');
          completer.complete(newStatus);
        } catch (e) {
          _logError('Failed to get status after consent: $e');
          completer.complete(currentStatus);
        }
      });

      return await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _logError('Consent request timed out');
          return currentStatus;
        },
      );
    } catch (e) {
      _logError('Consent request failed: $e');
      return await getConsentStatus(); // Return current status as fallback
    }
  }

  /// Show privacy options form (where required)
  Future<bool> showPrivacyOptionsForm() async {
    try {
      final isRequired = await ConsentInformation.instance
          .getPrivacyOptionsRequirementStatus();
      if (isRequired != PrivacyOptionsRequirementStatus.required) {
        _log('Privacy options not required');
        return false;
      }

      final completer = Completer<bool>();

      ConsentForm.showPrivacyOptionsForm((FormError? error) {
        if (error != null) {
          _logError('Privacy options form error: ${error.message}');
          completer.complete(false);
        } else {
          _log('Privacy options form shown successfully');
          completer.complete(true);
        }
      });

      return await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          _logError('Privacy options form timed out');
          return false;
        },
      );
    } catch (e) {
      _logError('Failed to show privacy options: $e');
      return false;
    }
  }

  /// Reset consent (for testing or user request)
  Future<void> resetConsent() async {
    try {
      ConsentInformation.instance.reset();
      await _clearStoredData();
      _log('Consent reset successfully');
    } catch (e) {
      _logError('Failed to reset consent: $e');
    }
  }

  /// Clear stored consent data
  Future<void> _clearStoredData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_consentStatusKey);
      await prefs.remove(_lastConsentRequestKey);
      await prefs.remove(_userRegionKey);
    } catch (e) {
      _logError('Failed to clear stored data: $e');
    }
  }

  /// Check if ads can be requested
  Future<bool> canRequestAds() async {
    try {
      // In debug mode with consent disabled, always allow ad requests
      if (kDebugMode && _disableConsentInDebug) {
        _log('Debug mode: Bypassing consent check, allowing ad requests');
        return true;
      }

      if (!_isInitialized) {
        final success = await initialize();
        if (!success) {
          _log('Initialization failed, allowing ads with fallback');
          return true; // Fail open for ads
        }
      }

      final canRequest = await ConsentInformation.instance.canRequestAds();
      _log('Consent check result: canRequestAds = $canRequest');
      return canRequest;
    } catch (e) {
      _logError('Failed to check if can request ads: $e');
      // In debug mode, be more permissive
      final fallback = kDebugMode ? true : true; // Always fail open for now
      _log('Using fallback canRequestAds = $fallback');
      return fallback;
    }
  }

  /// Check if personalized ads can be shown
  Future<bool> canShowPersonalizedAds() async {
    try {
      // In debug mode with consent disabled, allow personalized ads
      if (kDebugMode && _disableConsentInDebug) {
        _log('Debug mode: Allowing personalized ads');
        return true;
      }

      final status = await getConsentStatus();
      final canShow = status == ConsentStatus.obtained;
      _log('Personalized ads check: status = $status, canShow = $canShow');
      return canShow;
    } catch (e) {
      _logError('Failed to check personalized ads: $e');
      // In debug mode, be more permissive
      return kDebugMode && _disableConsentInDebug;
    }
  }

  /// Check if non-personalized ads can be shown
  Future<bool> canShowNonPersonalizedAds() async {
    try {
      // In debug mode with consent disabled, always allow non-personalized ads
      if (kDebugMode && _disableConsentInDebug) {
        _log('Debug mode: Allowing non-personalized ads');
        return true;
      }

      final status = await getConsentStatus();
      _log('Non-personalized ads check: status = $status');

      // Non-personalized ads can be shown in most cases
      switch (status) {
        case ConsentStatus.notRequired:
        case ConsentStatus.obtained:
          _log('Non-personalized ads allowed (not required or obtained)');
          return true;
        case ConsentStatus.required:
        case ConsentStatus.unknown:
          final canRequest = await canRequestAds();
          _log('Non-personalized ads: canRequestAds = $canRequest');
          return canRequest;
      }
    } catch (e) {
      _logError('Failed to check non-personalized ads: $e');
      return true; // Fail open for non-personalized ads
    }
  }

  /// Get ad request parameters based on consent
  Future<Map<String, String>> getAdRequestParameters() async {
    try {
      final canPersonalized = await canShowPersonalizedAds();
      final status = await getConsentStatus();

      // Add npa=1 for non-personalized ads in EEA regions
      if (status == ConsentStatus.required && !canPersonalized) {
        _log('Adding npa=1 parameter for non-personalized ads');
        return {'npa': '1'};
      }

      return {};
    } catch (e) {
      _logError('Failed to get ad request parameters: $e');
      return {};
    }
  }

  /// Get user-friendly consent status message
  Future<String> getConsentStatusMessage() async {
    try {
      final status = await getConsentStatus();
      switch (status) {
        case ConsentStatus.unknown:
          return 'Consent status unknown';
        case ConsentStatus.required:
          return 'Consent required for personalized ads';
        case ConsentStatus.notRequired:
          return 'Consent not required in your region';
        case ConsentStatus.obtained:
          return 'Consent obtained for personalized ads';
      }
    } catch (e) {
      _logError('Failed to get consent status message: $e');
      return 'Unable to determine consent status';
    }
  }

  /// Get cached user region
  Future<String> getUserRegion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userRegionKey) ?? 'unknown';
    } catch (e) {
      _logError('Failed to get user region: $e');
      return 'unknown';
    }
  }

  /// Check if consent is being bypassed in debug mode
  bool isConsentBypassedInDebug() {
    return kDebugMode && _disableConsentInDebug;
  }

  /// Validate consent for ad requests
  Future<bool> validateConsentForAdRequest() async {
    try {
      final canRequest = await canRequestAds();
      final status = await getConsentStatus();
      _log('Ad request validation - Status: $status, Can request: $canRequest');
      return canRequest;
    } catch (e) {
      _logError('Consent validation failed: $e');
      return true; // Fail open for ads
    }
  }

  /// Get comprehensive debug information
  Future<Map<String, dynamic>> getConsentDebugInfo() async {
    try {
      final status = await getConsentStatus();
      final canRequest = await canRequestAds();
      final canPersonalized = await canShowPersonalizedAds();
      final canNonPersonalized = await canShowNonPersonalizedAds();
      final inConsentRegion = await isInConsentRegion();
      final formAvailable = await isConsentFormAvailable();
      final region = await getUserRegion();

      return {
        'consentStatus': status.toString(),
        'canRequestAds': canRequest,
        'canShowPersonalizedAds': canPersonalized,
        'canShowNonPersonalizedAds': canNonPersonalized,
        'isInConsentRegion': inConsentRegion,
        'isConsentFormAvailable': formAvailable,
        'userRegion': region,
        'isInitialized': _isInitialized,
        'initializationError': _initializationError,
        'forceEeaTesting': _forceEeaTesting,
        'debugMode': kDebugMode,
        'disableConsentInDebug': _disableConsentInDebug,
        'consentBypassedInDebug': isConsentBypassedInDebug(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': 'Failed to get debug info: $e',
        'isInitialized': _isInitialized,
        'initializationError': _initializationError,
        'debugMode': kDebugMode,
        'consentBypassedInDebug': isConsentBypassedInDebug(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Initialize and request consent if needed (convenience method)
  Future<ConsentStatus> initializeAndRequestConsent() async {
    try {
      // In debug mode with consent disabled, return a permissive status
      if (kDebugMode && _disableConsentInDebug) {
        _log(
            'Debug mode: Skipping consent initialization, returning not required');
        return ConsentStatus.notRequired;
      }

      final initialized = await initialize();
      if (!initialized) {
        _logError('Initialization failed, returning unknown status');
        return ConsentStatus.unknown;
      }

      final status = await getConsentStatus();

      // Only request consent if actually required
      if (status == ConsentStatus.required) {
        return await requestConsent();
      }

      _log('Consent initialization completed with status: $status');
      return status;
    } catch (e) {
      _logError('Failed to initialize and request consent: $e');
      return ConsentStatus.unknown;
    }
  }

  /// Check if privacy options are required
  Future<bool> isPrivacyOptionsRequired() async {
    try {
      if (!_isInitialized) {
        final success = await initialize();
        if (!success) return false;
      }

      final status = await ConsentInformation.instance
          .getPrivacyOptionsRequirementStatus();
      return status == PrivacyOptionsRequirementStatus.required;
    } catch (e) {
      _logError('Failed to check privacy options requirement: $e');
      return false;
    }
  }

  /// Log regular messages (only in debug mode or for admins)
  void _log(String message) {
    if (kDebugMode || AdMobCompliance.shouldLogVerbose) {
      debugPrint('[ConsentService] $message');
    }
  }

  /// Log error messages (always shown)
  void _logError(String message) {
    debugPrint('[ConsentService ERROR] $message');
  }

  /// Quick test method to verify consent bypass works in debug mode
  static Future<void> testConsentBypass() async {
    if (!kDebugMode) {
      debugPrint('[ConsentTest] Not in debug mode - skipping test');
      return;
    }

    debugPrint('🧪 Testing Consent Bypass in Debug Mode...');

    try {
      final service = ConsentService.instance;

      // Test initialization
      final initialized = await service.initialize();
      debugPrint('✓ Initialized: $initialized');

      // Test bypass status
      final bypassActive = service.isConsentBypassedInDebug();
      debugPrint('✓ Bypass Active: $bypassActive');

      // Test ad request permissions
      final canRequest = await service.canRequestAds();
      debugPrint('✓ Can Request Ads: $canRequest');

      final canPersonalized = await service.canShowPersonalizedAds();
      debugPrint('✓ Can Show Personalized: $canPersonalized');

      final canNonPersonalized = await service.canShowNonPersonalizedAds();
      debugPrint('✓ Can Show Non-Personalized: $canNonPersonalized');

      // Overall result
      final success = bypassActive && canRequest && canNonPersonalized;
      debugPrint('🎯 Test Result: ${success ? "✅ PASS" : "❌ FAIL"}');

      if (!success) {
        debugPrint('💡 Check that _disableConsentInDebug is set to true');
      }
    } catch (e) {
      debugPrint('❌ Test failed with error: $e');
    }

    debugPrint('🏁 Consent bypass test completed\n');
  }

  /// Dispose resources
  void dispose() {
    _isInitialized = false;
    _isInitializing = false;
    _initializationError = null;
  }
}
