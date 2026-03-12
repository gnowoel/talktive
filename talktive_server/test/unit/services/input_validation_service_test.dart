import 'package:test/test.dart';
import 'package:talktive_server/src/services/input_validation_service.dart';

void main() {
  group('InputValidationService Tests', () {
    group('validateName', () {
      test('valid name returns success', () {
        final result = InputValidationService.validateName('John Doe');
        expect(result.isValid, isTrue);
      });

      test('empty name returns error', () {
        final result = InputValidationService.validateName('');
        expect(result.isValid, isFalse);
        expect(result.error, contains('cannot be empty'));
      });

      test('short name returns error', () {
        final result = InputValidationService.validateName('A');
        expect(result.isValid, isFalse);
        expect(result.error, contains('at least 2 characters'));
      });

      test('long name returns error', () {
        final longName = 'A' * 51;
        final result = InputValidationService.validateName(longName);
        expect(result.isValid, isFalse);
        expect(result.error, contains('50 characters or less'));
      });
    });

    group('validateGender', () {
      test('valid genders return success', () {
        expect(InputValidationService.validateGender('male').isValid, isTrue);
        expect(InputValidationService.validateGender('female').isValid, isTrue);
        expect(
          InputValidationService.validateGender('non-binary').isValid,
          isTrue,
        );
        expect(
          InputValidationService.validateGender('prefer-not-to-say').isValid,
          isTrue,
        );
      });

      test('invalid gender returns error', () {
        final result = InputValidationService.validateGender('robot');
        expect(result.isValid, isFalse);
        expect(result.error, contains('Invalid gender selection'));
      });
    });

    group('validateMessageContent', () {
      test('valid message returns success', () {
        final result = InputValidationService.validateMessageContent(
          'Hello world',
        );
        expect(result.isValid, isTrue);
      });

      test('empty message returns error', () {
        final result = InputValidationService.validateMessageContent('   ');
        expect(result.isValid, isFalse);
      });

      test('overly long message returns error', () {
        final longMessage = 'M' * 2001;
        final result = InputValidationService.validateMessageContent(
          longMessage,
        );
        expect(result.isValid, isFalse);
      });
    });

    group('validatePagination', () {
      test('valid pagination returns success', () {
        final result = InputValidationService.validatePagination(
          limit: 20,
          offset: 0,
        );
        expect(result.isValid, isTrue);
      });

      test('invalid limit returns error', () {
        expect(
          InputValidationService.validatePagination(
            limit: 0,
            offset: 0,
          ).isValid,
          isFalse,
        );
        expect(
          InputValidationService.validatePagination(
            limit: 101,
            offset: 0,
          ).isValid,
          isFalse,
        );
      });

      test('negative offset returns error', () {
        final result = InputValidationService.validatePagination(
          limit: 20,
          offset: -1,
        );
        expect(result.isValid, isFalse);
      });
    });

    group('validateStringList', () {
      test('valid list returns success', () {
        final result = InputValidationService.validateStringList([
          'gaming',
          'coding',
        ], 'Interests');
        expect(result.isValid, isTrue);
      });

      test('list with empty items returns error', () {
        final result = InputValidationService.validateStringList([
          'gaming',
          '',
        ], 'Interests');
        expect(result.isValid, isFalse);
      });

      test('too many items returns error', () {
        final items = List.generate(11, (i) => 'Item $i');
        final result = InputValidationService.validateStringList(
          items,
          'Interests',
        );
        expect(result.isValid, isFalse);
      });
    });
  });
}
