class AppInterests {
  static const List<String> all = [
    // --- ⚽ SPORTS & FITNESS ---
    '⚽ Sports & Fitness',
    '🧘 Wellness & Health',
    '🚵 Adventure & Outdoors',

    // --- 🎮 ENTERTAINMENT ---
    '🎮 Gaming & Arcade',
    '🎵 Music & Audio',
    '🎬 Movies & Shows',
    '📷 Photography & Art',

    // --- 💻 TECH & WORK ---
    '💻 Tech & Software',
    '🔬 Science & Innovation',
    '💰 Business & Finance',

    // --- 🍴 LIFESTYLE ---
    '🍴 Food & Cooking',
    '☕ Coffee & Chill',
    '👗 Fashion & Style',
    '🌱 Pets & Nature',

    // --- 📚 CULTURE & LEARNING ---
    '📚 Reading & Writing',
    '🏛️ History & Culture',
    '🌍 Travel & World',
    '🧩 Hobbies & DIY',
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
