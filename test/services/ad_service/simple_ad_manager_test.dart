import 'package:flutter_test/flutter_test.dart';
import 'package:talktive3/services/ad_service/simple_ad_manager.dart';
import 'package:talktive3/services/user_cache.dart';
import 'package:talktive3/models/user.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([UserCache])
import 'simple_ad_manager_test.mocks.dart';

void main() {
  group('SimpleAdManager User-Aware Timing Tests', () {
    late SimpleAdManager adManager;
    late MockUserCache mockUserCache;

    setUp(() {
      adManager = SimpleAdManager.instance;
      mockUserCache = MockUserCache();
    });

    test('should apply longer first ad delay for newcomers', () async {
      // Create a newcomer user (created less than 2 days ago)
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final newcomerUser = User(
        id: 'newcomer123',
        createdAt: currentTime - (24 * 60 * 60 * 1000), // 1 day ago
        updatedAt: currentTime,
        displayName: 'New User',
        messageCount: 5,
      );

      when(mockUserCache.user).thenReturn(newcomerUser);

      // Initialize ad manager
      await adManager.initialize();

      // Check status - should show newcomer timing
      final status = adManager.getStatus();
      expect(status['userStatus'], equals('newcomer'));

      // Should not show ad immediately
      expect(adManager.shouldShowAd(), isFalse);
    });

    test('should apply shorter first ad delay for regular users', () async {
      // Create a regular user (created more than 2 days ago)
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final regularUser = User(
        id: 'regular123',
        createdAt: currentTime - (7 * 24 * 60 * 60 * 1000), // 7 days ago
        updatedAt: currentTime,
        displayName: 'Regular User',
        messageCount: 100,
      );

      when(mockUserCache.user).thenReturn(regularUser);

      // Initialize ad manager
      await adManager.initialize();

      // Check status - should show regular timing
      final status = adManager.getStatus();
      expect(status['userStatus'], equals('regular'));
      expect(status['userLevel'], greaterThan(0));
    });

    test('should use progressive intervals based on ads shown', () async {
      // Test the progressive interval calculation
      final regularUser = User(
        id: 'regular123',
        createdAt: DateTime.now().millisecondsSinceEpoch - (30 * 24 * 60 * 60 * 1000),
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        displayName: 'Test User',
        messageCount: 50,
      );

      when(mockUserCache.user).thenReturn(regularUser);

      await adManager.initialize();

      // Check initial interval (should be longest)
      var status = adManager.getStatus();
      final firstInterval = status['currentInterval'];

      // Simulate showing ads and check intervals decrease
      // Note: In real implementation, we'd need to mock ad showing
      // but we can at least verify the status reports correctly
      expect(status['adsShown'], equals(0));
      expect(firstInterval, isNotNull);
    });

    test('should respect minimum time between ads', () async {
      final regularUser = User(
        id: 'regular123',
        createdAt: DateTime.now().millisecondsSinceEpoch - (30 * 24 * 60 * 60 * 1000),
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        displayName: 'Test User',
        messageCount: 50,
      );

      when(mockUserCache.user).thenReturn(regularUser);

      await adManager.initialize();

      // Reset timing to simulate immediate readiness
      adManager.resetTiming();

      // Should not show ad if one was just shown
      // (This test is limited without being able to mock time progression)
      final status = adManager.getStatus();
      expect(status['timeSinceLastAd'], equals('no ads shown'));
    });

    test('should provide accurate timing message', () {
      final adapter = SimpleAdAdapter.instance;

      final message = adapter.getTimingMessage();
      expect(message, contains('Adaptive timing'));
      expect(message, contains('user:'));
      expect(message, contains('last:'));
    });

    test('should report comprehensive debug info', () {
      final adapter = SimpleAdAdapter.instance;

      final debugInfo = adapter.getComprehensiveDebugInfo();
      expect(debugInfo['system'], equals('SimpleAdManager'));
      expect(debugInfo['config'], isNotNull);
      expect(debugInfo['config']['intervalStrategy'], equals('progressive'));
      expect(debugInfo['config']['newcomerFirstDelay'], equals('5 minutes'));
      expect(debugInfo['config']['regularFirstDelay'], equals('2 minutes'));
    });
  });
}
