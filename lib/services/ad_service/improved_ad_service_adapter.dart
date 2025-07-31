import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'improved_ad_manager.dart';
import 'improved_consent_manager.dart';
import 'improved_room_ads.dart';

/// Adapter to integrate improved ad manager with existing ad service
/// This provides a bridge between the old ad service API and the new improved system
class ImprovedAdServiceAdapter {
  static ImprovedAdServiceAdapter? _instance;
  static ImprovedAdServiceAdapter get instance =>
      _instance ??= ImprovedAdServiceAdapter._();

  ImprovedAdServiceAdapter._();

  final ImprovedAdManager _adManager = ImprovedAdManager.instance;
  final ImprovedConsentManager _consentManager =
      ImprovedConsentManager.instance;

  // Ad unit IDs cache
  final Map<String, String> _adUnitIds = {};

  // Active ads tracking
  final Map<String, Ad> _activeAds = {};

  /// Initialize the adapter
  Future<void> initialize() async {
    _log('Initializing improved ad service adapter');

    // Start async initialization of ad manager
    await _adManager.initializeAsync();

    // Also initialize the improved room ads for session tracking
    // This ensures room-based ad logic works properly
    try {
      await ImprovedRoomAds.instance.initialize();
      _log('Improved room ads initialized for session tracking');
    } catch (e) {
      _logError('Failed to initialize improved room ads: $e');
      // Continue anyway - the base ad system can still work
    }

    _log('Ad service adapter initialized');
  }

  /// Set ad unit IDs for different ad types
  void setAdUnitIds({
    String? bannerId,
    String? interstitialId,
    String? rewardedId,
    String? nativeId,
  }) {
    if (bannerId != null) _adUnitIds['banner'] = bannerId;
    if (interstitialId != null) _adUnitIds['interstitial'] = interstitialId;
    if (rewardedId != null) _adUnitIds['rewarded'] = rewardedId;
    if (nativeId != null) _adUnitIds['native'] = nativeId;

    _log('Ad unit IDs configured');
  }

  /// Get ad unit ID for specific type
  String? getAdUnitId(String adType) {
    return _adUnitIds[adType];
  }

  /// Check if ads can be requested
  bool canRequestAds() {
    return _consentManager.canRequestAds;
  }

  /// Check if personalized ads can be shown
  bool canShowPersonalizedAds() {
    return _consentManager.canShowPersonalizedAds;
  }

  /// Check if non-personalized ads can be shown
  bool canShowNonPersonalizedAds() {
    return _consentManager.canShowNonPersonalizedAds;
  }

  /// Get current consent status
  ConsentStatus getConsentStatus() {
    return _consentManager.consentStatus;
  }

  /// Load a banner ad
  Future<BannerAd?> loadBannerAd({
    String? adUnitId,
    AdSize size = AdSize.banner,
    Map<String, String>? customTargeting,
  }) async {
    try {
      final unitId = adUnitId ?? _adUnitIds['banner'];
      if (unitId == null) {
        _logError('No banner ad unit ID provided');
        return null;
      }

      final banner = await _adManager.loadBannerAd(
        adUnitId: unitId,
        size: size,
        customTargeting: customTargeting,
      );

      if (banner != null) {
        _activeAds[banner.adUnitId] = banner;
      }

      return banner;
    } catch (e) {
      _logError('Failed to load banner ad: $e');
      return null;
    }
  }

  /// Load an interstitial ad
  Future<InterstitialAd?> loadInterstitialAd({
    String? adUnitId,
    Map<String, String>? customTargeting,
  }) async {
    try {
      final unitId = adUnitId ?? _adUnitIds['interstitial'];
      if (unitId == null) {
        _logError('No interstitial ad unit ID provided');
        return null;
      }

      final interstitial = await _adManager.loadInterstitialAd(
        adUnitId: unitId,
        customTargeting: customTargeting,
      );

      if (interstitial != null) {
        _activeAds[interstitial.adUnitId] = interstitial;
      }

      return interstitial;
    } catch (e) {
      _logError('Failed to load interstitial ad: $e');
      return null;
    }
  }

  /// Load a rewarded ad
  Future<RewardedAd?> loadRewardedAd({
    String? adUnitId,
    Map<String, String>? customTargeting,
    int maxRetries = 2,
  }) async {
    try {
      final unitId = adUnitId ?? _adUnitIds['rewarded'];
      if (unitId == null) {
        _logError('No rewarded ad unit ID provided');
        return null;
      }

      final rewarded = await _adManager.loadRewardedAd(
        adUnitId: unitId,
        customTargeting: customTargeting,
        maxRetries: maxRetries,
      );

      if (rewarded != null) {
        _activeAds[rewarded.adUnitId] = rewarded;
      }

      return rewarded;
    } catch (e) {
      _logError('Failed to load rewarded ad: $e');
      return null;
    }
  }

  /// Load a native ad
  Future<NativeAd?> loadNativeAd({
    String? adUnitId,
    NativeTemplateStyle? templateStyle,
    Map<String, String>? customTargeting,
  }) async {
    try {
      final unitId = adUnitId ?? _adUnitIds['native'];
      if (unitId == null) {
        _logError('No native ad unit ID provided');
        return null;
      }

      final style = templateStyle ?? _getDefaultNativeStyle();

      final native = await _adManager.loadNativeAd(
        adUnitId: unitId,
        templateStyle: style,
        customTargeting: customTargeting,
      );

      if (native != null) {
        _activeAds[native.adUnitId] = native;
      }

      return native;
    } catch (e) {
      _logError('Failed to load native ad: $e');
      return null;
    }
  }

