import 'package:flutter/foundation.dart';

/// Optimized Ad Configuration for Maximum Revenue with Excellent UX
///
/// This configuration removes session limits while maintaining excellent user
/// experience through intelligent timing and preloading strategies.
///
/// Key Design Principles:
/// - No session limits (unlimited revenue potential)
/// - Low request-to-impression ratio through smart preloading
/// - User-first timing to avoid annoyance
/// - Engagement-aware frequency adjustment
class OptimizedAdConfig {
  // === SESSION CONFIGURATION ===

  /// Maximum ads per session - SET TO NULL for unlimited ads
  /// This removes artificial revenue caps for engaged users
  static const int? maxAdsPerSession = null;

  /// Whether to enforce any session limits (disabled for maximum revenue)
  static const bool enforceSessionLimits = false;

  // === USER EXPERIENCE TIMING ===

  /// Minimum time between ads - optimized for UX while maximizing frequency
  /// 2 minutes provides good balance between revenue and user experience
  static const Duration minTimeBetweenAds = Duration(minutes: 2);

  /// Time before showing first ad - allows user to get engaged first
  /// 45 seconds ensures user is committed to the session
  static const Duration minSessionTimeBeforeFirstAd = Duration(seconds: 45);

  /// Minimum session duration before considering user "engaged"
  /// After 5 minutes, user is clearly engaged and can handle more frequent ads
  static const Duration engagedUserSessionThreshold = Duration(minutes: 5);

  /// Reduced time between ads for highly engaged users (after 5+ minutes)
  /// 90 seconds for engaged users who are clearly enjoying the app
  static const Duration minTimeBetweenAdsEngaged = Duration(seconds: 90);

  // === TRANSITION REQUIREMENTS ===

  /// Transitions required before first ad - ensures user is navigating actively
  static const int transitionsBeforeFirstAd = 2;

  /// Transitions required between subsequent ads - balanced for frequency
  static const int transitionsBetweenAds = 2;

  /// Increased transitions required for very frequent users (spam protection)
  static const int transitionsForRapidUsers = 3;

  // === INTELLIGENT PRELOADING (LOW REQUEST-TO-IMPRESSION RATIO) ===

  /// Delay before preloading first ad - ensures we don't waste requests
  static const Duration initialAdLoadDelay = Duration(seconds: 30);

  /// Delay before preloading next ad after showing one
  /// Immediate preloading ensures we're always ready
  static const Duration nextAdLoadDelay = Duration(seconds: 5);

  /// Maximum time to wait for ad to load before considering it failed
  static const Duration maxAdLoadWaitTime = Duration(seconds: 15);

  /// Delay before retrying failed ad load - prevents rapid retry spam
  static const Duration adLoadRetryDelay = Duration(minutes: 1);

  /// Only preload ads when we're likely to show them soon
  static const bool intelligentPreloadingOnly = true;

  /// Don't preload if user hasn't been active recently
  static const Duration maxInactivityForPreload = Duration(minutes: 3);

  // === USER BEHAVIOR ANALYSIS ===

  /// Maximum consecutive quick navigations before increasing requirements
  /// Protects against users rapidly clicking through content
  static const int maxConsecutiveQuickNavs = 6;

  /// Time window considered "quick navigation" (10 seconds)
  static const Duration quickNavigationWindow = Duration(seconds: 10);

  /// Inactivity time before considering user disengaged
  /// Don't show ads to users who aren't actively using the app
  static const Duration maxInactivityTime = Duration(minutes: 10);

  /// Time window for analyzing navigation patterns
  static const Duration navigationAnalysisWindow = Duration(minutes: 5);

  /// Minimum navigations in analysis window to be considered active
  static const int minNavigationsForActive = 3;

  // === BACKGROUND/FOREGROUND BEHAVIOR ===

  /// Time in background before considering session pause
  static const Duration backgroundTimeForPause = Duration(minutes: 2);

  /// Time in background before doing soft session reset (not full reset)
  static const Duration backgroundTimeForSoftReset = Duration(minutes: 10);

  /// Don't show ads immediately when app resumes (give user time to orient)
  static const Duration noAdsAfterResumeDelay = Duration(seconds: 15);

  // === PROGRESSIVE TIMING SYSTEM ===

  /// Use progressive timing - ads become more frequent as user shows engagement
  static const bool useProgressiveTiming = true;

  /// Engagement levels and their corresponding timing
  static const Map<String, Duration> engagementBasedTiming = {
    'new': Duration(minutes: 3), // First 5 minutes - slower pace
    'engaged': Duration(minutes: 2), // 5-15 minutes - standard pace
    'highly_engaged': Duration(seconds: 90), // 15+ minutes - faster pace
  };

  /// Engagement thresholds (session duration in minutes)
  static const Map<String, int> engagementThresholds = {
    'new': 0, // 0-5 minutes
    'engaged': 5, // 5-15 minutes
    'highly_engaged': 15, // 15+ minutes
  };

  // === QUALITY ASSURANCE ===

  /// Enable comprehensive logging for optimization
  static const bool verboseLogging = kDebugMode;

  /// Always validate compliance before showing ads
  static const bool alwaysValidateCompliance = true;

  /// Log detailed timing decisions for analysis
  static const bool logTimingDecisions = kDebugMode;

  /// Track user experience metrics
  static const bool trackUserExperienceMetrics = true;

  // === HELPER METHODS ===

