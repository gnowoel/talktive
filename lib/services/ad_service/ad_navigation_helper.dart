import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_service.dart';
import 'ad_timing_manager.dart';

/// Navigation helper that manages interstitial ad placement during navigation
/// Follows AdMob best practices for non-intrusive ad placement
class AdNavigationHelper {
  static AdNavigationHelper? _instance;
  static AdNavigationHelper get instance =>
      _instance ??= AdNavigationHelper._();

  AdNavigationHelper._();

  final AdService _adService = AdService.instance;
  final AdTimingManager _timingManager = AdTimingManager.instance;

  /// Navigate to a new screen with optional interstitial ad
  /// This is the main method for navigation with ads
  Future<T?> navigateWithAd<T>({
    required BuildContext context,
    required Widget destination,
    String? routeName,
    NavigationType navigationType = NavigationType.push,
    bool forceAd = false,
    VoidCallback? onAdShown,
    VoidCallback? onAdFailed,
    VoidCallback? onNavigationComplete,
  }) async {
    // Check if we should show an interstitial ad
    final shouldShowAd =
        forceAd || _shouldShowInterstitialForNavigation(navigationType);

    if (shouldShowAd && _adService.isInterstitialAdReady) {
      // Show interstitial ad before navigation
      await _showInterstitialAdForNavigation(
        context: context,
        onAdShown: onAdShown,
        onAdFailed: onAdFailed,
      );
    }

    // Perform the navigation
    T? result;
    try {
      switch (navigationType) {
        case NavigationType.push:
          if (context.mounted) {
            result = await Navigator.push<T>(
              context,
              MaterialPageRoute(
                builder: (context) => destination,
                settings: RouteSettings(name: routeName),
              ),
            );
          }
          break;
        case NavigationType.pushReplacement:
          if (context.mounted) {
            result = await Navigator.pushReplacement<T, dynamic>(
              context,
              MaterialPageRoute(
                builder: (context) => destination,
                settings: RouteSettings(name: routeName),
              ),
            );
          }
          break;
        case NavigationType.pushAndRemoveUntil:
          if (context.mounted) {
            result = await Navigator.pushAndRemoveUntil<T>(
              context,
              MaterialPageRoute(
                builder: (context) => destination,
                settings: RouteSettings(name: routeName),
              ),
              (route) => false,
            );
          }
          break;
        case NavigationType.pop:
          if (context.mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          break;
      }
    } catch (e) {
      debugPrint('Navigation error: $e');
    }

    onNavigationComplete?.call();
    return result;
  }

  /// Navigate between chats with appropriate ad timing
  Future<T?> navigateToChat<T>({
    required BuildContext context,
    required Widget chatPage,
    String? chatId,
  }) async {
    _timingManager.trackChatTransition();

    return navigateWithAd<T>(
      context: context,
      destination: chatPage,
      routeName: '/chat/$chatId',
      navigationType: NavigationType.push,
      onAdShown: () {
        debugPrint('Interstitial ad shown for chat transition');
      },
      onAdFailed: () {
        debugPrint('Failed to show interstitial ad for chat transition');
      },
    );
  }

  /// Navigate to topic with appropriate ad timing
  Future<T?> navigateToTopic<T>({
    required BuildContext context,
    required Widget topicPage,
    String? topicId,
  }) async {
    _timingManager.trackTopicJoin();

    return navigateWithAd<T>(
      context: context,
      destination: topicPage,
      routeName: '/topic/$topicId',
      navigationType: NavigationType.push,
      onAdShown: () {
        debugPrint('Interstitial ad shown for topic transition');
      },
      onAdFailed: () {
        debugPrint('Failed to show interstitial ad for topic transition');
      },
    );
  }

  /// Navigate back with optional interstitial (be careful with this)
  Future<void> navigateBack({
    required BuildContext context,
    dynamic result,
    bool showAdOnBack = false,
  }) async {
    if (showAdOnBack && _canShowBackInterstitial()) {
      await _showInterstitialAdForNavigation(
        context: context,
        onAdShown: () {
          debugPrint('Interstitial ad shown on back navigation');
        },
        onAdFailed: () {
          debugPrint('Failed to show interstitial ad on back navigation');
        },
      );
    }

    if (context.mounted && Navigator.canPop(context)) {
      Navigator.pop(context, result);
    }
  }

  /// Navigate to home/main screen with app launch ad
  Future<T?> navigateToHome<T>({
    required BuildContext context,
    required Widget homePage,
  }) async {
    final shouldShowLaunchAd = _timingManager.canShowAppLaunchInterstitial();

    return navigateWithAd<T>(
      context: context,
      destination: homePage,
      routeName: '/home',
      navigationType: NavigationType.pushAndRemoveUntil,
      forceAd: shouldShowLaunchAd,
      onAdShown: () {
        debugPrint('App launch interstitial ad shown');
      },
      onAdFailed: () {
        debugPrint('Failed to show app launch interstitial ad');
      },
    );
  }

  /// Show rewarded ad with navigation reward
  Future<void> showRewardedAdForFeature({
    required BuildContext context,
    required VoidCallback onRewardEarned,
    VoidCallback? onAdFailed,
    String featureName = 'premium_feature',
  }) async {
    if (!_adService.isRewardedAdReady) {
      debugPrint('Rewarded ad not ready for feature: $featureName');
      onAdFailed?.call();
      return;
    }

    await _adService.showRewardedAd(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        debugPrint('User earned reward: ${reward.amount} ${reward.type}');
        _timingManager.markRewardedShown();
        onRewardEarned();
      },
      onAdClosed: () {
        debugPrint('Rewarded ad closed for feature: $featureName');
      },
      onAdFailedToShow: () {
        debugPrint('Failed to show rewarded ad for feature: $featureName');
        onAdFailed?.call();
      },
    );
  }

