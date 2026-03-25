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
    '⚽ Soccer',
    '🏀 Basketball',
    '🎾 Tennis',
    '🏐 Volleyball',
    '🏈 Football',
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
    '✍️ Writing',
    '🍳 Cooking',
    '🛠️ DIY',
    '🚗 Cars',
    '🏡 Interior',
    '🏥 Health',
    '🎲 Board Games',
    '🧩 Puzzles',
    '🧘 Meditation',
    '🌻 Gardening',
    '🧶 Crafting',
    '🎙️ Podcasting',
    '🎭 Anime',
    '🤖 AI',
    '🔭 Astronomy',
    '🏛️ History',
    '📚 Philosophy',
    '🎨 Design',
    '🏄 Surfing',
    '🎿 Skiing',
    '🧗 Climbing',
    '🎣 Fishing',
    '🚲 Cycling',
    '🍷 Wine',
    '☕ Coffee',
    '📸 Vlogging',
    '🃏 Magic',
    '🎭 Stand-up',
    '🏛️ Architecture',
    '🧬 Biology',
    '📐 Math',
    '♟️ Chess',
    '🛹 Skating',
    '🥊 Boxing',
    '🥋 Martial Arts',
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
