import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'robust_consent_service.dart';

/// Robust ad request helper that ensures consent compliance
///
/// Key improvements:
/// - Never requests ads without proper consent
/// - Provides clear feedback when ads can't be shown
/// - Handles consent flow automatically when needed
/// - Prevents wasted ad requests that won't fill
class RobustAdRequestHelper {
  static RobustAdRequestHelper? _instance;
  static RobustAdRequestHelper get instance =>
      _instance ??= RobustAdRequestHelper._();

  RobustAdRequestHelper._();

  final RobustConsentService _consentService = RobustConsentService.instance;

  // Track request statistics
  int _totalRequests = 0;
  int _blockedRequests = 0;
  int _successfulLoads = 0;
  int _failedLoads = 0;

  /// Validate if we can make an ad request
  Future<AdRequestValidation> validateAdRequest() async {
    _totalRequests++;

    try {
      // First validate consent
      final validation = await _consentService.validateConsentForAds();

      if (!validation.canRequestAds) {
        _blockedRequests++;
        _log('Ad request blocked: ${validation.message}');

        return AdRequestValidation(
          canRequestAds: false,
          reason: validation.message,
          action: validation.action,
          consentStatus: validation.consentStatus,
        );
      }

      _log('Ad request validated - can proceed');
      return AdRequestValidation(
        canRequestAds: true,
        reason: 'All requirements met',
        action: 'proceed',
        consentStatus: validation.consentStatus,
      );
    } catch (e) {
      _blockedRequests++;
      _logError('Failed to validate ad request: $e');
      return AdRequestValidation(
        canRequestAds: false,
        reason: 'Validation error: $e',
        action: 'error',
        consentStatus: ConsentStatus.unknown,
      );
    }
  }

  /// Create an ad request with proper consent parameters
  Future<AdRequest?> createAdRequest({
    List<String>? keywords,
    String? contentUrl,
    List<String>? neighboringContentUrls,
    Map<String, String>? customParameters,
  }) async {
    try {
      // Validate before creating request
      final validation = await validateAdRequest();
      if (!validation.canRequestAds) {
        _log('Cannot create ad request: ${validation.reason}');
        return null;
      }

      // Get consent-based parameters
      final consentParams = await _consentService.getAdRequestParameters();

      // Merge parameters
      final Map<String, String> finalParams = {
        ...consentParams,
        ...?customParameters,
      };

      final adRequest = AdRequest(
        keywords: keywords,
        contentUrl: contentUrl,
        neighboringContentUrls: neighboringContentUrls,
        extras: finalParams,
      );

      _log('Created ad request with params: $finalParams');
      return adRequest;
    } catch (e) {
      _logError('Failed to create ad request: $e');
      return null;
    }
  }

