import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../config/ad_config.dart';
import 'admob_compliance.dart';
import 'simplified_ad_config.dart';

/// Simplified Room Transition Ads Service
///
/// This service manages interstitial ads between room transitions with:
/// - Increased ad frequency for better monetization
/// - Simplified logic for more predictable ad showing
/// - Maintained user experience and compliance
class SimplifiedRoomAds extends ChangeNotifier with WidgetsBindingObserver {
  static SimplifiedRoomAds? _instance;
  static SimplifiedRoomAds get instance => _instance ??= SimplifiedRoomAds._();

  SimplifiedRoomAds._();

  // === SESSION STATE ===
  DateTime? _sessionStart;
  DateTime? _lastAdShown;
  int _roomTransitions = 0;
  int _adsShownThisSession = 0;

  // === AD STATE ===
  InterstitialAd? _interstitialAd;
  bool _isAdReady = false;
  bool _isLoading = false;

  // === LIFECYCLE STATE ===
  DateTime? _lastBackgroundTime;
  DateTime? _lastSessionReset;
  AppLifecycleState _currentLifecycleState = AppLifecycleState.resumed;

  // === QUICK NAVIGATION TRACKING ===
  DateTime? _lastNavigationTime;
  int _consecutiveQuickNavigations = 0;

  // === GETTERS ===
  bool get isAdReady => _isAdReady;
  int get roomTransitions => _roomTransitions;
  int get adsShownThisSession => _adsShownThisSession;
  bool get hasSessionLimit => SimplifiedAdConfig.shouldEnforceSessionLimits();
  int? get maxAdsPerSession =>
      SimplifiedAdConfig.getEffectiveMaxAdsPerSession();

  /// Initialize the simplified ad service
  void initialize() {
    _sessionStart = DateTime.now();
    _roomTransitions = 0;
    _adsShownThisSession = 0;
    _lastAdShown = null;
    _consecutiveQuickNavigations = 0;

    // Register lifecycle observer
    WidgetsBinding.instance.addObserver(this);

    // Initialize compliance system
    AdMobCompliance.initialize();

    if (SimplifiedAdConfig.verboseLogging) {
      _logSessionStart();
    }

    // Validate configuration
    if (!SimplifiedAdConfig.validateConfig()) {
      debugPrint('ERROR: Invalid SimplifiedAdConfig detected');
    }

    // Start aggressive ad loading
    Future.delayed(SimplifiedAdConfig.initialAdLoadDelay, () {
      if (_shouldLoadAd()) {
        _preloadInterstitialAd();
      }
    });

    notifyListeners();
  }

  void _logSessionStart() {
    debugPrint('=== SimplifiedRoomAds: Session Started ===');
    debugPrint('Configuration: ${SimplifiedAdConfig.getConfigDescription()}');
    debugPrint('App ID: ${AdConfig.appId}');
    debugPrint('Interstitial Ad Unit: ${AdConfig.interstitialAdUnitId}');
    debugPrint('Debug Mode: $kDebugMode');
    debugPrint('Admin User: ${AdMobCompliance.isCurrentUserAdmin}');
    debugPrint('Using Test Ads: ${AdMobCompliance.shouldUseTestAds}');
    AdMobCompliance.logComplianceStatus();
    debugPrint('=======================================');
  }

  /// Track room transition with simplified logic
  void trackRoomTransition() {
    _roomTransitions++;
    _updateNavigationTracking();

    if (SimplifiedAdConfig.verboseLogging) {
      debugPrint('Room transition tracked: $_roomTransitions total');
    }

    // Aggressive ad preloading if not ready
    if (!_isAdReady && !_isLoading && _shouldLoadAd()) {
      _preloadInterstitialAd();
    }

    notifyListeners();
  }

