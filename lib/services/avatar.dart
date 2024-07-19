import 'dart:math';

import 'package:flutter/material.dart';
import 'package:talktive/services/prefs.dart';
import 'package:unicode_emojis/unicode_emojis.dart';

class Avatar extends ChangeNotifier {
  Avatar._();

  static final Avatar _instance = Avatar._();

  factory Avatar() => _instance;

  final prefs = Prefs();

  late Emoji _emoji;

  String get name => _emoji.name;

  String get code => _emoji.emoji;

  void refresh() {
    final emoji = _randomEmoji();
    saveEmoji(emoji); // no wait
  }

  Future<void> saveEmoji(Emoji emoji) async {
    _emoji = emoji;
    await prefs.setString('emoji', emoji.toJson());
    notifyListeners();
  }

  Future<void> loadEmoji() async {
    final string = await prefs.getString('emoji');
    if (string == null) {
      refresh();
    } else {
      _emoji = Emoji.fromJson(string);
      notifyListeners();
    }
  }

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
}
