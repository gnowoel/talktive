import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'room_transition_ads.dart';
import 'simplified_room_ads.dart';
import 'admob_compliance.dart';
import 'optimized_ad_config.dart';
import 'ad_request_helper.dart';

/// Ad Service Adapter - Compatibility layer for GoRouterRoomHelper
///
/// This adapter provides a unified interface that allows GoRouterRoomHelper
/// to work with both the current RoomTransitionAds and new SimplifiedRoomAds
/// systems. It enables A/B testing and gradual migration.
class AdServiceAdapter {
  static AdServiceAdapter? _instance;
  static AdServiceAdapter get instance => _instance ??= AdServiceAdapter._();

  AdServiceAdapter._();

  // === FEATURE FLAGS ===

  /// Feature flag to control which ad system to use
  /// Set to true to use the new SimplifiedRoomAds system
  /// Set to false to use the current RoomTransitionAds system
  static const bool _useSimplifiedAdSystem = true;

  /// Feature flag for A/B testing (overrides _useSimplifiedAdSystem if not null)
  /// This can be dynamically controlled based on user segments
  static bool? _abTestUseSimplified;

  /// Set A/B test configuration for specific users
  static void setABTestConfiguration(bool useSimplified) {
    _abTestUseSimplified = useSimplified;
    debugPrint(
        'AdServiceAdapter: A/B test set to use ${useSimplified ? 'Optimized' : 'Current'} ad system');
  }

  /// Clear A/B test configuration (falls back to feature flag)
  static void clearABTestConfiguration() {
    _abTestUseSimplified = null;
    debugPrint('AdServiceAdapter: A/B test cleared, using feature flag');
  }

  /// Determine which ad system to use
  bool get _shouldUseSimplifiedSystem {
    return _abTestUseSimplified ?? _useSimplifiedAdSystem;
  }

  /// Get the current ad system name for logging/debugging
  String get currentSystemName {
    return _shouldUseSimplifiedSystem
        ? 'OptimizedRoomAds'
        : 'RoomTransitionAds';
  }

  // === UNIFIED INTERFACE ===

  /// Initialize the appropriate ad system with consent handling
  Future<void> initialize() async {
    debugPrint('AdServiceAdapter: Initializing $currentSystemName with consent handling');
    debugPrint('Configuration: ${OptimizedAdConfig.getConfigDescription()}');

    try {
      // Initialize consent-aware ad system first
      final canShowAds = await AdRequestHelper.instance.handleConsentAndInitialize();
      debugPrint('AdServiceAdapter: Consent initialization completed, can show ads: $canShowAds');

      // Initialize the appropriate ad system
      if (_shouldUseSimplifiedSystem) {
        SimplifiedRoomAds.instance.initialize();
      } else {
        RoomTransitionAds.instance.initialize();
      }

      debugPrint('AdServiceAdapter: $currentSystemName initialized successfully');
    } catch (e) {
      debugPrint('AdServiceAdapter: Failed to initialize with consent: $e');

      // Fallback: Initialize ad system without consent (will handle gracefully)
      if (_shouldUseSimplifiedSystem) {
        SimplifiedRoomAds.instance.initialize();
      } else {
        RoomTransitionAds.instance.initialize();
      }
    }
  }

  /// Track room transition in the appropriate ad system
  void trackRoomTransition() {
    if (_shouldUseSimplifiedSystem) {
      SimplifiedRoomAds.instance.trackRoomTransition();
    } else {
      RoomTransitionAds.instance.trackRoomTransition();
    }
  }

  /// Check if ad should be shown now (with consent validation)
  Future<bool> shouldShowAdNow() async {
    try {
      // First validate consent
      final validation = await AdRequestHelper.instance.validateAdRequest();
      if (!validation.canRequestAds) {
        debugPrint('AdServiceAdapter: Cannot show ad due to consent: ${validation.message}');
        return false;
      }

      // Then check ad system specific logic
      if (_shouldUseSimplifiedSystem) {
        return await SimplifiedRoomAds.instance.shouldShowAdNow();
      } else {
        return await RoomTransitionAds.instance.shouldShowAdNow();
      }
    } catch (e) {
      debugPrint('AdServiceAdapter: Error checking if should show ad: $e');
      return false;
    }
  }

  /// Show ad if appropriate (with consent validation)
  Future<bool> showAdIfAppropriate() async {
    try {
      // Validate consent before attempting to show ad
      final validation = await AdRequestHelper.instance.validateAdRequest();
      if (!validation.canRequestAds) {
        debugPrint('AdServiceAdapter: Cannot show ad due to consent: ${validation.message}');
        return false;
      }

      // Show ad using appropriate system
      if (_shouldUseSimplifiedSystem) {
        return await SimplifiedRoomAds.instance.showAdIfAppropriate();
      } else {
        return await RoomTransitionAds.instance.showAdIfAppropriate();
      }
    } catch (e) {
      debugPrint('AdServiceAdapter: Error showing ad: $e');
      return false;
    }
  }

