class AppInterests {
  static const List<String> all = [
    '🎮 Gaming & Games',
    '🎵 Music & Podcasting',
    '🎬 Movies & TV',
    '📚 Books & Writing',
    '🎨 Art & Design',
    '📷 Photography',
    '✈️ Travel & Culture',
    '🍴 Food & Dining',
    '⚽ Sports & Fitness',
    '🧘 Wellness & Health',
    '💻 Tech & Science',
    '🌌 Astronomy',
    '🌱 Nature & Pets',
    '👗 Fashion & Beauty',
    '💰 Business & Finance',
    '🏛️ History & Society',
    '⚖️ Law & Politics',
    '☕ Coffee & Tea',
    '🛠️ DIY & Crafts',
    '🧩 Puzzles & Strategy',
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
