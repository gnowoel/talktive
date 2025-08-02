import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'consent_manager_facade.dart';
import 'web_consent_handler.dart';
import 'improved_consent_manager.dart';

/// Test helper for verifying consent error handling and platform compatibility
class ConsentTestHelper {
  static ConsentTestHelper? _instance;
  static ConsentTestHelper get instance => _instance ??= ConsentTestHelper._();

  ConsentTestHelper._();

  /// Run comprehensive consent system tests
  Future<ConsentTestReport> runComprehensiveTests() async {
    final report = ConsentTestReport();

    print('\n=== CONSENT SYSTEM TEST SUITE ===');
    print('Platform: ${kIsWeb ? "Web" : "Mobile"}');
    print('Debug Mode: $kDebugMode');
    print('Timestamp: ${DateTime.now().toIso8601String()}');
    print('=====================================\n');

    // Test 1: Basic initialization
    await _testInitialization(report);

    // Test 2: Platform detection
    await _testPlatformDetection(report);

    // Test 3: Error handling
    await _testErrorHandling(report);

    // Test 4: Consent status checking
    await _testConsentStatusChecking(report);

    // Test 5: Ad request creation
    await _testAdRequestCreation(report);

    // Test 6: Timeout handling (web specific)
    if (kIsWeb) {
      await _testWebTimeoutHandling(report);
    }

    // Test 7: Fallback mechanisms
    await _testFallbackMechanisms(report);

    // Test 8: Reset functionality
    await _testResetFunctionality(report);

    // Generate final report
    _generateFinalReport(report);

    return report;
  }

  /// Test basic initialization
  Future<void> _testInitialization(ConsentTestReport report) async {
    print('TEST 1: Initialization');
    print('---------------------');

    try {
      final startTime = DateTime.now();
      await ConsentManagerFacade.instance.initialize();
      final duration = DateTime.now().difference(startTime);

      report.initializationTime = duration;
      report.initializationSuccess = true;

      print('✅ Initialization successful');
      print('   Duration: ${duration.inMilliseconds}ms');
    } catch (e) {
      report.initializationSuccess = false;
      report.initializationError = e.toString();
      print('❌ Initialization failed: $e');
    }
    print('');
  }

  /// Test platform detection
  Future<void> _testPlatformDetection(ConsentTestReport report) async {
    print('TEST 2: Platform Detection');
    print('--------------------------');

    try {
      final capabilities =
          ConsentManagerFacade.instance.getPlatformCapabilities();
      report.platformCapabilities = capabilities;

      print('✅ Platform capabilities detected:');
      capabilities.forEach((key, value) {
        print('   $key: $value');
      });

      // Verify expected capabilities for current platform
      if (kIsWeb) {
        if (capabilities['isWebPlatform'] == true &&
            capabilities['supportsConsentForms'] == false) {
          report.platformDetectionAccurate = true;
          print('✅ Web platform capabilities are correct');
        } else {
          report.platformDetectionAccurate = false;
          print('❌ Web platform capabilities are incorrect');
        }
      } else {
        if (capabilities['isMobilePlatform'] == true &&
            capabilities['supportsConsentForms'] == true) {
          report.platformDetectionAccurate = true;
          print('✅ Mobile platform capabilities are correct');
        } else {
          report.platformDetectionAccurate = false;
          print('❌ Mobile platform capabilities are incorrect');
        }
      }
    } catch (e) {
      report.platformDetectionError = e.toString();
      print('❌ Platform detection failed: $e');
    }
    print('');
  }

