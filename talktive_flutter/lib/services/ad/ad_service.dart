import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'consent_service.dart';
import '../../config/ad_config.dart';
import '../../providers/current_resident_provider.dart';
import '../../helpers/resident_ext.dart';

/// Service that manages interstitial ads and their display logic
class AdService {
  final Ref ref;
  final ConsentService _consentService;

  InterstitialAd? _interstitialAd;
  bool _isAdReady = false;
  bool _isLoading = false;
  DateTime? _lastAdShown;

  // Minimal interval between ads to prevent user frustration
  static const Duration _minInterval = Duration(minutes: 2);

  AdService(this.ref, this._consentService);

  String get _interstitialAdUnitId {
    // In Serverpod version, we check the resident's admin status for compliance
    final resident = ref.read(currentResidentProvider).value;
    final isAdmin = resident?.isAdmin ?? false;

    // AdMob Policy: Use test ads for debug mode and admin accounts
    if (kDebugMode || isAdmin) {
      debugPrint('[AdService] Using test ad unit ID');
      // Official Google Interstitial Test ID
      return 'ca-app-pub-3940256099942544/1033173712';
    }

    debugPrint('[AdService] Using production ad unit ID');
    return AdConfig.interstitialAdUnitId;
  }

  /// Initialize the Mobile Ads SDK and Consent Service
  Future<void> initialize() async {
    if (kIsWeb) {
      debugPrint('[AdService] Skipping ads initialization on Web');
      return;
    }
    debugPrint('[AdService] Initializing Mobile Ads SDK...');
    try {
      await MobileAds.instance.initialize();
      await _consentService.initialize();

      // Load first ad after initialization
      _loadInterstitialAd();
    } catch (e) {
      debugPrint('[AdService] Initialization error: $e');
    }
  }

  /// Load a new interstitial ad in the background
  void _loadInterstitialAd() async {
    if (_isLoading || _isAdReady) return;

    if (!_consentService.canRequestAds) {
      debugPrint('[AdService] Cannot request ads: No consent');
      return;
    }

    _isLoading = true;
    debugPrint('[AdService] Loading interstitial ad...');

    try {
      await InterstitialAd.load(
        adUnitId: _interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('[AdService] Interstitial ad loaded');
            _interstitialAd = ad;
            _isAdReady = true;
            _isLoading = false;

            _setupAdCallbacks(ad);
          },
          onAdFailedToLoad: (error) {
            debugPrint(
              '[AdService] Interstitial ad failed to load: ${error.message}',
            );
            _isLoading = false;
            _interstitialAd = null;
            _isAdReady = false;

            // Retry after a delay (30s)
            Future.delayed(
              const Duration(seconds: 30),
              () => _loadInterstitialAd(),
            );
          },
        ),
      );
    } catch (e) {
      debugPrint('[AdService] Exception loading ad: $e');
      _isLoading = false;
    }
  }

  void _setupAdCallbacks(InterstitialAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('[AdService] Ad dismissed');
        ad.dispose();
        _interstitialAd = null;
        _isAdReady = false;
        _loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdService] Ad failed to show: ${error.message}');
        ad.dispose();
        _interstitialAd = null;
        _isAdReady = false;
        _loadInterstitialAd();
      },
      onAdShowedFullScreenContent: (ad) {
        debugPrint('[AdService] Ad showed full screen content');
      },
    );
  }

  /// Check if an ad should be shown to the current user
  bool _shouldShowAd() {
    final resident = ref.read(currentResidentProvider).value;

    // 1. App must have an ad ready
    if (!_isAdReady || _interstitialAd == null) return false;

    // 2. User must not be a premium member
    if (resident == null || resident.isPremium) return false;

    // 3. Must respect the cooldown interval
    if (_lastAdShown != null) {
      final elapsed = DateTime.now().difference(_lastAdShown!);
      if (elapsed < _minInterval) {
        debugPrint(
          '[AdService] Ad skipped: Cooldown active (${elapsed.inSeconds}s elapsed)',
        );
        return false;
      }
    }

    return true;
  }

  /// Show the interstitial ad if conditions are met
  /// [onAdClosed] is called whether the ad was shown and dismissed, or if it was skipped.
  Future<void> showInterstitialAd({VoidCallback? onAdClosed}) async {
    if (kIsWeb) {
      onAdClosed?.call();
      return;
    }
    if (!_shouldShowAd()) {
      debugPrint('[AdService] Conditions not met, skipping ad');
      onAdClosed?.call();
      return;
    }

    debugPrint('[AdService] Showing interstitial ad');
    _lastAdShown = DateTime.now();

    // Override callbacks to ensure onAdClosed is triggered
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('[AdService] Ad dismissed by user');
        ad.dispose();
        _interstitialAd = null;
        _isAdReady = false;
        onAdClosed?.call();
        _loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdService] Ad failed to show: ${error.message}');
        ad.dispose();
        _interstitialAd = null;
        _isAdReady = false;
        onAdClosed?.call();
        _loadInterstitialAd();
      },
    );

    try {
      await _interstitialAd!.show();
    } catch (e) {
      debugPrint('[AdService] Error showing ad: $e');
      onAdClosed?.call();
    }
  }
}

final adServiceProvider = Provider<AdService>((ref) {
  final consent = ref.watch(consentServiceProvider);
  return AdService(ref, consent);
});
