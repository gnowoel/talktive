import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admob_compliance.dart';

/// Consent Management Service for GDPR compliance
///
/// This service handles user consent for personalized ads in the EEA, UK, and Switzerland
/// using Google's User Messaging Platform (UMP) SDK to resolve "No CMP" AdMob policy issues.
class ConsentService {
  static ConsentService? _instance;
  static ConsentService get instance => _instance ??= ConsentService._();

  ConsentService._();

  static const String _consentStatusKey = 'consent_status';
  static const String _lastConsentRequestKey = 'last_consent_request';
  static const String _consentVersionKey = 'consent_version';
  static const String _userRegionKey = 'user_region';

  // Current consent version - increment when privacy policy changes
  static const int currentConsentVersion = 1;

  // Set to true only when explicitly testing GDPR compliance
  static const bool _forceEeaTesting = false;

  bool _isInitialized = false;
  bool _isRequestingConsent = false;
  bool _initializationFailed = false;
  final Completer<void> _initializationCompleter = Completer<void>();

  /// Initialize the consent service
  Future<void> initialize() async {
    if (_isInitialized) return;
    if (_initializationCompleter.isCompleted)
      return _initializationCompleter.future;

    try {
      // Update consent information
      await _updateConsentInformation();
      _isInitialized = true;
      _initializationFailed = false;

      if (!_initializationCompleter.isCompleted) {
        _initializationCompleter.complete();
      }

      _logConsentStatus('Consent service initialized successfully');
    } catch (e) {
      _initializationFailed = true;
      _logError('Failed to initialize consent service: $e');

      if (!_initializationCompleter.isCompleted) {
        _initializationCompleter.complete(); // Complete anyway to not block ads
      }

      // Don't rethrow - allow ads to continue with fallback behavior
    }
  }

  /// Update consent information from Google
  Future<void> _updateConsentInformation() async {
    final completer = Completer<void>();

    try {
      // Only set debug geography when explicitly testing GDPR
      ConsentDebugSettings? debugSettings;
      if (kDebugMode && _forceEeaTesting) {
        debugSettings = ConsentDebugSettings(
          debugGeography: DebugGeography.debugGeographyEea,
          testIdentifiers: [
            // Add your test device IDs here if needed
          ],
        );
        _logConsentStatus('Debug mode: Forcing EEA geography for testing');
      }

      final params = ConsentRequestParameters(
        consentDebugSettings: debugSettings,
      );

      ConsentInformation.instance.requestConsentInfoUpdate(
        params,
        () async {
          _logConsentStatus('Consent information updated successfully');
          await _saveRegionInfo();
          completer.complete();
        },
        (FormError error) {
          _logError('Failed to update consent information: ${error.message}');
          // Complete anyway to not block initialization
          completer.complete();
        },
      );

      return completer.future;
    } catch (e) {
      _logError('Exception in _updateConsentInformation: $e');
      // Don't rethrow - complete to avoid blocking
      return;
    }
  }

  /// Save region information for debugging
  Future<void> _saveRegionInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final status = await getConsentStatus();

      String region = 'unknown';
      if (status == ConsentStatus.notRequired) {
        region = 'non_eea';
      } else if (status == ConsentStatus.required ||
          status == ConsentStatus.obtained) {
        region = 'eea';
      }