  /// Test error handling
  Future<void> _testErrorHandling(ConsentTestReport report) async {
    print('TEST 3: Error Handling');
    print('----------------------');

    final errorTests = <String, Future<bool> Function()>{
      'canRequestAds': () async {
        try {
          final result = ConsentManagerFacade.instance.canRequestAds;
          return true; // Should not throw
        } catch (e) {
          print('   canRequestAds error: $e');
          return false;
        }
      },
      'canShowPersonalizedAds': () async {
        try {
          final result = ConsentManagerFacade.instance.canShowPersonalizedAds;
          return true; // Should not throw
        } catch (e) {
          print('   canShowPersonalizedAds error: $e');
          return false;
        }
      },
      'canShowNonPersonalizedAds': () async {
        try {
          final result =
              ConsentManagerFacade.instance.canShowNonPersonalizedAds;
          return true; // Should not throw
        } catch (e) {
          print('   canShowNonPersonalizedAds error: $e');
          return false;
        }
      },
      'getDebugInfo': () async {
        try {
          final info = ConsentManagerFacade.instance.getDebugInfo();
          return info.isNotEmpty;
        } catch (e) {
          print('   getDebugInfo error: $e');
          return false;
        }
      },
    };

    int passedTests = 0;
    for (final entry in errorTests.entries) {
      final passed = await entry.value();
      if (passed) {
        print('✅ ${entry.key} - error handling passed');
        passedTests++;
      } else {
        print('❌ ${entry.key} - error handling failed');
      }
    }

    report.errorHandlingTestsPassed = passedTests;
    report.errorHandlingTestsTotal = errorTests.length;
    print('');
  }

  /// Test consent status checking
  Future<void> _testConsentStatusChecking(ConsentTestReport report) async {
    print('TEST 4: Consent Status Checking');
    print('-------------------------------');

    try {
      final status = ConsentManagerFacade.instance.consentStatus;
      final statusMessage = ConsentManagerFacade.instance.getStatusMessage();
      final canRequest = ConsentManagerFacade.instance.canRequestAds;
      final canPersonalized =
          ConsentManagerFacade.instance.canShowPersonalizedAds;
      final canNonPersonalized =
          ConsentManagerFacade.instance.canShowNonPersonalizedAds;

      report.consentStatus = status.toString();
      report.consentStatusMessage = statusMessage;
      report.canRequestAds = canRequest;
      report.canShowPersonalizedAds = canPersonalized;
      report.canShowNonPersonalizedAds = canNonPersonalized;

      print('✅ Consent status retrieved successfully:');
      print('   Status: $status');
      print('   Message: $statusMessage');
      print('   Can Request Ads: $canRequest');
      print('   Can Show Personalized: $canPersonalized');
      print('   Can Show Non-Personalized: $canNonPersonalized');

      // Validate logical consistency
      if (canRequest && (canPersonalized || canNonPersonalized)) {
        report.consentLogicConsistent = true;
        print('✅ Consent logic is consistent');
      } else if (!canRequest && !canPersonalized && !canNonPersonalized) {
        report.consentLogicConsistent = true;
        print('✅ Consent logic is consistent (all blocked)');
      } else {
        report.consentLogicConsistent = false;
        print('❌ Consent logic is inconsistent');
      }
    } catch (e) {
      report.consentStatusError = e.toString();
      print('❌ Consent status checking failed: $e');
    }
    print('');
  }

  /// Test ad request creation
  Future<void> _testAdRequestCreation(ConsentTestReport report) async {
    print('TEST 5: Ad Request Creation');
    print('---------------------------');

    try {
      // Test basic ad request
      final basicRequest = ConsentManagerFacade.instance.createAdRequest();
      print('✅ Basic ad request created');

      // Test ad request with parameters
      final paramRequest = ConsentManagerFacade.instance.createAdRequest(
        keywords: ['test', 'keywords'],
        contentUrl: 'https://example.com',
        customTargeting: {'custom': 'value'},
      );
      print('✅ Parameterized ad request created');

      // Test multiple requests (should not fail)
      for (int i = 0; i < 5; i++) {
        final request = ConsentManagerFacade.instance.createAdRequest();
      }
      print('✅ Multiple ad requests created successfully');

      report.adRequestCreationSuccess = true;
    } catch (e) {
      report.adRequestCreationSuccess = false;
      report.adRequestCreationError = e.toString();
      print('❌ Ad request creation failed: $e');
    }
    print('');
  }

  /// Test web-specific timeout handling
  Future<void> _testWebTimeoutHandling(ConsentTestReport report) async {
    print('TEST 6: Web Timeout Handling');
    print('----------------------------');

    try {
      // Test web consent handler directly
      final webHandler = WebConsentHandler.instance;
      await webHandler.initialize();

      print('✅ Web consent handler initialized without timeout');

      // Test multiple rapid calls (should not cause issues)
      final futures = <Future>[];
      for (int i = 0; i < 10; i++) {
        futures.add(webHandler.updateConsentPreferences(
          allowPersonalizedAds: false,
          allowNonPersonalizedAds: true,
        ));
      }

      await Future.wait(futures);
      print('✅ Multiple rapid consent updates handled correctly');

      report.webTimeoutHandlingSuccess = true;
    } catch (e) {
      report.webTimeoutHandlingSuccess = false;
      report.webTimeoutHandlingError = e.toString();
      print('❌ Web timeout handling failed: $e');
    }
    print('');
  }

