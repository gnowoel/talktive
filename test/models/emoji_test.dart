import 'package:flutter_test/flutter_test.dart';
import 'package:talktive/models/emoji.dart';

void main() {
  group('Emoji', () {
    final json = <String, dynamic>{
      'name': 'name',
      'code': 'code',
    };

    test('constructor', () {
      final emoji = Emoji(
        name: json['name'] as String,
        code: json['code'] as String,
      );

      expect(emoji, isA<Emoji>());
    });

    test('fromJson()', () {
      final emoji = Emoji.fromJson(json);

      expect(emoji, isA<Emoji>());
    });

    test('toJson()', () {
      final emojiObject = Emoji.fromJson(json);
      final emojiJson = emojiObject.toJson();

      expect(emojiJson['code'], equals(json['code']));
    });

    test('Emoji.random()', () {
      final emoji1 = Emoji.fromJson(json);
      final emoji2 = Emoji.random();

      expect(emoji1.name == emoji2.name, isFalse);
      expect(emoji1.code == emoji2.code, isFalse);
      expect(emoji2.name, isNotEmpty);
      expect(emoji2.code, isNotEmpty);
    });
  });
}
