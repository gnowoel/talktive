import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'improved_consent_manager.dart';

/// Improved ad manager that ensures ads can be shown even without consent
/// by properly handling non-personalized ads
class ImprovedAdManager {
  static ImprovedAdManager? _instance;
  static ImprovedAdManager get instance => _instance ??= ImprovedAdManager._();

  ImprovedAdManager._();

  final ImprovedConsentManager _consentManager =
      ImprovedConsentManager.instance;

  // State management
  bool _isInitialized = false;
  bool _isInitializing = false;

  // Ad configuration
  static const Duration _adLoadTimeout = Duration(seconds: 10);
  static const int _maxAdLoadRetries = 2;

  // Statistics
  int _totalAdRequests = 0;
  int _successfulLoads = 0;
  int _failedLoads = 0;
  int _consentBlockedRequests = 0;

  /// Initialize ad manager without blocking app startup
  Future<void> initializeAsync() async {
    if (_isInitialized || _isInitializing) return;

    _isInitializing = true;

    try {
      // Start consent manager initialization (non-blocking)
      _consentManager.initializeAsync();

      // Initialize Mobile Ads SDK
      await _initializeMobileAds();

      _isInitialized = true;
      _log('Ad manager initialized successfully');
    } catch (e) {
      _logError('Failed to initialize ad manager: $e');
      // Don't throw - allow app to continue without ads
      _isInitialized = true;
    } finally {
      _isInitializing = false;
    }
  }

