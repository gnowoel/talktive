import 'package:flutter/material.dart';
import '../config/theme.dart';

class MentionHelper {
  /// Parses message content and returns a TextSpan with highlighted mentions.
  /// Supports usernames with spaces by matching against the current resident's name
  /// and other common mention formats.
  static TextSpan buildMessageSpan({
    required String content,
    required TextStyle baseStyle,
    required Color mentionColor,
    String? currentUserName,
  }) {
    if (!content.contains('@')) {
      return TextSpan(text: content, style: baseStyle);
    }

    final spans = <TextSpan>[];
    
    // If we have the current user's name, we prioritize finding that specific mention
    // to apply the 'me' styling.
    String remainingContent = content;
    
    // We'll use a simple approach: find all occurrences of @Name and wrap them.
    // To handle names with spaces effectively, we'd ideally have a list of all members,
    // but on the client, we usually at least know the currentUser.
    
    // Regex for current user mention (supports spaces if we escape it)
    RegExp? meRegex;
    if (currentUserName != null && currentUserName.isNotEmpty) {
      meRegex = RegExp(
        '@' + RegExp.escape(currentUserName) + r'(?=\s|$|[^\w])',
        caseSensitive: false,
      );
    }

    // General regex for other mentions (stops at space/punctuation for generic ones)
    final generalMentionRegex = RegExp(r'@[a-zA-Z0-9_]+');

    int lastIndex = 0;
    
    // This is a simplified parser. For full space support for OTHERS, we'd need more info.
    // But for the CURRENT user (the most important highlight), this works perfectly.
    
    void addSegment(String text, bool isMention, bool isMe) {
      if (text.isEmpty) return;
      spans.add(TextSpan(
        text: text,
        style: isMention 
          ? baseStyle.copyWith(
              color: isMe ? AppTheme.accentColor : mentionColor,
              fontWeight: FontWeight.bold,
              backgroundColor: isMe ? AppTheme.accentColor.withValues(alpha: 0.1) : null,
            )
          : baseStyle,
      ));
    }

    // Find all mentions
    final allMatches = <_MentionMatch>[];
    
    if (meRegex != null) {
      for (final match in meRegex.allMatches(content)) {
        allMatches.add(_MentionMatch(match.start, match.end, true));
      }
    }
    
    for (final match in generalMentionRegex.allMatches(content)) {
      // Only add if not already covered by a 'me' match
      if (!allMatches.any((m) => m.start <= match.start && m.end >= match.end)) {
        allMatches.add(_MentionMatch(match.start, match.end, false));
      }
    }
    
    allMatches.sort((a, b) => a.start.compareTo(b.start));

    int currentPos = 0;
    for (final match in allMatches) {
      // Add text before match
      if (match.start > currentPos) {
        addSegment(content.substring(currentPos, match.start), false, false);
      }
      // Add the mention
      addSegment(content.substring(match.start, match.end), true, match.isMe);
      currentPos = match.end;
    }
    
    // Add remaining text
    if (currentPos < content.length) {
      addSegment(content.substring(currentPos), false, false);
    }

    return TextSpan(children: spans);
  }

  /// Checks if a message contains a mention of the given display name.
  static bool containsMention(String messageContent, String displayName) {
    if (displayName.isEmpty || messageContent.isEmpty) {
      return false;
    }
    final mention = '@$displayName';
    return messageContent.toLowerCase().contains(mention.toLowerCase());
  }

  /// Checks if a message contains a mention of the current user, using refined boundary logic.
  static bool containsExactMention(String messageContent, String displayName) {
    if (displayName.isEmpty || messageContent.isEmpty) {
      return false;
    }
    final pattern = RegExp(
      r'@' + RegExp.escape(displayName) + r'(?=\s|$|[^\w])',
      caseSensitive: false,
    );
    return pattern.hasMatch(messageContent);
  }
}

class _MentionMatch {
  final int start;
  final int end;
  final bool isMe;
  _MentionMatch(this.start, this.end, this.isMe);
}