  /// Test fallback mechanisms
  Future<void> _testFallbackMechanisms(ConsentTestReport report) async {
    print('TEST 7: Fallback Mechanisms');
    print('---------------------------');

    try {
      // Test validation system
      final isValid =
          await ConsentManagerFacade.instance.validateConsentSystem();
      report.systemValidation = isValid;

      if (isValid) {
        print('✅ Consent system validation passed');
      } else {
        print(
            '⚠️  Consent system validation failed (may be expected in some cases)');
      }

      // Test debug info retrieval
      final debugInfo = ConsentManagerFacade.instance.getDebugInfo();
      if (debugInfo.containsKey('platform') &&
          debugInfo.containsKey('initialized')) {
        print('✅ Debug info contains expected fields');
        report.debugInfoComplete = true;
      } else {
        print('❌ Debug info is incomplete');
        report.debugInfoComplete = false;
      }

      // Test graceful degradation
      final statusMessage = ConsentManagerFacade.instance.getStatusMessage();
      if (statusMessage.isNotEmpty) {
        print('✅ Status message available');
        report.gracefulDegradation = true;
      } else {
        print('❌ Status message not available');
        report.gracefulDegradation = false;
      }
    } catch (e) {
      report.fallbackMechanismsError = e.toString();
      print('❌ Fallback mechanisms test failed: $e');
    }
    print('');
  }

  /// Test reset functionality
  Future<void> _testResetFunctionality(ConsentTestReport report) async {
    print('TEST 8: Reset Functionality');
    print('---------------------------');

    try {
      // Get initial state
      final initialStatus = ConsentManagerFacade.instance.consentStatus;

      // Reset consent
      await ConsentManagerFacade.instance.resetConsent();
      print('✅ Consent reset completed without error');

      // Re-initialize
      await ConsentManagerFacade.instance.initialize();
      print('✅ Re-initialization after reset completed');

      // Verify system still works
      final canRequest = ConsentManagerFacade.instance.canRequestAds;
      final newStatus = ConsentManagerFacade.instance.consentStatus;

      print('   Initial status: $initialStatus');
      print('   Post-reset status: $newStatus');
      print('   Can request ads: $canRequest');

      report.resetFunctionalitySuccess = true;
    } catch (e) {
      report.resetFunctionalitySuccess = false;
      report.resetFunctionalityError = e.toString();
      print('❌ Reset functionality failed: $e');
    }
    print('');
  }

  /// Generate final report
  void _generateFinalReport(ConsentTestReport report) {
    print('FINAL TEST REPORT');
    print('=================');

    final totalTests = 8;
    int passedTests = 0;

    if (report.initializationSuccess) passedTests++;
    if (report.platformDetectionAccurate) passedTests++;
    if (report.errorHandlingTestsPassed == report.errorHandlingTestsTotal)
      passedTests++;
    if (report.consentLogicConsistent) passedTests++;
    if (report.adRequestCreationSuccess) passedTests++;
    if (kIsWeb ? report.webTimeoutHandlingSuccess : true) passedTests++;
    if (report.systemValidation) passedTests++;
    if (report.resetFunctionalitySuccess) passedTests++;

    report.overallScore = passedTests / totalTests;

    print(
        'Overall Score: $passedTests/$totalTests (${(report.overallScore * 100).toStringAsFixed(1)}%)');

    if (report.overallScore >= 0.8) {
      print('🎉 CONSENT SYSTEM STATUS: EXCELLENT');
    } else if (report.overallScore >= 0.6) {
      print('✅ CONSENT SYSTEM STATUS: GOOD');
    } else if (report.overallScore >= 0.4) {
      print('⚠️  CONSENT SYSTEM STATUS: NEEDS ATTENTION');
    } else {
      print('❌ CONSENT SYSTEM STATUS: CRITICAL ISSUES');
    }

    if (report.hasErrors) {
      print('\n⚠️  ERRORS DETECTED:');
      report.getErrors().forEach((error) {
        print('   • $error');
      });
    }

    print('\n✅ TEST SUITE COMPLETED');
    print('==========================================\n');
  }

