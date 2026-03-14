class MentionHelper {
  /// Check if a message mentions a specific user (case insensitive)
  static bool containsMention(String messageContent, String displayName) {
    if (displayName.isEmpty || messageContent.isEmpty) return false;
    
    // Regular expression to match @DisplayName specifically, 
    // ensuring it's not part of another word.
    final pattern = RegExp(
      '@' + RegExp.escape(displayName) + r'(?=\s|$|[^\w])',
      caseSensitive: false,
    );
    return pattern.hasMatch(messageContent);
  }

  /// Check for an exact mention of the user's display name
  static bool containsExactMention(String messageContent, String displayName) {
    return containsMention(messageContent, displayName);
  }
}