  /// Initialize Mobile Ads SDK
  Future<void> _initializeMobileAds() async {
    try {
      await MobileAds.instance.initialize();
      _log('Mobile Ads SDK initialized');

      // Configure test devices if in debug mode
      if (kDebugMode) {
        MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(
            testDeviceIds: <String>[
              'YOUR_TEST_DEVICE_ID', // Add your test device IDs here
            ],
          ),
        );
      }
    } catch (e) {
      _logError('Failed to initialize Mobile Ads SDK: $e');
      rethrow;
    }
  }

  /// Load a banner ad
  Future<BannerAd?> loadBannerAd({
    required String adUnitId,
    required AdSize size,
    Map<String, String>? customTargeting,
  }) async {
    _totalAdRequests++;

    try {
      // Check if we can request ads
      if (!_canRequestAds()) {
        _consentBlockedRequests++;
        _log('Banner ad request blocked - no consent for any ads');
        return null;
      }

      // Create appropriate ad request
      final adRequest = _createAdRequest(customTargeting: customTargeting);

      final completer = Completer<BannerAd?>();

      final bannerAd = BannerAd(
        adUnitId: adUnitId,
        size: size,
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

      // Load the ad with timeout
      await bannerAd.load();

      return await completer.future.timeout(
        _adLoadTimeout,
        onTimeout: () {
          _failedLoads++;
          _logError('Banner ad load timed out');
          bannerAd.dispose();
          return null;
        },
      );
    } catch (e) {
      _failedLoads++;
      _logError('Exception loading banner ad: $e');
      return null;
    }
  }

  /// Load an interstitial ad
  Future<InterstitialAd?> loadInterstitialAd({
    required String adUnitId,
    Map<String, String>? customTargeting,
  }) async {
    _totalAdRequests++;

    try {
      // Check if we can request ads
      if (!_canRequestAds()) {
        _consentBlockedRequests++;
        _log('Interstitial ad request blocked - no consent for any ads');
        return null;
      }

      // Create appropriate ad request
      final adRequest = _createAdRequest(customTargeting: customTargeting);

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

      return await completer.future.timeout(
        _adLoadTimeout,
        onTimeout: () {
          _failedLoads++;
          _logError('Interstitial ad load timed out');
          return null;
        },
      );
    } catch (e) {
      _failedLoads++;
      _logError('Exception loading interstitial ad: $e');
      return null;
    }
  }

  /// Load a rewarded ad with retry logic
  Future<RewardedAd?> loadRewardedAd({
    required String adUnitId,
    Map<String, String>? customTargeting,
    int maxRetries = _maxAdLoadRetries,
  }) async {
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      if (attempt > 0) {
        _log('Retrying rewarded ad load (attempt ${attempt + 1})');
        await Future.delayed(Duration(seconds: attempt));
      }

      _totalAdRequests++;

      try {
        // Check if we can request ads
        if (!_canRequestAds()) {
          _consentBlockedRequests++;
          _log('Rewarded ad request blocked - no consent for any ads');
          return null;
        }

        // Create appropriate ad request
        final adRequest = _createAdRequest(customTargeting: customTargeting);

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

        final ad = await completer.future.timeout(
          _adLoadTimeout,
          onTimeout: () {
            _failedLoads++;
            _logError('Rewarded ad load timed out');
            return null;
          },
        );

        if (ad != null) {
          return ad; // Success!
        }

        // Continue to retry if ad is null
      } catch (e) {
        _failedLoads++;
        _logError('Exception loading rewarded ad: $e');
        // Continue to retry
      }
    }

    _logError('Failed to load rewarded ad after ${maxRetries + 1} attempts');
    return null;
  }

  /// Load a native ad
  Future<NativeAd?> loadNativeAd({
    required String adUnitId,
    required NativeTemplateStyle templateStyle,
    Map<String, String>? customTargeting,
  }) async {
    _totalAdRequests++;

    try {
      // Check if we can request ads
      if (!_canRequestAds()) {
        _consentBlockedRequests++;
        _log('Native ad request blocked - no consent for any ads');
        return null;
      }

      // Create appropriate ad request
      final adRequest = _createAdRequest(customTargeting: customTargeting);

      final completer = Completer<NativeAd?>();

      final nativeAd = NativeAd(
        adUnitId: adUnitId,
        request: adRequest,
        listener: NativeAdListener(
          onAdLoaded: (Ad ad) {
            _successfulLoads++;
            _log('Native ad loaded successfully');
            completer.complete(ad as NativeAd);
          },
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            _failedLoads++;
            _logError('Native ad failed to load: ${error.message}');
            ad.dispose();
            completer.complete(null);
          },
        ),
        nativeTemplateStyle: templateStyle,
      );

      await nativeAd.load();

      return await completer.future.timeout(
        _adLoadTimeout,
        onTimeout: () {
          _failedLoads++;
          _logError('Native ad load timed out');
          nativeAd.dispose();
          return null;
        },
      );
    } catch (e) {
      _failedLoads++;
      _logError('Exception loading native ad: $e');
      return null;
    }
  }

  /// Check if we can request ads
  bool _canRequestAds() {
    final canRequest = _consentManager.canRequestAds;
    if (!canRequest) {
      _log('Cannot request ads - consent not available');
    }
    return canRequest;
  }

  /// Create ad request with appropriate parameters
  AdRequest _createAdRequest({Map<String, String>? customTargeting}) {
    return _consentManager.createAdRequest(customTargeting: customTargeting);
  }

  /// Show consent form manually (e.g., from privacy settings)
  Future<ConsentResult> showConsentForm() async {
    return await _consentManager.requestConsentManually();
  }

  /// Show privacy options
  Future<bool> showPrivacyOptions() async {
    return await _consentManager.showPrivacyOptions();
  }

  /// Get current ad serving status
  AdServingStatus getAdServingStatus() {
    if (!_consentManager.canRequestAds) {
      return AdServingStatus.blocked;
    } else if (_consentManager.canShowPersonalizedAds) {
      return AdServingStatus.personalized;
    } else if (_consentManager.canShowNonPersonalizedAds) {
      return AdServingStatus.nonPersonalized;
    } else {
      return AdServingStatus.blocked;
    }
  }

  /// Get statistics
  Map<String, dynamic> getStatistics() {
    final fillRate = _totalAdRequests > 0
        ? (_successfulLoads / _totalAdRequests * 100).toStringAsFixed(2)
        : '0.00';

    final blockRate = _totalAdRequests > 0
        ? (_consentBlockedRequests / _totalAdRequests * 100).toStringAsFixed(2)
        : '0.00';

    return {
      'initialized': _isInitialized,
      'totalRequests': _totalAdRequests,
      'successfulLoads': _successfulLoads,
      'failedLoads': _failedLoads,
      'consentBlockedRequests': _consentBlockedRequests,
      'fillRate': '$fillRate%',
      'blockRate': '$blockRate%',
      'adServingStatus': getAdServingStatus().toString(),
      'consentInfo': _consentManager.getDebugInfo(),
    };
  }

  /// Reset statistics
  void resetStatistics() {
    _totalAdRequests = 0;
    _successfulLoads = 0;
    _failedLoads = 0;
    _consentBlockedRequests = 0;
  }

  /// Reset consent (for testing)
  Future<void> resetConsent() async {
    await _consentManager.resetConsent();
  }

  /// Logging helpers
  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[ImprovedAdManager] $message');
    }
  }

  void _logError(String message) {
    debugPrint('[ImprovedAdManager ERROR] $message');
  }
}

/// Ad serving status
enum AdServingStatus {
  personalized,
  nonPersonalized,
  blocked,
}
