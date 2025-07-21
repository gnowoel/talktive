import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../config/ad_config.dart';
import 'admob_compliance.dart';

/// Manages interstitial ads specifically for room transitions (chat ↔ topic)
/// Follows AdMob best practices for respectful, non-intrusive ad placement
class RoomTransitionAds extends ChangeNotifier with WidgetsBindingObserver {
  static RoomTransitionAds? _instance;
  static RoomTransitionAds get instance => _instance ??= RoomTransitionAds._();

  RoomTransitionAds._();

  // Current session state
  DateTime? _sessionStart;
  DateTime? _lastAdShown;
  int _roomTransitions = 0;
  int _adsShownThisSession = 0;

  // Navigation pattern tracking
  List<DateTime> _recentNavigations = [];
  DateTime? _lastNavigationTime;
  int _consecutiveQuickNavigations = 0;

  // Lifecycle state tracking
  DateTime? _lastBackgroundTime;
  DateTime? _lastSessionReset;
  AppLifecycleState _currentLifecycleState = AppLifecycleState.resumed;

  // Ad loading state
  InterstitialAd? _interstitialAd;
  bool _isAdReady = false;
  bool _isLoading = false;

  // Timing configuration (balanced for visibility and UX)
  static const int _minMinutesBetweenAds = 2; // 2 minutes minimum between ads
  static const int _transitionsBeforeFirstAd =
      2; // User must transition 2 times before first ad
  static const int _transitionsPerAdAfterFirst = 2; // Then every 2 transitions
  static const int _maxAdsPerSession = 5; // Maximum 5 ads per session
  static const int _minSessionMinutesBeforeAds =
      1; // Wait 1 minute into session
  static const int _minMinutesInBackgroundForReset =
      10; // Reset session after 10+ minutes in background
  static const int _minMinutesBetweenSessionResets =
      30; // Minimum 30 minutes between session resets

  // Getters
  bool get isAdReady => _isAdReady;
  int get roomTransitions => _roomTransitions;
  int get adsShownThisSession => _adsShownThisSession;

  /// Initialize the room transition ad manager
  void initialize() {
    _sessionStart = DateTime.now();
    _roomTransitions = 0;
    _adsShownThisSession = 0;
    _lastAdShown = null;

    // Register lifecycle observer for session management
    WidgetsBinding.instance.addObserver(this);

    // Initialize AdMob compliance system
    AdMobCompliance.initialize();

    debugPrint('RoomTransitionAds: Session started');
    debugPrint('RoomTransitionAds: Configuration Check:');
    debugPrint('  - App ID: ${AdConfig.appId}');
    debugPrint('  - Interstitial Ad Unit ID: ${AdConfig.interstitialAdUnitId}');
    debugPrint('  - Debug Mode: $kDebugMode');
    debugPrint('  - Admin User: ${AdMobCompliance.isCurrentUserAdmin}');
    debugPrint('  - Using Test Ads: ${AdMobCompliance.shouldUseTestAds}');
    debugPrint(
        '  - Test ID Pattern: ${AdConfig.interstitialAdUnitId.contains('3940256099942544') ? 'YES (Test ID)' : 'NO (Production ID)'}');

    // Log compliance status
    if (AdMobCompliance.shouldLogVerbose) {
      AdMobCompliance.logComplianceStatus();
    }

    // Load ad after short delay to ensure session is established
    Future.delayed(const Duration(seconds: 30), () {
      if (_shouldLoadAd()) {
        _preloadInterstitialAd();
      }
    });
    notifyListeners();
  }

