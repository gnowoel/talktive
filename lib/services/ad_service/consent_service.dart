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

  // Current consent version - increment when privacy policy changes
  static const int currentConsentVersion = 1;

  bool _isInitialized = false;
  bool _isRequestingConsent = false;
  final Completer<void> _initializationCompleter = Completer<void>();

  /// Initialize the consent service
  Future<void> initialize() async {
    if (_isInitialized) return;
    if (_initializationCompleter.isCompleted) return _initializationCompleter.future;

    try {
      // Update consent information
      await _updateConsentInformation();
      _isInitialized = true;

      if (!_initializationCompleter.isCompleted) {
        _initializationCompleter.complete();
      }

      _logConsentStatus('Consent service initialized');
    } catch (e) {
      _logError('Failed to initialize consent service: $e');

      if (!_initializationCompleter.isCompleted) {
        _initializationCompleter.completeError(e);
      }
      rethrow;
    }
  }

  /// Update consent information from Google
  Future<void> _updateConsentInformation() async {
    final completer = Completer<void>();

    try {
      final params = ConsentRequestParameters(
        // Set to true for testing in EEA region
        consentDebugSettings: kDebugMode
            ? ConsentDebugSettings(
                debugGeography: DebugGeography.debugGeographyEea,
                testIdentifiers: [
                  // Add your test device IDs here if needed
                ],
              )
            : null,
      );

      ConsentInformation.instance.requestConsentInfoUpdate(
        params,
        () async {
          _logConsentStatus('Consent information updated successfully');
          completer.complete();
        },
        (FormError error) {
          _logError('Failed to update consent information: ${error.message}');
          completer.completeError(error);
        },
      );

      return completer.future;
    } catch (e) {
      _logError('Failed to update consent information: $e');
      rethrow;
    }
  }

  /// Check if consent is required
  Future<bool> isConsentRequired() async {
    if (!_isInitialized) await initialize();

    final status = await getConsentStatus();
    return status == ConsentStatus.required;
  }

  /// Get current consent status
  Future<ConsentStatus> getConsentStatus() async {
    if (!_isInitialized) await initialize();

    try {
      return await ConsentInformation.instance.getConsentStatus();
    } catch (e) {
      _logError('Failed to get consent status: $e');
      return ConsentStatus.unknown;
    }
  }

  /// Check if consent form is available
  Future<bool> isConsentFormAvailable() async {
    if (!_isInitialized) await initialize();

    try {
      return await ConsentInformation.instance.isConsentFormAvailable();
    } catch (e) {
      _logError('Failed to check consent form availability: $e');
      return false;
    }
  }

  /// Check if privacy options are required
  Future<bool> isPrivacyOptionsRequired() async {
    if (!_isInitialized) await initialize();

    try {
      return await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
    } catch (e) {
      _logError('Failed to check privacy options requirement: $e');
      return false;
    }
  }

  /// Request consent from user
  Future<ConsentStatus> requestConsent() async {
    if (!_isInitialized) await initialize();
    if (_isRequestingConsent) {
      _logConsentStatus('Consent request already in progress');
      return await getConsentStatus();
    }

    _isRequestingConsent = true;
    final completer = Completer<ConsentStatus>();

    try {
      // Check if we need to show consent form
      final status = await getConsentStatus();

      if (status == ConsentStatus.obtained ||
          status == ConsentStatus.notRequired) {
        _logConsentStatus('Consent already obtained or not required: $status');
        _isRequestingConsent = false;
        return status;
      }

      // Load and show consent form if required
      ConsentForm.loadAndShowConsentFormIfRequired((FormError? loadAndShowError) async {
        if (loadAndShowError != null) {
          _logError('Consent form error: ${loadAndShowError.message}');
          completer.completeError(loadAndShowError);
        } else {
          // Consent has been gathered or was not required
          final newStatus = await getConsentStatus();
          await _saveConsentStatus();
          _logConsentStatus('Consent request completed with status: $newStatus');
          completer.complete(newStatus);
        }
        _isRequestingConsent = false;
      });

      return completer.future;
    } catch (e) {
      _isRequestingConsent = false;
      _logError('Failed to request consent: $e');
      rethrow;
    }
  }

  /// Show privacy options form
  Future<void> showPrivacyOptionsForm() async {
    if (!_isInitialized) await initialize();

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

  /// Check if ads can be requested
  Future<bool> canRequestAds() async {
    if (!_isInitialized) await initialize();

    try {
      return await ConsentInformation.instance.canRequestAds();
    } catch (e) {
      _logError('Failed to check if can request ads: $e');
      return false;
    }
  }

  /// Check if personalized ads can be shown
  Future<bool> canShowPersonalizedAds() async {
    final status = await getConsentStatus();
    return status == ConsentStatus.obtained;
  }

  /// Check if non-personalized ads can be shown
  Future<bool> canShowNonPersonalizedAds() async {
    return await canRequestAds();
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

      return {
        'consentStatus': status.toString(),
        'isConsentRequired': isRequired,
        'isConsentFormAvailable': formAvailable,
        'canShowPersonalizedAds': canPersonalized,
        'canShowNonPersonalizedAds': canNonPersonalized,
        'canRequestAds': canRequest,
        'privacyOptionsRequired': privacyOptionsRequired,
        'isInitialized': _isInitialized,
        'isRequestingConsent': _isRequestingConsent,
        'consentVersion': currentConsentVersion,
        'debugMode': kDebugMode,
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

      // Request consent if status is unknown or required
      if (status == ConsentStatus.unknown || status == ConsentStatus.required) {
        return await isConsentFormAvailable();
      }

      return false;
    } catch (e) {
      _logError('Failed to check if should request consent: $e');
      return false;
    }
  }

  /// Initialize and request consent if needed (convenience method)
  Future<ConsentStatus> initializeAndRequestConsent() async {
    await initialize();

    final completer = Completer<ConsentStatus>();

    try {
      // Update consent information and then check if consent is needed
      final params = ConsentRequestParameters(
        consentDebugSettings: kDebugMode
            ? ConsentDebugSettings(
                debugGeography: DebugGeography.debugGeographyEea,
                testIdentifiers: [],
              )
            : null,
      );

      ConsentInformation.instance.requestConsentInfoUpdate(
        params,
        () async {
          // After updating consent info, show form if required
          ConsentForm.loadAndShowConsentFormIfRequired((FormError? loadAndShowError) async {
            if (loadAndShowError != null) {
              _logError('Load and show consent form error: ${loadAndShowError.message}');
              // Don't fail completely, just return current status
            }

            final status = await getConsentStatus();
            await _saveConsentStatus();
            completer.complete(status);
          });
        },
        (FormError error) {
          _logError('Request consent info update error: ${error.message}');
          // Don't fail completely, try to get current status
          getConsentStatus().then((status) => completer.complete(status))
              .catchError((e) => completer.complete(ConsentStatus.unknown));
        },
      );

      return completer.future;
    } catch (e) {
      _logError('Failed to initialize and request consent: $e');
      return ConsentStatus.unknown;
    }
  }

  /// Validate that consent is properly configured for ad requests
  Future<bool> validateConsentForAdRequest() async {
    try {
      final canRequest = await canRequestAds();
      _logConsentStatus('Ad request validation - Can request ads: $canRequest');
      return canRequest;
    } catch (e) {
      _logError('Failed to validate consent for ad request: $e');
      return false;
    }
  }

  /// Get user-friendly consent status message
  Future<String> getConsentStatusMessage() async {
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
    final status = await getConsentStatus();
    return status == ConsentStatus.required || status == ConsentStatus.obtained;
  }

  /// Dispose resources
  void dispose() {
    _isInitialized = false;
  }
}
