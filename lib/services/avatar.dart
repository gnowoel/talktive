import 'dart:math';

import 'package:flutter/material.dart';
import 'package:unicode_emojis/unicode_emojis.dart';

class Avatar extends ChangeNotifier {
  Emoji current = _randomEmoji();

  static const _allEmojis = UnicodeEmojis.allEmojis;

  static Emoji _randomEmoji() {
    return _allEmojis[Random().nextInt(_allEmojis.length)];
  }

  void refresh() {
    current = _randomEmoji();
    notifyListeners();
  }
}
