import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../config/ad_config.dart';

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

  // Lifecycle state tracking
  DateTime? _lastBackgroundTime;
  DateTime? _lastSessionReset;
  AppLifecycleState _currentLifecycleState = AppLifecycleState.resumed;

  // Ad loading state
  InterstitialAd? _interstitialAd;
  bool _isAdReady = false;
  bool _isLoading = false;

  // Timing configuration (conservative for good UX)
  static const int _minMinutesBetweenAds = 3; // 3 minutes minimum between ads
  static const int _transitionsBeforeFirstAd =
      4; // User must transition 4 times before first ad
  static const int _transitionsPerAdAfterFirst = 3; // Then every 3 transitions
  static const int _maxAdsPerSession = 3; // Maximum 3 ads per session
  static const int _minSessionMinutesBeforeAds =
      2; // Wait 2 minutes into session
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

    debugPrint('RoomTransitionAds: Session started');
    debugPrint('RoomTransitionAds: Configuration Check:');
    debugPrint('  - App ID: ${AdConfig.appId}');
    debugPrint('  - Interstitial Ad Unit ID: ${AdConfig.interstitialAdUnitId}');
    debugPrint('  - Debug Mode: $kDebugMode');
    debugPrint(
        '  - Test ID Pattern: ${AdConfig.interstitialAdUnitId.contains('3940256099942544') ? 'YES (Test ID)' : 'NO (Production ID)'}');

    _configureTestDeviceSettings();
    _preloadInterstitialAd();
    notifyListeners();
  }

  /// Track when user transitions between rooms
  void trackRoomTransition() {
    _roomTransitions++;
    debugPrint('RoomTransitionAds: Transition #$_roomTransitions');
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
  }

  /// Check if we should show an interstitial ad right now
  bool shouldShowAdNow() {
    // Basic session checks
    if (_sessionStart == null) return false;
    if (_adsShownThisSession >= _maxAdsPerSession) {
      debugPrint('RoomTransitionAds: Session ad limit reached');
      return false;
    }
    if (!_isAdReady) {
      debugPrint('RoomTransitionAds: Ad not ready');
      return false;
    }

    // Time-based checks
    final sessionDuration = DateTime.now().difference(_sessionStart!);
    if (sessionDuration.inMinutes < _minSessionMinutesBeforeAds) {
      debugPrint(
          'RoomTransitionAds: Session too young (${sessionDuration.inMinutes}min < $_minSessionMinutesBeforeAds min)');
      return false;
    }

    if (_lastAdShown != null) {
      final timeSinceLastAd = DateTime.now().difference(_lastAdShown!);
      if (timeSinceLastAd.inMinutes < _minMinutesBetweenAds) {
        debugPrint(
            'RoomTransitionAds: Too soon since last ad (${timeSinceLastAd.inMinutes}min < $_minMinutesBetweenAds min)');
        return false;
      }
    }

    // Transition-based logic
    if (_adsShownThisSession == 0) {
      // First ad of session - require more transitions
      if (_roomTransitions < _transitionsBeforeFirstAd) {
        debugPrint(
            'RoomTransitionAds: Need ${_transitionsBeforeFirstAd - _roomTransitions} more transitions for first ad');
        return false;
      }
    } else {
      // Subsequent ads - require fewer transitions
      final transitionsSinceLastAd = _roomTransitions -
          (_adsShownThisSession * _transitionsPerAdAfterFirst);
      if (transitionsSinceLastAd < _transitionsPerAdAfterFirst) {
        debugPrint(
            'RoomTransitionAds: Need ${_transitionsPerAdAfterFirst - transitionsSinceLastAd} more transitions');
        return false;
      }
    }

    debugPrint('RoomTransitionAds: ✅ Should show ad now!');
    return true;
  }

  /// Show interstitial ad if timing is appropriate
  Future<bool> showAdIfAppropriate() async {
    if (!shouldShowAdNow()) {
      return false;
    }

    if (_interstitialAd == null) {
      debugPrint('RoomTransitionAds: No ad loaded');
      return false;
    }

    try {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (InterstitialAd ad) {
          debugPrint('RoomTransitionAds: Ad shown successfully');
          _lastAdShown = DateTime.now();
          _adsShownThisSession++;
          notifyListeners();
        },
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          debugPrint('RoomTransitionAds: Ad dismissed');
          ad.dispose();
          _interstitialAd = null;
          _isAdReady = false;
          notifyListeners();

          // Pre-load next ad
          _preloadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          debugPrint('RoomTransitionAds: Ad failed to show: $error');
          ad.dispose();
          _interstitialAd = null;
          _isAdReady = false;
          notifyListeners();

          // Try to load again
          _preloadInterstitialAd();
        },
      );

      await _interstitialAd!.show();
      return true;
    } catch (e) {
      debugPrint('RoomTransitionAds: Error showing ad: $e');
      return false;
    }
  }

  /// Pre-load interstitial ad for better performance
  Future<void> _preloadInterstitialAd() async {
    if (_isLoading || _isAdReady) return;

    _isLoading = true;
    notifyListeners();

    try {
      await InterstitialAd.load(
        adUnitId: _getInterstitialAdUnitId(),
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            debugPrint('RoomTransitionAds: Interstitial ad loaded');
            _interstitialAd = ad;
            _isAdReady = true;
            _isLoading = false;
            notifyListeners();
          },
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint(
                'RoomTransitionAds: Failed to load interstitial ad: $error');
            _interstitialAd = null;
            _isAdReady = false;
            _isLoading = false;
            notifyListeners();

            // Retry after delay
            Future.delayed(const Duration(seconds: 30), () {
              if (!_isAdReady && !_isLoading) {
                _preloadInterstitialAd();
              }
            });
          },
        ),
      );
    } catch (e) {
      debugPrint('RoomTransitionAds: Exception loading ad: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Configure test device settings for AdMob
  void _configureTestDeviceSettings() {
    // Configure request configuration for test device handling
    final requestConfiguration = RequestConfiguration(
      // Remove test device IDs to see production ads on emulator
      // WARNING: Only do this if you want to see real ads during development
      // This may impact your AdMob metrics and revenue
      testDeviceIds: kDebugMode ? [] : [], // Empty list = no test devices

      // Alternative: Keep test device detection in debug mode
      // testDeviceIds: kDebugMode ? ['YOUR_TEST_DEVICE_ID_HERE'] : [],

      tagForChildDirectedTreatment: TagForChildDirectedTreatment.unspecified,
      tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.unspecified,
    );

    MobileAds.instance.updateRequestConfiguration(requestConfiguration);

    debugPrint('RoomTransitionAds: Test device configuration updated');
    debugPrint('  - Test Device IDs: ${requestConfiguration.testDeviceIds}');
    debugPrint(
        '  - This will ${requestConfiguration.testDeviceIds?.isEmpty ?? true ? 'show PRODUCTION ads' : 'show TEST ads'}');
  }

  /// Get appropriate ad unit ID (test vs production)
  String _getInterstitialAdUnitId() {
    return AdConfig.interstitialAdUnitId;
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
  Map<String, dynamic> getSessionStats() {
    final sessionDuration = _sessionStart != null
        ? DateTime.now().difference(_sessionStart!)
        : Duration.zero;

    return {
      'sessionDurationMinutes': sessionDuration.inMinutes,
      'roomTransitions': _roomTransitions,
      'adsShownThisSession': _adsShownThisSession,
      'isAdReady': _isAdReady,
      'shouldShowAdNow': shouldShowAdNow(),
      'timeUntilNextAdEligible': getTimeUntilNextAdEligible()?.inMinutes,
      'maxAdsPerSession': _maxAdsPerSession,
      'transitionsNeededForNextAd': _calculateTransitionsNeededForNextAd(),
    };
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

    debugPrint('RoomTransitionAds: Session reset');
    notifyListeners();
  }

  /// Force reset session (for testing or manual reset)
  void forceResetSession() {
    _lastSessionReset = DateTime.now()
        .subtract(Duration(minutes: _minMinutesBetweenSessionResets + 1));
    resetSession();
    debugPrint('RoomTransitionAds: Session force reset');
  }

  /// Force load an ad (for testing purposes)
  Future<void> forceLoadAd() async {
    _isAdReady = false;
    _isLoading = false;
    await _preloadInterstitialAd();
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
