import 'package:flutter/material.dart';
import '../config/theme.dart';

class MentionHelper {
  /// Parses message content and returns a TextSpan with highlighted mentions.
  /// 
  /// [currentUserName] is the name of the recipient (the user reading the message).
  /// [otherMemberNames] is an optional list of other people in the conversation to highlight.
  static TextSpan buildMessageSpan({
    required String content,
    required TextStyle baseStyle,
    required Color mentionColor,
    String? currentUserName,
    List<String>? otherMemberNames,
    bool isCurrentUserSender = false,
  }) {
    if (!content.contains('@')) {
      return TextSpan(text: content, style: baseStyle);
    }

    final spans = <TextSpan>[];
    final allMatches = <_MentionMatch>[];
    
    // 1. Add current user match (prioritized, high visibility)
    if (currentUserName != null && currentUserName.isNotEmpty) {
      final mePattern = RegExp(
        '@' + RegExp.escape(currentUserName) + r'(?=\s|$|[^\w])',
        caseSensitive: false,
      );
      for (final match in mePattern.allMatches(content)) {
        allMatches.add(_MentionMatch(match.start, match.end, isMe: true));
      }
    }
    
    // 2. Add other participants matches (optional, standard color)
    if (otherMemberNames != null) {
      for (final name in otherMemberNames) {
        if (name.isEmpty) continue;
        if (currentUserName != null && name.toLowerCase() == currentUserName.toLowerCase()) continue;
        
        final pattern = RegExp(
          '@' + RegExp.escape(name) + r'(?=\s|$|[^\w])',
          caseSensitive: false,
        );
        for (final match in pattern.allMatches(content)) {
          // Only add if not already covered by a "me" match
          if (!allMatches.any((m) => m.start <= match.start && m.end >= match.end)) {
            allMatches.add(_MentionMatch(match.start, match.end, isMe: false));
          }
        }
      }
    }

    // Sort matches by position
    allMatches.sort((a, b) => a.start.compareTo(b.start));

    int currentPos = 0;
    for (final match in allMatches) {
      // Add text before the mention
      if (match.start > currentPos) {
        spans.add(TextSpan(
          text: content.substring(currentPos, match.start),
          style: baseStyle,
        ));
      }
      
      final mentionText = content.substring(match.start, match.end);
      
      if (match.isMe) {
        // Highly visible highlight for the user themselves
        spans.add(TextSpan(
          text: mentionText,
          style: baseStyle.copyWith(
            color: isCurrentUserSender ? Colors.white : AppTheme.accentColor,
            fontWeight: FontWeight.bold,
            // Use subtle background highlights with good contrast
            backgroundColor: isCurrentUserSender 
                ? Colors.white.withValues(alpha: 0.2) // On purple
                : AppTheme.accentColor.withValues(alpha: 0.15), // On white
          ),
        ));
      } else {
        // Standard highlight for other people
        spans.add(TextSpan(
          text: mentionText,
          style: baseStyle.copyWith(
            color: isCurrentUserSender ? Colors.white : mentionColor,
            fontWeight: FontWeight.w600,
          ),
        ));
      }
      currentPos = match.end;
    }
    
    // Add remaining text
    if (currentPos < content.length) {
      spans.add(TextSpan(
        text: content.substring(currentPos),
        style: baseStyle,
      ));
    }

    return TextSpan(children: spans);
  }

  /// Check if a message mentions a specific user
  static bool containsMention(String messageContent, String displayName) {
    if (displayName.isEmpty || messageContent.isEmpty) return false;
    final pattern = RegExp(
      '@' + RegExp.escape(displayName) + r'(?=\s|$|[^\w])',
      caseSensitive: false,
    );
    return pattern.hasMatch(messageContent);
  }

  /// Alias for containsMention
  static bool containsExactMention(String messageContent, String displayName) =>
      containsMention(messageContent, displayName);
}

class _MentionMatch {
  final int start;
  final int end;
  final bool isMe;
  _MentionMatch(this.start, this.end, {required this.isMe});
}
