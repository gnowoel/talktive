import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'consent_service.dart';
import 'admob_compliance.dart';

/// Helper class for making consent-aware ad requests
///
/// This class ensures ads can be loaded while properly respecting user consent
/// and GDPR requirements, while maximizing ad revenue by using non-personalized
/// ads when personalized ads aren't allowed.
class AdRequestHelper {
  static AdRequestHelper? _instance;
  static AdRequestHelper get instance => _instance ??= AdRequestHelper._();

  AdRequestHelper._();

  final ConsentService _consentService = ConsentService.instance;

  /// Create an AdRequest with proper consent parameters
  Future<AdRequest> createAdRequest({
    Map<String, String>? customParameters,
    List<String>? keywords,
    String? contentUrl,
    List<String>? neighboringContentUrls,
  }) async {
    try {
      // Get consent-based parameters
      final consentParams = await _consentService.getAdRequestParameters();

      // Merge custom parameters with consent parameters
      final Map<String, String> finalParams = {
        ...consentParams,
        ...?customParameters,
      };

      final adRequest = AdRequest(
        keywords: keywords,
        contentUrl: contentUrl,
        neighboringContentUrls: neighboringContentUrls,
        extras: finalParams.isNotEmpty ? finalParams : null,
      );

      _logAdRequest('Created ad request with params: $finalParams');
      return adRequest;
    } catch (e) {
      _logError('Failed to create ad request: $e');

      // Fallback to basic ad request
      return AdRequest(
        keywords: keywords,
        contentUrl: contentUrl,
        neighboringContentUrls: neighboringContentUrls,
        extras: customParameters,
      );
    }
  }

  /// Validate that ads can be requested and provide guidance
  Future<AdRequestValidation> validateAdRequest() async {
    try {
      final consentStatus = await _consentService.getConsentStatus();
      final canRequestAds = await _consentService.canRequestAds();
      final canShowPersonalized =
          await _consentService.canShowPersonalizedAds();
      final canShowNonPersonalized =
          await _consentService.canShowNonPersonalizedAds();
      final isConsentRequired = await _consentService.isInConsentRegion();

      // Determine if we can make ad requests (simplified logic)
      bool canMakeRequest = canRequestAds;

      // Determine ad type
      AdType recommendedAdType = AdType.personalized;
      if (!canShowPersonalized && canShowNonPersonalized) {
        recommendedAdType = AdType.nonPersonalized;
      } else if (!canShowPersonalized && !canShowNonPersonalized) {
        recommendedAdType = AdType.none;
        canMakeRequest = false;
      }

      String message = _getValidationMessage(
        consentStatus,
        canMakeRequest,
        recommendedAdType,
        isConsentRequired,
      );

      final validation = AdRequestValidation(
        canRequestAds: canMakeRequest,
        recommendedAdType: recommendedAdType,
        consentStatus: consentStatus,
        message: message,
        requiresConsent: isConsentRequired,
        canShowPersonalized: canShowPersonalized,
        canShowNonPersonalized: canShowNonPersonalized,
      );

      _logAdRequest('Ad request validation: ${validation.toString()}');
      return validation;
    } catch (e) {
      _logError('Failed to validate ad request: $e');

      // Return permissive fallback (simplified)
      return AdRequestValidation(
        canRequestAds: true,
        recommendedAdType: AdType.personalized,
        consentStatus: ConsentStatus.unknown,
        message: 'Validation failed, using fallback behavior',
        requiresConsent: false,
        canShowPersonalized: true,
        canShowNonPersonalized: true,
      );
    }
  }

