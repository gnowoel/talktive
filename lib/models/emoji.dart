import 'dart:math';

import 'package:unicode_emojis/unicode_emojis.dart' as emojis;

class Emoji {
  final String code;
  final String name;

  const Emoji({
    required this.code,
    required this.name,
  });

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
    };
  }

  factory Emoji.fromJson(Map<String, dynamic> json) {
    return Emoji(
      code: json['code'] as String,
      name: json['name'] as String,
    );
  }

  static Emoji random() {
    final randomEmoji = _collection[Random().nextInt(_collection.length)];

    return Emoji(
      code: randomEmoji.emoji,
      name: randomEmoji.name,
    );
  }

  static final List<emojis.Emoji> _collection = _emojis.where((emoji) {
    return _categories.contains(emoji.category) &&
        emoji.hasImgApple &&
        emoji.hasImgGoogle;
  }).toList();

  static const _emojis = emojis.UnicodeEmojis.allEmojis;

  static const List<emojis.Category> _categories = [
    emojis.Category.peopleAndBody,
    emojis.Category.animalsAndNature,
    emojis.Category.foodAndDrink,
    emojis.Category.travelAndPlaces,
    emojis.Category.activities,
    emojis.Category.objects,
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Emoji &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          name == other.name;

  @override
  int get hashCode => code.hashCode ^ name.hashCode;
}
