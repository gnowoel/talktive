import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:talktive/services/ad_service/admob_compliance.dart';

void main() {
  group('AdMobCompliance Tests', () {
    group('Test Ad Unit IDs', () {
      test('should have all required test ad unit IDs', () {
        final testIds = AdMobCompliance.testAdUnitIds;

        expect(testIds.containsKey('banner_android'), isTrue);
        expect(testIds.containsKey('banner_ios'), isTrue);
        expect(testIds.containsKey('interstitial_android'), isTrue);
        expect(testIds.containsKey('interstitial_ios'), isTrue);
        expect(testIds.containsKey('rewarded_android'), isTrue);
        expect(testIds.containsKey('rewarded_ios'), isTrue);

        // Verify they are Google's official test ad unit IDs
        expect(testIds['banner_android'],
            equals('ca-app-pub-3940256099942544/6300978111'));
        expect(testIds['banner_ios'],
            equals('ca-app-pub-3940256099942544/2934735716'));
        expect(testIds['interstitial_android'],
            equals('ca-app-pub-3940256099942544/1033173712'));
        expect(testIds['interstitial_ios'],
            equals('ca-app-pub-3940256099942544/4411468910'));
        expect(testIds['rewarded_android'],
            equals('ca-app-pub-3940256099942544/5224354917'));
        expect(testIds['rewarded_ios'],
            equals('ca-app-pub-3940256099942544/1712485313'));
      });

      test('should not have empty or null test ad unit IDs', () {
        final testIds = AdMobCompliance.testAdUnitIds;

        testIds.forEach((key, value) {
          expect(value, isNotNull);
          expect(value, isNotEmpty);
          expect(value, startsWith('ca-app-pub-'));
        });
      });
    });

    group('Compliance Status', () {
      test('should return correct compliance status structure', () async {
        final status = await AdMobCompliance.getComplianceStatus();

        expect(status, isA<Map<String, dynamic>>());
        expect(status['isCompliant'], isTrue);
        expect(status.containsKey('reason'), isTrue);
        expect(status.containsKey('isAdmin'), isTrue);
        expect(status.containsKey('isDebugMode'), isTrue);
        expect(status.containsKey('shouldUseTestAds'), isTrue);
        expect(status.containsKey('adUnitType'), isTrue);
        expect(status.containsKey('policyReference'), isTrue);
      });

      test('should have valid policy reference', () async {
        final status = await AdMobCompliance.getComplianceStatus();
        final policyRef = status['policyReference'] as String;

        expect(policyRef, isNotEmpty);
        expect(policyRef, contains('AdMob Policy'));
        expect(policyRef, contains('Publishers may not click their own ads'));
      });

      test('should validate compliance successfully', () {
        final isValid = AdMobCompliance.validateAdCompliance();
        expect(isValid, isTrue);
      });
    });

    group('User-Friendly Messages', () {
      test('should return non-empty user-friendly message', () {
        final message = AdMobCompliance.getUserFriendlyMessage();
        expect(message, isA<String>());
        expect(message, isNotEmpty);
      });

      test('should return string for admin notice', () {
        final notice = AdMobCompliance.getAdminNotice();
        expect(notice, isA<String>());
      });
    });

    group('Compliance Badge', () {
      test('should return appropriate badge in debug mode', () {
        final badge = AdMobCompliance.getComplianceBadge();
        if (kDebugMode) {
          expect(badge, equals('DEBUG'));
        } else {
          expect(badge, isA<String?>());
        }
      });
    });

    group('Ad Request Validation', () {
      test('should validate banner ad request', () async {
        final isValid = await AdMobCompliance.validateAdRequest('banner');
        expect(isValid, isTrue);
      });

      test('should validate interstitial ad request', () async {
        final isValid = await AdMobCompliance.validateAdRequest('interstitial');
        expect(isValid, isTrue);
      });

      test('should validate rewarded ad request', () async {
        final isValid = await AdMobCompliance.validateAdRequest('rewarded');
        expect(isValid, isTrue);
      });

      test('should handle unknown ad type gracefully', () async {
        final isValid = await AdMobCompliance.validateAdRequest('unknown');
        expect(isValid, isTrue); // Should still be valid (graceful handling)
      });
    });

    group('Detailed Compliance Info', () {
      test('should return detailed compliance information', () async {
        final info = await AdMobCompliance.getDetailedComplianceInfo();

        expect(info, isA<Map<String, dynamic>>());
        expect(info.containsKey('timestamp'), isTrue);
        expect(info.containsKey('userFriendlyMessage'), isTrue);
        expect(info.containsKey('complianceSummary'), isTrue);
        expect(info.containsKey('testAdUnitIds'), isTrue);
        expect(info.containsKey('isCompliant'), isTrue);
        expect(info.containsKey('reason'), isTrue);
        expect(info.containsKey('isAdmin'), isTrue);
        expect(info.containsKey('isDebugMode'), isTrue);
        expect(info.containsKey('shouldUseTestAds'), isTrue);
        expect(info.containsKey('adUnitType'), isTrue);
      });

      test('should have valid timestamp in detailed info', () async {
        final info = await AdMobCompliance.getDetailedComplianceInfo();
        final timestamp = info['timestamp'] as String;

        expect(timestamp, isNotEmpty);
        expect(() => DateTime.parse(timestamp), returnsNormally);
      });
    });

    group('Compliance Summary', () {
      test('should return non-empty compliance summary', () async {
        final summary = await AdMobCompliance.getComplianceSummary();
        expect(summary, isA<String>());
        expect(summary, isNotEmpty);
        expect(summary, startsWith('AdMob Compliance:'));
      });
    });

    group('Should Show Ads', () {
      test('should always return true for shouldShowAds', () {
        final shouldShow = AdMobCompliance.shouldShowAds();
        expect(shouldShow, isTrue);
      });
    });

    group('Compliance Monitoring', () {
      test('should indicate if compliance monitoring is active', () {
        final isActive = AdMobCompliance.isComplianceMonitoringActive;
        expect(isActive, isA<bool>());
      });

      test('should have appropriate log verbosity setting', () {
        final shouldLog = AdMobCompliance.shouldLogVerbose;
        expect(shouldLog, isA<bool>());
      });
    });

    group('Edge Cases', () {
      test('should handle initialization gracefully', () {
        expect(() => AdMobCompliance.initialize(), returnsNormally);
      });

      test('should handle safe logging with empty messages', () {
        expect(() => AdMobCompliance.safeLog(''), returnsNormally);
      });

      test('should handle logging with force flag', () {
        expect(() => AdMobCompliance.safeLog('test', forceLog: true),
            returnsNormally);
      });

      test('should handle null compliance warning gracefully', () {
        final warning = AdMobCompliance.getComplianceWarning();
        expect(warning, isA<String?>());
      });
    });

    group('Debug Mode Tests', () {
      test('should use test ads in debug mode', () {
        if (kDebugMode) {
          expect(AdMobCompliance.shouldUseTestAds, isTrue);
        }
      });

      test('should show debug badge in debug mode', () {
        if (kDebugMode) {
          final badge = AdMobCompliance.getComplianceBadge();
          expect(badge, equals('DEBUG'));
        }
      });
    });
  });
}
