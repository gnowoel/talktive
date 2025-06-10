class MentionHelper {
  /// Checks if a message contains a mention of the given display name
  /// Returns true if the message contains "@displayName" (case-insensitive)
  static bool containsMention(String messageContent, String displayName) {
    if (displayName.isEmpty || messageContent.isEmpty) {
      return false;
    }
    
    // Create the mention pattern: @displayName
    final mention = '@$displayName';
    
    // Convert both to lowercase for case-insensitive comparison
    final lowerContent = messageContent.toLowerCase();
    final lowerMention = mention.toLowerCase();
    
    // Check if the mention exists in the message
    return lowerContent.contains(lowerMention);
  }
  
  /// Checks if a message contains a mention of the current user
  /// Uses word boundary checking to avoid partial matches
  static bool containsExactMention(String messageContent, String displayName) {
    if (displayName.isEmpty || messageContent.isEmpty) {
      return false;
    }
    
    // Use RegExp for more precise matching
    // This ensures we match whole mentions, not partial ones
    final pattern = RegExp(
      r'@' + RegExp.escape(displayName) + r'(?=\s|$|[^\w])',
      caseSensitive: false,
    );
    
    return pattern.hasMatch(messageContent);
  }
}