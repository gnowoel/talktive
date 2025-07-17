import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../config/ad_config.dart';
import 'admob_compliance.dart';
import 'optimized_ad_config.dart';

/// Simplified Room Transition Ads Service
///
/// This service manages interstitial ads between room transitions with:
/// - Unlimited sessions for maximum revenue potential
/// - Engagement-based timing for better user experience
/// - Intelligent preloading for low request-to-impression ratio
/// - Maintained compliance and user experience
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

  // === NAVIGATION TRACKING ===
  DateTime? _lastNavigationTime;
  int _consecutiveQuickNavigations = 0;
  List<DateTime> _recentNavigations = [];

  // === GETTERS ===
  bool get isAdReady => _isAdReady;
  int get roomTransitions => _roomTransitions;
  int get adsShownThisSession => _adsShownThisSession;
  bool get hasSessionLimit => OptimizedAdConfig.enforceSessionLimits;
  int? get maxAdsPerSession => OptimizedAdConfig.maxAdsPerSession;
  String get userEngagementLevel =>
      OptimizedAdConfig.getUserEngagementLevel(_sessionStart != null
          ? DateTime.now().difference(_sessionStart!)
          : Duration.zero);

  /// Initialize the simplified ad service
  void initialize() {
    _sessionStart = DateTime.now();
    _roomTransitions = 0;
    _adsShownThisSession = 0;
    _lastAdShown = null;
    _consecutiveQuickNavigations = 0;
    _recentNavigations.clear();

    // Register lifecycle observer
    WidgetsBinding.instance.addObserver(this);

    // Initialize compliance system
    AdMobCompliance.initialize();

    if (OptimizedAdConfig.verboseLogging) {
      _logSessionStart();
    }

    // Validate configuration
    if (!OptimizedAdConfig.validateConfig()) {
      debugPrint('ERROR: Invalid OptimizedAdConfig detected');
    }

    // Start intelligent ad loading
    Future.delayed(OptimizedAdConfig.initialAdLoadDelay, () {
      if (_shouldPreloadAd()) {
        _preloadInterstitialAd();
      }
    });

    notifyListeners();
  }

  void _logSessionStart() {
    debugPrint('=== OptimizedRoomAds: Session Started ===');
    debugPrint('Configuration: ${OptimizedAdConfig.getConfigDescription()}');
    debugPrint('App ID: ${AdConfig.appId}');
    debugPrint('Interstitial Ad Unit: ${AdConfig.interstitialAdUnitId}');
    debugPrint('Debug Mode: $kDebugMode');
    debugPrint('Admin User: ${AdMobCompliance.isCurrentUserAdmin}');
    debugPrint('Using Test Ads: ${AdMobCompliance.shouldUseTestAds}');
    AdMobCompliance.logComplianceStatus();
    debugPrint('=======================================');
  }

  /// Track room transition with optimized logic
  void trackRoomTransition() {
    _roomTransitions++;
    _updateNavigationTracking();

    if (OptimizedAdConfig.verboseLogging) {
      debugPrint(
          'Room transition tracked: $_roomTransitions total (engagement: $userEngagementLevel)');
    }

    // Intelligent ad preloading if not ready
    if (_shouldPreloadAd()) {
      _preloadInterstitialAd();
    }

    notifyListeners();
  }

  void _updateNavigationTracking() {
    final now = DateTime.now();

    // Add to recent navigations list
    _recentNavigations.add(now);

    // Clean up old navigations (keep only last 5 minutes)
    _recentNavigations.removeWhere((navTime) =>
        now.difference(navTime) > OptimizedAdConfig.navigationAnalysisWindow);

    if (_lastNavigationTime != null) {
      final timeSinceLastNav = now.difference(_lastNavigationTime!);

      // Count as quick navigation if within quick window
      if (timeSinceLastNav < OptimizedAdConfig.quickNavigationWindow) {
        _consecutiveQuickNavigations++;
      } else {
        _consecutiveQuickNavigations = 0;
      }
    }

    _lastNavigationTime = now;
  }

  /// Optimized ad show decision logic with engagement-based timing
  bool shouldShowAdNow() {
    if (OptimizedAdConfig.verboseLogging) {
      debugPrint('=== Ad Show Decision Check (${userEngagementLevel}) ===');
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

    // 4. Session limit check (if enabled - should be disabled for unlimited)
    if (OptimizedAdConfig.enforceSessionLimits &&
        OptimizedAdConfig.maxAdsPerSession != null) {
      final maxAds = OptimizedAdConfig.maxAdsPerSession!;
      if (_adsShownThisSession >= maxAds) {
        _logDecision('❌ Session limit reached ($_adsShownThisSession/$maxAds)');
        return false;
      }
    }

    // 5. Session age check
    final sessionAge = DateTime.now().difference(_sessionStart!);
    if (sessionAge < OptimizedAdConfig.minSessionTimeBeforeFirstAd) {
      _logDecision(
          '❌ Session too young (${sessionAge.inSeconds}s < ${OptimizedAdConfig.minSessionTimeBeforeFirstAd.inSeconds}s)');
      return false;
    }

    // 6. Engagement-based time between ads check
    if (_lastAdShown != null) {
      final timeSinceLastAd = DateTime.now().difference(_lastAdShown!);
      final requiredInterval =
          OptimizedAdConfig.getTimingForEngagement(sessionAge);
      if (timeSinceLastAd < requiredInterval) {
        _logDecision(
            '❌ Too soon since last ad (${timeSinceLastAd.inSeconds}s < ${requiredInterval.inSeconds}s for $userEngagementLevel user)');
        return false;
      }
    }

    // 7. Transition requirement check (behavior-aware)
    final requiredTransitions = OptimizedAdConfig.getTransitionsRequired(
        _consecutiveQuickNavigations, _adsShownThisSession == 0);
    if (_roomTransitions < requiredTransitions) {
      _logDecision(
          '❌ Need ${requiredTransitions - _roomTransitions} more transitions (quick navs: $_consecutiveQuickNavigations)');
      return false;
    }

    // 8. User activity and spam protection checks
    if (_consecutiveQuickNavigations >
        OptimizedAdConfig.maxConsecutiveQuickNavs) {
      _logDecision(
          '❌ Too many quick navigations ($_consecutiveQuickNavigations)');
      return false;
    }

    // 9. User engagement check
    if (!OptimizedAdConfig.isUserActive(
        _lastNavigationTime, _recentNavigations.length)) {
      _logDecision('❌ User not sufficiently active');
      return false;
    }

    _logDecision('✅ All conditions met - SHOULD SHOW AD');
    return true;
  }

  void _logDecision(String message) {
    if (OptimizedAdConfig.verboseLogging) {
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

      if (OptimizedAdConfig.verboseLogging) {
        debugPrint(
            '✅ Ad shown successfully! Session: $_adsShownThisSession/${maxAdsPerSession ?? "unlimited"} (${userEngagementLevel})');
      }

      // Intelligently preload next ad
      Future.delayed(OptimizedAdConfig.nextAdLoadDelay, () {
        if (_shouldPreloadAd()) {
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

      if (OptimizedAdConfig.verboseLogging) {
        debugPrint(
            'Loading ad with unit ID: $adUnitId (engagement: $userEngagementLevel)');
      }

      await InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            _interstitialAd = ad;
            _isAdReady = true;
            _isLoading = false;

            if (OptimizedAdConfig.verboseLogging) {
              debugPrint('✅ Ad loaded successfully');
            }

            notifyListeners();
          },
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('❌ Failed to load ad: $error');
            _interstitialAd = null;
            _isAdReady = false;
            _isLoading = false;

            // Intelligent retry on failure
            Future.delayed(OptimizedAdConfig.adLoadRetryDelay, () {
              if (_shouldPreloadAd()) {
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

  /// Intelligent ad preloading decision
  bool _shouldPreloadAd() {
    // Don't preload if no session
    if (_sessionStart == null) return false;

    final sessionAge = DateTime.now().difference(_sessionStart!);

    // Use optimized preloading logic
    return OptimizedAdConfig.shouldPreloadAd(
      isAdReady: _isAdReady,
      isLoading: _isLoading,
      lastNavigation: _lastNavigationTime,
      recentNavigations: _recentNavigations.length,
      sessionDuration: sessionAge,
    );
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
    if (state == AppLifecycleState.paused) {
      _lastBackgroundTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed &&
        _lastBackgroundTime != null) {
      _handleAppResumed();
    }
  }

  void _handleAppResumed() {
    final backgroundDuration = DateTime.now().difference(_lastBackgroundTime!);

    if (OptimizedAdConfig.verboseLogging) {
      debugPrint('App resumed after ${backgroundDuration.inMinutes} minutes');
    }

    // Soft reset session if in background long enough
    if (backgroundDuration >= OptimizedAdConfig.backgroundTimeForSoftReset) {
      _maybeSoftResetSession();
    }

    // Load ad if needed, but respect resume delay
    Future.delayed(OptimizedAdConfig.noAdsAfterResumeDelay, () {
      if (_shouldPreloadAd()) {
        _preloadInterstitialAd();
      }
    });
  }

  void _maybeSoftResetSession() {
    if (OptimizedAdConfig.verboseLogging) {
      debugPrint(
          'Soft resetting session: keeping engagement level, resetting counters');
    }

    // Soft reset - keep session start time but reset counters
    // This maintains engagement level while giving fresh ad opportunities
    _roomTransitions = 0;
    _consecutiveQuickNavigations = 0;
    _recentNavigations.clear();

    // Don't reset _adsShownThisSession since we have no session limits
    // Don't reset _sessionStart to maintain engagement tracking

    notifyListeners();
  }

  /// Reset session state
  void resetSession() {
    _sessionStart = DateTime.now();
    _roomTransitions = 0;
    _adsShownThisSession = 0;
    _lastAdShown = null;
    _consecutiveQuickNavigations = 0;
    _recentNavigations.clear();

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

    // Calculate additional metrics for compatibility
    final isUserInGoodState = OptimizedAdConfig.isUserActive(
        _lastNavigationTime, _recentNavigations.length);
    final canShowAd = shouldShowAdNow();
    final sessionAge = _sessionStart != null
        ? DateTime.now().difference(_sessionStart!)
        : Duration.zero;

    // Calculate time until next ad eligible
    int? timeUntilNextAdEligible;
    if (_lastAdShown != null) {
      final requiredInterval =
          OptimizedAdConfig.getTimingForEngagement(sessionAge);
      final timeSinceLastAd = DateTime.now().difference(_lastAdShown!);
      final remaining = requiredInterval - timeSinceLastAd;
      if (!remaining.isNegative) {
        timeUntilNextAdEligible = remaining.inMinutes;
      }
    }

    // Calculate engagement score (0-100)
    int sessionEngagementScore = 0;
    if (sessionDuration > 0) {
      sessionEngagementScore = (sessionDuration * 10).clamp(0, 100);
      if (_recentNavigations.length > 3) sessionEngagementScore += 20;
      if (_consecutiveQuickNavigations < 3) sessionEngagementScore += 10;
    }

    // Determine next ad opportunity
    String nextAdOpportunity = 'Ready now';
    if (!canShowAd) {
      if (!_isAdReady) {
        nextAdOpportunity = 'Loading ad...';
      } else if (timeUntilNextAdEligible != null &&
          timeUntilNextAdEligible > 0) {
        nextAdOpportunity = '${timeUntilNextAdEligible}min';
      } else if (_roomTransitions <
          OptimizedAdConfig.getTransitionsRequired(
              _consecutiveQuickNavigations, _adsShownThisSession == 0)) {
        final needed = OptimizedAdConfig.getTransitionsRequired(
                _consecutiveQuickNavigations, _adsShownThisSession == 0) -
            _roomTransitions;
        nextAdOpportunity = '$needed more transitions';
      } else {
        nextAdOpportunity = 'Soon';
      }
    }

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
      'canShowAdNow': canShowAd,
      'userEngagementLevel': userEngagementLevel,
      'recentNavigationsCount': _recentNavigations.length,
      'configuration': OptimizedAdConfig.getConfigSummary(),
      // Additional fields for test page compatibility
      'isUserInGoodStateForAds': isUserInGoodState,
      'isOptimalAdMoment': canShowAd && _isAdReady,
      'engagementLevel': userEngagementLevel,
      'sessionEngagementScore': sessionEngagementScore,
      'nextAdOpportunity': nextAdOpportunity,
      'timeUntilNextAdEligible': timeUntilNextAdEligible,
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

    if (OptimizedAdConfig.enforceSessionLimits &&
        OptimizedAdConfig.maxAdsPerSession != null) {
      final maxAds = OptimizedAdConfig.maxAdsPerSession!;
      if (_adsShownThisSession >= maxAds) {
        return 'Session limit reached ($maxAds ads)';
      }
    }

    if (_lastAdShown != null) {
      final timeSinceLastAd = DateTime.now().difference(_lastAdShown!);
      final sessionAge = DateTime.now().difference(_sessionStart!);
      final requiredInterval =
          OptimizedAdConfig.getTimingForEngagement(sessionAge);
      final remaining = requiredInterval - timeSinceLastAd;
      if (remaining.isNegative) {
        return 'Ready (time condition met for $userEngagementLevel)';
      } else {
        return 'Wait ${remaining.inSeconds}s before next ad ($userEngagementLevel)';
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
        'Ads shown: $_adsShownThisSession, '
        'Engagement: $userEngagementLevel';
  }
}
