import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Robust consent service that ensures proper consent handling for AdMob
///
/// Key improvements:
/// - Always ensures consent is obtained before allowing ads
/// - Handles re-consent scenarios properly
/// - Provides clear consent state tracking
/// - Simplifies logic to reduce edge cases
class RobustConsentService {
  static RobustConsentService? _instance;
  static RobustConsentService get instance =>
      _instance ??= RobustConsentService._();

  RobustConsentService._();

  // State tracking
  bool _isInitialized = false;
  bool _isInitializing = false;
  DateTime? _lastConsentCheck;

  // Cache keys
  static const String _consentStatusKey = 'consent_status_v2';
  static const String _lastConsentCheckKey = 'last_consent_check_v2';
  static const String _consentChoicesKey = 'consent_choices_v2';
  static const String _canRequestAdsKey = 'can_request_ads_v2';

  // Debug settings
  static const bool _forceConsentInDebug = true; // Always test consent flow

  /// Initialize the consent service
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

    try {
      await _loadCachedState();
      await _updateConsentInformation();
      _isInitialized = true;
      _log('Consent service initialized successfully');
      return true;
    } catch (e) {
      _logError('Failed to initialize consent service: $e');
      _isInitialized = true; // Mark as initialized even on error
      return false;
    } finally {
      _isInitializing = false;
    }
  }

  /// Load cached consent state
  Future<void> _loadCachedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheckTimestamp = prefs.getInt(_lastConsentCheckKey);
      if (lastCheckTimestamp != null) {
        _lastConsentCheck =
            DateTime.fromMillisecondsSinceEpoch(lastCheckTimestamp);
      }
    } catch (e) {
      _logError('Failed to load cached state: $e');
    }
  }

  /// Update consent information from UMP SDK
  Future<void> _updateConsentInformation() async {
    final completer = Completer<void>();

    // Configure debug settings
    ConsentDebugSettings? debugSettings;
    if (kDebugMode && _forceConsentInDebug) {
      debugSettings = ConsentDebugSettings(
        debugGeography: DebugGeography.debugGeographyEea,
        testIdentifiers: [], // Add test device IDs if needed
      );
      _log('Debug mode: Forcing EEA geography for consent testing');
    }

    final params = ConsentRequestParameters(
      consentDebugSettings: debugSettings,
    );

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        _log('Consent information updated successfully');
        await _cacheConsentState();
        completer.complete();
      },
      (FormError error) {
        _logError('Failed to update consent info: ${error.message}');
        completer.complete(); // Complete anyway to not block
      },
    );

    await completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _logError('Consent info update timed out');
      },
    );
  }

  /// Cache current consent state
  Future<void> _cacheConsentState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _lastConsentCheck = DateTime.now();
      await prefs.setInt(
          _lastConsentCheckKey, _lastConsentCheck!.millisecondsSinceEpoch);

      // Cache consent status
      final status = await ConsentInformation.instance.getConsentStatus();
      await prefs.setInt(_consentStatusKey, status.index);

      // Cache canRequestAds
      final canRequest = await ConsentInformation.instance.canRequestAds();
      await prefs.setBool(_canRequestAdsKey, canRequest);

      _log(
          'Consent state cached - Status: $status, CanRequestAds: $canRequest');
    } catch (e) {
      _logError('Failed to cache consent state: $e');
    }
  }

  /// Get current consent status
  Future<ConsentStatus> getConsentStatus() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      return await ConsentInformation.instance.getConsentStatus();
    } catch (e) {
      _logError('Failed to get consent status: $e');
      return ConsentStatus.unknown;
    }
  }

  /// Check if we can request ads (the most important check)
  Future<bool> canRequestAds() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final canRequest = await ConsentInformation.instance.canRequestAds();
      _log('Can request ads: $canRequest');

      // If we can't request ads, we need to handle consent
      if (!canRequest) {
        _log('Cannot request ads - consent handling required');
      }

      return canRequest;
    } catch (e) {
      _logError('Failed to check if can request ads: $e');
      // Conservative approach - don't request ads if we can't check
      return false;
    }
  }

  /// Request consent from user with proper handling
  Future<ConsentResult> requestConsent() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      // Always update consent information first
      await _updateConsentInformation();

      final status = await getConsentStatus();
      _log('Current consent status before request: $status');

      // Check if consent is required
      if (status == ConsentStatus.notRequired) {
        _log('Consent not required in this region');
        return ConsentResult(
          success: true,
          status: status,
          canRequestAds: true,
          message: 'Consent not required in your region',
        );
      }

      // Check if already obtained
      if (status == ConsentStatus.obtained) {
        final canRequest = await canRequestAds();
        if (canRequest) {
          _log('Consent already obtained and ads can be requested');
          return ConsentResult(
            success: true,
            status: status,
            canRequestAds: canRequest,
            message: 'Consent already obtained',
          );
        }
        // If consent is obtained but we can't request ads, we need to re-consent
        _log('Consent obtained but cannot request ads - need re-consent');
      }

      // Load and show consent form
      final formShown = await _loadAndShowConsentForm();

      // Get updated status after form
      final newStatus = await getConsentStatus();
      final canRequest = await canRequestAds();

      await _cacheConsentState();

      _log(
          'Consent request completed - Status: $newStatus, CanRequestAds: $canRequest');

      return ConsentResult(
        success: formShown,
        status: newStatus,
        canRequestAds: canRequest,
        message: formShown
            ? 'Consent form shown successfully'
            : 'Failed to show consent form',
      );
    } catch (e) {
      _logError('Failed to request consent: $e');
      return ConsentResult(
        success: false,
        status: ConsentStatus.unknown,
        canRequestAds: false,
        message: 'Error requesting consent: $e',
      );
    }
  }

  /// Load and show consent form with proper error handling
  Future<bool> _loadAndShowConsentForm() async {
    final completer = Completer<bool>();

    try {
      // First check if form is available
      final formAvailable =
          await ConsentInformation.instance.isConsentFormAvailable();

      if (!formAvailable) {
        _log('Consent form not available');
        completer.complete(false);
        return completer.future;
      }

      // Load consent form first
      ConsentForm.loadConsentForm(
        (ConsentForm consentForm) {
          _log('Consent form loaded successfully');

          // Show the loaded form
          consentForm.show((FormError? error) {
            if (error != null) {
              _logError('Error showing consent form: ${error.message}');
              completer.complete(false);
            } else {
              _log('Consent form shown and closed');
              completer.complete(true);
            }
          });
        },
        (FormError error) {
          _logError('Failed to load consent form: ${error.message}');
          completer.complete(false);
        },
      );
    } catch (e) {
      _logError('Exception in consent form handling: $e');
      completer.complete(false);
    }

    return completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        _logError('Consent form timed out');
        return false;
      },
    );
  }

  /// Show privacy options form (for changing consent)
  Future<bool> showPrivacyOptionsForm() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      // Update consent info first
      await _updateConsentInformation();

      // Check if privacy options are required
      final required = await ConsentInformation.instance
          .getPrivacyOptionsRequirementStatus();

      if (required == PrivacyOptionsRequirementStatus.notRequired) {
        _log('Privacy options not required');

        // Even if not required, try to show consent form for users to change settings
        final result = await requestConsent();
        return result.success;
      }

      // Load and show privacy options
      final formShown = await _loadAndShowPrivacyOptionsForm();

      if (formShown) {
        await _cacheConsentState();
      }

      return formShown;
    } catch (e) {
      _logError('Failed to show privacy options: $e');
      return false;
    }
  }

  /// Load and show privacy options form
  Future<bool> _loadAndShowPrivacyOptionsForm() async {
    final completer = Completer<bool>();

    ConsentForm.showPrivacyOptionsForm((FormError? error) {
      if (error != null) {
        _logError('Error showing privacy options: ${error.message}');
        completer.complete(false);
      } else {
        _log('Privacy options form closed');
        completer.complete(true);
      }
    });

    return completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        _logError('Privacy options form timed out');
        return false;
      },
    );
  }

  /// Reset consent for testing
  Future<void> resetConsent() async {
    try {
      ConsentInformation.instance.reset();

      // Clear cached data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_consentStatusKey);
      await prefs.remove(_lastConsentCheckKey);
      await prefs.remove(_consentChoicesKey);
      await prefs.remove(_canRequestAdsKey);

      _lastConsentCheck = null;
      _log('Consent reset successfully');

      // Re-initialize to get fresh state
      _isInitialized = false;
      await initialize();
    } catch (e) {
      _logError('Failed to reset consent: $e');
    }
  }

  /// Get ad request parameters based on consent
  Future<Map<String, String>> getAdRequestParameters() async {
    try {
      final canRequest = await canRequestAds();

      if (!canRequest) {
        _log('Cannot request ads - returning empty parameters');
        return {};
      }

      final status = await getConsentStatus();

      // For users who haven't consented to personalized ads, add npa=1
      if (status != ConsentStatus.obtained) {
        _log('Adding npa=1 for non-personalized ads');
        return {'npa': '1'};
      }

      return {};
    } catch (e) {
      _logError('Failed to get ad request parameters: $e');
      return {'npa': '1'}; // Default to non-personalized
    }
  }

  /// Check if consent needs to be refreshed
  Future<bool> needsConsentRefresh() async {
    if (_lastConsentCheck == null) return true;

    // Refresh consent check every 24 hours
    final hoursSinceLastCheck =
        DateTime.now().difference(_lastConsentCheck!).inHours;
    return hoursSinceLastCheck >= 24;
  }

  /// Ensure consent is valid for ad requests
  Future<ConsentValidation> validateConsentForAds() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      // Check if we need to refresh consent
      if (await needsConsentRefresh()) {
        _log('Consent needs refresh - updating');
        await _updateConsentInformation();
      }

      final canRequest = await canRequestAds();
      final status = await getConsentStatus();

      // Determine what action is needed
      String action = 'none';
      String message = '';

      if (!canRequest) {
        if (status == ConsentStatus.required ||
            status == ConsentStatus.unknown) {
          action = 'request_consent';
          message = 'User consent required before showing ads';
        } else {
          action = 'check_settings';
          message = 'Cannot request ads - check privacy settings';
        }
      } else {
        message = 'Ads can be requested';
      }

      return ConsentValidation(
        canRequestAds: canRequest,
        consentStatus: status,
        action: action,
        message: message,
      );
    } catch (e) {
      _logError('Failed to validate consent for ads: $e');
      return ConsentValidation(
        canRequestAds: false,
        consentStatus: ConsentStatus.unknown,
        action: 'error',
        message: 'Failed to validate consent: $e',
      );
    }
  }

  /// Get debug information
  Future<Map<String, dynamic>> getDebugInfo() async {
    try {
      final status = await getConsentStatus();
      final canRequest = await canRequestAds();
      final prefs = await SharedPreferences.getInstance();

      return {
        'initialized': _isInitialized,
        'consentStatus': status.toString(),
        'canRequestAds': canRequest,
        'lastConsentCheck': _lastConsentCheck?.toIso8601String() ?? 'never',
        'cachedStatus': prefs.getInt(_consentStatusKey),
        'cachedCanRequestAds': prefs.getBool(_canRequestAdsKey),
        'debugMode': kDebugMode,
        'forceConsentInDebug': _forceConsentInDebug,
      };
    } catch (e) {
      return {'error': 'Failed to get debug info: $e'};
    }
  }

  /// Logging helpers
  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[RobustConsent] $message');
    }
  }

  void _logError(String message) {
    debugPrint('[RobustConsent ERROR] $message');
  }
}

/// Result of consent request
class ConsentResult {
  final bool success;
  final ConsentStatus status;
  final bool canRequestAds;
  final String message;

  ConsentResult({
    required this.success,
    required this.status,
    required this.canRequestAds,
    required this.message,
  });
}

/// Consent validation result
class ConsentValidation {
  final bool canRequestAds;
  final ConsentStatus consentStatus;
  final String action; // 'none', 'request_consent', 'check_settings', 'error'
  final String message;

  ConsentValidation({
    required this.canRequestAds,
    required this.consentStatus,
    required this.action,
    required this.message,
  });
}
