import 'dart:math';

import 'package:flutter/material.dart';
import 'package:unicode_emojis/unicode_emojis.dart';

class Avatar extends ChangeNotifier {
  Emoji current = _randomEmoji();

  static Emoji _randomEmoji() {
    return _selectedEmojis[Random().nextInt(_selectedEmojis.length)];
  }

  static final List<Emoji> _selectedEmojis = _allEmojis
      .where((emoji) => _selectedCategories.contains(emoji.category))
      .toList();

  static const _allEmojis = UnicodeEmojis.allEmojis;

  static const List<Category> _selectedCategories = [
    Category.peopleAndBody,
    Category.animalsAndNature,
    Category.foodAndDrink,
    Category.travelAndPlaces,
    Category.activities,
    Category.objects,
  ];

  void refresh() {
    current = _randomEmoji();
    notifyListeners();
  }
}
