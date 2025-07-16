import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'room_transition_ads.dart';
import 'simplified_room_ads.dart';
import 'admob_compliance.dart';

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
  static const bool _useSimplifiedAdSystem = false;

  /// Feature flag for A/B testing (overrides _useSimplifiedAdSystem if not null)
  /// This can be dynamically controlled based on user segments
  static bool? _abTestUseSimplified;

  /// Set A/B test configuration for specific users
  static void setABTestConfiguration(bool useSimplified) {
    _abTestUseSimplified = useSimplified;
    debugPrint(
        'AdServiceAdapter: A/B test set to use ${useSimplified ? 'Simplified' : 'Current'} ad system');
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
        ? 'SimplifiedRoomAds'
        : 'RoomTransitionAds';
  }

  // === UNIFIED INTERFACE ===

  /// Initialize the appropriate ad system
  void initialize() {
    debugPrint('AdServiceAdapter: Initializing $currentSystemName');

    if (_shouldUseSimplifiedSystem) {
      SimplifiedRoomAds.instance.initialize();
    } else {
      RoomTransitionAds.instance.initialize();
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

  /// Check if ad should be shown now
  bool shouldShowAdNow() {
    if (_shouldUseSimplifiedSystem) {
      return SimplifiedRoomAds.instance.shouldShowAdNow();
    } else {
      return RoomTransitionAds.instance.shouldShowAdNow();
    }
  }

  /// Show ad if appropriate
  Future<bool> showAdIfAppropriate() async {
    if (_shouldUseSimplifiedSystem) {
      return await SimplifiedRoomAds.instance.showAdIfAppropriate();
    } else {
      return await RoomTransitionAds.instance.showAdIfAppropriate();
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
  Map<String, dynamic> getSessionStats() {
    Map<String, dynamic> baseStats;

    if (_shouldUseSimplifiedSystem) {
      baseStats = SimplifiedRoomAds.instance.getSessionStats();
    } else {
      baseStats = RoomTransitionAds.instance.getSessionStats();
    }

    // Add adapter-specific information
    return {
      ...baseStats,
      'adSystemUsed': currentSystemName,
      'isABTest': _abTestUseSimplified != null,
      'adapterVersion': '1.0.0',
    };
  }

  /// Get compliance status
  Map<String, dynamic> getComplianceStatus() {
    if (_shouldUseSimplifiedSystem) {
      return SimplifiedRoomAds.instance.getComplianceStatus();
    } else {
      return RoomTransitionAds.instance.getComplianceStatus();
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
  String getStatusMessage() {
    if (_shouldUseSimplifiedSystem) {
      return SimplifiedRoomAds.instance.getStatusMessage();
    } else {
      // RoomTransitionAds doesn't have getStatusMessage, so create one
      if (!isAdReady) {
        return 'Ad not ready';
      }
      if (shouldShowAdNow()) {
        return 'Ready to show ad';
      }
      return 'Ad ready, waiting for conditions';
    }
  }

  /// Get comprehensive debug info
  Map<String, dynamic> getComprehensiveDebugInfo() {
    Map<String, dynamic> debugInfo;

    if (_shouldUseSimplifiedSystem) {
      debugInfo = {
        'sessionStats': SimplifiedRoomAds.instance.getSessionStats(),
        'complianceStatus': SimplifiedRoomAds.instance.getComplianceStatus(),
        'statusMessage': SimplifiedRoomAds.instance.getStatusMessage(),
        'timingInfo': SimplifiedRoomAds.instance.getTimingInfo(),
      };
    } else {
      debugInfo = RoomTransitionAds.instance.getComprehensiveDebugInfo();
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
  bool canShowAdsForNavigation() {
    // This method exists in both systems through their respective logic
    return shouldShowAdNow() && isAdReady;
  }

  /// Get navigation compliance message
  String getNavigationComplianceMessage() {
    return AdMobCompliance.getUserFriendlyMessage();
  }

  /// Get navigation compliance status
  Map<String, dynamic> getNavigationComplianceStatus() {
    return AdMobCompliance.getComplianceStatus();
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
  bool validateCompliance() {
    return AdMobCompliance.validateAdCompliance();
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
    if (shouldShowAdNow() && isAdReady) {
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
  Map<String, dynamic> compareAdDecisions() {
    final currentDecision = RoomTransitionAds.instance.shouldShowAdNow();
    final simplifiedDecision = SimplifiedRoomAds.instance.shouldShowAdNow();

    return {
      'currentSystemDecision': currentDecision,
      'simplifiedSystemDecision': simplifiedDecision,
      'decisionsMatch': currentDecision == simplifiedDecision,
      'currentSystemReady': RoomTransitionAds.instance.isAdReady,
      'simplifiedSystemReady': SimplifiedRoomAds.instance.isAdReady,
      'currentSystemStats': RoomTransitionAds.instance.getSessionStats(),
      'simplifiedSystemStats': SimplifiedRoomAds.instance.getSessionStats(),
    };
  }

  /// Get metrics for A/B testing analysis
  Map<String, dynamic> getABTestMetrics() {
    return {
      'systemUsed': currentSystemName,
      'isABTest': _abTestUseSimplified != null,
      'sessionStats': getSessionStats(),
      'complianceStatus': getComplianceStatus(),
      'adReadyState': isAdReady,
      'canShowAd': shouldShowAdNow(),
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
        'system': 'SimplifiedRoomAds',
        'configuration':
            SimplifiedRoomAds.instance.getSessionStats()['configuration'],
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
  void logSystemInfo() {
    debugPrint('=== AdServiceAdapter System Info ===');
    debugPrint('Current System: $currentSystemName');
    debugPrint('Feature Flag: $_useSimplifiedAdSystem');
    debugPrint('A/B Test Override: $_abTestUseSimplified');
    debugPrint('Effective Choice: $_shouldUseSimplifiedSystem');
    debugPrint('Session Stats: ${getSessionStats()}');
    debugPrint('=====================================');
  }
}
