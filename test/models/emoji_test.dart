import 'package:flutter_test/flutter_test.dart';
import 'package:talktive/models/emoji.dart';

void main() {
  group('Emoji', () {
    final json1 = <String, dynamic>{
      'name': 'name1',
      'code': 'code1',
    };

    final json2 = <String, dynamic>{
      'name': 'name2',
      'code': 'code2',
    };

    test('constructor', () {
      final emoji = Emoji(
        name: json1['name'] as String,
        code: json1['code'] as String,
      );

      expect(emoji, isA<Emoji>());
    });

    test('fromJson()', () {
      final emoji = Emoji.fromJson(json1);

      expect(emoji, isA<Emoji>());
    });

    test('toJson()', () {
      final emojiObject = Emoji.fromJson(json1);
      final emojiJson = emojiObject.toJson();

      expect(emojiJson['code'], equals(json1['code']));
    });

    test('Emoji.random()', () {
      final emoji2 = Emoji.random();

      expect(emoji2.name, isNotEmpty);
      expect(emoji2.code, isNotEmpty);
    });

    test('==', () {
      final emoji1 = Emoji.fromJson(json1);
      final emoji2 = Emoji.fromJson(json1);

      expect(emoji1 == emoji2, isTrue);
      expect(emoji1.hashCode == emoji2.hashCode, isTrue);
    });

    test('!=', () {
      final emoji1 = Emoji.fromJson(json1);
      final emoji2 = Emoji.fromJson(json2);

      expect(emoji1 == emoji2, isFalse);
      expect(emoji1.hashCode == emoji2.hashCode, isFalse);
    });
  });
}
