import 'package:flutter/foundation.dart';

/// Simplified Ad Configuration for increased frequency and better user experience
///
/// This configuration aims to:
/// - Increase ad frequency for better monetization
/// - Simplify complex logic that may prevent ads from showing
/// - Maintain user experience by avoiding spam
/// - Keep compliance for admin users
class SimplifiedAdConfig {
  // === TIMING CONFIGURATION ===

  /// Minimum time between ads (reduced from 2 minutes to 90 seconds)
  static const Duration minTimeBetweenAds = Duration(seconds: 90);

  /// Time to wait before showing first ad in session (reduced from 1 minute to 30 seconds)
  static const Duration minSessionTimeBeforeFirstAd = Duration(seconds: 30);

  /// Maximum time to wait for ad preloading before giving up
  static const Duration maxAdLoadWaitTime = Duration(seconds: 10);

  // === TRANSITION CONFIGURATION ===

  /// Room transitions required before first ad (reduced from 2 to 1)
  static const int transitionsBeforeFirstAd = 1;

  /// Room transitions required between subsequent ads (reduced from 2 to 1)
  static const int transitionsBetweenAds = 1;

  // === SESSION CONFIGURATION ===

  /// Maximum ads per session (increased from 5 to 8)
  /// Set to null to remove session limit entirely
  static const int? maxAdsPerSession = 8;

  /// Time in background before session reset (reduced from 10 to 5 minutes)
  static const Duration backgroundTimeForSessionReset = Duration(minutes: 5);

  /// Minimum time between session resets (reduced from 30 to 15 minutes)
  static const Duration minTimeBetweenSessionResets = Duration(minutes: 15);

  // === NAVIGATION PATTERN CONFIGURATION ===

  /// Maximum consecutive quick navigations before blocking ads (increased from 8 to 12)
  static const int maxConsecutiveQuickNavs = 12;

  /// Time window for navigation compression check (increased from 60 to 90 seconds)
  static const Duration navigationCompressionWindow = Duration(seconds: 90);

  /// Maximum navigations in compression window before blocking (increased from 5 to 8)
  static const int maxNavigationsInWindow = 8;

  /// Maximum inactivity time before considering user inactive (increased from 15 to 20 minutes)
  static const Duration maxInactivityTime = Duration(minutes: 20);

  // === AD LOADING CONFIGURATION ===

  /// Time to wait before preloading first ad after session start
  static const Duration initialAdLoadDelay = Duration(seconds: 20);

  /// Time to wait before retrying failed ad load (reduced from 1 minute to 30 seconds)
  static const Duration adLoadRetryDelay = Duration(seconds: 30);

  /// Time to wait after showing ad before preloading next one
  static const Duration nextAdLoadDelay = Duration(seconds: 45);

  // === FEATURE FLAGS ===

  /// Whether to enforce session ad limits (set to false to remove limits)
  static const bool enforceSessionLimits = true;

  /// Whether to use complex navigation pattern analysis
  static const bool useComplexNavigationAnalysis = false;

  /// Whether to preload ads aggressively
  static const bool aggressivePreloading = true;

  /// Whether to show ads on app resume (if conditions are met)
  static const bool allowAdsOnAppResume = true;

  /// Whether to reset counters more frequently for higher ad frequency
  static const bool useFrequentReset = true;

  // === ENGAGEMENT-BASED CONFIGURATION ===

  /// Whether to reduce ad frequency for new users (first session)
  static const bool reduceFrequencyForNewUsers = false;

  /// Whether to increase frequency for highly engaged users
  static const bool increaseFrequencyForEngagedUsers = true;

  /// Minimum session duration to be considered engaged (reduced from typical values)
  static const Duration engagedUserMinSessionTime = Duration(minutes: 3);

  /// Minimum transitions to be considered engaged (reduced)
  static const int engagedUserMinTransitions = 5;

  // === DEBUGGING AND COMPLIANCE ===

  /// Whether to use verbose logging for ad decisions
  static const bool verboseLogging = kDebugMode;

  /// Whether to always validate compliance before showing ads
  static const bool alwaysValidateCompliance = true;

  /// Whether to show debug information in release builds for admins
  static const bool showDebugForAdmins = true;

  // === HELPER METHODS ===

