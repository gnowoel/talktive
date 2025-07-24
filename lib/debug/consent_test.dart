import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/ad_service/consent_service.dart';
import '../services/ad_service/admob_compliance.dart';
import '../services/ad_service/ad_request_helper.dart';

/// Consent Test Script for Debug Mode Bypass Verification
///
/// This script tests that consent is properly bypassed in debug mode
/// and that ads can be requested without consent issues.
class ConsentTest {
  /// Run comprehensive consent bypass tests
  static Future<ConsentTestResults> runTests() async {
    debugPrint('🧪 Starting Consent Bypass Tests...');

    final results = ConsentTestResults();

    try {
      // Test 1: Check if we're in debug mode
      results.isDebugMode = kDebugMode;
      debugPrint('✓ Debug Mode: ${results.isDebugMode}');

      // Test 2: Initialize consent service
      final consentService = ConsentService.instance;
      results.consentServiceInitialized = await consentService.initialize();
      debugPrint(
          '✓ Consent Service Initialized: ${results.consentServiceInitialized}');

      // Test 3: Check consent bypass status
      results.consentBypassActive = consentService.isConsentBypassedInDebug();
      debugPrint('✓ Consent Bypass Active: ${results.consentBypassActive}');

      // Test 4: Check if ads can be requested
      results.canRequestAds = await consentService.canRequestAds();
      debugPrint('✓ Can Request Ads: ${results.canRequestAds}');

      // Test 5: Check personalized ads permission
      results.canShowPersonalizedAds =
          await consentService.canShowPersonalizedAds();
      debugPrint(
          '✓ Can Show Personalized Ads: ${results.canShowPersonalizedAds}');

      // Test 6: Check non-personalized ads permission
      results.canShowNonPersonalizedAds =
          await consentService.canShowNonPersonalizedAds();
      debugPrint(
          '✓ Can Show Non-Personalized Ads: ${results.canShowNonPersonalizedAds}');

      // Test 7: Get consent status
      results.consentStatus =
          (await consentService.getConsentStatus()).toString();
      debugPrint('✓ Consent Status: ${results.consentStatus}');

      // Test 8: Test AdMob compliance validation
      results.complianceValidationPassed =
          await AdMobCompliance.validateAdCompliance();
      debugPrint(
          '✓ Compliance Validation: ${results.complianceValidationPassed}');

      // Test 9: Test ad request validation
      final adRequestValidation =
          await AdRequestHelper.instance.validateAdRequest();
      results.adRequestValidationPassed = adRequestValidation.canRequestAds;
      results.adRequestValidationMessage = adRequestValidation.message;
      debugPrint(
          '✓ Ad Request Validation: ${results.adRequestValidationPassed}');
      debugPrint('  Message: ${results.adRequestValidationMessage}');

      // Test 10: Get debug information
      results.debugInfo = await consentService.getConsentDebugInfo();
      debugPrint('✓ Debug Info Retrieved: ${results.debugInfo != null}');

      // Overall test result
      results.overallSuccess = _evaluateOverallSuccess(results);

      debugPrint(
          '🎯 Overall Test Result: ${results.overallSuccess ? "PASS" : "FAIL"}');
    } catch (e) {
      debugPrint('❌ Test Exception: $e');
      results.exception = e.toString();
      results.overallSuccess = false;
    }

    debugPrint('🏁 Consent Bypass Tests Completed\n');
    return results;
  }

  /// Evaluate if all critical tests passed
  static bool _evaluateOverallSuccess(ConsentTestResults results) {
    if (!results.isDebugMode) {
      // If not in debug mode, different criteria apply
      return results.consentServiceInitialized &&
          results.complianceValidationPassed;
    }

    // In debug mode, consent should be bypassed and ads should work
    return results.consentServiceInitialized &&
        results.consentBypassActive &&
        results.canRequestAds &&
        results.canShowNonPersonalizedAds &&
        results.complianceValidationPassed &&
        results.adRequestValidationPassed;
  }