  /// Get default native ad template style
  NativeTemplateStyle _getDefaultNativeStyle() {
    return NativeTemplateStyle(
      templateType: TemplateType.medium,
      mainBackgroundColor: const Color(0xFFFFFFFF),
      cornerRadius: 8.0,
      callToActionTextStyle: NativeTemplateTextStyle(
        textColor: const Color(0xFFFFFFFF),
        backgroundColor: const Color(0xFF4285F4),
        style: NativeTemplateFontStyle.bold,
        size: 16.0,
      ),
      primaryTextStyle: NativeTemplateTextStyle(
        textColor: const Color(0xFF000000),
        style: NativeTemplateFontStyle.normal,
        size: 16.0,
      ),
      secondaryTextStyle: NativeTemplateTextStyle(
        textColor: const Color(0xFF606060),
        style: NativeTemplateFontStyle.normal,
        size: 14.0,
      ),
      tertiaryTextStyle: NativeTemplateTextStyle(
        textColor: const Color(0xFF808080),
        style: NativeTemplateFontStyle.normal,
        size: 12.0,
      ),
    );
  }

  /// Create ad request with current consent status
  AdRequest createAdRequest({
    List<String>? keywords,
    String? contentUrl,
    Map<String, String>? customTargeting,
  }) {
    return _consentManager.createAdRequest(
      keywords: keywords,
      contentUrl: contentUrl,
      customTargeting: customTargeting,
    );
  }

  /// Show consent form
  Future<ConsentResult> showConsentForm() async {
    return await _adManager.showConsentForm();
  }

  /// Show privacy options
  Future<bool> showPrivacyOptions() async {
    return await _adManager.showPrivacyOptions();
  }

  /// Check if consent form should be shown
  bool shouldShowConsentForm() {
    final status = _consentManager.consentStatus;
    return status == ConsentStatus.required || status == ConsentStatus.unknown;
  }

  /// Dispose a specific ad
  void disposeAd(Ad ad) {
    try {
      ad.dispose();
      _activeAds.remove(ad.adUnitId);
      _log('Disposed ad: ${ad.adUnitId}');
    } catch (e) {
      _logError('Failed to dispose ad: $e');
    }
  }

  /// Dispose all active ads
  void disposeAllAds() {
    for (final ad in _activeAds.values) {
      try {
        ad.dispose();
      } catch (e) {
        _logError('Failed to dispose ad: $e');
      }
    }
    _activeAds.clear();
    _log('Disposed all active ads');
  }

  /// Get ad serving status
  AdServingStatus getAdServingStatus() {
    return _adManager.getAdServingStatus();
  }

  /// Get statistics
  Map<String, dynamic> getStatistics() {
    final stats = _adManager.getStatistics();
    stats['activeAds'] = _activeAds.length;
    stats['adUnitIds'] = _adUnitIds;
    return stats;
  }

  /// Reset statistics
  void resetStatistics() {
    _adManager.resetStatistics();
  }

  /// Reset consent (for testing)
  Future<void> resetConsent() async {
    await _adManager.resetConsent();
  }

  /// Validate ad compliance
  Future<AdComplianceResult> validateAdCompliance() async {
    try {
      final canRequest = canRequestAds();
      final canPersonalized = canShowPersonalizedAds();
      final canNonPersonalized = canShowNonPersonalizedAds();
      final status = getConsentStatus();

      String message = '';
      bool isCompliant = true;

      if (!canRequest) {
        message = 'Cannot request ads - consent not obtained';
        isCompliant = false;
      } else if (canPersonalized) {
        message = 'Can show personalized ads';
      } else if (canNonPersonalized) {
        message = 'Can show non-personalized ads only';
      } else {
        message = 'Unexpected state - cannot determine ad type';
        isCompliant = false;
      }

      return AdComplianceResult(
        isCompliant: isCompliant,
        consentStatus: status,
        canRequestAds: canRequest,
        canShowPersonalizedAds: canPersonalized,
        canShowNonPersonalizedAds: canNonPersonalized,
        message: message,
      );
    } catch (e) {
      return AdComplianceResult(
        isCompliant: false,
        consentStatus: ConsentStatus.unknown,
        canRequestAds: false,
        canShowPersonalizedAds: false,
        canShowNonPersonalizedAds: false,
        message: 'Error validating compliance: $e',
      );
    }
  }

  /// Logging helpers
  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[ImprovedAdAdapter] $message');
    }
  }

  void _logError(String message) {
    debugPrint('[ImprovedAdAdapter ERROR] $message');
  }
}

/// Ad compliance validation result
class AdComplianceResult {
  final bool isCompliant;
  final ConsentStatus consentStatus;
  final bool canRequestAds;
  final bool canShowPersonalizedAds;
  final bool canShowNonPersonalizedAds;
  final String message;

  AdComplianceResult({
    required this.isCompliant,
    required this.consentStatus,
    required this.canRequestAds,
    required this.canShowPersonalizedAds,
    required this.canShowNonPersonalizedAds,
    required this.message,
  });
}
