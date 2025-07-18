import 'dart:math';

/// Service for managing dynamic personal prompts to encourage storytelling
class MomentPrompts {
  static final MomentPrompts _instance = MomentPrompts._internal();
  factory MomentPrompts() => _instance;
  MomentPrompts._internal();

  final Random _random = Random();

  /// Categories of personal prompts to encourage authentic sharing
  static const Map<String, List<String>> _promptCategories = {
    'daily_highlights': [
      'What made you smile today?',
      'What was the best part of your day?',
      'Share something good that happened today',
      'What surprised you today?',
      'Tell us about a small win you had',
    ],
    'discoveries': [
      'What did you learn recently?',
      'Share something that surprised you',
      'Tell us about something new you tried',
      'What realization did you have today?',
      'Share a "lightbulb moment" you experienced',
    ],
    'experiences': [
      'What interesting thing happened to you?',
      'Share a memorable moment from this week',
      'Tell us about an adventure, big or small',
      'What\'s something you experienced for the first time?',
      'Share a moment that made you think',
    ],
    'feelings': [
      'What are you excited about right now?',
      'Share something you\'re grateful for',
      'What made you feel proud recently?',
      'Tell us about something that moved you',
      'What\'s bringing you joy today?',
    ],
    'achievements': [
      'What progress did you make recently?',
      'Share a goal you accomplished',
      'Tell us about something you overcame',
      'What challenge did you face today?',
      'Share a moment you felt capable',
    ],
    'connections': [
      'Tell us about a meaningful conversation you had',
      'Share something someone said that stuck with you',
      'What act of kindness did you witness or receive?',
      'Tell us about someone who made your day better',
      'Share a moment of human connection',
    ],
    'observations': [
      'What did you notice around you today?',
      'Share something beautiful you saw',
      'Tell us about an interesting person you met',
      'What made you stop and think today?',
      'Share something that caught your attention',
    ],
  };

  /// Get a random prompt from all categories
  String getRandomPrompt() {
    final allPrompts = _getAllPrompts();
    return allPrompts[_random.nextInt(allPrompts.length)];
  }

  /// Get a prompt from a specific category
  String getPromptFromCategory(String category) {
    final prompts = _promptCategories[category];
    if (prompts == null || prompts.isEmpty) {
      return getRandomPrompt();
    }
    return prompts[_random.nextInt(prompts.length)];
  }

  /// Get a time-appropriate prompt
  String getTimeBasedPrompt() {
    final hour = DateTime.now().hour;

    if (hour >= 6 && hour < 12) {
      // Morning prompts
      return getPromptFromCategory('daily_highlights');
    } else if (hour >= 12 && hour < 17) {
      // Afternoon prompts
      return getPromptFromCategory('experiences');
    } else if (hour >= 17 && hour < 21) {
      // Evening prompts - reflection time
      final categories = ['achievements', 'feelings', 'connections'];
      final category = categories[_random.nextInt(categories.length)];
      return getPromptFromCategory(category);
    } else {
      // Night prompts - lighter content
      final categories = ['observations', 'discoveries'];
      final category = categories[_random.nextInt(categories.length)];
      return getPromptFromCategory(category);
    }
  }

  /// Get multiple prompts for variety
  List<String> getMultiplePrompts(int count) {
    final allPrompts = _getAllPrompts();
    final shuffled = List<String>.from(allPrompts)..shuffle(_random);
    return shuffled.take(count).toList();
  }

  /// Check if a title seems personal vs. generic
  bool isPersonalTitle(String title) {
    final lowerTitle = title.toLowerCase().trim();

    // Personal indicators
    final personalIndicators = [
      'i ',
      'my ',
      'me ',
      'today i',
      'yesterday i',
      'i just',
      'i finally',
      'i learned',
      'i discovered',
      'i tried',
      'i met',
      'i saw',
      'i felt',
      'i realized',
      'i achieved',
      'i overcame',
      'happened to me',
      'i experienced'
    ];

    for (final indicator in personalIndicators) {
      if (lowerTitle.startsWith(indicator) ||
          lowerTitle.contains(' $indicator')) {
        return true;
      }
    }

    return false;
  }

  /// Get suggestion for making a title more personal
  String getPersonalizationSuggestion(String title) {
    final suggestions = [
      'Try sharing your own experience! Start with "I..." or "Today I..."',
      'What happened to you personally? Share your story!',
      'Make it personal - tell us about your experience with this',
      'Share how this relates to your own life or experience',
      'Turn this into your personal story - what happened to you?',
    ];

    return suggestions[_random.nextInt(suggestions.length)];
  }

  /// Get all prompts as a flat list
  List<String> _getAllPrompts() {
    final allPrompts = <String>[];
    for (final prompts in _promptCategories.values) {
      allPrompts.addAll(prompts);
    }
    return allPrompts;
  }

  /// Get available categories
  List<String> getCategories() {
    return _promptCategories.keys.toList();
  }

  /// Get prompts for a specific category
  List<String> getPromptsForCategory(String category) {
    return _promptCategories[category] ?? [];
  }
}
