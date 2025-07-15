import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'room_transition_ads.dart';
import 'admob_compliance.dart';
import '../../helpers/routes.dart';

/// GoRouter-compatible helper for room navigation with respectful interstitial ads
///
/// Usage:
/// ```dart
/// // Navigate to chat
/// await GoRouterRoomHelper.goToChat(context, chatId);
///
/// // Navigate to topic
/// await GoRouterRoomHelper.goToTopic(context, topicId);
/// ```
class GoRouterRoomHelper {
  static final RoomTransitionAds _adManager = RoomTransitionAds.instance;

  /// Navigate to a chat room with potential ad display
  /// Uses context.go() for tab-level navigation
  static Future<void> goToChat(
      BuildContext context, String chatId, String chatCreatedAt) async {
    await _navigateToRoom(
      context: context,
      destination: encodeChatRoute(chatId, chatCreatedAt),
      navigationMethod: _NavigationMethod.go,
    );
  }

  /// Navigate to a topic room with potential ad display
  /// Uses context.go() for tab-level navigation
  static Future<void> goToTopic(
      BuildContext context, String topicId, String topicCreatorId) async {
    await _navigateToRoom(
      context: context,
      destination: encodeTopicRoute(topicId, topicCreatorId),
      navigationMethod: _NavigationMethod.go,
    );
  }

  /// Push to a chat room with potential ad display
  /// Uses context.push() for modal/overlay navigation
  static Future<T?> pushToChat<T>(
      BuildContext context, String chatId, String chatCreatedAt) async {
    return await _navigateToRoom<T>(
      context: context,
      destination: encodeChatRoute(chatId, chatCreatedAt),
      navigationMethod: _NavigationMethod.push,
    );
  }

  /// Push to a topic room with potential ad display
  /// Uses context.push() for modal/overlay navigation
  static Future<T?> pushToTopic<T>(
      BuildContext context, String topicId, String topicCreatorId) async {
    return await _navigateToRoom<T>(
      context: context,
      destination: encodeTopicRoute(topicId, topicCreatorId),
      navigationMethod: _NavigationMethod.push,
    );
  }

  /// Core navigation logic with ad timing and compliance validation
  static Future<T?> _navigateToRoom<T>({
    required BuildContext context,
    required String destination,
    required _NavigationMethod navigationMethod,
  }) async {
    // Track the room transition
    _adManager.trackRoomTransition();

    AdMobCompliance.safeLog(
        'Room transition tracked. Destination: $destination');

    // Validate compliance before attempting to show ads
    final isCompliant = _adManager.validateAndLogCompliance();
    if (!isCompliant) {
      AdMobCompliance.safeLog(
          'Compliance validation failed - skipping ad display',
          forceLog: true);
      // Continue with navigation without ads
      if (!context.mounted) return null;

      try {
        switch (navigationMethod) {
          case _NavigationMethod.go:
            context.go(destination);
            return null;
          case _NavigationMethod.push:
            return await context.push<T>(destination);
        }
      } catch (e) {
        AdMobCompliance.safeLog('Navigation error to $destination: $e',
            forceLog: true);
        return null;
      }
    }

    // Show ad if timing is appropriate and compliance is validated
    final adShown = await _adManager.showAdIfAppropriate();

    if (adShown) {
      AdMobCompliance.safeLog(
          'Showed interstitial ad before navigation to $destination');
    } else {
      AdMobCompliance.safeLog('No ad shown. ${_adManager.getTimingMessage()}');
    }

    // Ensure context is still valid after potential ad display
    if (!context.mounted) {
      debugPrint(
          'GoRouterRoomHelper: Context no longer mounted after potential ad display');
      return null;
    }

    // Perform the navigation based on method
    T? result;
    try {
      switch (navigationMethod) {
        case _NavigationMethod.go:
          context.go(destination);
          result = null;
          break;
        case _NavigationMethod.push:
          result = await context.push<T>(destination);
          break;
      }
    } catch (e) {
      debugPrint('GoRouterRoomHelper: Navigation error to $destination: $e');
      return null;
    }

    // Intelligently preload next ad after successful navigation
    _scheduleIntelligentAdPreload(adShown);

    return result;
  }

  /// Navigate without ads (for non-room destinations like settings, profile, etc.)
  static void goWithoutAd(BuildContext context, String destination) {
    if (context.mounted) {
      context.go(destination);
    }
  }

  /// Push without ads (for non-room destinations)
  static Future<T?> pushWithoutAd<T>(
      BuildContext context, String destination) async {
    if (context.mounted) {
      return await context.push<T>(destination);
    }
    return null;
  }

  /// Get current session statistics for debugging
  static Map<String, dynamic> getSessionStats() {
    return _adManager.getSessionStats();
  }