  /// Load banner ad with full consent validation
  Future<BannerAd?> loadBannerAd({
    required String adUnitId,
    required AdSize adSize,
    List<String>? keywords,
    Map<String, String>? customParameters,
  }) async {
    try {
      // Create ad request (includes validation)
      final adRequest = await createAdRequest(
        keywords: keywords,
        customParameters: customParameters,
      );

      if (adRequest == null) {
        _log('Banner ad load cancelled - no valid ad request');
        return null;
      }

      final completer = Completer<BannerAd?>();

      final bannerAd = BannerAd(
        adUnitId: adUnitId,
        size: adSize,
        request: adRequest,
        listener: BannerAdListener(
          onAdLoaded: (Ad ad) {
            _successfulLoads++;
            _log('Banner ad loaded successfully');
            completer.complete(ad as BannerAd);
          },
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            _failedLoads++;
            _logError('Banner ad failed to load: ${error.message}');
            ad.dispose();
            completer.complete(null);
          },
        ),
      );

      await bannerAd.load();
      return await completer.future;
    } catch (e) {
      _failedLoads++;
      _logError('Exception loading banner ad: $e');
      return null;
    }
  }

  /// Load interstitial ad with full consent validation
  Future<InterstitialAd?> loadInterstitialAd({
    required String adUnitId,
    List<String>? keywords,
    Map<String, String>? customParameters,
  }) async {
    try {
      // Create ad request (includes validation)
      final adRequest = await createAdRequest(
        keywords: keywords,
        customParameters: customParameters,
      );

      if (adRequest == null) {
        _log('Interstitial ad load cancelled - no valid ad request');
        return null;
      }

      final completer = Completer<InterstitialAd?>();

      InterstitialAd.load(
        adUnitId: adUnitId,
        request: adRequest,
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            _successfulLoads++;
            _log('Interstitial ad loaded successfully');
            completer.complete(ad);
          },
          onAdFailedToLoad: (LoadAdError error) {
            _failedLoads++;
            _logError('Interstitial ad failed to load: ${error.message}');
            completer.complete(null);
          },
        ),
      );

      return await completer.future;
    } catch (e) {
      _failedLoads++;
      _logError('Exception loading interstitial ad: $e');
      return null;
    }
  }

  /// Load rewarded ad with full consent validation
  Future<RewardedAd?> loadRewardedAd({
    required String adUnitId,
    List<String>? keywords,
    Map<String, String>? customParameters,
  }) async {
    try {
      // Create ad request (includes validation)
      final adRequest = await createAdRequest(
        keywords: keywords,
        customParameters: customParameters,
      );

      if (adRequest == null) {
        _log('Rewarded ad load cancelled - no valid ad request');
        return null;
      }

      final completer = Completer<RewardedAd?>();

      RewardedAd.load(
        adUnitId: adUnitId,
        request: adRequest,
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            _successfulLoads++;
            _log('Rewarded ad loaded successfully');
            completer.complete(ad);
          },
          onAdFailedToLoad: (LoadAdError error) {
            _failedLoads++;
            _logError('Rewarded ad failed to load: ${error.message}');
            completer.complete(null);
          },
        ),
      );

      return await completer.future;
    } catch (e) {
      _failedLoads++;
      _logError('Exception loading rewarded ad: $e');
      return null;
    }
  }

  /// Initialize Mobile Ads SDK with consent
  Future<bool> initializeMobileAds() async {
    try {
      _log('Initializing Mobile Ads SDK...');

      // Ensure consent service is initialized first
      final consentInitialized = await _consentService.initialize();
      _log('Consent service initialized: $consentInitialized');

      // Validate consent before initializing ads
      final validation = await _consentService.validateConsentForAds();
      _log('Consent validation: ${validation.message}');

      // Initialize Mobile Ads SDK
      await MobileAds.instance.initialize();
      _log('Mobile Ads SDK initialized');

      // Handle consent if needed
      if (!validation.canRequestAds && validation.action == 'request_consent') {
        _log('Consent required - prompting user');
        final result = await _consentService.requestConsent();
        _log('Consent request result: ${result.message}');
      }

      return true;
    } catch (e) {
      _logError('Failed to initialize Mobile Ads: $e');
      return false;
    }
  }

  /// Get request statistics
  Map<String, dynamic> getRequestStats() {
    final fillRate = _totalRequests > 0
        ? ((_successfulLoads / _totalRequests) * 100).toStringAsFixed(2)
        : '0.00';

    final blockRate = _totalRequests > 0
        ? ((_blockedRequests / _totalRequests) * 100).toStringAsFixed(2)
        : '0.00';

    return {
      'totalRequests': _totalRequests,
      'blockedRequests': _blockedRequests,
      'successfulLoads': _successfulLoads,
      'failedLoads': _failedLoads,
      'fillRate': '$fillRate%',
      'blockRate': '$blockRate%',
    };
  }

  /// Reset statistics
  void resetStats() {
    _totalRequests = 0;
    _blockedRequests = 0;
    _successfulLoads = 0;
    _failedLoads = 0;
  }

  /// Check if ads are being blocked due to consent
  Future<ConsentBlockInfo> checkConsentBlocking() async {
    final validation = await _consentService.validateConsentForAds();
    final debugInfo = await _consentService.getDebugInfo();

    return ConsentBlockInfo(
      isBlocked: !validation.canRequestAds,
      reason: validation.message,
      action: validation.action,
      consentStatus: validation.consentStatus,
      debugInfo: debugInfo,
    );
  }

  /// Logging helpers
  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[RobustAdRequest] $message');
    }
  }

  void _logError(String message) {
    debugPrint('[RobustAdRequest ERROR] $message');
  }
}

/// Ad request validation result
class AdRequestValidation {
  final bool canRequestAds;
  final String reason;
  final String action;
  final ConsentStatus consentStatus;

  AdRequestValidation({
    required this.canRequestAds,
    required this.reason,
    required this.action,
    required this.consentStatus,
  });
}

/// Consent blocking information
class ConsentBlockInfo {
  final bool isBlocked;
  final String reason;
  final String action;
  final ConsentStatus consentStatus;
  final Map<String, dynamic> debugInfo;

  ConsentBlockInfo({
    required this.isBlocked,
    required this.reason,
    required this.action,
    required this.consentStatus,
    required this.debugInfo,
  });
}