  /// Get effective max ads per session (null means unlimited)
  static int? getEffectiveMaxAdsPerSession() {
    return enforceSessionLimits ? maxAdsPerSession : null;
  }

  /// Check if session limits should be applied
  static bool shouldEnforceSessionLimits() {
    return enforceSessionLimits && maxAdsPerSession != null;
  }

  /// Get transitions required for next ad based on current session state
  static int getTransitionsForNextAd(int adsShownThisSession) {
    if (adsShownThisSession == 0) {
      return transitionsBeforeFirstAd;
    }
    return transitionsBetweenAds;
  }

  /// Check if navigation analysis should be simplified
  static bool shouldUseSimplifiedNavigation() {
    return !useComplexNavigationAnalysis;
  }

  /// Get configuration summary for debugging
  static Map<String, dynamic> getConfigSummary() {
    return {
      'version': '2.0.0',
      'description': 'Simplified configuration for increased ad frequency',
      'timingConfig': {
        'minTimeBetweenAds': '${minTimeBetweenAds.inSeconds}s',
        'minSessionTimeBeforeFirstAd':
            '${minSessionTimeBeforeFirstAd.inSeconds}s',
        'maxAdLoadWaitTime': '${maxAdLoadWaitTime.inSeconds}s',
      },
      'transitionConfig': {
        'transitionsBeforeFirstAd': transitionsBeforeFirstAd,
        'transitionsBetweenAds': transitionsBetweenAds,
      },
      'sessionConfig': {
        'maxAdsPerSession': maxAdsPerSession,
        'enforceSessionLimits': enforceSessionLimits,
        'backgroundTimeForSessionReset':
            '${backgroundTimeForSessionReset.inMinutes}min',
        'minTimeBetweenSessionResets':
            '${minTimeBetweenSessionResets.inMinutes}min',
      },
      'navigationConfig': {
        'useComplexAnalysis': useComplexNavigationAnalysis,
        'maxConsecutiveQuickNavs': maxConsecutiveQuickNavs,
        'navigationCompressionWindow':
            '${navigationCompressionWindow.inSeconds}s',
        'maxNavigationsInWindow': maxNavigationsInWindow,
        'maxInactivityTime': '${maxInactivityTime.inMinutes}min',
      },
      'loadingConfig': {
        'aggressivePreloading': aggressivePreloading,
        'initialAdLoadDelay': '${initialAdLoadDelay.inSeconds}s',
        'adLoadRetryDelay': '${adLoadRetryDelay.inSeconds}s',
        'nextAdLoadDelay': '${nextAdLoadDelay.inSeconds}s',
      },
      'featureFlags': {
        'allowAdsOnAppResume': allowAdsOnAppResume,
        'useFrequentReset': useFrequentReset,
        'increaseFrequencyForEngagedUsers': increaseFrequencyForEngagedUsers,
        'reduceFrequencyForNewUsers': reduceFrequencyForNewUsers,
      },
      'complianceConfig': {
        'alwaysValidateCompliance': alwaysValidateCompliance,
        'verboseLogging': verboseLogging,
        'showDebugForAdmins': showDebugForAdmins,
      }
    };
  }

  /// Validate configuration values
  static bool validateConfig() {
    // Ensure timing values are reasonable
    if (minTimeBetweenAds.inSeconds < 30) {
      debugPrint(
          'WARNING: minTimeBetweenAds is very short (${minTimeBetweenAds.inSeconds}s)');
    }

    if (maxAdsPerSession != null && maxAdsPerSession! > 15) {
      debugPrint('WARNING: maxAdsPerSession is very high ($maxAdsPerSession)');
    }

    if (transitionsBeforeFirstAd < 1 || transitionsBetweenAds < 1) {
      debugPrint('ERROR: Transition requirements must be at least 1');
      return false;
    }

    return true;
  }

  /// Get user-friendly description of current configuration
  static String getConfigDescription() {
    final maxAds =
        maxAdsPerSession != null ? '$maxAdsPerSession ads' : 'unlimited ads';
    final timeBetween = '${minTimeBetweenAds.inSeconds}s apart';
    final transitions = transitionsBetweenAds == 1
        ? 'every transition'
        : 'every $transitionsBetweenAds transitions';

    return 'Showing up to $maxAds per session, $timeBetween, $transitions after first ad';
  }
}
