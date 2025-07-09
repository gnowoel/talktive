import 'package:flutter/foundation.dart';

/// Manages ad timing and frequency to ensure good user experience
/// Follows AdMob best practices for ad frequency and placement
class AdTimingManager extends ChangeNotifier {
  static AdTimingManager? _instance;
  static AdTimingManager get instance => _instance ??= AdTimingManager._();

  AdTimingManager._();

  // Session tracking
  DateTime? _sessionStart;
  DateTime? _lastAppLaunch;
  int _sessionCount = 0;

  // Ad frequency tracking
  DateTime? _lastInterstitialShown;
  DateTime? _lastRewardedShown;
  DateTime? _lastBannerShown;

  // Counters
  int _interstitialCount = 0;
  int _rewardedCount = 0;
  int _totalAdsShown = 0;

  // User activity tracking
  int _chatTransitions = 0;
  int _messagesSent = 0;
  int _topicJoins = 0;
  DateTime? _lastUserAction;

  // Timing constraints (in seconds)
  static const int _minInterstitialInterval =
      45; // 45 seconds between interstitials
  static const int _minRewardedInterval = 30; // 30 seconds between rewarded
  static const int _minBannerInterval = 5; // 5 seconds between banner refreshes

  // Session limits
  static const int _maxInterstitialsPerSession = 4;
  static const int _maxRewardedPerSession = 8;
  static const int _maxTotalAdsPerSession = 12;

  // Activity thresholds for natural ad placement
  static const int _chatTransitionsForAd = 3;
  static const int _messagesForAd = 10;
  static const int _topicJoinsForAd = 2;

  // Session timeout (in minutes)
  static const int _sessionTimeoutMinutes = 30;

  /// Initialize the timing manager
  void initialize() {
    _sessionStart = DateTime.now();
    _lastAppLaunch = DateTime.now();
    _sessionCount++;

    debugPrint('AdTimingManager: Session #$_sessionCount started');
    notifyListeners();
  }

  /// Check if a new session should be started
  void checkSessionReset() {
    final now = DateTime.now();

    if (_lastUserAction != null) {
      final timeSinceLastAction = now.difference(_lastUserAction!);

      if (timeSinceLastAction.inMinutes >= _sessionTimeoutMinutes) {
        resetSession();
      }
    }

    _lastUserAction = now;
  }

  /// Reset session counters
  void resetSession() {
    _sessionStart = DateTime.now();
    _interstitialCount = 0;
    _rewardedCount = 0;
    _totalAdsShown = 0;
    _chatTransitions = 0;
    _messagesSent = 0;
    _topicJoins = 0;
    _sessionCount++;

    debugPrint('AdTimingManager: Session reset - Session #$_sessionCount');
    notifyListeners();
  }

  /// Track user activity - chat transitions
  void trackChatTransition() {
    checkSessionReset();
    _chatTransitions++;
    debugPrint('AdTimingManager: Chat transitions: $_chatTransitions');
    notifyListeners();
  }

  /// Track user activity - messages sent
  void trackMessageSent() {
    checkSessionReset();
    _messagesSent++;
    debugPrint('AdTimingManager: Messages sent: $_messagesSent');
    notifyListeners();
  }

  /// Track user activity - topic joins
  void trackTopicJoin() {
    checkSessionReset();
    _topicJoins++;
    debugPrint('AdTimingManager: Topic joins: $_topicJoins');
    notifyListeners();
  }

  /// Check if interstitial ad can be shown
  bool canShowInterstitial() {
    final now = DateTime.now();

    // Check session limits
    if (_interstitialCount >= _maxInterstitialsPerSession) {
      debugPrint('AdTimingManager: Interstitial session limit reached');
      return false;
    }

    if (_totalAdsShown >= _maxTotalAdsPerSession) {
      debugPrint('AdTimingManager: Total ads session limit reached');
      return false;
    }

    // Check time interval
    if (_lastInterstitialShown != null) {
      final timeSinceLastAd = now.difference(_lastInterstitialShown!);
      if (timeSinceLastAd.inSeconds < _minInterstitialInterval) {
        debugPrint(
            'AdTimingManager: Interstitial too soon (${timeSinceLastAd.inSeconds}s < ${_minInterstitialInterval}s)');
        return false;
      }
    }

    return true;
  }

  /// Check if rewarded ad can be shown
  bool canShowRewarded() {
    final now = DateTime.now();

    // Check session limits
    if (_rewardedCount >= _maxRewardedPerSession) {
      debugPrint('AdTimingManager: Rewarded session limit reached');
      return false;
    }

    if (_totalAdsShown >= _maxTotalAdsPerSession) {
      debugPrint('AdTimingManager: Total ads session limit reached');
      return false;
    }

    // Check time interval
    if (_lastRewardedShown != null) {
      final timeSinceLastAd = now.difference(_lastRewardedShown!);
      if (timeSinceLastAd.inSeconds < _minRewardedInterval) {
        debugPrint(
            'AdTimingManager: Rewarded too soon (${timeSinceLastAd.inSeconds}s < ${_minRewardedInterval}s)');
        return false;
      }
    }

    return true;
  }

  /// Check if banner ad can be shown
  bool canShowBanner() {
    final now = DateTime.now();

    // Check time interval
    if (_lastBannerShown != null) {
      final timeSinceLastAd = now.difference(_lastBannerShown!);
      if (timeSinceLastAd.inSeconds < _minBannerInterval) {
        return false;
      }
    }

    return true;
  }

  /// Check if it's a natural time to show interstitial based on user activity
  bool isNaturalInterstitialTime() {
    return _chatTransitions >= _chatTransitionsForAd ||
        _messagesSent >= _messagesForAd ||
        _topicJoins >= _topicJoinsForAd;
  }