  /// Get user-friendly timing message for debugging
  static String getTimingMessage() {
    return _adManager.getTimingMessage();
  }

  /// Check if an ad would show on the next room transition (for debugging)
  static bool wouldShowAdOnNextTransition() {
    return _adManager.shouldShowAdNow();
  }

  /// Reset the session (useful for testing or when app returns from background)
  static void resetSession() {
    _adManager.resetSession();
  }

  /// Get compliance status for room transition ads
  static Map<String, dynamic> getComplianceStatus() {
    return _adManager.getComplianceStatus();
  }

  /// Get comprehensive debug information including compliance
  static Map<String, dynamic> getComprehensiveDebugInfo() {
    return _adManager.getComprehensiveDebugInfo();
  }

  /// Get compliance message for room transition ads
  static String getComplianceMessage() {
    return _adManager.getComplianceMessage();
  }

  /// Validate compliance for room transition ads
  static bool validateCompliance() {
    return _adManager.validateAndLogCompliance();
  }

  /// Get detailed ad timing information for debugging
  static Map<String, dynamic> getDetailedTimingInfo() {
    final stats = _adManager.getSessionStats();
    return {
      'currentTime': DateTime.now().toIso8601String(),
      'sessionStats': stats,
      'adReady': _adManager.isAdReady,
      'shouldShowNow': _adManager.shouldShowAdNow(),
      'timingMessage': _adManager.getTimingMessage(),
      'complianceStatus': _adManager.getComplianceStatus(),
      'nextAdOpportunity': stats['nextAdOpportunity'],
      'optimalAdMoment': stats['isOptimalAdMoment'],
      'userInGoodState': stats['isUserInGoodStateForAds'],
      'engagementLevel': stats['engagementLevel'],
      'engagementScore': stats['sessionEngagementScore'],
    };
  }

  /// Intelligently schedule ad preloading based on user behavior
  static void _scheduleIntelligentAdPreload(bool adWasJustShown) {
    // If an ad was just shown, wait shorter before preloading the next one
    final delayMinutes = adWasJustShown ? 2 : 1;

    Future.delayed(Duration(minutes: delayMinutes), () {
      // More permissive conditions for better ad visibility
      final stats = _adManager.getSessionStats();
      final sessionDurationMinutes =
          stats['sessionDurationMinutes'] as int? ?? 0;
      final roomTransitions = stats['roomTransitions'] as int? ?? 0;

      // Preload if user shows any activity (more permissive)
      if (sessionDurationMinutes > 1 && roomTransitions > 0) {
        // Check if we should preload based on current ad readiness
        if (!_adManager.isAdReady && _adManager.validateAndLogCompliance()) {
          AdMobCompliance.safeLog(
              'Intelligently preloading ad after navigation');
          _adManager.preloadIfAppropriate();
        }
      } else {
        // For users showing high engagement, try aggressive preloading
        if (!_adManager.isAdReady && _adManager.validateAndLogCompliance()) {
          _adManager.enableAggressivePreloadingIfEngaged();
        }
      }
    });
  }
}

/// Extension methods for even easier navigation
extension GoRouterRoomExtensions on BuildContext {
  /// Navigate to chat with room transition ads
  Future<void> goToChat(String chatId, String chatCreatedAt) async {
    await GoRouterRoomHelper.goToChat(this, chatId, chatCreatedAt);
  }

  /// Navigate to topic with room transition ads
  Future<void> goToTopic(String topicId, String topicCreatorId) async {
    await GoRouterRoomHelper.goToTopic(this, topicId, topicCreatorId);
  }

  /// Push to chat with room transition ads
  Future<T?> pushToChat<T>(String chatId, String chatCreatedAt) async {
    return await GoRouterRoomHelper.pushToChat<T>(this, chatId, chatCreatedAt);
  }

  /// Push to topic with room transition ads
  Future<T?> pushToTopic<T>(String topicId, String topicCreatorId) async {
    return await GoRouterRoomHelper.pushToTopic<T>(
        this, topicId, topicCreatorId);
  }

  /// Navigate without ads (for non-room destinations)
  void goWithoutAd(String destination) {
    GoRouterRoomHelper.goWithoutAd(this, destination);
  }

  /// Push without ads (for non-room destinations)
  Future<T?> pushWithoutAd<T>(String destination) async {
    return await GoRouterRoomHelper.pushWithoutAd<T>(this, destination);
  }

  /// Check if ads can be shown for navigation (compliance-aware)
  bool canShowAdsForNavigation() {
    return GoRouterRoomHelper.validateCompliance();
  }

  /// Get compliance message for navigation
  String getNavigationComplianceMessage() {
    return GoRouterRoomHelper.getComplianceMessage();
  }