  /// Check if ad is ready
  bool get isAdReady {
    if (_shouldUseSimplifiedSystem) {
      return SimplifiedRoomAds.instance.isAdReady;
    } else {
      return RoomTransitionAds.instance.isAdReady;
    }
  }

  /// Get room transitions count
  int get roomTransitions {
    if (_shouldUseSimplifiedSystem) {
      return SimplifiedRoomAds.instance.roomTransitions;
    } else {
      return RoomTransitionAds.instance.roomTransitions;
    }
  }

  /// Get ads shown this session
  int get adsShownThisSession {
    if (_shouldUseSimplifiedSystem) {
      return SimplifiedRoomAds.instance.adsShownThisSession;
    } else {
      return RoomTransitionAds.instance.adsShownThisSession;
    }
  }

  /// Reset session
  void resetSession() {
    if (_shouldUseSimplifiedSystem) {
      SimplifiedRoomAds.instance.resetSession();
    } else {
      RoomTransitionAds.instance.resetSession();
    }
  }

  /// Force show ad for testing
  Future<bool> forceShowAdForTesting() async {
    if (_shouldUseSimplifiedSystem) {
      return await SimplifiedRoomAds.instance.forceShowAd();
    } else {
      return await RoomTransitionAds.instance.forceShowAd();
    }
  }

  /// Get session statistics
  Future<Map<String, dynamic>> getSessionStats() async {
    Map<String, dynamic> baseStats;

    if (_shouldUseSimplifiedSystem) {
      baseStats = await SimplifiedRoomAds.instance.getSessionStats();
    } else {
      baseStats = await RoomTransitionAds.instance.getSessionStats();
    }

    // Add adapter-specific and consent information
    Map<String, dynamic> consentInfo = {};
    try {
      final validation = await AdRequestHelper.instance.validateAdRequest();
      consentInfo = {
        'canRequestAds': validation.canRequestAds,
        'recommendedAdType': validation.recommendedAdType.name,
        'consentStatus': validation.consentStatus.toString(),
        'consentMessage': validation.message,
      };
    } catch (e) {
      consentInfo = {'consentError': 'Failed to get consent info: $e'};
    }

    return {
      ...baseStats,
      'adSystemUsed': currentSystemName,
      'isABTest': _abTestUseSimplified != null,
      'adapterVersion': '1.0.0',
      'consentInfo': consentInfo,
    };
  }

  /// Get compliance status
  Future<Map<String, dynamic>> getComplianceStatus() async {
    if (_shouldUseSimplifiedSystem) {
      return await SimplifiedRoomAds.instance.getComplianceStatus();
    } else {
      return await RoomTransitionAds.instance.getComplianceStatus();
    }
  }

  /// Get timing message for debugging
  String getTimingMessage() {
    if (_shouldUseSimplifiedSystem) {
      return SimplifiedRoomAds.instance.getTimingInfo();
    } else {
      return RoomTransitionAds.instance.getTimingMessage();
    }
  }

  /// Get status message
  Future<String> getStatusMessage() async {
    if (_shouldUseSimplifiedSystem) {
      return SimplifiedRoomAds.instance.getStatusMessage();
    } else {
      // RoomTransitionAds doesn't have getStatusMessage, so create one
      if (!isAdReady) {
        return 'Ad not ready';
      }
      if (await shouldShowAdNow()) {
        return 'Ready to show ad';
      }
      return 'Ad ready, waiting for conditions';
    }
  }

  /// Get comprehensive debug info
  Future<Map<String, dynamic>> getComprehensiveDebugInfo() async {
    Map<String, dynamic> debugInfo;

    if (_shouldUseSimplifiedSystem) {
      debugInfo = {
        'sessionStats': await SimplifiedRoomAds.instance.getSessionStats(),
        'complianceStatus':
            await SimplifiedRoomAds.instance.getComplianceStatus(),
        'statusMessage': SimplifiedRoomAds.instance.getStatusMessage(),
        'timingInfo': SimplifiedRoomAds.instance.getTimingInfo(),
      };
    } else {
      debugInfo = await RoomTransitionAds.instance.getComprehensiveDebugInfo();
    }

    // Add adapter-specific debug info
    debugInfo['adapter'] = {
      'currentSystem': currentSystemName,
      'featureFlagValue': _useSimplifiedAdSystem,
      'abTestValue': _abTestUseSimplified,
      'effectiveValue': _shouldUseSimplifiedSystem,
    };

    return debugInfo;
  }

