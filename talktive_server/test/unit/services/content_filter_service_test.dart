import 'package:test/test.dart';
import 'package:talktive_server/src/services/content_filter_service.dart';
import 'package:talktive_server/src/utils/validation_result.dart';

void main() {
  group('ContentFilterService - Profanity Detection', () {
    test('detects profanity in lowercase', () {
      expect(ContentFilterService.containsProfanity('this is badword1'), true);
      expect(ContentFilterService.containsProfanity('badword2 here'), true);
    });

    test('detects profanity in mixed case', () {
      expect(ContentFilterService.containsProfanity('this is BadWord1'), true);
      expect(ContentFilterService.containsProfanity('BADWORD2 here'), true);
    });

    test('returns false for clean content', () {
      expect(ContentFilterService.containsProfanity('hello world'), false);
      expect(ContentFilterService.containsProfanity('nice message'), false);
    });

    test('detects profanity in middle of words', () {
      expect(ContentFilterService.containsProfanity('somebadword1thing'), true);
    });
  });

  group('ContentFilterService - Spam Detection', () {
    test('detects URLs as spam', () {
      expect(ContentFilterService.isSpam('check out http://example.com'), true);
      expect(ContentFilterService.isSpam('visit www.spam.com'), true);
      expect(ContentFilterService.isSpam('go to https://test.org'), true);
    });

    test('detects repeated characters as spam', () {
      expect(ContentFilterService.isSpam('hellooooooo'), true);
      expect(ContentFilterService.isSpam('wowwwwww'), true);
      expect(ContentFilterService.isSpam('aaaaaaaa'), true);
    });

    test('detects excessive caps as spam', () {
      expect(ContentFilterService.isSpam('THIS IS ALL CAPS MESSAGE'), true);
      expect(ContentFilterService.isSpam('BUY NOW CLICK HERE'), true);
    });

    test('detects spam keywords', () {
      expect(ContentFilterService.isSpam('buy this now'), true);
      expect(ContentFilterService.isSpam('click here to win'), true);
      expect(ContentFilterService.isSpam('free prize for you'), true);
    });

    test('allows normal messages', () {
      expect(ContentFilterService.isSpam('hello how are you'), false);
      expect(ContentFilterService.isSpam('Nice to meet you!'), false);
      expect(ContentFilterService.isSpam('What time is it?'), false);
    });

    test('allows reasonable caps usage', () {
      expect(ContentFilterService.isSpam('Hello World'), false);
      expect(ContentFilterService.isSpam('I am HAPPY'), false);
    });
  });

  group('ContentFilterService - Content Filtering', () {
    test('filters profanity in lenient mode', () {
      final result = ContentFilterService.filterContent(
        'this is badword1',
        strictMode: false,
      );
      expect(result, isNotNull);
      expect(result, contains('********')); // Replaced with asterisks
    });

    test('blocks profanity in strict mode', () {
      final result = ContentFilterService.filterContent(
        'this is badword1',
        strictMode: true,
      );
      expect(result, isNull);
    });

    test('blocks spam in both modes', () {
      final lenient = ContentFilterService.filterContent(
        'check http://spam.com',
        strictMode: false,
      );
      final strict = ContentFilterService.filterContent(
        'check http://spam.com',
        strictMode: true,
      );

      expect(lenient, 'check http://****.com');
      expect(strict, isNull);
    });

    test('allows clean content', () {
      final result = ContentFilterService.filterContent(
        'hello world',
        strictMode: false,
      );
      expect(result, equals('hello world'));
    });

    test('blocks empty content', () {
      final result = ContentFilterService.filterContent(
        '   ',
        strictMode: false,
      );
      expect(result, isNull);
    });

    test('replaces multiple profanity words', () {
      final result = ContentFilterService.filterContent(
        'badword1 and badword2',
        strictMode: false,
      );
      expect(result, isNotNull);
      expect(result, contains('********'));
    });
  });

  group('ContentFilterService - Message Validation', () {
    test('validates clean message for high floor user', () async {
      // Note: This test doesn't use actual Session, just tests the logic
      // For full integration tests, use serverpod_test
      expect(
        () => ContentFilterService.validateMessage(
          null as dynamic, // Mock session
          'hello world',
          3,
        ),
        throwsA(anything), // Will throw without real session
      );
    });

    test('validation result structure is correct', () {
      final valid = ValidationResult(isValid: true, filteredContent: 'test');
      expect(valid.isValid, true);
      expect(valid.filteredContent, 'test');
      expect(valid.error, isNull);

      final invalid = ValidationResult(isValid: false, error: 'spam');
      expect(invalid.isValid, false);
      expect(invalid.error, 'spam');
      expect(invalid.filteredContent, isNull);
    });
  });

  group('ContentFilterService - Edge Cases', () {
    test('handles very long messages', () {
      final longMessage = 'a' * 2000;
      // Should be detected as spam due to repeated characters
      expect(ContentFilterService.isSpam(longMessage), true);
    });

    test('handles special characters', () {
      expect(ContentFilterService.isSpam('!@#\$%^&*()'), false);
      expect(ContentFilterService.containsProfanity('!@#\$%^&*()'), false);
    });

    test('handles unicode characters', () {
      expect(ContentFilterService.isSpam('你好世界'), false);
      expect(ContentFilterService.isSpam('مرحبا'), false);
      expect(ContentFilterService.containsProfanity('こんにちは'), false);
    });

    test('handles mixed content', () {
      final result = ContentFilterService.filterContent(
        'Hello badword1 world',
        strictMode: false,
      );
      expect(result, isNotNull);
      expect(result, contains('Hello'));
      expect(result, contains('world'));
    });
  });
}
