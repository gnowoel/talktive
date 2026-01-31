import '../services/moment_prompts.dart';

/// Helper class for filtering content and guiding users toward personal storytelling
class ContentFilter {
  static final ContentFilter _instance = ContentFilter._internal();
  factory ContentFilter() => _instance;
  ContentFilter._internal();

  final MomentPrompts _momentPrompts = MomentPrompts();

  /// Patterns that indicate generic discussion topics rather than personal stories
  static const List<String> _genericDiscussionPatterns = [
    // Direct discussion starters
    'let\'s discuss',
    'let\'s talk about',
    'what do you think about',
    'what are your thoughts on',
    'what\'s your opinion on',
    'anyone else think',
    'does anyone else',
    'does anyone',
    'anyone have',
    'what do you all think',
    'how do you feel about',
    'what are your views on',

    // Question-based discussion starters
    'what\'s the best',
    'what\'s your favorite',
    'which is better',
    'who else',
    'who thinks',
    'who agrees',
    'who disagrees',
    'who has',
    'who wants to',

    // Generic sharing requests
    'share your',
    'tell me about your',
    'what are some',
    'list your',
    'name your',
    'give me your',

    // Broad topic discussions
    'can we talk about',
    'i want to discuss',
    'let\'s chat about',
    'thoughts on',
    'opinions on',
    'feelings about',
    'debate about',
    'argue about',
  ];

  /// Words that often indicate generic topics
  static const List<String> _genericTopicWords = [
    'everyone',
    'people',
    'society',
    'world',
    'discuss',
    'debate',
    'opinion',
    'thoughts',
    'views',
    'perspective',
    'generally',
    'usually',
    'typically',
    'overall',
    'in general',
  ];

  /// Check if content appears to be a generic discussion topic
  bool isGenericDiscussion(String title, {String? message}) {
    final lowerTitle = title.toLowerCase().trim();
    final lowerMessage = message?.toLowerCase().trim() ?? '';

    // Check for generic discussion patterns
    for (final pattern in _genericDiscussionPatterns) {
      if (lowerTitle.contains(pattern) || lowerMessage.contains(pattern)) {
        return true;
      }
    }

    // Check for generic topic words
    int genericWordCount = 0;
    for (final word in _genericTopicWords) {
      if (lowerTitle.contains(word) || lowerMessage.contains(word)) {
        genericWordCount++;
      }
    }

    // If multiple generic words, likely a discussion topic
    if (genericWordCount >= 2) {
      return true;
    }

    // Check if it's asking for others' opinions without personal context
    if (_isAskingForOpinions(lowerTitle, lowerMessage)) {
      return true;
    }

    return false;
  }

  /// Check if the content is asking for others' opinions without personal context
  bool _isAskingForOpinions(String title, String message) {
    final opinionPatterns = [
      'what do you',
      'how do you',
      'do you think',
      'do you believe',
      'are you',
      'have you',
      'would you',
      'should we',
      'can we',
      'why do',
      'why don\'t',
      'when do',
      'where do',
      'which do',
      'who do',
    ];

    for (final pattern in opinionPatterns) {
      if (title.contains(pattern) || message.contains(pattern)) {
        // Check if there's personal context
        if (!_hasPersonalContext(title, message)) {
          return true;
        }
      }
    }

    return false;
  }

  /// Check if content has personal context
  bool _hasPersonalContext(String title, String message) {
    final personalIndicators = [
      'i ',
      'my ',
      'me ',
      'myself',
      'personally',
      'in my experience',
      'happened to me',
      'i experienced',
      'i went through',
      'i encountered',
      'i discovered',
      'i learned',
      'i realized',
      'i found',
      'i noticed',
      'i felt',
      'i thought',
      'i believe',
      'i think',
      'today i',
      'yesterday i',
      'recently i',
      'i just',
      'i finally',
      'i was',
      'i am',
      'i have',
      'i had',
      'i did',
      'i tried',
      'i met',
      'i saw',
      'i heard',
    ];

    final fullText = '$title $message'.toLowerCase();

    for (final indicator in personalIndicators) {
      if (fullText.contains(indicator)) {
        return true;
      }
    }

    return false;
  }

  /// Get personalization suggestions for generic content
  PersonalizationSuggestion getPersonalizationSuggestion(String title,
      {String? message}) {
    if (!isGenericDiscussion(title, message: message)) {
      return PersonalizationSuggestion.none();
    }

    final suggestions = [
      'Try sharing your own experience instead! Start with "I..." or "Today I..."',
      'What happened to you personally? Share your story!',
      'Make it personal - tell us about your experience with this',
      'Share how this relates to your own life or experience',
      'Turn this into your personal story - what happened to you?',
      'Instead of asking others, share what you experienced yourself',
      'People love hearing about real experiences - what\'s yours?',
      'Transform this into a personal moment you\'ve lived',
    ];

    final examples = [
      'Instead of "What\'s your favorite food?" try "I discovered this amazing restaurant today!"',
      'Instead of "Let\'s discuss movies" try "I watched a movie that completely changed my perspective"',
      'Instead of "What do you think about..." try "I experienced something that made me think..."',
      'Instead of "Anyone else..." try "I just went through something interesting..."',
    ];

    return PersonalizationSuggestion(
      isGeneric: true,
      suggestion: suggestions[DateTime.now().millisecond % suggestions.length],
      example: examples[DateTime.now().millisecond % examples.length],
      personalPrompt: _momentPrompts.getRandomPrompt(),
    );
  }

  /// Get a score for how personal the content is (0-100)
  int getPersonalityScore(String title, {String? message}) {
    if (isGenericDiscussion(title, message: message)) {
      return 0;
    }

    if (_momentPrompts.isPersonalTitle(title)) {
      return 100;
    }

    if (_hasPersonalContext(title, message ?? '')) {
      return 75;
    }

    // Neutral content
    return 50;
  }

  /// Check if content is likely to encourage personal sharing
  bool encouragesPersonalSharing(String title, {String? message}) {
    final personalityScore = getPersonalityScore(title, message: message);
    return personalityScore >= 75;
  }

  /// Get content quality assessment
  ContentQuality assessContentQuality(String title, {String? message}) {
    final personalityScore = getPersonalityScore(title, message: message);
    final isGeneric = isGenericDiscussion(title, message: message);

    if (isGeneric) {
      return ContentQuality.generic;
    } else if (personalityScore >= 75) {
      return ContentQuality.personal;
    } else {
      return ContentQuality.neutral;
    }
  }
}

/// Represents a suggestion for making content more personal
class PersonalizationSuggestion {
  final bool isGeneric;
  final String suggestion;
  final String example;
  final String personalPrompt;

  const PersonalizationSuggestion({
    required this.isGeneric,
    required this.suggestion,
    required this.example,
    required this.personalPrompt,
  });

  factory PersonalizationSuggestion.none() {
    return const PersonalizationSuggestion(
      isGeneric: false,
      suggestion: '',
      example: '',
      personalPrompt: '',
    );
  }
}

/// Represents the quality/type of content
enum ContentQuality {
  generic, // Discussion-style, asking for others' opinions
  neutral, // Neither clearly personal nor generic
  personal, // Personal story/experience
}