      await prefs.setString(_userRegionKey, region);
      _logConsentStatus('User region saved: $region');
    } catch (e) {
      _logError('Failed to save region info: $e');
    }
  }

  /// Check if consent is required
  Future<bool> isConsentRequired() async {
    if (!_isInitialized) await initialize();

    try {
      final status = await getConsentStatus();
      return status == ConsentStatus.required;
    } catch (e) {
      _logError('Failed to check if consent required: $e');
      return false; // Default to not required to avoid blocking ads
    }
  }

  /// Get current consent status
  Future<ConsentStatus> getConsentStatus() async {
    if (!_isInitialized && !_initializationFailed) await initialize();

    try {
      return await ConsentInformation.instance.getConsentStatus();
    } catch (e) {
      _logError('Failed to get consent status: $e');
      return ConsentStatus.unknown;
    }
  }

  /// Check if consent form is available
  Future<bool> isConsentFormAvailable() async {
    if (!_isInitialized && !_initializationFailed) await initialize();

    try {
      return await ConsentInformation.instance.isConsentFormAvailable();
    } catch (e) {
      _logError('Failed to check consent form availability: $e');
      return false;
    }
  }

  /// Check if privacy options are required
  Future<bool> isPrivacyOptionsRequired() async {
    if (!_isInitialized && !_initializationFailed) await initialize();

    try {
      return await ConsentInformation.instance
              .getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
    } catch (e) {
      _logError('Failed to check privacy options requirement: $e');
      return false;
    }
  }

  /// Request consent from user (only if in consent-required region)
  Future<ConsentStatus> requestConsent() async {
    if (!_isInitialized && !_initializationFailed) await initialize();
    if (_isRequestingConsent) {
      _logConsentStatus('Consent request already in progress');
      return await getConsentStatus();
    }

    _isRequestingConsent = true;
    final completer = Completer<ConsentStatus>();

    try {
      // Check current status first
      final status = await getConsentStatus();

      // Don't show consent form if not in EEA/consent region
      if (status == ConsentStatus.notRequired) {
        _logConsentStatus('Consent not required in this region: $status');
        _isRequestingConsent = false;
        return status;
      }

      // Don't show consent form if already obtained
      if (status == ConsentStatus.obtained) {
        _logConsentStatus('Consent already obtained: $status');
        _isRequestingConsent = false;
        return status;
      }

      // Check if form is available before attempting to show
      final formAvailable = await isConsentFormAvailable();
      if (!formAvailable) {
        _logConsentStatus(
            'Consent form not available, using current status: $status');
        _isRequestingConsent = false;
        return status;
      }

      // Load and show consent form if required
      ConsentForm.loadAndShowConsentFormIfRequired(
          (FormError? loadAndShowError) async {
        try {
          if (loadAndShowError != null) {
            _logError('Consent form error: ${loadAndShowError.message}');
            // Don't fail completely - get current status
            final currentStatus = await getConsentStatus();
            completer.complete(currentStatus);
          } else {
            // Consent has been gathered or was not required
            final newStatus = await getConsentStatus();
            await _saveConsentStatus();
            _logConsentStatus(
                'Consent request completed with status: $newStatus');
            completer.complete(newStatus);
          }
        } catch (e) {
          _logError('Error in consent form callback: $e');
          final fallbackStatus = await getConsentStatus();
          completer.complete(fallbackStatus);
        }
        _isRequestingConsent = false;
      });

      return completer.future;
    } catch (e) {
      _isRequestingConsent = false;
      _logError('Failed to request consent: $e');
      // Return current status instead of throwing
      return await getConsentStatus();
    }
  }

  /// Show privacy options form
  Future<void> showPrivacyOptionsForm() async {
    if (!_isInitialized && !_initializationFailed) await initialize();

    final completer = Completer<void>();

    try {
      ConsentForm.showPrivacyOptionsForm((FormError? formError) {
        if (formError != null) {
          _logError('Privacy options form error: ${formError.message}');
          completer.completeError(formError);
        } else {
          _logConsentStatus('Privacy options form shown successfully');
          completer.complete();
        }
      });

      return completer.future;
    } catch (e) {
      _logError('Failed to show privacy options form: $e');
      rethrow;
    }
  }

  /// Save consent status to preferences
  Future<void> _saveConsentStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final status = await getConsentStatus();

      await prefs.setInt(_consentStatusKey, status.index);
      await prefs.setInt(
          _lastConsentRequestKey, DateTime.now().millisecondsSinceEpoch);
      await prefs.setInt(_consentVersionKey, currentConsentVersion);

      _logConsentStatus('Consent status saved: $status');
    } catch (e) {
      _logError('Failed to save consent status: $e');
    }
  }

  /// Clear stored consent status
  Future<void> _clearConsentStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_consentStatusKey);
      await prefs.remove(_lastConsentRequestKey);
      await prefs.remove(_consentVersionKey);
      await prefs.remove(_userRegionKey);
    } catch (e) {
      _logError('Failed to clear consent status: $e');
    }
  }

  /// Reset consent (for testing or privacy settings)
  Future<void> resetConsent() async {
    try {
      if (_isInitialized) {
        ConsentInformation.instance.reset();
      }
      await _clearConsentStatus();
      _logConsentStatus('Consent reset successfully');
    } catch (e) {
      _logError('Failed to reset consent: $e');
    }
  }

  /// Check if ads can be requested (more permissive approach)
  Future<bool> canRequestAds() async {
    if (!_isInitialized && !_initializationFailed) await initialize();

    try {
      // If initialization failed, allow ads with fallback behavior
      if (_initializationFailed) {
        _logConsentStatus('Initialization failed, allowing ads with fallback');
        return true;
      }

      return await ConsentInformation.instance.canRequestAds();
    } catch (e) {
      _logError('Failed to check if can request ads: $e');
      // Default to true to avoid blocking ads completely
      return true;
    }
  }

  /// Check if personalized ads can be shown
  Future<bool> canShowPersonalizedAds() async {
    try {
      final status = await getConsentStatus();
      return status == ConsentStatus.obtained;
    } catch (e) {
      _logError('Failed to check personalized ads: $e');
      return false;
    }
  }

  /// Check if non-personalized ads can be shown
  Future<bool> canShowNonPersonalizedAds() async {
    try {
      final status = await getConsentStatus();

      // Non-personalized ads can be shown in these cases:
      // 1. Consent not required (non-EEA)
      // 2. Consent obtained (EEA with consent)
      // 3. When ads can be requested (fallback)
      if (status == ConsentStatus.notRequired ||
          status == ConsentStatus.obtained) {
        return true;
      }

      // Fallback check
      return await canRequestAds();
    } catch (e) {
      _logError('Failed to check non-personalized ads: $e');
      // Default to true for non-personalized ads as they're less restrictive
      return true;
    }
  }

  /// Get comprehensive consent status for debugging
  Future<Map<String, dynamic>> getConsentDebugInfo() async {
    try {
      final status = await getConsentStatus();
      final isRequired = await isConsentRequired();
      final formAvailable = await isConsentFormAvailable();
      final canPersonalized = await canShowPersonalizedAds();
      final canNonPersonalized = await canShowNonPersonalizedAds();
      final canRequest = await canRequestAds();
      final privacyOptionsRequired = await isPrivacyOptionsRequired();

      final prefs = await SharedPreferences.getInstance();
      final savedRegion = prefs.getString(_userRegionKey) ?? 'unknown';

      return {
        'consentStatus': status.toString(),
        'isConsentRequired': isRequired,
        'isConsentFormAvailable': formAvailable,
        'canShowPersonalizedAds': canPersonalized,
        'canShowNonPersonalizedAds': canNonPersonalized,
        'canRequestAds': canRequest,
        'privacyOptionsRequired': privacyOptionsRequired,
        'isInitialized': _isInitialized,
        'initializationFailed': _initializationFailed,
        'isRequestingConsent': _isRequestingConsent,
        'consentVersion': currentConsentVersion,
        'debugMode': kDebugMode,
        'forceEeaTesting': _forceEeaTesting,
        'userRegion': savedRegion,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': 'Failed to get consent debug info: $e',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Check if consent should be requested automatically
  Future<bool> shouldRequestConsent() async {
    try {
      // Don't auto-request if already requesting
      if (_isRequestingConsent) return false;

      final status = await getConsentStatus();

      // Only request consent if in EEA region and status requires it
      if (status == ConsentStatus.required) {
        return await isConsentFormAvailable();
      }

      return false;
    } catch (e) {
      _logError('Failed to check if should request consent: $e');
      return false;
    }
  }

  /// Initialize and request consent if needed (improved version)
  Future<ConsentStatus> initializeAndRequestConsent() async {
    await initialize();

    try {
      final status = await getConsentStatus();

      // Only show consent form if actually required
      if (status == ConsentStatus.required) {
        return await requestConsent();
      }

      _logConsentStatus('Consent not required or already handled: $status');
      return status;
    } catch (e) {
      _logError('Failed to initialize and request consent: $e');
      return ConsentStatus.unknown;
    }
  }

  /// Validate that consent is properly configured for ad requests
  Future<bool> validateConsentForAdRequest() async {
    try {
      final canRequest = await canRequestAds();
      final status = await getConsentStatus();

      _logConsentStatus(
          'Ad request validation - Status: $status, Can request: $canRequest');

      return canRequest;
    } catch (e) {
      _logError('Failed to validate consent for ad request: $e');
      return true; // Default to allowing ads
    }
  }

  /// Get ad request parameters based on consent status
  Future<Map<String, String>> getAdRequestParameters() async {
    try {
      final canPersonalized = await canShowPersonalizedAds();
      final status = await getConsentStatus();

      Map<String, String> params = {};

      // For EEA users without consent, request non-personalized ads
      if (status == ConsentStatus.required && !canPersonalized) {
        params['npa'] = '1'; // Non-personalized ads
        _logConsentStatus('Requesting non-personalized ads (npa=1)');
      }

      return params;
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
      return 'Unable to determine consent status';
    }
  }

  /// Log consent-related messages
  void _logConsentStatus(String message) {
    if (AdMobCompliance.shouldLogVerbose || kDebugMode) {
      debugPrint('[Consent Service] $message');
    }
  }

  /// Log consent-related errors
  void _logError(String message) {
    debugPrint('[Consent Service ERROR] $message');
  }

  /// Check if we're in a region that requires consent
  Future<bool> isInConsentRegion() async {
    try {
      final status = await getConsentStatus();
      return status == ConsentStatus.required ||
          status == ConsentStatus.obtained;
    } catch (e) {
      return false;
    }
  }

  /// Get stored region information
  Future<String> getUserRegion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userRegionKey) ?? 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }

  /// Dispose resources
  void dispose() {
    _isInitialized = false;
    _initializationFailed = false;
  }
}
