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
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () async {
          _currentStatus = await ConsentInformation.instance.getConsentStatus();
          _canRequestAds = await ConsentInformation.instance.canRequestAds();

          // Cache new values
          await prefs.setInt(_statusKey, _currentStatus.index);
          await prefs.setBool(_canRequestKey, _canRequestAds);

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
  Future<void> showConsentFormIfRequired() async {
    if (_currentStatus == ConsentStatus.required) {
      final isAvailable = await ConsentInformation.instance
          .isConsentFormAvailable();
      if (isAvailable) {
        final completer = Completer<void>();
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

              completer.complete();
            });
          },
          (FormError error) {
            debugPrint('[ConsentService] Form load error: ${error.message}');
            completer.complete();
          },
        );
        await completer.future;
      }
    }
  }

  /// Manually show privacy options (e.g. from settings)
  Future<void> showPrivacyOptions() async {
    final completer = Completer<void>();
    ConsentForm.showPrivacyOptionsForm((FormError? error) {
      completer.complete();
    });
    await completer.future;
  }
}

final consentServiceProvider = Provider<ConsentService>(
  (ref) => ConsentService(),
);