  /// Get suggested timing for next interstitial ad
  Duration? getTimeUntilNextInterstitial() {
    if (!canShowInterstitial()) {
      if (_lastInterstitialShown != null) {
        final timeSinceLastAd =
            DateTime.now().difference(_lastInterstitialShown!);
        final remainingTime =
            _minInterstitialInterval - timeSinceLastAd.inSeconds;

        if (remainingTime > 0) {
          return Duration(seconds: remainingTime);
        }
      }
    }
    return null;
  }

  /// Mark interstitial ad as shown
  void markInterstitialShown() {
    _lastInterstitialShown = DateTime.now();
    _interstitialCount++;
    _totalAdsShown++;

    // Reset activity counters after showing ad
    _chatTransitions = 0;
    _messagesSent = 0;
    _topicJoins = 0;

    debugPrint(
        'AdTimingManager: Interstitial shown - Count: $_interstitialCount, Total: $_totalAdsShown');
    notifyListeners();
  }

  /// Mark rewarded ad as shown
  void markRewardedShown() {
    _lastRewardedShown = DateTime.now();
    _rewardedCount++;
    _totalAdsShown++;

    debugPrint(
        'AdTimingManager: Rewarded shown - Count: $_rewardedCount, Total: $_totalAdsShown');
    notifyListeners();
  }

  /// Mark banner ad as shown
  void markBannerShown() {
    _lastBannerShown = DateTime.now();
    debugPrint('AdTimingManager: Banner shown');
    notifyListeners();
  }

  /// Check if app launch interstitial can be shown
  bool canShowAppLaunchInterstitial() {
    // Don't show on first launch
    if (_sessionCount <= 1) return false;

    // Don't show if app was just launched recently
    if (_lastAppLaunch != null) {
      final timeSinceLastLaunch = DateTime.now().difference(_lastAppLaunch!);
      if (timeSinceLastLaunch.inMinutes < 5) return false;
    }

    return canShowInterstitial();
  }

  /// Check if transition interstitial can be shown
  bool canShowTransitionInterstitial() {
    return canShowInterstitial() && isNaturalInterstitialTime();
  }

  /// Get ad placement recommendation
  AdPlacementRecommendation getAdPlacementRecommendation() {
    if (canShowTransitionInterstitial()) {
      return AdPlacementRecommendation.interstitial;
    }

    if (canShowRewarded()) {
      return AdPlacementRecommendation.rewarded;
    }

    if (canShowBanner()) {
      return AdPlacementRecommendation.banner;
    }

    return AdPlacementRecommendation.none;
  }

  /// Get current session statistics
  SessionStats getSessionStats() {
    final sessionDuration = _sessionStart != null
        ? DateTime.now().difference(_sessionStart!)
        : Duration.zero;

    return SessionStats(
      sessionNumber: _sessionCount,
      sessionDuration: sessionDuration,
      interstitialCount: _interstitialCount,
      rewardedCount: _rewardedCount,
      totalAdsShown: _totalAdsShown,
      chatTransitions: _chatTransitions,
      messagesSent: _messagesSent,
      topicJoins: _topicJoins,
      canShowInterstitial: canShowInterstitial(),
      canShowRewarded: canShowRewarded(),
      timeUntilNextInterstitial: getTimeUntilNextInterstitial(),
    );
  }

  /// Reset all timing data (for testing or admin purposes)
  void resetAllData() {
    _sessionStart = null;
    _lastAppLaunch = null;
    _sessionCount = 0;
    _lastInterstitialShown = null;
    _lastRewardedShown = null;
    _lastBannerShown = null;
    _interstitialCount = 0;
    _rewardedCount = 0;
    _totalAdsShown = 0;
    _chatTransitions = 0;
    _messagesSent = 0;
    _topicJoins = 0;
    _lastUserAction = null;

    debugPrint('AdTimingManager: All data reset');
    notifyListeners();
  }

  /// Get debug information
  Map<String, dynamic> getDebugInfo() {
    return {
      'sessionCount': _sessionCount,
      'sessionStart': _sessionStart?.toIso8601String(),
      'lastAppLaunch': _lastAppLaunch?.toIso8601String(),
      'interstitialCount': _interstitialCount,
      'rewardedCount': _rewardedCount,
      'totalAdsShown': _totalAdsShown,
      'chatTransitions': _chatTransitions,
      'messagesSent': _messagesSent,
      'topicJoins': _topicJoins,
      'lastInterstitialShown': _lastInterstitialShown?.toIso8601String(),
      'lastRewardedShown': _lastRewardedShown?.toIso8601String(),
      'lastBannerShown': _lastBannerShown?.toIso8601String(),
      'canShowInterstitial': canShowInterstitial(),
      'canShowRewarded': canShowRewarded(),
      'canShowBanner': canShowBanner(),
      'isNaturalInterstitialTime': isNaturalInterstitialTime(),
    };
  }
}

/// Enum for ad placement recommendations
enum AdPlacementRecommendation {
  interstitial,
  rewarded,
  banner,
  none,
}

/// Session statistics data class
class SessionStats {
  final int sessionNumber;
  final Duration sessionDuration;
  final int interstitialCount;
  final int rewardedCount;
  final int totalAdsShown;
  final int chatTransitions;
  final int messagesSent;
  final int topicJoins;
  final bool canShowInterstitial;
  final bool canShowRewarded;
  final Duration? timeUntilNextInterstitial;

  const SessionStats({
    required this.sessionNumber,
    required this.sessionDuration,
    required this.interstitialCount,
    required this.rewardedCount,
    required this.totalAdsShown,
    required this.chatTransitions,
    required this.messagesSent,
    required this.topicJoins,
    required this.canShowInterstitial,
    required this.canShowRewarded,
    this.timeUntilNextInterstitial,
  });
}