  /// Load banner ad with consent handling
  Future<BannerAd?> loadBannerAd({
    required String adUnitId,
    required AdSize adSize,
    Map<String, String>? customParameters,
    List<String>? keywords,
  }) async {
    try {
      // Validate consent before attempting to load ad
      final validation = await validateAdRequest();

      if (!validation.canRequestAds) {
        _logAdRequest('Cannot load ad: ${validation.message}');
        return null;
      }

      final adRequest = await createAdRequest(
        customParameters: customParameters,
        keywords: keywords,
      );

      final bannerAd = BannerAd(
        adUnitId: adUnitId,
        size: adSize,
        request: adRequest,
        listener: BannerAdListener(
          onAdLoaded: (Ad ad) {
            _logAdRequest(
                'Banner ad loaded successfully (${validation.recommendedAdType.name})');
          },
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            _logError('Banner ad failed to load: ${error.message}');
            ad.dispose();
          },
          onAdOpened: (Ad ad) {
            _logAdRequest('Banner ad opened');
          },
          onAdClosed: (Ad ad) {
            _logAdRequest('Banner ad closed');
          },
        ),
      );

      await bannerAd.load();
      return bannerAd;
    } catch (e) {
      _logError('Failed to load banner ad: $e');
      return null;
    }
  }

  /// Load interstitial ad with consent handling
  Future<InterstitialAd?> loadInterstitialAd({
    required String adUnitId,
    Map<String, String>? customParameters,
    List<String>? keywords,
  }) async {
    try {
      final validation = await validateAdRequest();

      if (!validation.canRequestAds) {
        _logAdRequest('Cannot request interstitial ad: ${validation.message}');
        return null;
      }

      final adRequest = await createAdRequest(
        customParameters: customParameters,
        keywords: keywords,
      );

      final completer = Completer<InterstitialAd?>();

      InterstitialAd.load(
        adUnitId: adUnitId,
        request: adRequest,
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            _logAdRequest(
                'Interstitial ad loaded successfully (${validation.recommendedAdType.name})');
            completer.complete(ad);
          },
          onAdFailedToLoad: (LoadAdError error) {
            _logError('Interstitial ad failed to load: ${error.message}');
            completer.complete(null);
          },
        ),
      );

      return completer.future;
    } catch (e) {
      _logError('Failed to load interstitial ad: $e');
      return null;
    }
  }

  /// Load rewarded ad with consent handling
  Future<RewardedAd?> loadRewardedAd({
    required String adUnitId,
    Map<String, String>? customParameters,
    List<String>? keywords,
  }) async {
    try {
      final validation = await validateAdRequest();

      if (!validation.canRequestAds) {
        _logAdRequest('Cannot request rewarded ad: ${validation.message}');
        return null;
      }

      final adRequest = await createAdRequest(
        customParameters: customParameters,
        keywords: keywords,
      );

      final completer = Completer<RewardedAd?>();

      RewardedAd.load(
        adUnitId: adUnitId,
        request: adRequest,
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            _logAdRequest(
                'Rewarded ad loaded successfully (${validation.recommendedAdType.name})');
            completer.complete(ad);
          },
          onAdFailedToLoad: (LoadAdError error) {
            _logError('Rewarded ad failed to load: ${error.message}');
            completer.complete(null);
          },
        ),
      );

      return completer.future;
    } catch (e) {
      _logError('Failed to load rewarded ad: $e');
      return null;
    }
  }

  /// Initialize ads with consent handling
  Future<bool> initializeAds() async {
    try {
      _logAdRequest('Initializing Mobile Ads SDK...');

      // Initialize the consent service first
      final consentInitialized = await _consentService.initialize();
      _logAdRequest('Consent service initialized: $consentInitialized');

      // Initialize Mobile Ads SDK
      await MobileAds.instance.initialize();

      // Validate consent for ad requests
      final validation = await validateAdRequest();

      _logAdRequest(
          'Mobile Ads SDK initialized. Can request ads: ${validation.canRequestAds}');

      return validation.canRequestAds;
    } catch (e) {
      _logError('Failed to initialize ads: $e');
      return false;
    }
  }

  /// Request consent if needed and return whether ads can be shown
  Future<bool> handleConsentAndInitialize() async {
    try {
      // Initialize and request consent if needed
      final consentStatus = await _consentService.initializeAndRequestConsent();

      // Initialize Mobile Ads SDK
      await MobileAds.instance.initialize();

      // Check if we can show ads
      final validation = await validateAdRequest();

      _logAdRequest(
          'Consent handled. Status: $consentStatus, Can show ads: ${validation.canRequestAds}');

      return validation.canRequestAds;
    } catch (e) {
      _logError('Failed to handle consent and initialize: $e');
      // Return true as fallback to not completely block ads
      return true;
    }
  }

  /// Get debug information about current ad request capability
  Future<Map<String, dynamic>> getDebugInfo() async {
    try {
      final consentDebug = await _consentService.getConsentDebugInfo();
      final validation = await validateAdRequest();

      return {
        'adRequestHelper': {
          'canRequestAds': validation.canRequestAds,
          'recommendedAdType': validation.recommendedAdType.name,
          'validationMessage': validation.message,
        },
        'consentService': consentDebug,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': 'Failed to get debug info: $e',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  String _getValidationMessage(
    ConsentStatus status,
    bool canRequest,
    AdType adType,
    bool requiresConsent,
  ) {
    if (!canRequest) {
      return 'Cannot request ads due to consent restrictions';
    }

    switch (status) {
      case ConsentStatus.notRequired:
        return 'Personalized ads allowed (non-EEA region)';
      case ConsentStatus.obtained:
        return 'Personalized ads allowed (consent obtained)';
      case ConsentStatus.required:
        if (adType == AdType.nonPersonalized) {
          return 'Non-personalized ads only (consent required but not obtained)';
        }
        return 'Ads blocked (consent required but not obtained)';
      case ConsentStatus.unknown:
        if (adType == AdType.nonPersonalized) {
          return 'Non-personalized ads (consent status unknown)';
        }
        return 'Ads allowed with fallback behavior';
    }
  }

  void _logAdRequest(String message) {
    if (AdMobCompliance.shouldLogVerbose || kDebugMode) {
      debugPrint('[Ad Request Helper] $message');
    }
  }

  void _logError(String message) {
    debugPrint('[Ad Request Helper ERROR] $message');
  }
}

/// Validation result for ad requests
class AdRequestValidation {
  final bool canRequestAds;
  final AdType recommendedAdType;
  final ConsentStatus consentStatus;
  final String message;
  final bool requiresConsent;
  final bool canShowPersonalized;
  final bool canShowNonPersonalized;

  const AdRequestValidation({
    required this.canRequestAds,
    required this.recommendedAdType,
    required this.consentStatus,
    required this.message,
    required this.requiresConsent,
    required this.canShowPersonalized,
    required this.canShowNonPersonalized,
  });

  @override
  String toString() {
    return 'AdRequestValidation(canRequest: $canRequestAds, type: ${recommendedAdType.name}, status: $consentStatus, message: $message)';
  }
}

/// Types of ads that can be shown
enum AdType {
  personalized,
  nonPersonalized,
  none,
}