  void _updateNavigationTracking() {
    final now = DateTime.now();

    if (_lastNavigationTime != null) {
      final timeSinceLastNav = now.difference(_lastNavigationTime!);

      // Count as quick navigation if within 10 seconds
      if (timeSinceLastNav.inSeconds < 10) {
        _consecutiveQuickNavigations++;
      } else {
        _consecutiveQuickNavigations = 0;
      }
    }

    _lastNavigationTime = now;
  }

  /// Simplified ad show decision logic
  bool shouldShowAdNow() {
    if (SimplifiedAdConfig.verboseLogging) {
      debugPrint('=== Ad Show Decision Check ===');
    }

    // 1. Compliance check (always required)
    if (!AdMobCompliance.validateAdRequest('interstitial')) {
      _logDecision('❌ Compliance validation failed');
      return false;
    }

    // 2. Session check
    if (_sessionStart == null) {
      _logDecision('❌ No active session');
      return false;
    }

    // 3. Ad ready check
    if (!_isAdReady) {
      _logDecision('❌ Ad not ready (loading: $_isLoading)');
      return false;
    }

    // 4. Session limit check (if enabled)
    if (SimplifiedAdConfig.shouldEnforceSessionLimits()) {
      final maxAds = SimplifiedAdConfig.getEffectiveMaxAdsPerSession()!;
      if (_adsShownThisSession >= maxAds) {
        _logDecision('❌ Session limit reached ($_adsShownThisSession/$maxAds)');
        return false;
      }
    }

    // 5. Session age check
    final sessionAge = DateTime.now().difference(_sessionStart!);
    if (sessionAge < SimplifiedAdConfig.minSessionTimeBeforeFirstAd) {
      _logDecision(
          '❌ Session too young (${sessionAge.inSeconds}s < ${SimplifiedAdConfig.minSessionTimeBeforeFirstAd.inSeconds}s)');
      return false;
    }

    // 6. Time between ads check
    if (_lastAdShown != null) {
      final timeSinceLastAd = DateTime.now().difference(_lastAdShown!);
      if (timeSinceLastAd < SimplifiedAdConfig.minTimeBetweenAds) {
        _logDecision(
            '❌ Too soon since last ad (${timeSinceLastAd.inSeconds}s < ${SimplifiedAdConfig.minTimeBetweenAds.inSeconds}s)');
        return false;
      }
    }

    // 7. Transition requirement check
    final requiredTransitions =
        SimplifiedAdConfig.getTransitionsForNextAd(_adsShownThisSession);
    if (_roomTransitions < requiredTransitions) {
      _logDecision(
          '❌ Need ${requiredTransitions - _roomTransitions} more transitions');
      return false;
    }

    // 8. Quick navigation spam check (simplified)
    if (_consecutiveQuickNavigations >
        SimplifiedAdConfig.maxConsecutiveQuickNavs) {
      _logDecision(
          '❌ Too many quick navigations ($_consecutiveQuickNavigations)');
      return false;
    }

    _logDecision('✅ All conditions met - SHOULD SHOW AD');
    return true;
  }

  void _logDecision(String message) {
    if (SimplifiedAdConfig.verboseLogging) {
      debugPrint(message);
    }
  }

  /// Show ad if appropriate with simplified flow
  Future<bool> showAdIfAppropriate() async {
    if (!shouldShowAdNow()) {
      return false;
    }

    if (_interstitialAd == null) {
      _logDecision('❌ No ad instance available');
      return false;
    }

    try {
      // Log compliance context
      AdMobCompliance.logAdShown('interstitial', context: 'room_transition');

      // Show the ad
      await _interstitialAd!.show();

      // Update tracking
      _lastAdShown = DateTime.now();
      _adsShownThisSession++;

      // Reset ad state
      _interstitialAd = null;
      _isAdReady = false;

      if (SimplifiedAdConfig.verboseLogging) {
        debugPrint(
            '✅ Ad shown successfully! Session: $_adsShownThisSession/${maxAdsPerSession ?? "unlimited"}');
      }

      // Aggressively preload next ad
      Future.delayed(SimplifiedAdConfig.nextAdLoadDelay, () {
        if (_shouldLoadAd()) {
          _preloadInterstitialAd();
        }
      });

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Error showing ad: $e');
      return false;
    }
  }

