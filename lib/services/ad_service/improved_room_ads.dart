import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'improved_ad_manager.dart';
import 'improved_consent_manager.dart';
import 'optimized_ad_config.dart';
import 'admob_compliance.dart';
import '../../config/ad_config.dart';

/// Improved room ads manager that integrates with the new ad system
/// Maintains session tracking and room-based ad logic while using improved ad loading
class ImprovedRoomAds extends ChangeNotifier with WidgetsBindingObserver {
  static ImprovedRoomAds? _instance;
  static ImprovedRoomAds get instance => _instance ??= ImprovedRoomAds._();

  ImprovedRoomAds._();

  // === AD MANAGERS ===
  final ImprovedAdManager _adManager = ImprovedAdManager.instance;
  final ImprovedConsentManager _consentManager =
      ImprovedConsentManager.instance;

  // === SESSION STATE ===
  DateTime? _sessionStart;
  int _roomTransitions = 0;
  int _adsShownThisSession = 0;
  DateTime? _lastAdShown;

  // === AD STATE ===
  InterstitialAd? _interstitialAd;
  bool _isAdReady = false;
  bool _isLoading = false;

  // === NAVIGATION TRACKING ===
  DateTime? _lastNavigationTime;
  int _consecutiveQuickNavigations = 0;
  final List<DateTime> _recentNavigations = [];

  // === CONFIGURATION ===
  bool _useTestAds = false;

  // === GETTERS ===
  bool get isAdReady => _isAdReady;
  int get roomTransitions => _roomTransitions;
  int get adsShownThisSession => _adsShownThisSession;
  bool get hasSessionLimit => OptimizedAdConfig.maxAdsPerSession != null;
  int? get maxAdsPerSession => OptimizedAdConfig.maxAdsPerSession;
  String get userEngagementLevel => _getUserEngagementLevel();

  /// Initialize the room ads system
  Future<void> initialize() async {
    debugPrint('[ImprovedRoomAds] Initializing...');

    // Initialize session
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

    // Initialize the improved ad manager
    await _adManager.initializeAsync();

    if (OptimizedAdConfig.verboseLogging) {
      _logSessionStart();
    }

    // Validate configuration
    if (!OptimizedAdConfig.validateConfig()) {
      debugPrint('[ImprovedRoomAds] ERROR: Invalid OptimizedAdConfig detected');
    }

    // Check if we should use test ads
    _useTestAds = AdMobCompliance.shouldUseTestAds;

    // Start intelligent ad loading after delay
    Future.delayed(OptimizedAdConfig.initialAdLoadDelay, () {
      if (_shouldPreloadAd()) {
        _preloadInterstitialAd();
      }
    });

    notifyListeners();
    debugPrint('[ImprovedRoomAds] Initialization complete');
  }

  void _logSessionStart() {
    debugPrint('=== ImprovedRoomAds: Session Started ===');
    debugPrint('Configuration: ${OptimizedAdConfig.getConfigDescription()}');
    debugPrint('Debug Mode: $kDebugMode');
    debugPrint('Admin User: ${AdMobCompliance.isCurrentUserAdmin}');
    debugPrint('Using Test Ads: $_useTestAds');
    debugPrint('Session Start: $_sessionStart');
    debugPrint('=======================================');
  }

  /// Track room transition
  void trackRoomTransition({String? destination}) {
    _roomTransitions++;
    _updateNavigationTracking();

    // Log room transition for compliance tracking
    if (OptimizedAdConfig.verboseLogging) {
      AdMobCompliance.logAdShown('room_transition',
          context: destination ?? 'unknown');
    }

    if (OptimizedAdConfig.verboseLogging) {
      debugPrint(
          '[ImprovedRoomAds] Room transition tracked: $_roomTransitions total (engagement: $userEngagementLevel)');
    }

    notifyListeners();
  }

  void _updateNavigationTracking() {
    final now = DateTime.now();

    // Update quick navigation tracking
    if (_lastNavigationTime != null) {
      final timeSinceLastNav = now.difference(_lastNavigationTime!);
      if (timeSinceLastNav < const Duration(seconds: 3)) {
        _consecutiveQuickNavigations++;
      } else {
        _consecutiveQuickNavigations = 0;
      }
    }

    _lastNavigationTime = now;
    _recentNavigations.add(now);

    // Keep only recent navigations
    _recentNavigations
        .removeWhere((nav) => now.difference(nav) > const Duration(minutes: 5));
  }