  /// Get timing based on user engagement level
  static Duration getTimingForEngagement(Duration sessionDuration) {
    if (!useProgressiveTiming) {
      return minTimeBetweenAds;
    }

    final sessionMinutes = sessionDuration.inMinutes;

    if (sessionMinutes >= engagementThresholds['highly_engaged']!) {
      return engagementBasedTiming['highly_engaged']!;
    } else if (sessionMinutes >= engagementThresholds['engaged']!) {
      return engagementBasedTiming['engaged']!;
    } else {
      return engagementBasedTiming['new']!;
    }
  }

  /// Get transitions required based on user behavior
  static int getTransitionsRequired(int consecutiveQuickNavs, bool isFirstAd) {
    if (isFirstAd) {
      return transitionsBeforeFirstAd;
    }

    // Increase requirements for rapid navigation users
    if (consecutiveQuickNavs > maxConsecutiveQuickNavs) {
      return transitionsForRapidUsers;
    }

    return transitionsBetweenAds;
  }

  /// Check if user should be considered active based on recent behavior
  static bool isUserActive(DateTime? lastNavigation, int recentNavigations) {
    if (lastNavigation == null) return false;

    final timeSinceLastNav = DateTime.now().difference(lastNavigation);
    if (timeSinceLastNav > maxInactivityTime) {
      return false;
    }

    // User is active if they've navigated recently and frequently enough
    return recentNavigations >= minNavigationsForActive;
  }

  /// Should we preload ad based on current state?
  static bool shouldPreloadAd({
    required bool isAdReady,
    required bool isLoading,
    required DateTime? lastNavigation,
    required int recentNavigations,
    required Duration sessionDuration,
  }) {
    // Don't preload if already ready or loading
    if (isAdReady || isLoading) return false;

    // Only preload for active users (saves requests)
    if (!isUserActive(lastNavigation, recentNavigations)) return false;

    // Don't preload too early in session
    if (sessionDuration < initialAdLoadDelay) return false;

    return true;
  }

  /// Get user engagement level
  static String getUserEngagementLevel(Duration sessionDuration) {
    final sessionMinutes = sessionDuration.inMinutes;

    if (sessionMinutes >= engagementThresholds['highly_engaged']!) {
      return 'highly_engaged';
    } else if (sessionMinutes >= engagementThresholds['engaged']!) {
      return 'engaged';
    } else {
      return 'new';
    }
  }

  /// Get configuration summary for debugging
  static Map<String, dynamic> getConfigSummary() {
    return {
      'version': '1.0.0-optimized',
      'description': 'Optimized for unlimited revenue with excellent UX',
      'sessionLimits': {
        'maxAdsPerSession': maxAdsPerSession?.toString() ?? 'UNLIMITED',
        'enforceSessionLimits': enforceSessionLimits,
      },
      'timing': {
        'minTimeBetweenAds': '${minTimeBetweenAds.inSeconds}s',
        'minTimeBetweenAdsEngaged': '${minTimeBetweenAdsEngaged.inSeconds}s',
        'minSessionTimeBeforeFirstAd':
            '${minSessionTimeBeforeFirstAd.inSeconds}s',
        'useProgressiveTiming': useProgressiveTiming,
      },
      'transitions': {
        'transitionsBeforeFirstAd': transitionsBeforeFirstAd,
        'transitionsBetweenAds': transitionsBetweenAds,
        'transitionsForRapidUsers': transitionsForRapidUsers,
      },
      'preloading': {
        'intelligentPreloadingOnly': intelligentPreloadingOnly,
        'initialAdLoadDelay': '${initialAdLoadDelay.inSeconds}s',
        'nextAdLoadDelay': '${nextAdLoadDelay.inSeconds}s',
        'maxInactivityForPreload': '${maxInactivityForPreload.inMinutes}min',
      },
      'userExperience': {
        'maxConsecutiveQuickNavs': maxConsecutiveQuickNavs,
        'maxInactivityTime': '${maxInactivityTime.inMinutes}min',
        'noAdsAfterResumeDelay': '${noAdsAfterResumeDelay.inSeconds}s',
      },
      'engagementLevels': engagementThresholds,
      'engagementTiming': engagementBasedTiming
          .map((key, value) => MapEntry(key, '${value.inSeconds}s')),
    };
  }

  /// Validate configuration
  static bool validateConfig() {
    // Ensure timing values are reasonable
    if (minTimeBetweenAds.inSeconds < 60) {
      debugPrint(
          'WARNING: minTimeBetweenAds is very short (${minTimeBetweenAds.inSeconds}s)');
      debugPrint('This may annoy users and reduce ad effectiveness');
    }

    if (minTimeBetweenAdsEngaged.inSeconds < 60) {
      debugPrint(
          'WARNING: minTimeBetweenAdsEngaged is very short (${minTimeBetweenAdsEngaged.inSeconds}s)');
    }

    // Ensure transitions are reasonable
    if (transitionsBeforeFirstAd < 1 || transitionsBetweenAds < 1) {
      debugPrint('ERROR: Transition requirements must be at least 1');
      return false;
    }

    // Validate engagement thresholds
    if (engagementThresholds['engaged']! >=
        engagementThresholds['highly_engaged']!) {
      debugPrint('ERROR: Engagement thresholds must be progressive');
      return false;
    }

    debugPrint('✅ OptimizedAdConfig validation passed');
    return true;
  }

  /// Get user-friendly configuration description
  static String getConfigDescription() {
    final unlimited = maxAdsPerSession == null
        ? 'unlimited ads'
        : '$maxAdsPerSession ads max';
    final baseTime = '${minTimeBetweenAds.inMinutes}min intervals';
    final engagedTime =
        '${minTimeBetweenAdsEngaged.inSeconds}s for engaged users';

    return 'Optimized: $unlimited, $baseTime ($engagedTime), progressive timing enabled';
  }
}
