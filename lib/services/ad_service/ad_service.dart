import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob service for managing ads throughout the app
/// Follows current best practices for Flutter AdMob integration
class AdService extends ChangeNotifier {
  static AdService? _instance;
  static AdService get instance => _instance ??= AdService._();

  AdService._();

  // Ad unit IDs - Replace with your actual ad unit IDs for production
  static const String _testBannerAndroid =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testBannerIOS = 'ca-app-pub-3940256099942544/2934735716';
  static const String _testInterstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testInterstitialIOS =
      'ca-app-pub-3940256099942544/4411468910';
  static const String _testRewardedAndroid =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _testRewardedIOS =
      'ca-app-pub-3940256099942544/1712485313';

  // Production ad unit IDs - Set these when you have real ad units
  static const String _prodBannerAndroid = 'YOUR_BANNER_AD_UNIT_ID_ANDROID';
  static const String _prodBannerIOS = 'YOUR_BANNER_AD_UNIT_ID_IOS';
  static const String _prodInterstitialAndroid =
      'YOUR_INTERSTITIAL_AD_UNIT_ID_ANDROID';
  static const String _prodInterstitialIOS = 'YOUR_INTERSTITIAL_AD_UNIT_ID_IOS';
  static const String _prodRewardedAndroid = 'YOUR_REWARDED_AD_UNIT_ID_ANDROID';
  static const String _prodRewardedIOS = 'YOUR_REWARDED_AD_UNIT_ID_IOS';

  // Use test ads in debug mode
  static const bool _useTestAds = kDebugMode;

  bool _isInitialized = false;
  bool _isLoading = false;

  // Ad instances
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  // Ad state tracking
  bool _isBannerAdReady = false;
  bool _isInterstitialAdReady = false;
  bool _isRewardedAdReady = false;

  // Frequency control
  DateTime? _lastInterstitialShown;
  int _interstitialCount = 0;

  static const int _minInterstitialInterval = 30; // seconds
  static const int _maxInterstitialsPerSession = 3;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get isBannerAdReady => _isBannerAdReady;
  bool get isInterstitialAdReady => _isInterstitialAdReady;
  bool get isRewardedAdReady => _isRewardedAdReady;

  /// Initialize the AdMob SDK
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('AdMob initialized successfully');