  // === NAVIGATION SPECIFIC METHODS ===

  /// Check if ads can be shown for navigation
  Future<bool> canShowAdsForNavigation() async {
    // This method exists in both systems through their respective logic
    return await shouldShowAdNow() && isAdReady;
  }

  /// Get navigation compliance message
  String getNavigationComplianceMessage() {
    return AdMobCompliance.getUserFriendlyMessage();
  }

  /// Get navigation compliance status
  Future<Map<String, dynamic>> getNavigationComplianceStatus() async {
    return await AdMobCompliance.getComplianceStatus();
  }

  /// Get compliance message for display
  String getComplianceMessage() {
    if (_shouldUseSimplifiedSystem) {
      return AdMobCompliance.getUserFriendlyMessage();
    } else {
      return RoomTransitionAds.instance.getComplianceMessage();
    }
  }

  /// Validate compliance before navigation
  Future<bool> validateCompliance() async {
    return await AdMobCompliance.validateAdCompliance();
  }

  // === HIGH-LEVEL NAVIGATION METHODS ===

  /// Navigate with ad consideration
  Future<void> navigateWithAdConsideration(
    BuildContext context,
    String route, {
    bool isPush = false,
    Object? extra,
    Map<String, String>? pathParameters,
    Map<String, dynamic>? queryParameters,
  }) async {
    // Track the navigation
    trackRoomTransition();

    // Try to show ad if appropriate
    bool adShown = false;
    if (await shouldShowAdNow() && isAdReady) {
      try {
        adShown = await showAdIfAppropriate();
        if (adShown) {
          debugPrint('AdServiceAdapter: Ad shown before navigation to $route');
        }
      } catch (e) {
        debugPrint('AdServiceAdapter: Error showing ad: $e');
      }
    }

    // Perform navigation
    if (isPush) {
      if (extra != null) {
        context.push(route, extra: extra);
      } else {
        context.pushNamed(
          route,
          pathParameters: pathParameters ?? {},
          queryParameters: queryParameters ?? {},
        );
      }
    } else {
      if (extra != null) {
        context.go(route, extra: extra);
      } else {
        context.goNamed(
          route,
          pathParameters: pathParameters ?? {},
          queryParameters: queryParameters ?? {},
        );
      }
    }

    // Log navigation completion
    debugPrint(
        'AdServiceAdapter: Navigation to $route completed (ad shown: $adShown)');
  }

  /// Navigate without attempting to show ads
  void navigateWithoutAd(
    BuildContext context,
    String route, {
    bool isPush = false,
    Object? extra,
    Map<String, String>? pathParameters,
    Map<String, dynamic>? queryParameters,
  }) {
    // Still track transition for future ad timing
    trackRoomTransition();

    // Perform navigation without ad
    if (isPush) {
      if (extra != null) {
        context.push(route, extra: extra);
      } else {
        context.pushNamed(
          route,
          pathParameters: pathParameters ?? {},
          queryParameters: queryParameters ?? {},
        );
      }
    } else {
      if (extra != null) {
        context.go(route, extra: extra);
      } else {
        context.goNamed(
          route,
          pathParameters: pathParameters ?? {},
          queryParameters: queryParameters ?? {},
        );
      }
    }

    debugPrint(
        'AdServiceAdapter: Navigation to $route completed (no ad attempted)');
  }

  // === COMPARISON AND TESTING METHODS ===

  /// Compare decision between both ad systems (for A/B testing insights)
  Future<Map<String, dynamic>> compareAdDecisions() async {
    final currentDecision = await RoomTransitionAds.instance.shouldShowAdNow();
    final simplifiedDecision =
        await SimplifiedRoomAds.instance.shouldShowAdNow();

    return {
      'currentSystemDecision': currentDecision,
      'simplifiedSystemDecision': simplifiedDecision,
      'decisionsMatch': currentDecision == simplifiedDecision,
      'currentSystemReady': RoomTransitionAds.instance.isAdReady,
      'simplifiedSystemReady': SimplifiedRoomAds.instance.isAdReady,
      'currentSystemStats': await RoomTransitionAds.instance.getSessionStats(),
      'simplifiedSystemStats':
          await SimplifiedRoomAds.instance.getSessionStats(),
    };
  }