  /// Preload interstitial ad with simplified logic
  Future<void> _preloadInterstitialAd() async {
    if (_isLoading || _isAdReady) return;

    _isLoading = true;
    notifyListeners();

    try {
      final adUnitId = _getAdUnitId();

      if (SimplifiedAdConfig.verboseLogging) {
        debugPrint('Loading ad with unit ID: $adUnitId');
      }

      await InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            _interstitialAd = ad;
            _isAdReady = true;
            _isLoading = false;

            if (SimplifiedAdConfig.verboseLogging) {
              debugPrint('✅ Ad loaded successfully');
            }

            notifyListeners();
          },
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('❌ Failed to load ad: $error');
            _interstitialAd = null;
            _isAdReady = false;
            _isLoading = false;

            // Quick retry on failure
            Future.delayed(SimplifiedAdConfig.adLoadRetryDelay, () {
              if (!_isAdReady && !_isLoading && _shouldLoadAd()) {
                _preloadInterstitialAd();
              }
            });

            notifyListeners();
          },
        ),
      );
    } catch (e) {
      debugPrint('❌ Exception loading ad: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Simplified ad loading decision
  bool _shouldLoadAd() {
    // Don't load if no session
    if (_sessionStart == null) return false;

    // Don't load if at session limit
    if (SimplifiedAdConfig.shouldEnforceSessionLimits()) {
      final maxAds = SimplifiedAdConfig.getEffectiveMaxAdsPerSession()!;
      if (_adsShownThisSession >= maxAds) return false;
    }

    // Don't load if session too young
    final sessionAge = DateTime.now().difference(_sessionStart!);
    if (sessionAge.inSeconds < 15) return false;

    // Don't load if too soon after last ad
    if (_lastAdShown != null) {
      final timeSinceLastAd = DateTime.now().difference(_lastAdShown!);
      if (timeSinceLastAd.inSeconds < 45) return false;
    }

    return true;
  }

  /// Get appropriate ad unit ID using compliance system
  String _getAdUnitId() {
    if (AdMobCompliance.shouldUseTestAds) {
      return AdMobCompliance.testAdUnitIds['interstitial_android']!;
    } else {
      return AdConfig.interstitialAdUnitId;
    }
  }

  /// Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _currentLifecycleState = state;

    if (state == AppLifecycleState.paused) {
      _lastBackgroundTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed &&
        _lastBackgroundTime != null) {
      _handleAppResumed();
    }
  }

  void _handleAppResumed() {
    final backgroundDuration = DateTime.now().difference(_lastBackgroundTime!);

    if (SimplifiedAdConfig.verboseLogging) {
      debugPrint('App resumed after ${backgroundDuration.inMinutes} minutes');
    }

    // Reset session if in background long enough
    if (backgroundDuration >=
        SimplifiedAdConfig.backgroundTimeForSessionReset) {
      _maybeResetSession();
    }

    // Load ad if needed
    if (SimplifiedAdConfig.allowAdsOnAppResume &&
        !_isAdReady &&
        !_isLoading &&
        _shouldLoadAd()) {
      Future.delayed(const Duration(seconds: 5), () {
        _preloadInterstitialAd();
      });
    }
  }

  void _maybeResetSession() {
    // Check if enough time has passed since last reset
    if (_lastSessionReset != null) {
      final timeSinceReset = DateTime.now().difference(_lastSessionReset!);
      if (timeSinceReset < SimplifiedAdConfig.minTimeBetweenSessionResets) {
        return;
      }
    }

    if (SimplifiedAdConfig.verboseLogging) {
      debugPrint(
          'Resetting session: ads $_adsShownThisSession -> 0, transitions $_roomTransitions -> 0');
    }

    resetSession();
    _lastSessionReset = DateTime.now();
  }

  /// Reset session state
  void resetSession() {
    _sessionStart = DateTime.now();
    _roomTransitions = 0;
    _adsShownThisSession = 0;
    _lastAdShown = null;
    _consecutiveQuickNavigations = 0;

    notifyListeners();
  }

  /// Force load an ad (for testing)
  Future<void> forceLoadAd() async {
    _isAdReady = false;
    _isLoading = false;
    await _preloadInterstitialAd();
  }

  /// Force show an ad (for testing)
  Future<bool> forceShowAd() async {
    if (_interstitialAd != null) {
      await _interstitialAd!.show();
      _lastAdShown = DateTime.now();
      _adsShownThisSession++;
      _interstitialAd = null;
      _isAdReady = false;
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Get session statistics
  Map<String, dynamic> getSessionStats() {
    final sessionDuration = _sessionStart != null
        ? DateTime.now().difference(_sessionStart!).inMinutes
        : 0;

    final timeSinceLastAd = _lastAdShown != null
        ? DateTime.now().difference(_lastAdShown!).inMinutes
        : null;

    return {
      'sessionDurationMinutes': sessionDuration,
      'roomTransitions': _roomTransitions,
      'adsShownThisSession': _adsShownThisSession,
      'maxAdsPerSession': maxAdsPerSession,
      'hasSessionLimit': hasSessionLimit,
      'isAdReady': _isAdReady,
      'isLoading': _isLoading,
      'timeSinceLastAdMinutes': timeSinceLastAd,
      'consecutiveQuickNavs': _consecutiveQuickNavigations,
      'canShowAdNow': shouldShowAdNow(),
      'configuration': SimplifiedAdConfig.getConfigSummary(),
    };
  }

  /// Get compliance status
  Map<String, dynamic> getComplianceStatus() {
    final generalCompliance = AdMobCompliance.getComplianceStatus();
    final currentAdUnitId = _getAdUnitId();

    return {
      ...generalCompliance,
      'currentAdUnitId': currentAdUnitId,
      'isUsingTestAdUnit': currentAdUnitId.contains('3940256099942544'),
      'adReadyState': _isAdReady,
      'canShowAd': shouldShowAdNow(),
      'complianceValidated': AdMobCompliance.validateAdRequest('interstitial'),
    };
  }

  /// Get user-friendly status message
  String getStatusMessage() {
    if (!_isAdReady) {
      return _isLoading ? 'Loading ad...' : 'No ad loaded';
    }

    if (shouldShowAdNow()) {
      return 'Ready to show ad';
    }

    if (SimplifiedAdConfig.shouldEnforceSessionLimits()) {
      final maxAds = SimplifiedAdConfig.getEffectiveMaxAdsPerSession()!;
      if (_adsShownThisSession >= maxAds) {
        return 'Session limit reached ($maxAds ads)';
      }
    }

    if (_lastAdShown != null) {
      final timeSinceLastAd = DateTime.now().difference(_lastAdShown!);
      final remaining = SimplifiedAdConfig.minTimeBetweenAds - timeSinceLastAd;
      if (remaining.isNegative) {
        return 'Ready (time condition met)';
      } else {
        return 'Wait ${remaining.inSeconds}s before next ad';
      }
    }

    return 'Ad ready, waiting for transition';
  }

  /// Dispose resources
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _interstitialAd?.dispose();
    super.dispose();
  }

  /// Get timing info for debugging
  String getTimingInfo() {
    final now = DateTime.now();
    final sessionAge =
        _sessionStart != null ? now.difference(_sessionStart!) : Duration.zero;
    final timeSinceLastAd =
        _lastAdShown != null ? now.difference(_lastAdShown!) : null;

    return 'Session: ${sessionAge.inMinutes}min, '
        'Last ad: ${timeSinceLastAd?.inMinutes ?? "never"}min ago, '
        'Transitions: $_roomTransitions, '
        'Ads shown: $_adsShownThisSession';
  }
}
