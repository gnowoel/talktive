import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'improved_consent_manager.dart';
import 'web_consent_handler.dart';

/// Platform-aware consent manager facade that automatically chooses
/// the appropriate consent implementation based on the current platform
class ConsentManagerFacade {
  static ConsentManagerFacade? _instance;
  static ConsentManagerFacade get instance =>
      _instance ??= ConsentManagerFacade._();

  ConsentManagerFacade._();

  // Platform detection
  bool get isWebPlatform => kIsWeb;

  // Lazy initialization of platform-specific managers
  ImprovedConsentManager? _mobileManager;
  WebConsentHandler? _webHandler;

  ImprovedConsentManager get _mobile =>
      _mobileManager ??= ImprovedConsentManager.instance;
  WebConsentHandler get _web => _webHandler ??= WebConsentHandler.instance;

  /// Initialize the appropriate consent manager for the current platform
  Future<void> initialize() async {
    try {
      _log(
          'Initializing consent manager for ${isWebPlatform ? "web" : "mobile"} platform');

      if (isWebPlatform) {
        await _web.initialize();
      } else {
        _mobile.initializeAsync();
        // Wait a bit for mobile initialization to start
        await Future.delayed(const Duration(milliseconds: 100));
      }

      _log('Consent manager initialization completed');
    } catch (e) {
      _logError('Failed to initialize consent manager: $e');
      // Continue anyway - each platform should handle its own fallbacks
    }
  }

  /// Get current consent status
  ConsentStatus get consentStatus {
    if (isWebPlatform) {
      return _mapWebStatusToMobile(_web.consentStatus);
    } else {
      return _mobile.consentStatus;
    }
  }

  /// Check if ads can be requested
  bool get canRequestAds {
    try {
      if (isWebPlatform) {
        return _web.canRequestAds;
      } else {
        return _mobile.canRequestAds;
      }
    } catch (e) {
      _logError('Error checking canRequestAds: $e');
      // Return safe default
      return kDebugMode;
    }
  }

  /// Check if personalized ads can be shown
  bool get canShowPersonalizedAds {
    try {
      if (isWebPlatform) {
        return _web.canShowPersonalizedAds;
      } else {
        return _mobile.canShowPersonalizedAds;
      }
    } catch (e) {
      _logError('Error checking canShowPersonalizedAds: $e');
      // Return safe default
      return kDebugMode;
    }
  }

  /// Check if non-personalized ads can be shown
  bool get canShowNonPersonalizedAds {
    try {
      if (isWebPlatform) {
        return _web.canShowNonPersonalizedAds;
      } else {
        return _mobile.canShowNonPersonalizedAds;
      }
    } catch (e) {
      _logError('Error checking canShowNonPersonalizedAds: $e');
      // Return safe default
      return true;
    }
  }

  /// Create ad request with appropriate parameters
  AdRequest createAdRequest({
    List<String>? keywords,
    String? contentUrl,
    Map<String, String>? customTargeting,
  }) {
    try {
      if (isWebPlatform) {
        final extras = _web.createAdRequestExtras();
        if (customTargeting != null) {
          extras.addAll(customTargeting);
        }

        return AdRequest(
          keywords: keywords,
          contentUrl: contentUrl,
          extras: extras,
        );
      } else {
        return _mobile.createAdRequest(
          keywords: keywords,
          contentUrl: contentUrl,
          customTargeting: customTargeting,
        );
      }
    } catch (e) {
      _logError('Error creating ad request: $e');
      // Return basic ad request as fallback
      final Map<String, String> extras = {...?customTargeting};
      if (!canShowPersonalizedAds) {
        extras['npa'] = '1';
      }

      return AdRequest(
        keywords: keywords,
        contentUrl: contentUrl,
        extras: extras,
      );
    }
  }

  /// Request consent manually (e.g., from privacy settings)
  Future<ConsentFacadeResult> requestConsentManually() async {
    try {
      _log('Requesting consent manually');

      if (isWebPlatform) {
        // Show web-specific consent dialog
        final success = await _web.showConsentDialog();
        return ConsentFacadeResult(
          success: success,
          status: consentStatus,
          canRequestAds: canRequestAds,
          canShowPersonalizedAds: canShowPersonalizedAds,
          canShowNonPersonalizedAds: canShowNonPersonalizedAds,
          platform: 'web',
        );
      } else {
        // Use mobile consent manager
        final result = await _mobile.requestConsentManually();
        return ConsentFacadeResult(
          success: result.success,
          status: result.status,
          canRequestAds: result.canRequestAds,
          canShowPersonalizedAds: result.canShowPersonalizedAds,
          canShowNonPersonalizedAds: result.canShowNonPersonalizedAds,
          platform: 'mobile',
        );
      }
    } catch (e) {
      _logError('Failed to request consent manually: $e');
      return ConsentFacadeResult(
        success: false,
        status: consentStatus,
        canRequestAds: canRequestAds,
        canShowPersonalizedAds: canShowPersonalizedAds,
        canShowNonPersonalizedAds: canShowNonPersonalizedAds,
        platform: isWebPlatform ? 'web' : 'mobile',
        error: e.toString(),
      );
    }
  }

  /// Show privacy options form (mobile only)
  Future<bool> showPrivacyOptions() async {
    try {
      if (isWebPlatform) {
        _log('Privacy options not supported on web platform');
        // Fallback to manual consent request
        final result = await requestConsentManually();
        return result.success;
      } else {
        return await _mobile.showPrivacyOptions();
      }
    } catch (e) {
      _logError('Failed to show privacy options: $e');
      return false;
    }
  }

