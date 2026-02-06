import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'improved_consent_manager.dart';
import '../../config/ad_config.dart';

import '../../services/user_cache.dart';

/// Simple ad manager without complex session management
/// Just loads ads and shows them based on simple timing rules
class SimpleAdManager {
  static SimpleAdManager? _instance;
  static SimpleAdManager get instance => _instance ??= SimpleAdManager._();

  SimpleAdManager._();

  // Core components
  final ImprovedConsentManager _consentManager =
      ImprovedConsentManager.instance;

  // Ad state
  InterstitialAd? _interstitialAd;
  bool _isAdReady = false;
  bool _isLoading = false;
  bool _isInitialized = false;

  // User-aware timing control
  DateTime? _lastAdShown;
  int _adsShownCount = 0;
  DateTime? _initTime;

  // Progressive timing intervals based on user status
  // IMPROVED TIMING STRATEGY:
  // - Newcomers: First ad at 3min, then every ~3min, 2.6min, 2.25min, 1.9min, 1.5min
  // - Regular users: First ad at 1.5min, then every ~2min, 1.75min, 1.5min, 1.25min, 1min
  // - Minimum 60s between ads to prevent disruption
  // - Progressive decrease keeps frequency reasonable while increasing revenue
  static const Duration _newcomerFirstAdDelay = Duration(minutes: 3);
  static const Duration _regularFirstAdDelay = Duration(seconds: 90);
  static const Duration _minTimeBetweenAds = Duration(seconds: 60);

  // Progressive interval multipliers (gradually decrease frequency)
  static const List<double> _intervalMultipliers = [
    2.0, // First interval: 2x base (~3-2 minutes)
    1.75, // Second interval: 1.75x base (~2.6-1.75 minutes)
    1.5, // Third interval: 1.5x base (~2.25-1.5 minutes)
    1.25, // Fourth interval: 1.25x base (~1.9-1.25 minutes)
    1.0, // Fifth+ interval: 1x base (~1.5-1 minutes)
  ];

  // Ad unit IDs
  String get _interstitialAdUnitId {
    if (kDebugMode) {
      return 'ca-app-pub-3940256099942544/1033173712'; // Google test ID
    }
    return AdConfig.interstitialAdUnitId;
  }

  /// Initialize the ad manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('[SimpleAdManager] Initializing...');

    // Initialize consent manager (non-blocking)
    _consentManager.initializeAsync();

    // Initialize Mobile Ads SDK
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      _initTime = DateTime.now();
      debugPrint('[SimpleAdManager] Initialized successfully');