  /// Track when user transitions between rooms
  void trackRoomTransition() {
    _roomTransitions++;

    // Track navigation patterns
    final now = DateTime.now();
    _recentNavigations.add(now);

    // Keep only last 10 navigations for pattern analysis
    if (_recentNavigations.length > 10) {
      _recentNavigations.removeAt(0);
    }

    // Track consecutive quick navigations
    if (_lastNavigationTime != null) {
      final timeSinceLastNav = now.difference(_lastNavigationTime!);
      if (timeSinceLastNav.inSeconds < 30) {
        _consecutiveQuickNavigations++;
      } else {
        _consecutiveQuickNavigations = 0;
      }
    }

    _lastNavigationTime = now;

    AdMobCompliance.safeLog('Room transition #$_roomTransitions tracked');
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final previousState = _currentLifecycleState;
    _currentLifecycleState = state;

    debugPrint(
        'RoomTransitionAds: Lifecycle changed from $previousState to $state');

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _lastBackgroundTime = DateTime.now();
        debugPrint(
            'RoomTransitionAds: App went to background at $_lastBackgroundTime');
        break;

      case AppLifecycleState.resumed:
        _handleAppResumed(previousState);
        break;

      case AppLifecycleState.inactive:
        // Handle brief inactivity (like receiving a phone call)
        break;

      case AppLifecycleState.hidden:
        // Handle when app is hidden but not paused
        break;
    }
  }

  /// Handle app resuming from background
  void _handleAppResumed(AppLifecycleState previousState) {
    final now = DateTime.now();

    if (_lastBackgroundTime != null) {
      final backgroundDuration = now.difference(_lastBackgroundTime!);
      debugPrint(
          'RoomTransitionAds: App resumed after ${backgroundDuration.inMinutes} minutes in background');

      // Check if we should reset the session
      if (_shouldResetSessionOnResume(backgroundDuration)) {
        debugPrint(
            'RoomTransitionAds: Resetting session due to long background time');
        _resetSessionFromBackground();
      } else {
        debugPrint(
            'RoomTransitionAds: Session continues (background time too short)');
      }
    }

    _lastBackgroundTime = null;
  }

  /// Check if session should be reset based on background time
  bool _shouldResetSessionOnResume(Duration backgroundDuration) {
    // Must be in background for minimum time
    if (backgroundDuration.inMinutes < _minMinutesInBackgroundForReset) {
      return false;
    }

    // Respect minimum time between session resets
    if (_lastSessionReset != null) {
      final timeSinceLastReset = DateTime.now().difference(_lastSessionReset!);
      if (timeSinceLastReset.inMinutes < _minMinutesBetweenSessionResets) {
        debugPrint(
            'RoomTransitionAds: Session reset blocked - only ${timeSinceLastReset.inMinutes} minutes since last reset');
        return false;
      }
    }

    return true;
  }

  /// Reset session when returning from background
  void _resetSessionFromBackground() {
    final previousAdsShown = _adsShownThisSession;
    final previousTransitions = _roomTransitions;

    resetSession();

    debugPrint('RoomTransitionAds: Background session reset completed');
    debugPrint('  - Previous ads shown: $previousAdsShown');
    debugPrint('  - Previous transitions: $previousTransitions');
    debugPrint('  - New session allows up to $_maxAdsPerSession more ads');

    _lastSessionReset = DateTime.now();

    // Load ads after session reset with shorter delay
    Future.delayed(const Duration(minutes: 1), () {
      if (_shouldLoadAd()) {
        _preloadInterstitialAd();
      }
    });
  }

  /// Check if we should show an interstitial ad right now
  Future<bool> shouldShowAdNow() async {
    AdMobCompliance.safeLog('=== Ad Show Check Started ===');

    // Validate ad compliance first
    if (!await AdMobCompliance.validateAdRequest('interstitial')) {
      AdMobCompliance.safeLog('❌ Ad request validation failed');
      return false;
    }
    AdMobCompliance.safeLog('✅ Ad compliance validation passed');

    // Basic session checks
    if (_sessionStart == null) {
      AdMobCompliance.safeLog('❌ Session not started');
      return false;
    }
    AdMobCompliance.safeLog('✅ Session started: $_sessionStart');

    if (_adsShownThisSession >= _maxAdsPerSession) {
      AdMobCompliance.safeLog(
          '❌ Session ad limit reached ($_adsShownThisSession/$_maxAdsPerSession)');
      return false;
    }
    AdMobCompliance.safeLog('✅ Session ad limit OK ($_adsShownThisSession/$_maxAdsPerSession)');

    if (!_isAdReady) {
      AdMobCompliance.safeLog('❌ Ad not ready (loading: $_isLoading)');
      return false;
    }
    AdMobCompliance.safeLog('✅ Ad is ready');

    // Time-based checks
    final sessionDuration = DateTime.now().difference(_sessionStart!);
    if (sessionDuration.inMinutes < _minSessionMinutesBeforeAds) {
      AdMobCompliance.safeLog(
          '❌ Session too young (${sessionDuration.inSeconds}s < ${_minSessionMinutesBeforeAds * 60}s)');
      return false;
    }
    AdMobCompliance.safeLog('✅ Session age OK (${sessionDuration.inSeconds}s)');

    if (_lastAdShown != null) {
      final timeSinceLastAd = DateTime.now().difference(_lastAdShown!);
      if (timeSinceLastAd.inMinutes < _minMinutesBetweenAds) {
        AdMobCompliance.safeLog(
            '❌ Too soon since last ad (${timeSinceLastAd.inSeconds}s < ${_minMinutesBetweenAds * 60}s)');
        return false;
      }
      AdMobCompliance.safeLog('✅ Time since last ad OK (${timeSinceLastAd.inSeconds}s)');
    } else {
      AdMobCompliance.safeLog('✅ No previous ad shown in session');
    }

    // Transition-based logic
    if (_adsShownThisSession == 0) {
      // First ad of session - require more transitions
      if (_roomTransitions < _transitionsBeforeFirstAd) {
        AdMobCompliance.safeLog(
            '❌ Need ${_transitionsBeforeFirstAd - _roomTransitions} more transitions for first ad (have $_roomTransitions, need $_transitionsBeforeFirstAd)');
        return false;
      }
      AdMobCompliance.safeLog('✅ First ad transition requirement met ($_roomTransitions >= $_transitionsBeforeFirstAd)');
    } else {
      // Subsequent ads - require fewer transitions
      final transitionsSinceLastAd = _roomTransitions -
          (_adsShownThisSession * _transitionsPerAdAfterFirst);
      if (transitionsSinceLastAd < _transitionsPerAdAfterFirst) {
        AdMobCompliance.safeLog(
            '❌ Need ${_transitionsPerAdAfterFirst - transitionsSinceLastAd} more transitions (have $transitionsSinceLastAd, need $_transitionsPerAdAfterFirst)');
        return false;
      }
      AdMobCompliance.safeLog('✅ Subsequent ad transition requirement met (transitions since last: $transitionsSinceLastAd)');
    }

    // Check if user is in a good state for ads (not disrupting flow)
    if (!_isUserInGoodStateForAds()) {
      AdMobCompliance.safeLog('❌ User not in good state for ads');
      return false;
    }
    AdMobCompliance.safeLog('✅ User in good state for ads');

    // Check if this is an optimal moment for showing an ad
    if (!_isOptimalAdMoment()) {
      AdMobCompliance.safeLog('❌ Not optimal moment for ad');
      return false;
    }
    AdMobCompliance.safeLog('✅ Optimal moment for ad');

    AdMobCompliance.safeLog('🎯 ✅ SHOULD SHOW AD NOW! All conditions met');
    return true;
  }

  /// Show interstitial ad if timing is appropriate
  Future<bool> showAdIfAppropriate() async {
    if (!await shouldShowAdNow()) {
      return false;
    }

    if (_interstitialAd == null) {
      AdMobCompliance.safeLog('No ad loaded');
      return false;
    }

    // Log compliance context before showing ad
    if (AdMobCompliance.shouldLogVerbose) {
      AdMobCompliance.safeLog(
          'Showing room transition ad - ${AdMobCompliance.getComplianceSummary()}');
    }

    try {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (InterstitialAd ad) {
          AdMobCompliance.logAdShown('interstitial',
              context: 'room transition');
          _lastAdShown = DateTime.now();
          _adsShownThisSession++;
          notifyListeners();
        },
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          AdMobCompliance.safeLog('Room transition ad dismissed');
          ad.dispose();
          _interstitialAd = null;
          _isAdReady = false;
          notifyListeners();

          // Pre-load next ad with optimal delay
          Future.delayed(_getOptimalPreloadDelay(), () {
            if (_shouldLoadAd()) {
              _preloadInterstitialAd();
            }
          });
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          AdMobCompliance.safeLog('Room transition ad failed to show: $error',
              forceLog: true);
          ad.dispose();
          _interstitialAd = null;
          _isAdReady = false;
          notifyListeners();

          // Try to load again with optimal delay
          Future.delayed(_getOptimalPreloadDelay(), () {
            if (_shouldLoadAd()) {
              _preloadInterstitialAd();
            }
          });
        },
      );

      await _interstitialAd!.show();
      return true;
    } catch (e) {
      AdMobCompliance.safeLog('Error showing room transition ad: $e',
          forceLog: true);
      return false;
    }
  }

  /// Pre-load interstitial ad for better performance
  Future<void> _preloadInterstitialAd() async {
    if (_isLoading || _isAdReady) return;

    // Check if we should actually load an ad before making the request
    if (!_shouldLoadAd()) {
      AdMobCompliance.safeLog('Skipping ad load - conditions not met');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final adUnitId = _getInterstitialAdUnitId();
      AdMobCompliance.safeLog(
          'Loading interstitial ad with unit ID: $adUnitId');

      await InterstitialAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            AdMobCompliance.safeLog('Interstitial ad loaded successfully');
            _interstitialAd = ad;
            _isAdReady = true;
            _isLoading = false;
            notifyListeners();
          },
          onAdFailedToLoad: (LoadAdError error) {
            AdMobCompliance.safeLog('Failed to load interstitial ad: $error',
                forceLog: true);
            _interstitialAd = null;
            _isAdReady = false;
            _isLoading = false;
            notifyListeners();

            // Moderate retry delay with condition checking
            Future.delayed(const Duration(minutes: 1), () {
              if (!_isAdReady && !_isLoading && _shouldLoadAd()) {
                _preloadInterstitialAd();
              }
            });
          },
        ),
      );
    } catch (e) {
      AdMobCompliance.safeLog('Exception loading ad: $e', forceLog: true);
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check if we should load an ad based on current session state
  bool _shouldLoadAd() {
    // Don't load if session hasn't started
    if (_sessionStart == null) return false;

    // Don't load if we've reached session ad limit
    if (_adsShownThisSession >= _maxAdsPerSession) return false;

    // Don't load if session is too young
    final sessionDuration = DateTime.now().difference(_sessionStart!);
    if (sessionDuration.inSeconds < 30) {
      return false;
    }

    // Don't load if we just showed an ad recently
    if (_lastAdShown != null) {
      final timeSinceLastAd = DateTime.now().difference(_lastAdShown!);
      if (timeSinceLastAd.inSeconds < 90) {
        return false;
      }
    }

    // Don't load if we don't have enough room transitions yet
    if (_adsShownThisSession == 0 &&
        _roomTransitions < (_transitionsBeforeFirstAd - 1)) {
      return false;
    }

    // Check navigation patterns to avoid loading for inactive users
    if (!_hasHealthyNavigationPattern()) {
      AdMobCompliance.safeLog(
          'Unhealthy navigation pattern - skipping ad load: ${_getNavigationPatternSummary()}');
      return false;
    }

    return true;
  }

  /// Check if user has a healthy navigation pattern (more permissive for better ad visibility)
  bool _hasHealthyNavigationPattern() {
    // Allow more rapid navigation - only block if extremely rapid
    if (_consecutiveQuickNavigations > 8) {
      AdMobCompliance.safeLog(
          'Navigation pattern: Extremely rapid ($_consecutiveQuickNavigations quick navs)');
      return false;
    }

    // More permissive navigation pattern checking
    if (_recentNavigations.length >= 5) {
      final now = DateTime.now();
      final oldestRecent = _recentNavigations.first;
      final timeSpan = now.difference(oldestRecent);

      // Only block if all recent navigations happened within 1 minute (very rapid browsing)
      if (timeSpan.inSeconds < 60) {
        AdMobCompliance.safeLog(
            'Navigation pattern: Too compressed (${_recentNavigations.length} navs in ${timeSpan.inSeconds}s)');
        return false;
      }

      // Increase inactivity threshold to 15 minutes
      if (_lastNavigationTime != null) {
        final timeSinceLastNav = now.difference(_lastNavigationTime!);
        if (timeSinceLastNav.inMinutes > 15) {
          AdMobCompliance.safeLog(
              'Navigation pattern: Too sparse (${timeSinceLastNav.inMinutes}min since last nav)');
          return false;
        }
      }
    }

    return true;
  }

  /// Get navigation pattern summary for debugging
  String _getNavigationPatternSummary() {
    final now = DateTime.now();
    String summary = 'QuickNavs: $_consecutiveQuickNavigations';

    if (_recentNavigations.isNotEmpty) {
      final recentCount = _recentNavigations.length;
      final oldestRecent = _recentNavigations.first;
      final recentSpan = now.difference(oldestRecent);
      summary += ', Recent: $recentCount navs in ${recentSpan.inMinutes}min';
    }

    if (_lastNavigationTime != null) {
      final timeSinceLastNav = now.difference(_lastNavigationTime!);
      summary += ', LastNav: ${timeSinceLastNav.inMinutes}min ago';
    }

    return summary;
  }

  /// Intelligently preload ad if conditions are appropriate
  /// This method can be called by external triggers (like navigation helpers)
  /// to proactively load ads when user behavior suggests they'll be needed
  Future<void> preloadIfAppropriate() async {
    if (_isLoading || _isAdReady) {
      AdMobCompliance.safeLog(
          'Skipping intelligent preload - ad already loading/ready');
      return;
    }

    if (!_shouldLoadAd()) {
      AdMobCompliance.safeLog(
          'Skipping intelligent preload - conditions not met');
      return;
    }

    AdMobCompliance.safeLog('Intelligent preload triggered');
    await _preloadInterstitialAd();
  }

  /// Enable aggressive preloading for highly engaged users
  /// This method detects user engagement patterns and preloads more aggressively
  Future<void> enableAggressivePreloadingIfEngaged() async {
    if (_isLoading || _isAdReady) return;

    // Check if user shows high engagement patterns
    if (!_isHighlyEngagedUser()) return;

    AdMobCompliance.safeLog('Aggressive preload triggered for engaged user');
    await _preloadInterstitialAd();
  }

  /// Detect if user shows high engagement patterns
  bool _isHighlyEngagedUser() {
    if (_sessionStart == null) return false;

    final sessionDuration = DateTime.now().difference(_sessionStart!);

    // User must be in session for at least 2 minutes
    if (sessionDuration.inMinutes < 2) return false;

    // High engagement indicators:
    // 1. Multiple room transitions in short time
    if (_roomTransitions >= 3 && sessionDuration.inMinutes < 5) return true;

    // 2. Consistent navigation pattern (not too rapid, not too sparse)
    if (_recentNavigations.length >= 3) {
      final now = DateTime.now();
      final oldestRecent = _recentNavigations.first;
      final timeSpan = now.difference(oldestRecent);

      // Good engagement: 3+ navigations spread over 2-8 minutes
      if (timeSpan.inMinutes >= 2 && timeSpan.inMinutes <= 8) return true;
    }

    // 3. Long session with reasonable activity
    if (sessionDuration.inMinutes >= 5 && _roomTransitions >= 2) return true;

    return false;
  }

  /// Get user engagement level as a string
  String _getEngagementLevel() {
    final score = _calculateEngagementScore();
    if (score >= 80) return 'High';
    if (score >= 50) return 'Medium';
    if (score >= 20) return 'Low';
    return 'Minimal';
  }

  /// Calculate engagement score (0-100)
  int _calculateEngagementScore() {
    if (_sessionStart == null) return 0;

    final sessionDuration = DateTime.now().difference(_sessionStart!);
    int score = 0;

    // Session duration score (0-30 points)
    if (sessionDuration.inMinutes >= 10) {
      score += 30;
    } else if (sessionDuration.inMinutes >= 5) {
      score += 20;
    } else if (sessionDuration.inMinutes >= 2) {
      score += 10;
    }

    // Room transitions score (0-25 points)
    if (_roomTransitions >= 8) {
      score += 25;
    } else if (_roomTransitions >= 5) {
      score += 20;
    } else if (_roomTransitions >= 3) {
      score += 15;
    } else if (_roomTransitions >= 1) {
      score += 10;
    }

    // Navigation pattern score (0-25 points)
    if (_hasHealthyNavigationPattern()) {
      score += 25;
    } else if (_consecutiveQuickNavigations <= 3) {
      score += 15;
    } else if (_consecutiveQuickNavigations <= 6) {
      score += 10;
    }

    // Session consistency score (0-20 points)
    if (_recentNavigations.length >= 4) {
      final now = DateTime.now();
      final oldestRecent = _recentNavigations.first;
      final timeSpan = now.difference(oldestRecent);

      // Consistent activity over time
      if (timeSpan.inMinutes >= 3 && timeSpan.inMinutes <= 10) {
        score += 20;
      } else if (timeSpan.inMinutes >= 2 && timeSpan.inMinutes <= 15) {
        score += 15;
      } else if (timeSpan.inMinutes >= 1) {
        score += 10;
      }
    }

    return score.clamp(0, 100);
  }

  /// Get appropriate ad unit ID (test vs production)
  /// Uses AdMob compliance system to determine correct ad unit for user role
  String _getInterstitialAdUnitId() {
    final shouldUseTestAds = AdMobCompliance.shouldUseTestAds;

    if (shouldUseTestAds) {
      // Use test ad unit IDs for debug mode or admin users
      final testIds = AdMobCompliance.testAdUnitIds;
      return Platform.isAndroid
          ? testIds['interstitial_android']!
          : testIds['interstitial_ios']!;
    } else {
      // Use production ad unit ID from config
      return AdConfig.interstitialAdUnitId;
    }
  }

  /// Get time until next ad is eligible
  Duration? getTimeUntilNextAdEligible() {
    if (_lastAdShown == null) return null;

    final timeSinceLastAd = DateTime.now().difference(_lastAdShown!);
    final remainingMinutes = _minMinutesBetweenAds - timeSinceLastAd.inMinutes;

    if (remainingMinutes > 0) {
      return Duration(minutes: remainingMinutes);
    }
    return null;
  }

  /// Get current session statistics for debugging
  Future<Map<String, dynamic>> getSessionStats() async {
    final sessionDuration = _sessionStart != null
        ? DateTime.now().difference(_sessionStart!)
        : Duration.zero;

    final lastNavMinutesAgo = _lastNavigationTime != null
        ? DateTime.now().difference(_lastNavigationTime!).inMinutes
        : null;

    return {
      'sessionDurationMinutes': sessionDuration.inMinutes,
      'roomTransitions': _roomTransitions,
      'adsShownThisSession': _adsShownThisSession,
      'isAdReady': _isAdReady,
      'shouldShowAdNow': await shouldShowAdNow(),
      'timeUntilNextAdEligible': getTimeUntilNextAdEligible()?.inMinutes,
      'maxAdsPerSession': _maxAdsPerSession,
      'transitionsNeededForNextAd': _calculateTransitionsNeededForNextAd(),
      'consecutiveQuickNavigations': _consecutiveQuickNavigations,
      'recentNavigationsCount': _recentNavigations.length,
      'lastNavigationMinutesAgo': lastNavMinutesAgo,
      'navigationPatternSummary': _getNavigationPatternSummary(),
      'hasHealthyNavigationPattern': _hasHealthyNavigationPattern(),
      'isHighlyEngaged': _isHighlyEngagedUser(),
      'engagementLevel': _getEngagementLevel(),
      'sessionEngagementScore': _calculateEngagementScore(),
      'isOptimalAdMoment': _isOptimalAdMoment(),
      'isUserInGoodStateForAds': _isUserInGoodStateForAds(),
      'nextAdOpportunity': _predictNextAdOpportunity(),
    };
  }

  /// Check if current moment is optimal for showing an ad
  bool _isOptimalAdMoment() {
    // Much more permissive - only block in extreme cases

    // Allow ads even with unhealthy navigation patterns (for better visibility)
    // Only block if extremely rapid navigation
    if (_consecutiveQuickNavigations >= 8) {
      AdMobCompliance.safeLog('Optimal moment: Too rapid navigation (${_consecutiveQuickNavigations} quick navs)');
      return false;
    }

    // Reduce session requirement significantly (2 minutes -> 15 seconds)
    if (_sessionStart != null) {
      final sessionDuration = DateTime.now().difference(_sessionStart!);
      if (sessionDuration.inSeconds < 15) {
        AdMobCompliance.safeLog('Optimal moment: Session too new (${sessionDuration.inSeconds}s)');
        return false;
      }
    }

    // Much simpler timing logic - just ensure it's not immediate after app start
    AdMobCompliance.safeLog('Optimal moment: Good to show ad');
    return true;
  }

  /// Get optimal delay for next ad preload based on current conditions
  Duration _getOptimalPreloadDelay() {
    if (_isHighlyEngagedUser()) {
      return const Duration(seconds: 30);
    }

    if (_hasHealthyNavigationPattern()) {
      return const Duration(minutes: 1);
    }

    // Default delay for less engaged users
    return const Duration(minutes: 2);
  }

  /// Check if user is in a good state for ads (not disrupting flow)
  bool _isUserInGoodStateForAds() {
    // Only block if user is extremely rapidly navigating
    if (_consecutiveQuickNavigations >= 6) {
      AdMobCompliance.safeLog('User state: Too rapid navigation ($_consecutiveQuickNavigations quick navs)');
      return false;
    }

    // Only block very new sessions (reduced from 45 to 10 seconds)
    if (_sessionStart != null) {
      final sessionDuration = DateTime.now().difference(_sessionStart!);
      if (sessionDuration.inSeconds < 10) {
        AdMobCompliance.safeLog('User state: Session too new (${sessionDuration.inSeconds}s)');
        return false;
      }
    }

    // Don't block based on recent navigation - ads can show after navigation
    AdMobCompliance.safeLog('User state: Good for ads');
    return true;
  }

  /// Predict when next ad opportunity might occur (for debugging)
  Future<String> _predictNextAdOpportunity() async {
    if (!await shouldShowAdNow()) {
      if (_adsShownThisSession >= _maxAdsPerSession) {
        return "Session limit reached";
      }

      if (!_isAdReady) {
        return "Ad not ready - loading in progress";
      }

      final timeUntilEligible = getTimeUntilNextAdEligible();
      if (timeUntilEligible != null) {
        return "Next eligible in ${timeUntilEligible.inMinutes}min";
      }

      final transitionsNeeded = _calculateTransitionsNeededForNextAd();
      if (transitionsNeeded > 0) {
        return "Need $transitionsNeeded more transitions";
      }

      if (!_hasHealthyNavigationPattern()) {
        return "Waiting for healthy navigation pattern";
      }
    }

    return "Ready to show ad";
  }

  /// Calculate how many more transitions needed for next ad
  int _calculateTransitionsNeededForNextAd() {
    if (_adsShownThisSession == 0) {
      return _transitionsBeforeFirstAd - _roomTransitions;
    } else {
      final transitionsSinceLastAd = _roomTransitions -
          (_adsShownThisSession * _transitionsPerAdAfterFirst);
      return _transitionsPerAdAfterFirst - transitionsSinceLastAd;
    }
  }

  /// Reset session (useful for testing or when app is backgrounded for long time)
  void resetSession() {
    _sessionStart = DateTime.now();
    _roomTransitions = 0;
    _adsShownThisSession = 0;
    _lastAdShown = null;

    // Clear navigation pattern tracking
    _recentNavigations.clear();
    _lastNavigationTime = null;
    _consecutiveQuickNavigations = 0;

    AdMobCompliance.safeLog('Session reset - new session started');
    notifyListeners();
  }

  /// Force reset session (for testing or manual reset)
  void forceResetSession() {
    _lastSessionReset = DateTime.now()
        .subtract(Duration(minutes: _minMinutesBetweenSessionResets + 1));
    resetSession();
    AdMobCompliance.safeLog('Session force reset completed');
  }

  /// Force load an ad (for testing purposes)
  Future<void> forceLoadAd() async {
    _isAdReady = false;
    _isLoading = false;
    await _preloadInterstitialAd();
  }

  /// Force show an ad immediately (for testing purposes)
  /// Bypasses all timing and engagement restrictions
  Future<bool> forceShowAd() async {
    AdMobCompliance.safeLog('🔧 FORCE SHOW AD - Testing mode');

    if (_interstitialAd == null) {
      AdMobCompliance.safeLog('❌ No ad loaded - attempting to load first');
      await forceLoadAd();
      // Wait a bit for ad to load
      await Future.delayed(const Duration(seconds: 2));
      if (_interstitialAd == null) {
        AdMobCompliance.safeLog('❌ Failed to load ad for force show');
        return false;
      }
    }

    // Validate compliance before showing ad
    if (!await AdMobCompliance.validateAdRequest('interstitial')) {
      AdMobCompliance.safeLog('❌ Compliance validation failed - cannot force show');
      return false;
    }

    try {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (InterstitialAd ad) {
          AdMobCompliance.logAdShown('interstitial', context: 'force show test');
          _lastAdShown = DateTime.now();
          _adsShownThisSession++;
          notifyListeners();
        },
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          AdMobCompliance.safeLog('Force shown ad dismissed');
          ad.dispose();
          _interstitialAd = null;
          _isAdReady = false;
          notifyListeners();
          // Preload next ad
          _preloadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          AdMobCompliance.safeLog('Force shown ad failed to show: $error', forceLog: true);
          ad.dispose();
          _interstitialAd = null;
          _isAdReady = false;
          notifyListeners();
          // Try to load again
          _preloadInterstitialAd();
        },
      );

      await _interstitialAd!.show();
      AdMobCompliance.safeLog('🎯 ✅ FORCE SHOW AD SUCCESS');
      return true;
    } catch (e) {
      AdMobCompliance.safeLog('❌ Error force showing ad: $e', forceLog: true);
      return false;
    }
  }

  /// Get compliance status specific to room transition ads
  Future<Map<String, dynamic>> getComplianceStatus() async {
    final generalCompliance = await AdMobCompliance.getComplianceStatus();
    final currentAdUnitId = _getInterstitialAdUnitId();

    return {
      ...generalCompliance,
      'currentAdUnitId': currentAdUnitId,
      'isUsingTestAdUnit': currentAdUnitId.contains('3940256099942544'),
      'adReadyState': _isAdReady,
      'canShowAd': await shouldShowAdNow(),
      'complianceValidated': await AdMobCompliance.validateAdRequest('interstitial'),
    };
  }

  /// Get comprehensive debug information including compliance
  Future<Map<String, dynamic>> getComprehensiveDebugInfo() async {
    final sessionStats = await getSessionStats();
    final complianceStatus = await getComplianceStatus();
    final lifecycleStats = getLifecycleStats();

    return {
      'session': sessionStats,
      'compliance': complianceStatus,
      'lifecycle': lifecycleStats,
      'timingMessage': getTimingMessage(),
      'complianceSummary': await AdMobCompliance.getComplianceSummary(),
      'userFriendlyMessage': AdMobCompliance.getUserFriendlyMessage(),
    };
  }

  /// Validate compliance and log detailed status
  Future<bool> validateAndLogCompliance() async {
    final isValid = await AdMobCompliance.validateAdRequest('interstitial');

    if (AdMobCompliance.shouldLogVerbose) {
      final status = await getComplianceStatus();
      AdMobCompliance.safeLog('=== Room Transition Ads Compliance Check ===');
      AdMobCompliance.safeLog('Valid: $isValid');
      AdMobCompliance.safeLog('Admin User: ${status['isAdmin']}');
      AdMobCompliance.safeLog('Using Test Ads: ${status['shouldUseTestAds']}');
      AdMobCompliance.safeLog('Ad Unit ID: ${status['currentAdUnitId']}');
      AdMobCompliance.safeLog(
          'Is Test Ad Unit: ${status['isUsingTestAdUnit']}');
      AdMobCompliance.safeLog('Can Show Ad: ${status['canShowAd']}');
      AdMobCompliance.safeLog('============================================');
    }

    return isValid;
  }

  /// Get user-friendly compliance message for room transition ads
  String getComplianceMessage() {
    if (AdMobCompliance.isCurrentUserAdmin) {
      return 'Room transition ads: Using test ads (Admin user)';
    } else if (kDebugMode) {
      return 'Room transition ads: Using test ads (Debug mode)';
    } else {
      return 'Room transition ads: Using production ads';
    }
  }

  /// Dispose resources
  @override
  void dispose() {
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isAdReady = false;
    super.dispose();
  }

  /// Get user-friendly message about ad timing
  String getTimingMessage() {
    if (_adsShownThisSession >= _maxAdsPerSession) {
      return 'No more ads this session ($_adsShownThisSession/$_maxAdsPerSession)';
    }

    if (_sessionStart != null) {
      final sessionDuration = DateTime.now().difference(_sessionStart!);
      if (sessionDuration.inMinutes < _minSessionMinutesBeforeAds) {
        final remaining =
            _minSessionMinutesBeforeAds - sessionDuration.inMinutes;
        return 'Ads start in ${remaining}min (respectful timing)';
      }
    }

    final timeUntilEligible = getTimeUntilNextAdEligible();
    if (timeUntilEligible != null) {
      return 'Next ad eligible in ${timeUntilEligible.inMinutes}min';
    }

    final transitionsNeeded = _calculateTransitionsNeededForNextAd();
    if (transitionsNeeded > 0) {
      return 'Next ad after $transitionsNeeded more room transitions';
    }

    if (!_isAdReady) {
      return 'Loading ad...';
    }

    return 'Ad ready to show';
  }

  /// Get session statistics including lifecycle info
  Map<String, dynamic> getLifecycleStats() {
    final stats = getSessionStats();

    stats.addAll({
      'currentLifecycleState': _currentLifecycleState.toString(),
      'lastBackgroundTime': _lastBackgroundTime?.toIso8601String(),
      'lastSessionReset': _lastSessionReset?.toIso8601String(),
      'canResetSession': _lastSessionReset != null
          ? DateTime.now().difference(_lastSessionReset!).inMinutes >=
              _minMinutesBetweenSessionResets
          : true,
    });

    return stats;
  }
}