  /// Reset consent preferences
  Future<void> resetConsent() async {
    try {
      _log('Resetting consent preferences');

      if (isWebPlatform) {
        await _web.resetConsent();
      } else {
        await _mobile.resetConsent();
      }

      _log('Consent preferences reset successfully');
    } catch (e) {
      _logError('Failed to reset consent: $e');
    }
  }

  /// Update consent preferences (web platform specific)
  Future<bool> updateConsentPreferences({
    required bool allowPersonalizedAds,
    required bool allowNonPersonalizedAds,
  }) async {
    try {
      if (isWebPlatform) {
        return await _web.updateConsentPreferences(
          allowPersonalizedAds: allowPersonalizedAds,
          allowNonPersonalizedAds: allowNonPersonalizedAds,
        );
      } else {
        _log(
            'Consent preference updates not supported on mobile platform - use consent forms instead');
        return false;
      }
    } catch (e) {
      _logError('Failed to update consent preferences: $e');
      return false;
    }
  }

  /// Get debug information
  Map<String, dynamic> getDebugInfo() {
    try {
      final Map<String, dynamic> info = {
        'facade_platform': isWebPlatform ? 'web' : 'mobile',
        'debug_mode': kDebugMode,
        'timestamp': DateTime.now().toIso8601String(),
      };

      if (isWebPlatform) {
        info.addAll(_web.getDebugInfo());
      } else {
        info.addAll(_mobile.getDebugInfo());
      }

      return info;
    } catch (e) {
      _logError('Error getting debug info: $e');
      return {
        'facade_platform': isWebPlatform ? 'web' : 'mobile',
        'debug_mode': kDebugMode,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Get user-friendly status message
  String getStatusMessage() {
    try {
      if (isWebPlatform) {
        return _web.getStatusMessage();
      } else {
        // Create a status message for mobile platform
        switch (consentStatus) {
          case ConsentStatus.unknown:
            return 'Consent status unknown';
          case ConsentStatus.required:
            return 'Consent required for ads';
          case ConsentStatus.notRequired:
            return 'Consent not required (outside EEA)';
          case ConsentStatus.obtained:
            return 'Consent obtained for personalized ads';
        }
      }
    } catch (e) {
      _logError('Error getting status message: $e');
      return 'Consent status unavailable';
    }
  }

  /// Check if user has made a consent choice (web platform)
  Future<bool> hasUserMadeChoice() async {
    try {
      if (isWebPlatform) {
        return await _web.hasUserMadeChoice;
      } else {
        // On mobile, we can check if consent status is not unknown
        return consentStatus != ConsentStatus.unknown;
      }
    } catch (e) {
      _logError('Error checking user choice status: $e');
      return false;
    }
  }

  /// Validate that consent system is working properly
  Future<bool> validateConsentSystem() async {
    try {
      _log('Validating consent system');

      // Basic validation checks
      final canRequest = canRequestAds;
      final hasPersonalized = canShowPersonalizedAds;
      final hasNonPersonalized = canShowNonPersonalizedAds;

      _log(
          'Validation results - canRequest: $canRequest, personalized: $hasPersonalized, nonPersonalized: $hasNonPersonalized');

      // In debug mode, everything should work
      if (kDebugMode) {
        return true;
      }

      // At minimum, we should be able to request some type of ads
      return canRequest && (hasPersonalized || hasNonPersonalized);
    } catch (e) {
      _logError('Consent system validation failed: $e');
      return false;
    }
  }

  /// Map web consent status to mobile ConsentStatus enum
  ConsentStatus _mapWebStatusToMobile(WebConsentStatus webStatus) {
    switch (webStatus) {
      case WebConsentStatus.unknown:
        return ConsentStatus.unknown;
      case WebConsentStatus.granted:
        return ConsentStatus.obtained;
      case WebConsentStatus.limitedGranted:
        return ConsentStatus
            .obtained; // Limited consent still counts as obtained
      case WebConsentStatus.denied:
        return ConsentStatus.required;
      case WebConsentStatus.notRequired:
        return ConsentStatus.notRequired;
    }
  }

  /// Get platform-specific capability information
  Map<String, bool> getPlatformCapabilities() {
    return {
      'supportsConsentForms': !isWebPlatform,
      'supportsPrivacyOptions': !isWebPlatform,
      'supportsUmpSdk': !isWebPlatform,
      'supportsManualPreferences': isWebPlatform,
      'isWebPlatform': isWebPlatform,
      'isMobilePlatform': !isWebPlatform,
    };
  }

  /// Logging helpers
  void _log(String message) {
    if (kDebugMode) {
      print('[ConsentFacade] $message');
    }
  }

  void _logError(String message) {
    print('[ConsentFacade ERROR] $message');
  }
}

/// Result of consent operations through the facade
class ConsentFacadeResult {
  final bool success;
  final ConsentStatus status;
  final bool canRequestAds;
  final bool canShowPersonalizedAds;
  final bool canShowNonPersonalizedAds;
  final String platform;
  final String? error;

  ConsentFacadeResult({
    required this.success,
    required this.status,
    required this.canRequestAds,
    required this.canShowPersonalizedAds,
    required this.canShowNonPersonalizedAds,
    required this.platform,
    this.error,
  });

  @override
  String toString() {
    return 'ConsentFacadeResult(success: $success, status: $status, platform: $platform, error: $error)';
  }
}