      // Start preloading an ad after a short delay
      Future.delayed(const Duration(seconds: 5), () {
        _loadInterstitialAd();
      });
    } catch (e) {
      debugPrint('[SimpleAdManager] Failed to initialize: $e');
      _isInitialized = true; // Mark as initialized anyway
    }
  }

  /// Load an interstitial ad
  Future<void> _loadInterstitialAd() async {
    if (_isLoading || _isAdReady) return;

    // Check if we can request ads
    if (!_consentManager.canRequestAds) {
      debugPrint('[SimpleAdManager] Cannot load ad - no consent');
      return;
    }

    _isLoading = true;

    try {
      debugPrint('[SimpleAdManager] Loading interstitial ad...');

      // Create ad request with appropriate consent
      final adRequest = _consentManager.createAdRequest(
        customTargeting: {'simple': 'true'},
      );

      InterstitialAd.load(
        adUnitId: _interstitialAdUnitId,
        request: adRequest,
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            debugPrint('[SimpleAdManager] Ad loaded successfully');
            _interstitialAd = ad;
            _isAdReady = true;
            _isLoading = false;

            // Set up callbacks
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (Ad ad) {
                debugPrint('[SimpleAdManager] Ad dismissed');
                ad.dispose();
                _interstitialAd = null;
                _isAdReady = false;
                // Load next ad after a delay
                Future.delayed(
                    const Duration(seconds: 10), _loadInterstitialAd);
              },
              onAdFailedToShowFullScreenContent: (Ad ad, AdError error) {
                debugPrint(
                    '[SimpleAdManager] Ad failed to show: ${error.message}');
                ad.dispose();
                _interstitialAd = null;
                _isAdReady = false;
                // Try loading again
                Future.delayed(const Duration(seconds: 5), _loadInterstitialAd);
              },
            );
          },
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('[SimpleAdManager] Ad failed to load: ${error.message}');
            _isLoading = false;
            // Retry after delay
            Future.delayed(const Duration(seconds: 30), _loadInterstitialAd);
          },
        ),
      );
    } catch (e) {
      debugPrint('[SimpleAdManager] Exception loading ad: $e');
      _isLoading = false;
    }
  }

  /// Get appropriate interval based on user status and ad count
  Duration _getAdInterval() {
    // Base interval depends on user status
    final user = UserCache().user;
    final bool isNewcomer = user != null && user.status == 'newcomer';
    final Duration baseInterval = isNewcomer
        ? Duration(seconds: 90) // 1.5 minute base for newcomers
        : Duration(seconds: 60); // 1 minute base for regular users

    // Apply progressive multiplier based on how many ads shown
    final multiplierIndex =
        _adsShownCount.clamp(0, _intervalMultipliers.length - 1);
    final multiplier = _intervalMultipliers[multiplierIndex];

    // Calculate actual interval
    final interval = Duration(
        milliseconds: (baseInterval.inMilliseconds * multiplier).round());

    // Ensure we never go below minimum
    return interval.compareTo(_minTimeBetweenAds) > 0
        ? interval
        : _minTimeBetweenAds;
  }

  /// Get first ad delay based on user status
  Duration _getFirstAdDelay() {
    final user = UserCache().user;
    if (user == null) return _regularFirstAdDelay;

    // Give newcomers more time to explore
    if (user.status == 'newcomer') {
      return _newcomerFirstAdDelay;
    }

    // Regular users get standard delay
    return _regularFirstAdDelay;
  }

  /// Check if we should show an ad now
  bool shouldShowAd() {
    // Not initialized yet
    if (!_isInitialized || _initTime == null) {
      debugPrint('[SimpleAdManager] Not initialized yet');
      return false;
    }

    // No consent to show ads
    if (!_consentManager.canRequestAds) {
      debugPrint('[SimpleAdManager] No consent for ads');
      return false;
    }

    // Ad not ready
    if (!_isAdReady || _interstitialAd == null) {
      debugPrint('[SimpleAdManager] Ad not ready');
      return false;
    }

    // Too soon after initialization
    final timeSinceInit = DateTime.now().difference(_initTime!);
    final firstAdDelay = _getFirstAdDelay();
    if (timeSinceInit < firstAdDelay) {
      debugPrint(
          '[SimpleAdManager] Too soon after init: ${timeSinceInit.inSeconds}s < ${firstAdDelay.inSeconds}s');
      return false;
    }

    // Too soon after last ad
    if (_lastAdShown != null) {
      final timeSinceLastAd = DateTime.now().difference(_lastAdShown!);
      final requiredInterval = _getAdInterval();
      if (timeSinceLastAd < requiredInterval) {
        debugPrint(
            '[SimpleAdManager] Too soon since last ad: ${timeSinceLastAd.inSeconds}s < ${requiredInterval.inSeconds}s');
        return false;
      }
    }

    debugPrint('[SimpleAdManager] ✅ Should show ad');
    return true;
  }

  /// Show an ad if appropriate
  Future<bool> showAdIfAppropriate() async {
    if (!shouldShowAd()) {
      return false;
    }

    try {
      debugPrint('[SimpleAdManager] Showing ad...');
      await _interstitialAd!.show();

      // Update tracking
      _lastAdShown = DateTime.now();
      _adsShownCount++;

      debugPrint(
          '[SimpleAdManager] ✅ Ad shown successfully (total: $_adsShownCount)');
      return true;
    } catch (e) {
      debugPrint('[SimpleAdManager] Failed to show ad: $e');
      // Reset ad state
      _interstitialAd?.dispose();
      _interstitialAd = null;
      _isAdReady = false;
      // Try loading a new ad
      _loadInterstitialAd();
      return false;
    }
  }

  /// Force load an ad (for testing)
  Future<void> forceLoadAd() async {
    debugPrint('[SimpleAdManager] Force loading ad...');
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isAdReady = false;
    await _loadInterstitialAd();
  }

  /// Get current status
  Map<String, dynamic> getStatus() {
    return {
      'initialized': _isInitialized,
      'adReady': _isAdReady,
      'loading': _isLoading,
      'adsShown': _adsShownCount,
      'lastAdShown': _lastAdShown?.toIso8601String() ?? 'never',
      'canRequestAds': _consentManager.canRequestAds,
      'canShowPersonalized': _consentManager.canShowPersonalizedAds,
      'canShowNonPersonalized': _consentManager.canShowNonPersonalizedAds,
      'timeSinceInit': _initTime != null
          ? '${DateTime.now().difference(_initTime!).inSeconds}s'
          : 'not initialized',
      'timeSinceLastAd': _lastAdShown != null
          ? '${DateTime.now().difference(_lastAdShown!).inSeconds}s'
          : 'no ads shown',
      'currentInterval': '${_getAdInterval().inSeconds}s',
      'userStatus': UserCache().user?.status ?? 'unknown',
      'userLevel': UserCache().user?.level ?? 0,
    };
  }

  /// Reset timing (for testing)
  void resetTiming() {
    _lastAdShown = null;
    _initTime = DateTime.now();
    debugPrint('[SimpleAdManager] Timing reset');
  }

  /// Dispose resources
  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isAdReady = false;
  }
}

