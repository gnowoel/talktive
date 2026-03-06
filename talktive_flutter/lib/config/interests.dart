class AppInterests {
  static const List<String> all = [
    '🎮 Gaming',
    '🎵 Music',
    '🎬 Movies',
    '📚 Books',
    '🎨 Art',
    '📷 Photography',
    '✈️ Travel',
    '🍔 Food',
    '💪 Fitness',
    '🧘 Yoga',
    '⚽ Sports',
    '💻 Tech',
    '🌱 Nature',
    '🐕 Pets',
    '👗 Fashion',
    '💄 Beauty',
    '🎭 Theater',
    '🎪 Comedy',
    '🔬 Science',
    '🌍 Culture',
    '💰 Crypto',
    '📈 Trading',
    '🎯 Business',
    '🚀 Startups',
  ];

  /// Gets the interest without the emoji.
  static String getName(String interest) {
    if (interest.isEmpty) return interest;
    final parts = interest.split(' ');
    if (parts.length > 1) {
      return parts.sublist(1).join(' ');
    }
    return interest;
  }

  /// Gets the emoji from the interest string.
  static String getEmoji(String interest) {
    if (interest.isEmpty) return '';
    final parts = interest.split(' ');
    if (parts.isNotEmpty) {
      return parts[0];
    }
    return '';
  }
}