      // Pre-load ads
      await _preloadAds();
    } catch (e) {
      debugPrint('Failed to initialize AdMob: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Pre-load ads for better performance
  Future<void> _preloadAds() async {
    await Future.wait([
      _loadBannerAd(),
      _loadInterstitialAd(),
      _loadRewardedAd(),
    ]);
  }

  /// Get appropriate ad unit ID based on platform and ad type
  String getAdUnitId(String adType) {
    if (_useTestAds) {
      switch (adType) {
        case 'banner':
          return Platform.isAndroid ? _testBannerAndroid : _testBannerIOS;
        case 'interstitial':
          return Platform.isAndroid
              ? _testInterstitialAndroid
              : _testInterstitialIOS;
        case 'rewarded':
          return Platform.isAndroid ? _testRewardedAndroid : _testRewardedIOS;
        default:
          throw ArgumentError('Unknown ad type: $adType');
      }
    } else {
      switch (adType) {
        case 'banner':
          return Platform.isAndroid ? _prodBannerAndroid : _prodBannerIOS;
        case 'interstitial':
          return Platform.isAndroid
              ? _prodInterstitialAndroid
              : _prodInterstitialIOS;
        case 'rewarded':
          return Platform.isAndroid ? _prodRewardedAndroid : _prodRewardedIOS;
        default:
          throw ArgumentError('Unknown ad type: $adType');
      }
    }
  }

  /// Load banner ad
  Future<void> _loadBannerAd() async {
    try {
      _bannerAd = BannerAd(
        adUnitId: getAdUnitId('banner'),
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            debugPrint('Banner ad loaded');
            _isBannerAdReady = true;
            notifyListeners();
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('Banner ad failed to load: $error');
            _isBannerAdReady = false;
            _bannerAd?.dispose();
            _bannerAd = null;
            notifyListeners();
          },
          onAdOpened: (ad) => debugPrint('Banner ad opened'),
          onAdClosed: (ad) => debugPrint('Banner ad closed'),
        ),
      );

      await _bannerAd!.load();
    } catch (e) {
      debugPrint('Error loading banner ad: $e');
      _isBannerAdReady = false;
      notifyListeners();
    }
  }

  /// Load interstitial ad
  Future<void> _loadInterstitialAd() async {
    try {
      await InterstitialAd.load(
        adUnitId: getAdUnitId('interstitial'),
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('Interstitial ad loaded');
            _interstitialAd = ad;
            _isInterstitialAdReady = true;
            notifyListeners();
          },
          onAdFailedToLoad: (error) {
            debugPrint('Interstitial ad failed to load: $error');
            _interstitialAd = null;
            _isInterstitialAdReady = false;
            notifyListeners();
          },
        ),
      );
    } catch (e) {
      debugPrint('Error loading interstitial ad: $e');
      _isInterstitialAdReady = false;
      notifyListeners();
    }
  }

  /// Load rewarded ad
  Future<void> _loadRewardedAd() async {
    try {
      await RewardedAd.load(
        adUnitId: getAdUnitId('rewarded'),
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('Rewarded ad loaded');
            _rewardedAd = ad;
            _isRewardedAdReady = true;
            notifyListeners();
          },
          onAdFailedToLoad: (error) {
            debugPrint('Rewarded ad failed to load: $error');
            _rewardedAd = null;
            _isRewardedAdReady = false;
            notifyListeners();
          },
        ),
      );
    } catch (e) {
      debugPrint('Error loading rewarded ad: $e');
      _isRewardedAdReady = false;
      notifyListeners();
    }
  }

  /// Get banner ad widget
  Widget? getBannerAdWidget() {
    if (_isBannerAdReady && _bannerAd != null) {
      return SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    return null;
  }

  /// Show interstitial ad with frequency control
  Future<void> showInterstitialAd({
    VoidCallback? onAdClosed,
    VoidCallback? onAdFailedToShow,
  }) async {
    if (!_canShowInterstitial()) {
      debugPrint('Interstitial ad not ready or frequency limit reached');
      onAdFailedToShow?.call();
      return;
    }

    try {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          debugPrint('Interstitial ad showed full screen content');
          _lastInterstitialShown = DateTime.now();
          _interstitialCount++;
        },
        onAdDismissedFullScreenContent: (ad) {
          debugPrint('Interstitial ad dismissed');
          ad.dispose();
          _interstitialAd = null;
          _isInterstitialAdReady = false;
          notifyListeners();
          onAdClosed?.call();

          // Reload for next time
          _loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('Interstitial ad failed to show: $error');
          ad.dispose();
          _interstitialAd = null;
          _isInterstitialAdReady = false;
          notifyListeners();
          onAdFailedToShow?.call();

          // Reload for next time
          _loadInterstitialAd();
        },
      );

      await _interstitialAd!.show();
    } catch (e) {
      debugPrint('Error showing interstitial ad: $e');
      onAdFailedToShow?.call();
    }
  }

  /// Show rewarded ad
  Future<void> showRewardedAd({
    required void Function(AdWithoutView, RewardItem) onUserEarnedReward,
    VoidCallback? onAdClosed,
    VoidCallback? onAdFailedToShow,
  }) async {
    if (!_isRewardedAdReady || _rewardedAd == null) {
      debugPrint('Rewarded ad not ready');
      onAdFailedToShow?.call();
      return;
    }

    try {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          debugPrint('Rewarded ad showed full screen content');
        },
        onAdDismissedFullScreenContent: (ad) {
          debugPrint('Rewarded ad dismissed');
          ad.dispose();
          _rewardedAd = null;
          _isRewardedAdReady = false;
          notifyListeners();
          onAdClosed?.call();

          // Reload for next time
          _loadRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('Rewarded ad failed to show: $error');
          ad.dispose();
          _rewardedAd = null;
          _isRewardedAdReady = false;
          notifyListeners();
          onAdFailedToShow?.call();

          // Reload for next time
          _loadRewardedAd();
        },
      );

      await _rewardedAd!.show(onUserEarnedReward: onUserEarnedReward);
    } catch (e) {
      debugPrint('Error showing rewarded ad: $e');
      onAdFailedToShow?.call();
    }
  }

  /// Check if interstitial ad can be shown based on frequency limits
  bool _canShowInterstitial() {
    if (!_isInterstitialAdReady || _interstitialAd == null) return false;

    // Check session limit
    if (_interstitialCount >= _maxInterstitialsPerSession) return false;

    // Check time interval
    if (_lastInterstitialShown != null) {
      final timeSinceLastAd =
          DateTime.now().difference(_lastInterstitialShown!);
      if (timeSinceLastAd.inSeconds < _minInterstitialInterval) return false;
    }

    return true;
  }

  /// Reset session counters (call when app starts or after significant breaks)
  void resetSessionCounters() {
    _interstitialCount = 0;
    _lastInterstitialShown = null;
    notifyListeners();
  }

  /// Dispose all ads
  @override
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }
}