  /// Get current compliance status for debugging
  Map<String, dynamic> getNavigationComplianceStatus() {
    return GoRouterRoomHelper.getComplianceStatus();
  }

  /// Navigate to chat with compliance validation
  Future<void> goToChatSafe(String chatId, String chatCreatedAt) async {
    if (canShowAdsForNavigation()) {
      await goToChat(chatId, chatCreatedAt);
    } else {
      // Navigate without ads for compliance
      goWithoutAd(encodeChatRoute(chatId, chatCreatedAt));
    }
  }

  /// Navigate to topic with compliance validation
  Future<void> goToTopicSafe(String topicId, String topicCreatorId) async {
    if (canShowAdsForNavigation()) {
      await goToTopic(topicId, topicCreatorId);
    } else {
      // Navigate without ads for compliance
      goWithoutAd(encodeTopicRoute(topicId, topicCreatorId));
    }
  }
}

/// Internal enum for navigation methods
enum _NavigationMethod {
  go,
  push,
}

/// Debug widget to show ad timing information and compliance status
class RoomAdDebugInfo extends StatelessWidget {
  const RoomAdDebugInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Room Transition Ads Debug',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),

          // Compliance Information
          Text(
            'AdMob Compliance:',
            style: TextStyle(
              color: Colors.yellow,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
          Text(
            'Admin: ${AdMobCompliance.isCurrentUserAdmin} | Test Ads: ${AdMobCompliance.shouldUseTestAds}',
            style: TextStyle(color: Colors.white, fontSize: 10),
          ),
          if (AdMobCompliance.getComplianceBadge() != null)
            Text(
              'Badge: ${AdMobCompliance.getComplianceBadge()}',
              style: TextStyle(color: Colors.orange, fontSize: 10),
            ),

          const SizedBox(height: 4),

          // Session Statistics
          Consumer<RoomTransitionAds>(
            builder: (context, adManager, child) {
              final stats = adManager.getSessionStats();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Session Statistics:',
                    style: TextStyle(
                      color: Colors.yellow,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    'Transitions: ${stats['roomTransitions']} | Ads: ${stats['adsShownThisSession']}/${stats['maxAdsPerSession']}',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  Text(
                    'Status: ${adManager.getTimingMessage()}',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  Text(
                    'Session: ${stats['sessionDurationMinutes']}min',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  Text(
                    'Compliance: ${GoRouterRoomHelper.getComplianceMessage()}',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),

                  const SizedBox(height: 4),

                  // Navigation Pattern Information
                  Text(
                    'Navigation Pattern:',
                    style: TextStyle(
                      color: Colors.yellow,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    'Quick Navs: ${stats['consecutiveQuickNavigations']} | Recent: ${stats['recentNavigationsCount']}',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  Text(
                    'Healthy Pattern: ${stats['hasHealthyNavigationPattern'] ? 'Yes' : 'No'}',
                    style: TextStyle(
                        color: stats['hasHealthyNavigationPattern']
                            ? Colors.green
                            : Colors.orange,
                        fontSize: 10),
                  ),
                  if (stats['lastNavigationMinutesAgo'] != null)
                    Text(
                      'Last Nav: ${stats['lastNavigationMinutesAgo']}min ago',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),

                  const SizedBox(height: 4),

                  // User Engagement Information
                  Text(
                    'User Engagement:',
                    style: TextStyle(
                      color: Colors.yellow,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    'Level: ${stats['engagementLevel']} | Score: ${stats['sessionEngagementScore']}/100',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  Text(
                    'Highly Engaged: ${stats['isHighlyEngaged'] ? 'Yes' : 'No'}',
                    style: TextStyle(
                        color: stats['isHighlyEngaged']
                            ? Colors.green
                            : Colors.grey,
                        fontSize: 10),
                  ),

                  const SizedBox(height: 4),

                  // Current Frequency Settings
                  Text(
                    'Ad Frequency (Updated):',
                    style: TextStyle(
                      color: Colors.yellow,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    'Between Ads: 2min | First Ad: 2 transitions',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  Text(
                    'Subsequent: 2 transitions | Max/Session: 5',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),

                  const SizedBox(height: 4),

                  // Timing Prediction
                  Text(
                    'Next Ad Opportunity:',
                    style: TextStyle(
                      color: Colors.yellow,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    '${stats['nextAdOpportunity']}',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  Text(
                    'Optimal Moment: ${stats['isOptimalAdMoment'] ? 'Yes' : 'No'}',
                    style: TextStyle(
                        color: stats['isOptimalAdMoment']
                            ? Colors.green
                            : Colors.orange,
                        fontSize: 10),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
