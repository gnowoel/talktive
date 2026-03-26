import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/ad/ad_service.dart';

/// Navigation utilities that handle showing interstitial ads before popping a screen
extension AdNavigationExtensions on BuildContext {
  /// Pops the current screen with an optional interstitial ad consideration
  /// [ref] is the Riverpod Ref to access the AdService
  /// [showAd] whether to attempt showing an ad (default: true)
  Future<void> popWithAd(WidgetRef ref, {bool showAd = true}) async {
    if (!mounted) return;

    if (!showAd) {
      if (canPop()) {
        pop();
      } else {
        Navigator.of(this).maybePop();
      }
      return;
    }

    final adService = ref.read(adServiceProvider);
    
    // Attempt to show the ad, then pop the screen
    await adService.showInterstitialAd(onAdClosed: () {
      if (mounted) {
        if (canPop()) {
          pop();
        } else {
          Navigator.of(this).maybePop();
        }
      }
    });
  }
}