  /// Get metrics for A/B testing analysis
  Future<Map<String, dynamic>> getABTestMetrics() async {
    return {
      'systemUsed': currentSystemName,
      'isABTest': _abTestUseSimplified != null,
      'sessionStats': await getSessionStats(),
      'complianceStatus': await getComplianceStatus(),
      'adReadyState': isAdReady,
      'canShowAd': await shouldShowAdNow(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Force preload ad (if supported by the active system)
  Future<void> preloadAd() async {
    if (_shouldUseSimplifiedSystem) {
      await SimplifiedRoomAds.instance.forceLoadAd();
    } else {
      // RoomTransitionAds preloads automatically, but we can trigger it
      await RoomTransitionAds.instance.forceLoadAd();
    }
  }

  /// Dispose resources
  void dispose() {
    if (_shouldUseSimplifiedSystem) {
      SimplifiedRoomAds.instance.dispose();
    } else {
      RoomTransitionAds.instance.dispose();
    }
  }

  // === UTILITY METHODS ===

  /// Get system configuration summary
  Map<String, dynamic> getSystemConfiguration() {
    if (_shouldUseSimplifiedSystem) {
      return {
        'system': 'OptimizedRoomAds',
        'configuration': OptimizedAdConfig.getConfigSummary(),
      };
    } else {
      return {
        'system': 'RoomTransitionAds',
        'configuration': {
          'description': 'Legacy room transition ads system',
          'hardcodedConfiguration': true,
        },
      };
    }
  }

  /// Log system switch for debugging
  Future<void> logSystemInfo() async {
    debugPrint('=== AdServiceAdapter System Info ===');
    debugPrint('Current System: $currentSystemName');
    debugPrint('Feature Flag: $_useSimplifiedAdSystem');
    debugPrint('A/B Test Override: $_abTestUseSimplified');
    debugPrint('Effective Choice: $_shouldUseSimplifiedSystem');
    debugPrint('Session Stats: ${await getSessionStats()}');
    if (_shouldUseSimplifiedSystem) {
      debugPrint(
          'Optimized Config: ${OptimizedAdConfig.getConfigDescription()}');
    }
    debugPrint('=====================================');
  }

  /// Enable optimized ad system for this user
  static void enableOptimizedSystem() {
    setABTestConfiguration(true);
    debugPrint('AdServiceAdapter: Optimized ad system enabled');
  }

  /// Disable optimized ad system (fallback to current)
  static void disableOptimizedSystem() {
    setABTestConfiguration(false);
    debugPrint('AdServiceAdapter: Reverted to current ad system');
  }

  /// Get current configuration details
  Map<String, dynamic> getCurrentConfiguration() {
    if (_shouldUseSimplifiedSystem) {
      return {
        'system': 'OptimizedRoomAds',
        'unlimited_sessions': !OptimizedAdConfig.enforceSessionLimits,
        'progressive_timing': OptimizedAdConfig.useProgressiveTiming,
        'engagement_aware': true,
        'configuration': OptimizedAdConfig.getConfigSummary(),
      };
    } else {
      return {
        'system': 'RoomTransitionAds',
        'session_limited': true,
        'progressive_timing': false,
        'engagement_aware': false,
        'configuration': 'Legacy hardcoded configuration',
      };
    }
  }

  /// Get migration status and recommendations
  Future<Map<String, dynamic>> getMigrationStatus() async {
    final currentConfig = getCurrentConfiguration();
    final stats = await getSessionStats();

    return {
      'migration_complete': _shouldUseSimplifiedSystem,
      'system_in_use': currentSystemName,
      'unlimited_revenue': currentConfig['unlimited_sessions'] ?? false,
      'engagement_optimization': currentConfig['engagement_aware'] ?? false,
      'current_session_performance': {
        'ads_shown': stats['adsShownThisSession'],
        'transitions': stats['roomTransitions'],
        'session_duration_minutes': stats['sessionDurationMinutes'],
        'engagement_level': stats['userEngagementLevel'] ?? 'unknown',
      },
      'recommendations': await _getMigrationRecommendations(),
    };
  }

  Future<List<String>> _getMigrationRecommendations() async {
    List<String> recommendations = [];

    if (!_shouldUseSimplifiedSystem) {
      recommendations
          .add('Enable optimized ad system to increase revenue potential');
      recommendations.add(
          'Remove session limits for unlimited revenue from engaged users');
      recommendations
          .add('Use engagement-based timing for better user experience');
    } else {
      final stats = await getSessionStats();
      final sessionMinutes = stats['sessionDurationMinutes'] as int;
      final adsShown = stats['adsShownThisSession'] as int;

      if (sessionMinutes > 15 && adsShown > 0) {
        recommendations
            .add('User is highly engaged - unlimited revenue potential active');
      }

      if (sessionMinutes > 5) {
        recommendations
            .add('User reached engaged status - faster ad timing active');
      }

      recommendations
          .add('Optimized system active - monitor user experience metrics');
    }

    return recommendations;
  }
}