  /// Check if ad should be shown now
  Future<bool> shouldShowAdNow() async {
    if (OptimizedAdConfig.verboseLogging) {
      debugPrint(
          '[ImprovedRoomAds] === Ad Show Decision Check ($userEngagementLevel) ===');
    }

    // 1. Session check
    if (_sessionStart == null) {
      _logDecision('❌ No active session');
      return false;
    }

    // 2. Consent check
    if (!_consentManager.canRequestAds) {
      _logDecision('❌ Cannot request ads - consent not available');
      return false;
    }

    // 3. Compliance check
    if (!await AdMobCompliance.validateAdRequest('interstitial')) {
      _logDecision('❌ Compliance validation failed');
      return false;
    }

    // 4. Ad ready check
    if (!_isAdReady) {
      _logDecision('❌ Ad not ready (loading: $_isLoading)');
      return false;
    }

    // 5. Session limit check
    if (OptimizedAdConfig.enforceSessionLimits &&
        OptimizedAdConfig.maxAdsPerSession != null) {
      final maxAds = OptimizedAdConfig.maxAdsPerSession!;
      if (_adsShownThisSession >= maxAds) {
        _logDecision('❌ Session limit reached ($_adsShownThisSession/$maxAds)');
        return false;
      }
    }

    // 6. Session age check
    final sessionAge = DateTime.now().difference(_sessionStart!);
    if (sessionAge < OptimizedAdConfig.minSessionTimeBeforeFirstAd) {
      _logDecision(
          '❌ Session too young (${sessionAge.inSeconds}s < ${OptimizedAdConfig.minSessionTimeBeforeFirstAd.inSeconds}s)');
      return false;
    }

    // 7. Time between ads check
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

    // 8. Transition requirement check
    final requiredTransitions = OptimizedAdConfig.getTransitionsRequired(
        _consecutiveQuickNavigations, _adsShownThisSession == 0);
    if (_roomTransitions < requiredTransitions) {
      _logDecision(
          '❌ Need ${requiredTransitions - _roomTransitions} more transitions (quick navs: $_consecutiveQuickNavigations)');
      return false;
    }

    // 9. User activity check
    if (_consecutiveQuickNavigations >
        OptimizedAdConfig.maxConsecutiveQuickNavs) {
      _logDecision(
          '❌ Too many quick navigations ($_consecutiveQuickNavigations)');
      return false;
    }

    // 10. User engagement check
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
      debugPrint('[ImprovedRoomAds] $message');
    }
  }

  /// Show ad if appropriate
  Future<bool> showAdIfAppropriate() async {
    if (!await shouldShowAdNow()) {
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
            '[ImprovedRoomAds] ✅ Ad shown successfully! Session: $_adsShownThisSession/${maxAdsPerSession ?? "unlimited"} ($userEngagementLevel)');
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
      debugPrint('[ImprovedRoomAds] ❌ Error showing ad: $e');
      return false;
    }
  }

  /// Preload interstitial ad using improved ad manager
  Future<void> _preloadInterstitialAd() async {
    if (_isLoading || _isAdReady) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Check if we can request ads
      if (!_consentManager.canRequestAds) {
        if (OptimizedAdConfig.verboseLogging) {
          debugPrint('[ImprovedRoomAds] ❌ Cannot load ad: No consent for ads');
        }
        _isLoading = false;
        notifyListeners();
        return;
      }

      final adUnitId = _getAdUnitId();

      if (OptimizedAdConfig.verboseLogging) {
        debugPrint(
            '[ImprovedRoomAds] Loading ad with unit ID: $adUnitId (engagement: $userEngagementLevel)');
      }

      // Use improved ad manager to load ad
      final interstitialAd = await _adManager.loadInterstitialAd(
        adUnitId: adUnitId,
        customTargeting: {
          'room_ads': 'true',
          'engagement': userEngagementLevel,
        },
      );

      if (interstitialAd != null) {
        _interstitialAd = interstitialAd;
        _isAdReady = true;
        _isLoading = false;

        // Set up full screen callbacks
        _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (Ad ad) {
            ad.dispose();
            _interstitialAd = null;
            _isAdReady = false;
          },
          onAdFailedToShowFullScreenContent: (Ad ad, AdError error) {
            debugPrint('[ImprovedRoomAds] Ad failed to show: ${error.message}');
            ad.dispose();
            _interstitialAd = null;
            _isAdReady = false;
          },
        );

        if (OptimizedAdConfig.verboseLogging) {
          debugPrint('[ImprovedRoomAds] ✅ Ad loaded successfully');
        }

        notifyListeners();
      } else {
        debugPrint(
            '[ImprovedRoomAds] ❌ Failed to load ad: Ad manager returned null');
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
      }
    } catch (e) {
      debugPrint('[ImprovedRoomAds] ❌ Exception loading ad: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check if we should preload an ad
  bool _shouldPreloadAd() {
    // Don't preload if we already have an ad or are loading
    if (_isAdReady || _isLoading) return false;

    // Don't preload if session limit reached
    if (OptimizedAdConfig.enforceSessionLimits &&
        OptimizedAdConfig.maxAdsPerSession != null &&
        _adsShownThisSession >= OptimizedAdConfig.maxAdsPerSession!) {
      return false;
    }

    // Check if consent is available
    if (!_consentManager.canRequestAds) {
      return false;
    }

    return true;
  }

  /// Get appropriate ad unit ID
  String _getAdUnitId() {
    if (_useTestAds || kDebugMode) {
      // Return Google's test interstitial ad unit ID
      return 'ca-app-pub-3940256099942544/1033173712';
    }
    return AdConfig.interstitialAdUnitId;
  }

  /// Get user engagement level
  String _getUserEngagementLevel() {
    if (_sessionStart == null) return 'new';

    final sessionAge = DateTime.now().difference(_sessionStart!);

    if (sessionAge < const Duration(minutes: 5)) {
      return 'new';
    } else if (sessionAge < const Duration(minutes: 15)) {
      return 'engaged';
    } else {
      return 'retained';
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _handleAppResumed();
    }
  }

  void _handleAppResumed() {
    if (_sessionStart == null) return;

    final sessionAge = DateTime.now().difference(_sessionStart!);
    if (sessionAge > const Duration(hours: 1)) {
      if (OptimizedAdConfig.verboseLogging) {
        debugPrint(
            '[ImprovedRoomAds] Session timeout detected, considering soft reset');
      }
      _maybeSoftResetSession();
    }
  }

  void _maybeSoftResetSession() {
    // Keep some tracking but reset limits
    _adsShownThisSession = 0;
    _lastAdShown = null;
    _consecutiveQuickNavigations = 0;
    _recentNavigations.clear();

    if (OptimizedAdConfig.verboseLogging) {
      debugPrint('[ImprovedRoomAds] Soft session reset completed');
    }

    // Preload ad for new session
    if (_shouldPreloadAd()) {
      _preloadInterstitialAd();
    }

    notifyListeners();
  }

  /// Reset session completely
  void resetSession() {
    _sessionStart = DateTime.now();
    _roomTransitions = 0;
    _adsShownThisSession = 0;
    _lastAdShown = null;
    _consecutiveQuickNavigations = 0;
    _recentNavigations.clear();

    if (OptimizedAdConfig.verboseLogging) {
      debugPrint('[ImprovedRoomAds] Session reset');
    }

    notifyListeners();
  }

  /// Force load an ad (for testing)
  Future<void> forceLoadAd() async {
    await _preloadInterstitialAd();
  }

  /// Force show an ad (for testing)
  Future<bool> forceShowAd() async {
    if (_interstitialAd != null) {
      return await showAdIfAppropriate();
    }
    return false;
  }

  /// Get session statistics
  Map<String, dynamic> getSessionStats() {
    final sessionAge = _sessionStart != null
        ? DateTime.now().difference(_sessionStart!)
        : Duration.zero;
    final lastAdAge =
        _lastAdShown != null ? DateTime.now().difference(_lastAdShown!) : null;

    return {
      'sessionActive': _sessionStart != null,
      'sessionAge': '${sessionAge.inMinutes}min',
      'roomTransitions': _roomTransitions,
      'adsShown': _adsShownThisSession,
      'maxAdsPerSession': maxAdsPerSession ?? 'unlimited',
      'lastAdShown':
          lastAdAge != null ? '${lastAdAge.inMinutes}min ago' : 'never',
      'userEngagement': userEngagementLevel,
      'adReady': _isAdReady,
      'adLoading': _isLoading,
      'consecutiveQuickNavs': _consecutiveQuickNavigations,
      'recentNavCount': _recentNavigations.length,
      'canRequestAds': _consentManager.canRequestAds,
      'adServingStatus': _adManager.getAdServingStatus().toString(),
    };
  }

  /// Get compliance status
  Future<Map<String, dynamic>> getComplianceStatus() async {
    final stats = getSessionStats();
    final compliance = await AdMobCompliance.getComplianceStatus();
    return {...stats, ...compliance};
  }

  /// Get status message
  String getStatusMessage() {
    if (_sessionStart == null) {
      return 'Session not initialized';
    }

    if (!_consentManager.canRequestAds) {
      return 'Ads disabled - no consent';
    }

    if (_isLoading) {
      return 'Loading ad...';
    }

    if (_isAdReady) {
      return 'Ad ready to show';
    }

    if (OptimizedAdConfig.enforceSessionLimits &&
        OptimizedAdConfig.maxAdsPerSession != null &&
        _adsShownThisSession >= OptimizedAdConfig.maxAdsPerSession!) {
      return 'Session limit reached';
    }

    return 'Waiting for conditions';
  }

  /// Dispose resources
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _interstitialAd?.dispose();
    super.dispose();
  }

  /// Get timing information
  Map<String, String> getTimingInfo() {
    final sessionAge = _sessionStart != null
        ? DateTime.now().difference(_sessionStart!)
        : Duration.zero;
    final requiredInterval =
        OptimizedAdConfig.getTimingForEngagement(sessionAge);

    return {
      'engagement': userEngagementLevel,
      'requiredInterval': '${requiredInterval.inSeconds}s',
      'sessionAge': '${sessionAge.inMinutes}min',
    };
  }
}
