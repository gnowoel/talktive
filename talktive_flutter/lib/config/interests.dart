class AppInterests {
  static const List<String> all = [
    '🎮 Gaming',
    '🎵 Music',
    '🎬 Movies',
    '📚 Books',
    '🎨 Creative Arts',
    '📷 Photography',
    '✈️ Travel',
    '🍴 Food & Dining',
    '⚽ Sports',
    '💪 Fitness',
    '🧘 Wellness',
    '💻 Technology',
    '🌱 Nature',
    '🐕 Pets',
    '👗 Fashion',
    '🎭 Entertainment',
    '🔬 Science',
    '🌍 Culture',
    '💰 Business & Finance',
    '✍️ Writing',
    '🛠️ DIY & Crafts',
    '🚗 Automotive',
    '🎲 Games',
    '🌌 Astronomy',
    '🏛️ History',
    '☕ Coffee & Tea',
    '🥊 Martial Arts',
    '🎙️ Podcasting',
    '💄 Beauty',
    '🦾 Robotics',
    '🧩 Puzzles',
    '🏛️ Architecture',
    '⚖️ Law & Politics',
    '🎸 Musicians',
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
