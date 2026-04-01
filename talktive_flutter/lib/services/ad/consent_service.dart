import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service that handles User Messaging Platform (UMP) consent
class ConsentService {
  static const String _statusKey = 'ad_consent_status';
  static const String _canRequestKey = 'ad_consent_can_request';

  ConsentStatus _currentStatus = ConsentStatus.unknown;
  bool _canRequestAds = false;
  bool _isInitialized = false;

  ConsentStatus get currentStatus => _currentStatus;
  bool get canRequestAds => _canRequestAds;
  bool get isInitialized => _isInitialized;

  /// Initialize consent info. Returns true if request can be made.
  Future<bool> initialize() async {
    if (_isInitialized) return _canRequestAds;
    if (kIsWeb) {
      _isInitialized = true;
      return false;
    }

    try {
      // 1. Load cached values first for immediate access
      final prefs = await SharedPreferences.getInstance();
      final cachedStatusIndex = prefs.getInt(_statusKey);
      if (cachedStatusIndex != null) {
        _currentStatus = ConsentStatus.values[cachedStatusIndex];
      }
      _canRequestAds = prefs.getBool(_canRequestKey) ?? false;

      // 2. Update consent info from UMP
      final completer = Completer<void>();

      // For development, we can force the consent form to appear by setting debug settings
      final params = ConsentRequestParameters(
        consentDebugSettings: kDebugMode
            ? ConsentDebugSettings(
                debugGeography: DebugGeography.debugGeographyEea,
                // The ID from your logs: B3EEABB8EE11C2BE770B684D95219ECB
                testIdentifiers: ['B3EEABB8EE11C2BE770B684D95219ECB'],
              )
            : null,
      );

      ConsentInformation.instance.requestConsentInfoUpdate(
        params,
        () async {
          _currentStatus = await ConsentInformation.instance.getConsentStatus();
          _canRequestAds = await ConsentInformation.instance.canRequestAds();

          // Cache new values
          await prefs.setInt(_statusKey, _currentStatus.index);
          await prefs.setBool(_canRequestKey, _canRequestAds);

          debugPrint(
            '[ConsentService] Consent info updated: status=$_currentStatus, canRequest=$_canRequestAds',
          );
          completer.complete();
        },
        (FormError error) {
          debugPrint('[ConsentService] UMP error: ${error.message}');
          completer.complete();
        },
      );

      // Wait a bit for UMP but don't block forever
      await completer.future.timeout(
        const Duration(seconds: 3),
        onTimeout: () => debugPrint('[ConsentService] Update timed out'),
      );

      _isInitialized = true;
      return _canRequestAds;
    } catch (e) {
      debugPrint('[ConsentService] Initialization error: $e');
      return _canRequestAds;
    }
  }

  /// Show the consent form if required
  Future<bool> showConsentFormIfRequired() async {
    if (kIsWeb) return false;

    // Ensure we have the latest status
    _currentStatus = await ConsentInformation.instance.getConsentStatus();

    if (_currentStatus == ConsentStatus.required) {
      debugPrint('[ConsentService] Consent is required, showing form...');
      final isAvailable = await ConsentInformation.instance
          .isConsentFormAvailable();
      if (isAvailable) {
        final completer = Completer<bool>();
        ConsentForm.loadConsentForm(
          (ConsentForm consentForm) {
            consentForm.show((FormError? error) async {
              _currentStatus = await ConsentInformation.instance
                  .getConsentStatus();
              _canRequestAds = await ConsentInformation.instance
                  .canRequestAds();

              final prefs = await SharedPreferences.getInstance();
              await prefs.setInt(_statusKey, _currentStatus.index);
              await prefs.setBool(_canRequestKey, _canRequestAds);

              debugPrint(
                '[ConsentService] Form dismissed. New status: $_currentStatus',
              );
              completer.complete(true);
            });
          },
          (FormError error) {
            debugPrint('[ConsentService] Form load error: ${error.message}');
            completer.complete(false);
          },
        );
        return await completer.future;
      }
    } else {
      debugPrint('[ConsentService] Consent not required: $_currentStatus');
    }
    return false;
  }

  /// Manually show privacy options (e.g. from settings)
  Future<void> showPrivacyOptions() async {
    if (kIsWeb) return;

    debugPrint(
      '[ConsentService] Checking if privacy options form is available...',
    );
    final requirementStatus = await ConsentInformation.instance
        .getPrivacyOptionsRequirementStatus();

    if (requirementStatus == PrivacyOptionsRequirementStatus.required) {
      final completer = Completer<void>();
      ConsentForm.showPrivacyOptionsForm((FormError? error) async {
        if (error != null) {
          debugPrint(
            '[ConsentService] Privacy options error: ${error.message}',
          );
        }

        // Refresh status after form is closed
        _currentStatus = await ConsentInformation.instance.getConsentStatus();
        _canRequestAds = await ConsentInformation.instance.canRequestAds();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_statusKey, _currentStatus.index);
        await prefs.setBool(_canRequestKey, _canRequestAds);

        completer.complete();
      });
      await completer.future;
    } else {
      debugPrint(
        '[ConsentService] Privacy options form not required/available: $requirementStatus',
      );
      // If privacy options isn't available, we can try showing the consent form if it's required
      // or simply tell the user it's not available in their region.
      throw Exception('Privacy settings are not available in your region.');
    }
  }

  /// Resets the consent state (useful for testing or forcing another chance)
  Future<void> reset() async {
    if (kIsWeb) return;
    await ConsentInformation.instance.reset();
    _currentStatus = ConsentStatus.unknown;
    _canRequestAds = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_statusKey);
    await prefs.remove(_canRequestKey);

    // Re-initialize after reset
    await initialize();
  }
}

final consentServiceProvider = Provider<ConsentService>(
  (ref) => ConsentService(),
);
