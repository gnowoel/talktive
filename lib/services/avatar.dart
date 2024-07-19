import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:talktive/services/prefs.dart';
import 'package:unicode_emojis/unicode_emojis.dart' as emojis;

import '../models/emoji.dart';

class Avatar extends ChangeNotifier {
  Avatar._();

  static final Avatar _instance = Avatar._();

  factory Avatar() => _instance;

  final prefs = Prefs();

  late Emoji _emoji;

  String get name => _emoji.name;

  String get code => _emoji.code;

  void refresh() {
    final emoji = _randomEmoji();
    _saveEmoji(emoji); // no wait
  }

  Future<void> initEmoji() async {
    final string = await prefs.getString('emoji');

    if (string == null) {
      refresh();
      return;
    }

    try {
      _emoji = Emoji.fromJson(jsonDecode(string));
    } catch (e) {
      refresh();
    }
  }

  Future<void> _saveEmoji(Emoji emoji) async {
    _emoji = emoji;
    await prefs.setString('emoji', jsonEncode(emoji.toJson()));
    notifyListeners();
  }

  static Emoji _randomEmoji() {
    // TODO: Check availability in both Apple and Google platforms
    final randomEmoji =
        _selectedEmojis[Random().nextInt(_selectedEmojis.length)];
    return Emoji(
      name: randomEmoji.name,
      code: randomEmoji.emoji,
    );
  }

  static final List<emojis.Emoji> _selectedEmojis = _allEmojis
      .where((emoji) => _selectedCategories.contains(emoji.category))
      .toList();

  static const _allEmojis = emojis.UnicodeEmojis.allEmojis;

  static const List<emojis.Category> _selectedCategories = [
    emojis.Category.peopleAndBody,
    emojis.Category.animalsAndNature,
    emojis.Category.foodAndDrink,
    emojis.Category.travelAndPlaces,
    emojis.Category.activities,
    emojis.Category.objects,
  ];
}