/// Simple adapter for backward compatibility with existing code
class SimpleAdAdapter {
  static SimpleAdAdapter? _instance;
  static SimpleAdAdapter get instance => _instance ??= SimpleAdAdapter._();

  SimpleAdAdapter._();

  final SimpleAdManager _adManager = SimpleAdManager.instance;

  /// Initialize the adapter
  Future<void> initialize() async {
    await _adManager.initialize();
  }

  /// Track room transition (simplified - just for compatibility)
  void trackRoomTransition({String? destination}) {
    debugPrint(
        '[SimpleAdAdapter] Room transition: ${destination ?? 'unknown'}');
    // No complex tracking needed
  }

  /// Show ad if appropriate
  Future<bool> showAdIfAppropriate() async {
    return await _adManager.showAdIfAppropriate();
  }

  /// Check if ad is ready
  bool get isAdReady => _adManager._isAdReady;

  /// Get session stats (simplified)
  Map<String, dynamic> getSessionStats() {
    return _adManager.getStatus();
  }

  /// Get status message
  String getStatusMessage() {
    final status = _adManager.getStatus();
    if (!status['initialized']) return 'Not initialized';
    if (!status['canRequestAds']) return 'No consent for ads';
    if (status['loading']) return 'Loading ad...';
    if (status['adReady']) return 'Ad ready';
    return 'Waiting for next ad opportunity';
  }

  /// Reset session (for compatibility)
  void resetSession() {
    _adManager.resetTiming();
  }

  /// Navigate with ad consideration
  Future<T?> navigateWithAdConsideration<T>({
    required BuildContext context,
    required String route,
    required Future<T?> Function() navigationAction,
  }) async {
    // Track the transition
    trackRoomTransition(destination: route);

    // Try to show ad
    final adShown = await showAdIfAppropriate();
    if (adShown) {
      debugPrint('[SimpleAdAdapter] Ad shown before navigation to $route');
    }

    // Navigate regardless of ad
    return await navigationAction();
  }

  /// Dispose resources
  void dispose() {
    _adManager.dispose();
  }

  // Additional methods for compatibility with existing code

  /// Validate compliance (simplified)
  Future<bool> validateCompliance() async {
    return _adManager._consentManager.canRequestAds;
  }

  /// Get timing message
  String getTimingMessage() {
    final status = _adManager.getStatus();
    final timeSinceLastAd = status['timeSinceLastAd'] ?? 'never';
    final currentInterval = status['currentInterval'] ?? 'unknown';
    final userStatus = status['userStatus'] ?? 'unknown';
    return 'Adaptive timing: Next ad in $currentInterval (user: $userStatus, last: $timeSinceLastAd)';
  }

  /// Get room transitions (always 0 for simple system)
  int get roomTransitions => 0;

  /// Get ads shown this session
  int get adsShownThisSession => _adManager._adsShownCount;

  /// Check if should show ad now
  Future<bool> shouldShowAdNow() async {
    return _adManager.shouldShowAd();
  }

  /// Get compliance status
  Future<Map<String, dynamic>> getComplianceStatus() async {
    return {
      'compliant': true,
      'system': 'simple',
      'canRequestAds': _adManager._consentManager.canRequestAds,
      'adsShown': _adManager._adsShownCount,
    };
  }

  /// Get comprehensive debug info
  Map<String, dynamic> getComprehensiveDebugInfo() {
    return {
      'system': 'SimpleAdManager',
      'status': _adManager.getStatus(),
      'config': {
        'minTimeBetweenAds': '${SimpleAdManager._minTimeBetweenAds.inSeconds}s',
        'newcomerFirstDelay':
            '${SimpleAdManager._newcomerFirstAdDelay.inMinutes} minutes',
        'regularFirstDelay':
            '${SimpleAdManager._regularFirstAdDelay.inMinutes} minutes',
        'intervalStrategy': 'progressive',
        'adsShown': _adManager._adsShownCount,
      }
    };
  }

  /// Get current system name
  String get currentSystemName => 'SimpleAdManager';

  /// Get compliance message
  String getComplianceMessage() {
    if (!_adManager._consentManager.canRequestAds) {
      return 'Ads disabled - no consent';
    }
    return 'Ads enabled - simplified system';
  }

  /// Force show ad for testing
  Future<bool> forceShowAdForTesting() async {
    if (_adManager._isAdReady && _adManager._interstitialAd != null) {
      try {
        await _adManager._interstitialAd!.show();
        _adManager._lastAdShown = DateTime.now();
        _adManager._adsShownCount++;
        return true;
      } catch (e) {
        debugPrint('[SimpleAdAdapter] Force show failed: $e');
      }
    }
    return false;
  }

  /// Preload ad
  Future<void> preloadAd() async {
    await _adManager._loadInterstitialAd();
  }
}
