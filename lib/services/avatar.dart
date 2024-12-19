import 'package:flutter/material.dart';

import '../models/emoji.dart';

class Avatar extends ChangeNotifier {
  Avatar._() {
    init();
  }

  static final Avatar _instance = Avatar._();

  factory Avatar() => _instance;

  Emoji _emoji = Emoji.random();

  String get name => _emoji.name;

  String get code => _emoji.code;

  void refresh() {
    final emoji = _getNewEmoji();
    _saveEmoji(emoji);
  }

  void init() async {
    refresh();
  }

  Emoji _getNewEmoji() {
    var emoji = Emoji.random();
    if (emoji.code == _emoji.code || emoji.code == '\u{1f916}') {
      emoji = _getNewEmoji();
    }
    return emoji;
  }

  void _saveEmoji(Emoji emoji) {
    _emoji = emoji;
    notifyListeners();
  }
}
