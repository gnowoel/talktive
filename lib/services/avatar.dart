import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/emoji.dart';
import 'prefs.dart';

class Avatar extends ChangeNotifier {
  Avatar._();

  static final Avatar _instance = Avatar._();

  factory Avatar() => _instance;

  final prefs = Prefs();

  late Emoji _emoji;

  String get name => _emoji.name;

  String get code => _emoji.code;

  void refresh() {
    final emoji = _getNewEmoji();
    _saveEmoji(emoji); // no wait
  }

  Future<void> init() async {
    final string = await prefs.getString('emoji');
    final emoji =
        string == null ? Emoji.random() : Emoji.fromJson(jsonDecode(string));

    await _saveEmoji(emoji);
  }

  Emoji _getNewEmoji() {
    var emoji = Emoji.random();
    if (emoji.code == _emoji.code || emoji.code == '\u{1f916}') {
      emoji = _getNewEmoji();
    }
    return emoji;
  }

  Future<void> _saveEmoji(Emoji emoji) async {
    _emoji = emoji;
    await prefs.setString('emoji', jsonEncode(emoji.toJson()));
    notifyListeners();
  }
}