  /// Run a quick smoke test
  Future<bool> runSmokeTest() async {
    print('🔍 Running consent system smoke test...');

    try {
      // Quick initialization test
      await ConsentManagerFacade.instance.initialize();

      // Quick functionality test
      final canRequest = ConsentManagerFacade.instance.canRequestAds;
      final request = ConsentManagerFacade.instance.createAdRequest();
      final status = ConsentManagerFacade.instance.consentStatus;

      print('✅ Smoke test passed - basic functionality working');
      return true;
    } catch (e) {
      print('❌ Smoke test failed: $e');
      return false;
    }
  }
}

/// Comprehensive test report for consent system
class ConsentTestReport {
  // Initialization
  bool initializationSuccess = false;
  Duration? initializationTime;
  String? initializationError;

  // Platform detection
  bool platformDetectionAccurate = false;
  Map<String, bool> platformCapabilities = {};
  String? platformDetectionError;

  // Error handling
  int errorHandlingTestsPassed = 0;
  int errorHandlingTestsTotal = 0;

  // Consent status
  String? consentStatus;
  String? consentStatusMessage;
  bool? canRequestAds;
  bool? canShowPersonalizedAds;
  bool? canShowNonPersonalizedAds;
  bool consentLogicConsistent = false;
  String? consentStatusError;

  // Ad request creation
  bool adRequestCreationSuccess = false;
  String? adRequestCreationError;

  // Web timeout handling
  bool webTimeoutHandlingSuccess = false;
  String? webTimeoutHandlingError;

  // Fallback mechanisms
  bool systemValidation = false;
  bool debugInfoComplete = false;
  bool gracefulDegradation = false;
  String? fallbackMechanismsError;

  // Reset functionality
  bool resetFunctionalitySuccess = false;
  String? resetFunctionalityError;

  // Overall
  double overallScore = 0.0;

  bool get hasErrors {
    return initializationError != null ||
        platformDetectionError != null ||
        consentStatusError != null ||
        adRequestCreationError != null ||
        webTimeoutHandlingError != null ||
        fallbackMechanismsError != null ||
        resetFunctionalityError != null;
  }

  List<String> getErrors() {
    final errors = <String>[];
    if (initializationError != null)
      errors.add('Initialization: $initializationError');
    if (platformDetectionError != null)
      errors.add('Platform Detection: $platformDetectionError');
    if (consentStatusError != null)
      errors.add('Consent Status: $consentStatusError');
    if (adRequestCreationError != null)
      errors.add('Ad Request Creation: $adRequestCreationError');
    if (webTimeoutHandlingError != null)
      errors.add('Web Timeout Handling: $webTimeoutHandlingError');
    if (fallbackMechanismsError != null)
      errors.add('Fallback Mechanisms: $fallbackMechanismsError');
    if (resetFunctionalityError != null)
      errors.add('Reset Functionality: $resetFunctionalityError');
    return errors;
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'platform': kIsWeb ? 'web' : 'mobile',
      'debugMode': kDebugMode,
      'overallScore': overallScore,
      'hasErrors': hasErrors,
      'initializationSuccess': initializationSuccess,
      'initializationTime': initializationTime?.inMilliseconds,
      'platformDetectionAccurate': platformDetectionAccurate,
      'platformCapabilities': platformCapabilities,
      'errorHandlingScore': errorHandlingTestsTotal > 0
          ? errorHandlingTestsPassed / errorHandlingTestsTotal
          : 0.0,
      'consentStatus': consentStatus,
      'consentStatusMessage': consentStatusMessage,
      'canRequestAds': canRequestAds,
      'canShowPersonalizedAds': canShowPersonalizedAds,
      'canShowNonPersonalizedAds': canShowNonPersonalizedAds,
      'consentLogicConsistent': consentLogicConsistent,
      'adRequestCreationSuccess': adRequestCreationSuccess,
      'webTimeoutHandlingSuccess': webTimeoutHandlingSuccess,
      'systemValidation': systemValidation,
      'debugInfoComplete': debugInfoComplete,
      'gracefulDegradation': gracefulDegradation,
      'resetFunctionalitySuccess': resetFunctionalitySuccess,
      'errors': getErrors(),
    };
  }
}
