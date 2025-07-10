import 'package:flutter/material.dart';
import 'room_transition_ads.dart';

/// Simple navigation helper for room transitions with respectful interstitial ads
/// Focuses only on chat-to-chat and chat-to-topic transitions
class RoomNavigation {
  static RoomNavigation? _instance;
  static RoomNavigation get instance => _instance ??= RoomNavigation._();

  RoomNavigation._();

  final RoomTransitionAds _adManager = RoomTransitionAds.instance;

  /// Navigate to a chat room with optional ad
  Future<T?> navigateToChat<T>({
    required BuildContext context,
    required Widget chatPage,
    String? chatId,
    bool replace = false,
  }) async {
    return _navigateToRoom<T>(
      context: context,
      destination: chatPage,
      routeName: '/chat${chatId != null ? '/$chatId' : ''}',
      replace: replace,
    );
  }

  /// Navigate to a topic room with optional ad
  Future<T?> navigateToTopic<T>({
    required BuildContext context,
    required Widget topicPage,
    String? topicId,
    bool replace = false,
  }) async {
    return _navigateToRoom<T>(
      context: context,
      destination: topicPage,
      routeName: '/topic${topicId != null ? '/$topicId' : ''}',
      replace: replace,
    );
  }

  /// Core room navigation logic with ad timing
  Future<T?> _navigateToRoom<T>({
    required BuildContext context,
    required Widget destination,
    String? routeName,
    bool replace = false,
  }) async {
    // Track the room transition
    _adManager.trackRoomTransition();

    // Show ad if timing is appropriate
    final adShown = await _adManager.showAdIfAppropriate();

    if (adShown) {
      debugPrint('RoomNavigation: Showed interstitial ad before navigation');
    }

    // Ensure context is still valid after potential ad display
    if (!context.mounted) {
      debugPrint('RoomNavigation: Context no longer mounted after ad');
      return null;
    }

    // Perform the navigation
    try {
      if (replace) {
        return await Navigator.pushReplacement<T, dynamic>(
          context,
          MaterialPageRoute(
            builder: (context) => destination,
            settings: RouteSettings(name: routeName),
          ),
        );
      } else {
        return await Navigator.push<T>(
          context,
          MaterialPageRoute(
            builder: (context) => destination,
            settings: RouteSettings(name: routeName),
          ),
        );
      }
    } catch (e) {
      debugPrint('RoomNavigation: Navigation error: $e');
      return null;
    }
  }

  /// Simple navigation without ads (for non-room transitions)
  Future<T?> navigateWithoutAd<T>({
    required BuildContext context,
    required Widget destination,
    String? routeName,
    bool replace = false,
  }) async {
    if (!context.mounted) return null;

    try {
      if (replace) {
        return await Navigator.pushReplacement<T, dynamic>(
          context,
          MaterialPageRoute(
            builder: (context) => destination,
            settings: RouteSettings(name: routeName),
          ),
        );
      } else {
        return await Navigator.push<T>(
          context,
          MaterialPageRoute(
            builder: (context) => destination,
            settings: RouteSettings(name: routeName),
          ),
        );
      }
    } catch (e) {
      debugPrint('RoomNavigation: Navigation error: $e');
      return null;
    }
  }

  /// Get current session statistics for debugging
  Map<String, dynamic> getStats() {
    return _adManager.getSessionStats();
  }

  /// Get user-friendly timing message
  String getTimingMessage() {
    return _adManager.getTimingMessage();
  }

  /// Check if an ad would show on next transition (for debugging)
  bool wouldShowAdOnNextTransition() {
    return _adManager.shouldShowAdNow();
  }
}

/// Extension methods for easier navigation
extension RoomNavigationExtensions on BuildContext {
  /// Navigate to chat with room transition ads
  Future<T?> navigateToChat<T>({
    required Widget chatPage,
    String? chatId,
    bool replace = false,
  }) {
    return RoomNavigation.instance.navigateToChat<T>(
      context: this,
      chatPage: chatPage,
      chatId: chatId,
      replace: replace,
    );
  }

  /// Navigate to topic with room transition ads
  Future<T?> navigateToTopic<T>({
    required Widget topicPage,
    String? topicId,
    bool replace = false,
  }) {
    return RoomNavigation.instance.navigateToTopic<T>(
      context: this,
      topicPage: topicPage,
      topicId: topicId,
      replace: replace,
    );
  }

  /// Navigate without ads (for settings, profile, etc.)
  Future<T?> navigateWithoutAd<T>({
    required Widget destination,
    String? routeName,
    bool replace = false,
  }) {
    return RoomNavigation.instance.navigateWithoutAd<T>(
      context: this,
      destination: destination,
      routeName: routeName,
      replace: replace,
    );
  }
}
