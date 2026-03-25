/// Supported languages for the application
class AppLanguages {
  static const List<Map<String, String>> all = [
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
    {'code': 'es', 'name': 'Spanish', 'flag': '🇪🇸'},
    {'code': 'fr', 'name': 'French', 'flag': '🇫🇷'},
    {'code': 'de', 'name': 'German', 'flag': '🇩🇪'},
    {'code': 'it', 'name': 'Italian', 'flag': '🇮🇹'},
    {'code': 'pt', 'name': 'Portuguese', 'flag': '🇵🇹'},
    {'code': 'ru', 'name': 'Russian', 'flag': '🇷🇺'},
    {'code': 'ja', 'name': 'Japanese', 'flag': '🇯🇵'},
    {'code': 'ko', 'name': 'Korean', 'flag': '🇰🇷'},
    {'code': 'zh', 'name': 'Chinese', 'flag': '🇨🇳'},
    {'code': 'hi', 'name': 'Hindi', 'flag': '🇮🇳'},
    {'code': 'ar', 'name': 'Arabic', 'flag': '🇸🇦'},
    {'code': 'tr', 'name': 'Turkish', 'flag': '🇹🇷'},
    {'code': 'vi', 'name': 'Vietnamese', 'flag': '🇻🇳'},
    {'code': 'id', 'name': 'Indonesian', 'flag': '🇮🇩'},
    {'code': 'th', 'name': 'Thai', 'flag': '🇹🇭'},
    {'code': 'nl', 'name': 'Dutch', 'flag': '🇳🇱'},
    {'code': 'pl', 'name': 'Polish', 'flag': '🇵🇱'},
    {'code': 'sv', 'name': 'Swedish', 'flag': '🇸🇪'},
    {'code': 'no', 'name': 'Norwegian', 'flag': '🇳🇴'},
    {'code': 'fi', 'name': 'Finnish', 'flag': '🇫🇮'},
    {'code': 'da', 'name': 'Danish', 'flag': '🇩🇰'},
    {'code': 'el', 'name': 'Greek', 'flag': '🇬🇷'},
    {'code': 'uk', 'name': 'Ukrainian', 'flag': '🇺🇦'},
    {'code': 'he', 'name': 'Hebrew', 'flag': '🇮🇱'},
    {'code': 'fa', 'name': 'Persian', 'flag': '🇮🇷'},
    {'code': 'ms', 'name': 'Malay', 'flag': '🇲🇾'},
    {'code': 'tl', 'name': 'Tagalog', 'flag': '🇵🇭'},
  ];

  static String getFlag(String code) {
    return all.firstWhere(
      (l) => l['code'] == code,
      orElse: () => {'flag': '🌍'},
    )['flag']!;
  }

  static String getName(String code) {
    return all.firstWhere(
      (l) => l['code'] == code,
      orElse: () => {'name': code.toUpperCase()},
    )['name']!;
  }
}
