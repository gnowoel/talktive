import 'dart:math';

import 'package:unicode_emojis/unicode_emojis.dart';

class AvatarService {
  Emoji current = _randomEmoji();

  AvatarService._();

  static final AvatarService _instance = AvatarService._();

  static const _allEmojis = UnicodeEmojis.allEmojis;

  static Emoji _randomEmoji() {
    return _allEmojis[Random().nextInt(_allEmojis.length)];
  }

  factory AvatarService() => _instance;
}
