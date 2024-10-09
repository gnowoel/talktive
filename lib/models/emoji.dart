import 'dart:math';

import 'package:unicode_emojis/unicode_emojis.dart' as emojis;

class Emoji {
  final String name;
  final String code;

  Emoji({
    required this.name,
    required this.code,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
    };
  }

  factory Emoji.fromJson(Map<String, dynamic> json) {
    return Emoji(
      name: json['name'] as String,
      code: json['code'] as String,
    );
  }

  static Emoji random() {
    final randomEmoji = _collection[Random().nextInt(_collection.length)];

    return Emoji(
      name: randomEmoji.name,
      code: randomEmoji.emoji,
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
          name == other.name &&
          code == other.code;

  @override
  int get hashCode => name.hashCode ^ code.hashCode;
}
