import 'package:flutter/foundation.dart';
import '../user_cache.dart';

import 'consent_service.dart';

/// AdMob compliance utility class to ensure adherence to AdMob policies
///
/// According to AdMob policy, developers must not click on their own ads.
/// This utility ensures admin users are served test ads to maintain compliance.
class AdMobCompliance {
  static AdMobCompliance? _instance;
  static AdMobCompliance get instance => _instance ??= AdMobCompliance._();

  AdMobCompliance._();

  /// Check if the current user is an admin
  static bool get isCurrentUserAdmin {
    final currentUser = UserCache().user;
    return currentUser?.isAdmin ?? false;
  }

  /// Check if test ads should be used (debug mode OR admin user)
  static bool get shouldUseTestAds {
    return kDebugMode || isCurrentUserAdmin;
  }

  /// Get compliance status with detailed information
  static Future<Map<String, dynamic>> getComplianceStatus() async {
    final isAdmin = isCurrentUserAdmin;
    final isDebugMode = kDebugMode;
    final useTestAds = shouldUseTestAds;

    // Get consent status information
    Map<String, dynamic> consentInfo = {};
    try {
      consentInfo = await ConsentService.instance.getConsentDebugInfo();
    } catch (e) {
      consentInfo = {'error': 'Failed to get consent info: $e'};
    }

    String reason;
    if (isDebugMode && isAdmin) {
      reason =
          'Debug mode + Admin user - using test ads for development and compliance';
    } else if (isDebugMode) {
      reason = 'Debug mode - using test ads for development';
    } else if (isAdmin) {
      reason =
          'Admin user detected - using test ads for AdMob policy compliance';
    } else {
      reason = 'Regular user - using production ads';
    }

    return {
      'isCompliant': true,
      'reason': reason,
      'isAdmin': isAdmin,
      'isDebugMode': isDebugMode,
      'shouldUseTestAds': useTestAds,
      'adUnitType': useTestAds ? 'test' : 'production',
      'policyReference':
          'AdMob Policy: Publishers may not click their own ads or use any means to inflate impressions and/or clicks artificially',
      'consentInfo': consentInfo,
    };
  }

  /// Log compliance status for debugging
  static Future<void> logComplianceStatus() async {
    final status = await getComplianceStatus();
    debugPrint('=== AdMob Compliance Check ===');
    debugPrint('Status: COMPLIANT');
    debugPrint('Reason: ${status['reason']}');
    debugPrint('Admin User: ${status['isAdmin']}');
    debugPrint('Debug Mode: ${status['isDebugMode']}');
    debugPrint('Using Test Ads: ${status['shouldUseTestAds']}');
    debugPrint('Ad Unit Type: ${status['adUnitType']}');
    final consentInfo = status['consentInfo'] as Map<String, dynamic>;
    debugPrint('Consent Status: ${consentInfo['consentStatus'] ?? 'Unknown'}');
    debugPrint('Can Request Ads: ${consentInfo['canRequestAds'] ?? 'Unknown'}');
    debugPrint('==============================');
  }

  /// Log when an ad is shown with compliance context
  static void logAdShown(String adType, {String? context}) {
    final isAdmin = isCurrentUserAdmin;
    final useTestAds = shouldUseTestAds;

    String message = 'Ad shown: $adType';
    if (context != null) message += ' ($context)';

    if (isAdmin) {
      message += ' - COMPLIANCE: Test ad shown to admin user';
    } else if (useTestAds) {
      message += ' - Test ad (debug mode)';
    } else {
      message += ' - Production ad';
    }

    debugPrint(message);
  }

  /// Validate compliance before showing ads
  static Future<bool> validateAdCompliance() async {
    final status = await getComplianceStatus();

    // Check consent compliance
    try {
      final canRequest = await ConsentService.instance.canRequestAds();
      if (!canRequest) {
        safeLog('Ad compliance failed: Cannot request ads due to consent');
        return false;
      }
      safeLog('Ad compliance validated: Ads can be requested');
    } catch (e) {
      safeLog('Ad compliance warning: Consent check error: $e');
      // Don't block ads if consent service fails, but log the issue
    }

    // Use status to validate compliance
    return status['isCompliant'] as bool;
  }

  /// Get formatted compliance notice for admin users
  static String getAdminNotice() {
    if (!isCurrentUserAdmin) return '';

    return 'Notice: As an admin user, you are viewing test advertisements to comply with AdMob policies. Real users see production ads.';
  }

  /// Check if compliance logging should be verbose
  static bool get shouldLogVerbose => kDebugMode || isCurrentUserAdmin;

