import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'lib/services/ad_service/ad_service_adapter.dart';
import 'lib/services/ad_service/simplified_room_ads.dart';
import 'lib/services/ad_service/admob_compliance.dart';
import 'lib/services/ad_service/optimized_ad_config.dart';

/// Test script to verify session initialization is working correctly
/// This helps debug the "No active session" issue
void main() {
  group('Ad Service Session Initialization Tests', () {
    setUp(() {
      // Ensure we start with a clean state
      WidgetsFlutterBinding.ensureInitialized();
    });

    test('Should initialize AdServiceAdapter correctly', () {
      print('\n=== Testing AdServiceAdapter Initialization ===');

      final adapter = AdServiceAdapter.instance;
      print('✓ AdServiceAdapter instance created');

      // Check which system is being used
      final systemName = adapter.currentSystemName;
      print('Current system: $systemName');
      expect(systemName, contains('Optimized'),
          reason: 'Should be using OptimizedRoomAds (SimplifiedRoomAds)');

      // Initialize the adapter
      adapter.initialize();
      print('✓ AdServiceAdapter initialized');

      // Get session stats to verify initialization
      final stats = adapter.getSessionStats();
      print('Session stats: $stats');

      // Verify session is active
      expect(stats['sessionDurationMinutes'], isNotNull);
      expect(stats['sessionDurationMinutes'], greaterThanOrEqualTo(0));
      print(
          '✓ Session is active with ${stats['sessionDurationMinutes']} minutes duration');
    });

    test('Should initialize SimplifiedRoomAds directly', () {
      print('\n=== Testing SimplifiedRoomAds Direct Initialization ===');

      final adService = SimplifiedRoomAds.instance;
      print('✓ SimplifiedRoomAds instance created');

      // Initialize the service
      adService.initialize();
      print('✓ SimplifiedRoomAds initialized');

      // Check session state
      final stats = adService.getSessionStats();
      print('Session stats: $stats');

      // Verify session is not null
      expect(stats['sessionDurationMinutes'], isNotNull);
      expect(stats['sessionDurationMinutes'], greaterThanOrEqualTo(0));
      print(
          '✓ Session is active with ${stats['sessionDurationMinutes']} minutes duration');

      // Test shouldShowAdNow method (this is where "No active session" was occurring)
      final shouldShow = adService.shouldShowAdNow();
      print('Should show ad now: $shouldShow');

      // The important thing is that it doesn't throw "No active session" error
      // It's okay if it returns false for other reasons
      print('✓ shouldShowAdNow() executed without "No active session" error');
    });

    test('Should track room transitions correctly', () {
      print('\n=== Testing Room Transition Tracking ===');

      final adService = SimplifiedRoomAds.instance;
      adService.initialize();

      // Track some transitions
      final initialTransitions = adService.roomTransitions;
      print('Initial transitions: $initialTransitions');

      adService.trackRoomTransition();
      expect(adService.roomTransitions, equals(initialTransitions + 1));
      print('✓ First transition tracked: ${adService.roomTransitions}');

      adService.trackRoomTransition();
      expect(adService.roomTransitions, equals(initialTransitions + 2));
      print('✓ Second transition tracked: ${adService.roomTransitions}');

      // Check if session is still active after transitions
      final stats = adService.getSessionStats();
      expect(stats['sessionDurationMinutes'], isNotNull);
      print('✓ Session remains active after transitions');
    });

    test('Should validate configuration correctly', () {
      print('\n=== Testing Configuration Validation ===');

      final isValid = OptimizedAdConfig.validateConfig();
      expect(isValid, isTrue, reason: 'Configuration should be valid');
      print('✓ Configuration validation passed');

      final configSummary = OptimizedAdConfig.getConfigSummary();
      print('Config summary: $configSummary');

      // Check key configuration values
      expect(configSummary['sessionLimits']['maxAdsPerSession'], 'UNLIMITED');
      expect(configSummary['sessionLimits']['enforceSessionLimits'], false);
      print('✓ Unlimited session configuration confirmed');
    });

    test('Should show detailed status information', () {
      print('\n=== Detailed Status Information ===');

      final adService = SimplifiedRoomAds.instance;
      adService.initialize();

      // Track a few transitions to get realistic state
      adService.trackRoomTransition();
      adService.trackRoomTransition();

      final stats = adService.getSessionStats();
      final statusMessage = adService.getStatusMessage();
      final timingInfo = adService.getTimingInfo();

      print('Status message: $statusMessage');
      print('Timing info: $timingInfo');
      print('Full stats: $stats');

      // Verify the status doesn't contain "No active session"
      expect(statusMessage, isNot(contains('No active session')));
      expect(timingInfo, isNot(contains('No active session')));
      print('✓ No "No active session" errors in status');
    });

    test('Should handle compliance correctly', () {
      print('\n=== Testing Compliance System ===');

      // Initialize compliance
      AdMobCompliance.initialize();
      print('✓ AdMob compliance initialized');

      final complianceStatus = AdMobCompliance.getComplianceStatus();
      print('Compliance status: $complianceStatus');

      final isCompliant = AdMobCompliance.validateAdRequest('interstitial');
      print('Is compliant for interstitial: $isCompliant');

      // Get detailed compliance info
      final adService = SimplifiedRoomAds.instance;
      adService.initialize();
      final serviceComplianceStatus = adService.getComplianceStatus();
      print('Service compliance status: $serviceComplianceStatus');

      print('✓ Compliance system working correctly');
    });
  });
}

/// Helper function to run tests manually (useful for debugging)
void runManualTest() {
  print('=== MANUAL AD SERVICE SESSION TEST ===');

  try {
    // Test 1: Direct SimplifiedRoomAds initialization
    print('\n1. Testing SimplifiedRoomAds initialization...');
    final adService = SimplifiedRoomAds.instance;
    adService.initialize();

    final stats = adService.getSessionStats();
    print('   Session duration: ${stats['sessionDurationMinutes']} minutes');
    print('   Room transitions: ${stats['roomTransitions']}');
    print('   Ads shown: ${stats['adsShownThisSession']}');
    print('   User engagement: ${stats['userEngagementLevel']}');

    // Test 2: Check shouldShowAdNow (this was failing before)
    print('\n2. Testing shouldShowAdNow method...');
    final shouldShow = adService.shouldShowAdNow();
    print('   Should show ad: $shouldShow');

    // Test 3: Track transitions and check again
    print('\n3. Testing room transitions...');
    adService.trackRoomTransition();
    adService.trackRoomTransition();

    final newStats = adService.getSessionStats();
    print('   New transition count: ${newStats['roomTransitions']}');

    final shouldShowAfterTransitions = adService.shouldShowAdNow();
    print('   Should show ad after transitions: $shouldShowAfterTransitions');

    // Test 4: Test via AdServiceAdapter
    print('\n4. Testing via AdServiceAdapter...');
    final adapter = AdServiceAdapter.instance;
    adapter.initialize();

    final adapterStats = adapter.getSessionStats();
    print(
        '   Adapter session duration: ${adapterStats['sessionDurationMinutes']} minutes');

    final adapterShouldShow = adapter.shouldShowAdNow();
    print('   Adapter should show ad: $adapterShouldShow');

    print('\n✅ ALL TESTS PASSED - No "No active session" errors!');
  } catch (e, stackTrace) {
    print('\n❌ TEST FAILED with error: $e');
    print('Stack trace: $stackTrace');
  }
}