  /// Check if we should show interstitial for navigation
  bool _shouldShowInterstitialForNavigation(NavigationType navigationType) {
    // Don't show ads on back navigation by default
    if (navigationType == NavigationType.pop) return false;

    // Check timing manager conditions
    if (!_timingManager.canShowInterstitial()) return false;

    // Check if it's a natural time for interstitial
    if (!_timingManager.isNaturalInterstitialTime()) return false;

    return true;
  }

  /// Show interstitial ad for navigation
  Future<void> _showInterstitialAdForNavigation({
    required BuildContext context,
    VoidCallback? onAdShown,
    VoidCallback? onAdFailed,
  }) async {
    try {
      await _adService.showInterstitialAd(
        onAdClosed: () {
          _timingManager.markInterstitialShown();
          onAdShown?.call();
        },
        onAdFailedToShow: () {
          onAdFailed?.call();
        },
      );
    } catch (e) {
      debugPrint('Error showing interstitial ad: $e');
      onAdFailed?.call();
    }
  }

  /// Check if we can show interstitial on back navigation
  /// This should be used very carefully to avoid annoying users
  bool _canShowBackInterstitial() {
    // Only show back interstitials in very specific scenarios
    // For example, after user has been in app for a while
    final sessionStats = _timingManager.getSessionStats();

    // Don't show if user just started the session
    if (sessionStats.sessionDuration.inMinutes < 5) return false;

    // Don't show if user has seen many ads already
    if (sessionStats.totalAdsShown >= 2) return false;

    // Must meet basic timing requirements
    if (!_timingManager.canShowInterstitial()) return false;

    return true;
  }

  /// Create a dialog that offers rewarded ad for premium features
  Future<void> showRewardedAdDialog({
    required BuildContext context,
    required String title,
    required String description,
    required VoidCallback onRewardEarned,
    VoidCallback? onDeclined,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(description),
              const SizedBox(height: 16),
              const Icon(
                Icons.play_circle_fill,
                size: 48,
                color: Colors.green,
              ),
              const SizedBox(height: 8),
              const Text(
                'Watch a short video to unlock this feature',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onDeclined?.call();
              },
              child: const Text('Not Now'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                showRewardedAdForFeature(
                  context: context,
                  onRewardEarned: onRewardEarned,
                  onAdFailed: onDeclined,
                  featureName: title,
                );
              },
              child: const Text('Watch Ad'),
            ),
          ],
        );
      },
    );
  }

  /// Show interstitial ad with loading dialog
  Future<void> showInterstitialWithLoading({
    required BuildContext context,
    VoidCallback? onAdShown,
    VoidCallback? onAdFailed,
  }) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Wait a moment to ensure ad is ready
    await Future.delayed(const Duration(milliseconds: 500));

    // Hide loading dialog
    if (context.mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    // Show the ad
    if (context.mounted) {
      await _showInterstitialAdForNavigation(
        context: context,
        onAdShown: onAdShown,
        onAdFailed: onAdFailed,
      );
    }
  }

  /// Get navigation statistics for debugging
  Map<String, dynamic> getNavigationStats() {
    return {
      'timingManagerStats': _timingManager.getDebugInfo(),
      'adServiceReady': {
        'banner': _adService.isBannerAdReady,
        'interstitial': _adService.isInterstitialAdReady,
        'rewarded': _adService.isRewardedAdReady,
      },
      'recommendations': {
        'placement': _timingManager.getAdPlacementRecommendation().toString(),
        'canShowInterstitial': _timingManager.canShowInterstitial(),
        'canShowRewarded': _timingManager.canShowRewarded(),
        'isNaturalTime': _timingManager.isNaturalInterstitialTime(),
      },
    };
  }
}

/// Types of navigation for ad placement decisions
enum NavigationType {
  push,
  pushReplacement,
  pushAndRemoveUntil,
  pop,
}

/// Extension methods for easier navigation
extension NavigationExtensions on BuildContext {
  /// Navigate with ad helper
  Future<T?> navigateWithAd<T>({
    required Widget destination,
    String? routeName,
    NavigationType navigationType = NavigationType.push,
    bool forceAd = false,
  }) {
    return AdNavigationHelper.instance.navigateWithAd<T>(
      context: this,
      destination: destination,
      routeName: routeName,
      navigationType: navigationType,
      forceAd: forceAd,
    );
  }

  /// Navigate to chat with ads
  Future<T?> navigateToChat<T>({
    required Widget chatPage,
    String? chatId,
  }) {
    return AdNavigationHelper.instance.navigateToChat<T>(
      context: this,
      chatPage: chatPage,
      chatId: chatId,
    );
  }

  /// Navigate to topic with ads
  Future<T?> navigateToTopic<T>({
    required Widget topicPage,
    String? topicId,
  }) {
    return AdNavigationHelper.instance.navigateToTopic<T>(
      context: this,
      topicPage: topicPage,
      topicId: topicId,
    );
  }

  /// Show rewarded ad dialog
  Future<void> showRewardedAdDialog({
    required String title,
    required String description,
    required VoidCallback onRewardEarned,
    VoidCallback? onDeclined,
  }) {
    return AdNavigationHelper.instance.showRewardedAdDialog(
      context: this,
      title: title,
      description: description,
      onRewardEarned: onRewardEarned,
      onDeclined: onDeclined,
    );
  }
}