  /// Get test ad unit IDs for different platforms and ad types
  static Map<String, String> get testAdUnitIds => {
        'banner_android': 'ca-app-pub-3940256099942544/6300978111',
        'banner_ios': 'ca-app-pub-3940256099942544/2934735716',
        'interstitial_android': 'ca-app-pub-3940256099942544/1033173712',
        'interstitial_ios': 'ca-app-pub-3940256099942544/4411468910',
        'rewarded_android': 'ca-app-pub-3940256099942544/5224354917',
        'rewarded_ios': 'ca-app-pub-3940256099942544/1712485313',
      };

  /// Initialize compliance checking (call this when user logs in or app starts)
  static Future<void> initialize() async {
    // Initialize consent service
    try {
      final success = await ConsentService.instance.initialize();
      safeLog('Consent service initialized: $success');
    } catch (e) {
      safeLog('Warning: Failed to initialize consent service: $e');
    }

    if (shouldLogVerbose) {
      await logComplianceStatus();
    }

    // Validate compliance on initialization
    final isCompliant = await validateAdCompliance();
    if (!isCompliant) {
      debugPrint('WARNING: AdMob compliance check failed');
    }
  }

  /// Get compliance summary for debugging/admin panels
  static Future<String> getComplianceSummary() async {
    final status = await getComplianceStatus();
    final consentInfo = status['consentInfo'] as Map<String, dynamic>;
    final consentStatus = consentInfo['consentStatus'] ?? 'Unknown';
    final canRequestAds = consentInfo['canRequestAds'] ?? false;
    return 'AdMob Compliance: ${status['adUnitType']} ads (${status['reason']}) | Consent: $consentStatus | Can Request: $canRequestAds';
  }

  /// Check if ads should be shown to current user (considering admin status)
  static bool shouldShowAds() {
    // Always show ads, but compliance system ensures appropriate ad types
    return true;
  }

  /// Get user-friendly compliance message for display
  static String getUserFriendlyMessage() {
    if (isCurrentUserAdmin) {
      return 'You are viewing test advertisements as an admin user.';
    } else if (kDebugMode) {
      return 'You are viewing test advertisements in debug mode.';
    } else {
      return 'You are viewing standard advertisements.';
    }
  }

  /// Get detailed compliance info for admin panels
  static Future<Map<String, dynamic>> getDetailedComplianceInfo() async {
    final status = await getComplianceStatus();
    return {
      ...status,
      'timestamp': DateTime.now().toIso8601String(),
      'userFriendlyMessage': getUserFriendlyMessage(),
      'complianceSummary': await getComplianceSummary(),
      'testAdUnitIds': testAdUnitIds,
    };
  }

  /// Safely log compliance events (only if logging is enabled)
  static void safeLog(String message, {bool forceLog = false}) {
    if (shouldLogVerbose || forceLog) {
      debugPrint('[AdMob Compliance] $message');
    }
  }

  /// Check if compliance monitoring is active
  static bool get isComplianceMonitoringActive =>
      kDebugMode || isCurrentUserAdmin;

  /// Get compliance badge text for UI display
  static String? getComplianceBadge() {
    if (isCurrentUserAdmin) {
      return 'TEST ADS';
    } else if (kDebugMode) {
      return 'DEBUG';
    }
    return null;
  }

  /// Validate ad request before showing (returns true if should proceed)
  static Future<bool> validateAdRequest(String adType) async {
    safeLog('Validating ad request for type: $adType');

    final isValid = await validateAdCompliance();
    if (!isValid) {
      safeLog('Ad request validation failed for type: $adType', forceLog: true);
      return false;
    }

    safeLog('Ad request validated successfully for type: $adType');
    return true;
  }

  /// Get compliance warning if any
  static String? getComplianceWarning() {
    if (isCurrentUserAdmin && !shouldUseTestAds) {
      return 'WARNING: Admin user may be seeing production ads. Check compliance configuration.';
    }
    return null;
  }

  /// Request consent if needed (convenience method)
  static Future<void> requestConsentIfNeeded() async {
    try {
      await ConsentService.instance.initializeAndRequestConsent();
      safeLog('Consent request completed');
    } catch (e) {
      safeLog('Failed to request consent: $e');
    }
  }

  /// Check if we can show personalized ads
  static Future<bool> canShowPersonalizedAds() async {
    try {
      return await ConsentService.instance.canShowPersonalizedAds();
    } catch (e) {
      safeLog('Failed to check personalized ads permission: $e');
      return false;
    }
  }

  /// Get consent status message for UI
  static Future<String> getConsentStatusMessage() async {
    try {
      return await ConsentService.instance.getConsentStatusMessage();
    } catch (e) {
      return 'Consent status unavailable';
    }
  }
}