  /// Generate detailed test report
  static String generateReport(ConsentTestResults results) {
    final buffer = StringBuffer();

    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('         CONSENT BYPASS TEST REPORT');
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln();

    buffer.writeln('🔧 Environment:');
    buffer.writeln('   Debug Mode: ${results.isDebugMode ? "✅" : "❌"}');
    buffer.writeln('   Test Time: ${DateTime.now()}');
    buffer.writeln();

    buffer.writeln('🚀 Initialization:');
    buffer.writeln(
        '   Consent Service: ${results.consentServiceInitialized ? "✅" : "❌"}');
    buffer.writeln();

    buffer.writeln('🔐 Consent Bypass:');
    buffer.writeln(
        '   Bypass Active: ${results.consentBypassActive ? "✅" : "❌"}');
    buffer.writeln('   Can Request Ads: ${results.canRequestAds ? "✅" : "❌"}');
    buffer.writeln(
        '   Personalized Ads: ${results.canShowPersonalizedAds ? "✅" : "❌"}');
    buffer.writeln(
        '   Non-Personalized Ads: ${results.canShowNonPersonalizedAds ? "✅" : "❌"}');
    buffer.writeln('   Consent Status: ${results.consentStatus}');
    buffer.writeln();

    buffer.writeln('✅ Compliance Validation:');
    buffer.writeln(
        '   AdMob Compliance: ${results.complianceValidationPassed ? "✅" : "❌"}');
    buffer.writeln(
        '   Ad Request Validation: ${results.adRequestValidationPassed ? "✅" : "❌"}');
    if (results.adRequestValidationMessage != null) {
      buffer.writeln(
          '   Validation Message: ${results.adRequestValidationMessage}');
    }
    buffer.writeln();

    if (results.debugInfo != null) {
      buffer.writeln('🐛 Debug Information:');
      results.debugInfo!.forEach((key, value) {
        buffer.writeln('   $key: $value');
      });
      buffer.writeln();
    }

    if (results.exception != null) {
      buffer.writeln('❌ Exception:');
      buffer.writeln('   ${results.exception}');
      buffer.writeln();
    }

    buffer.writeln(
        '🎯 OVERALL RESULT: ${results.overallSuccess ? "✅ PASS" : "❌ FAIL"}');

    if (results.isDebugMode && !results.overallSuccess) {
      buffer.writeln();
      buffer.writeln('💡 Troubleshooting:');
      if (!results.consentBypassActive) {
        buffer.writeln(
            '   • Consent bypass is not active - check _disableConsentInDebug setting');
      }
      if (!results.canRequestAds) {
        buffer.writeln(
            '   • Cannot request ads - consent bypass may not be working');
      }
      if (!results.complianceValidationPassed) {
        buffer.writeln(
            '   • Compliance validation failed - check AdMob compliance settings');
      }
    }

    buffer.writeln('═══════════════════════════════════════');

    return buffer.toString();
  }

  /// Quick test method that can be called from anywhere
  static Future<void> quickTest() async {
    final results = await runTests();
    final report = generateReport(results);
    debugPrint(report);
  }
}

/// Test results container
class ConsentTestResults {
  bool isDebugMode = false;
  bool consentServiceInitialized = false;
  bool consentBypassActive = false;
  bool canRequestAds = false;
  bool canShowPersonalizedAds = false;
  bool canShowNonPersonalizedAds = false;
  String? consentStatus;
  bool complianceValidationPassed = false;
  bool adRequestValidationPassed = false;
  String? adRequestValidationMessage;
  Map<String, dynamic>? debugInfo;
  String? exception;
  bool overallSuccess = false;
}

/// Flutter widget to display test results
class ConsentTestWidget extends StatefulWidget {
  const ConsentTestWidget({super.key});

  @override
  State<ConsentTestWidget> createState() => _ConsentTestWidgetState();
}

class _ConsentTestWidgetState extends State<ConsentTestWidget> {
  ConsentTestResults? _results;
  bool _isRunning = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consent Bypass Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _isRunning ? null : _runTest,
              child: _isRunning
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Running Tests...'),
                      ],
                    )
                  : const Text('Run Consent Tests'),
            ),
            const SizedBox(height: 16),
            if (_results != null) ...[
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _results!.overallSuccess
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      border: Border.all(
                        color: _results!.overallSuccess
                            ? Colors.green
                            : Colors.red,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      ConsentTest.generateReport(_results!),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _runTest() async {
    setState(() {
      _isRunning = true;
    });

    try {
      final results = await ConsentTest.runTests();
      setState(() {
        _results = results;
      });
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }
}
