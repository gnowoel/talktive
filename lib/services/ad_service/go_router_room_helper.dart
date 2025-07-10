import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'room_transition_ads.dart';
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

  /// Core navigation logic with ad timing
  static Future<T?> _navigateToRoom<T>({
    required BuildContext context,
    required String destination,
    required _NavigationMethod navigationMethod,
  }) async {
    // Track the room transition
    _adManager.trackRoomTransition();

    debugPrint(
        'GoRouterRoomHelper: Room transition tracked. Destination: $destination');

    // Show ad if timing is appropriate
    final adShown = await _adManager.showAdIfAppropriate();

    if (adShown) {
      debugPrint(
          'GoRouterRoomHelper: Showed interstitial ad before navigation to $destination');
    } else {
      debugPrint(
          'GoRouterRoomHelper: No ad shown. ${_adManager.getTimingMessage()}');
    }

    // Ensure context is still valid after potential ad display
    if (!context.mounted) {
      debugPrint(
          'GoRouterRoomHelper: Context no longer mounted after potential ad display');
      return null;
    }

    // Perform the navigation based on method
    try {
      switch (navigationMethod) {
        case _NavigationMethod.go:
          context.go(destination);
          return null;
        case _NavigationMethod.push:
          return await context.push<T>(destination);
      }
    } catch (e) {
      debugPrint('GoRouterRoomHelper: Navigation error to $destination: $e');
      return null;
    }
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
}

/// Internal enum for navigation methods
enum _NavigationMethod {
  go,
  push,
}

/// Debug widget to show ad timing information
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
          Consumer<RoomTransitionAds>(
            builder: (context, adManager, child) {
              final stats = adManager.getSessionStats();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
