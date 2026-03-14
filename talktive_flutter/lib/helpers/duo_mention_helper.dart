import 'package:flutter/material.dart';
import '../config/theme.dart';

class DuoMentionHelper {
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
    
    // 1. Split by @ to find potential mention starts
    final atIndices = <int>[];
    for (int i = 0; i < content.length; i++) {
      if (content[i] == '@') atIndices.add(i);
    }

    for (final index in atIndices) {
      final remaining = content.substring(index + 1);
      final chunk = remaining.length > 50 ? remaining.substring(0, 50) : remaining;
      if (chunk.isEmpty) continue;

      bool matched = false;

      // 1.1 Match Current User (Me) prioritized
      if (currentUserName != null && currentUserName.isNotEmpty) {
        if (chunk.toLowerCase().startsWith(currentUserName.toLowerCase())) {
          allMatches.add(_MentionMatch(index, index + 1 + currentUserName.length, isMe: true));
          matched = true;
        }
      }

      if (matched) continue;

      // 1.2 Match Other Members (Longest Match first for spaces)
      if (otherMemberNames != null && otherMemberNames.isNotEmpty) {
        // Sort otherMemberNames by length DESC to match "Leo Smith" before "Leo"
        final sortedNames = List<String>.from(otherMemberNames)
          ..sort((a, b) => b.length.compareTo(a.length));

        for (final name in sortedNames) {
          if (name.isEmpty) continue;
          if (chunk.toLowerCase().startsWith(name.toLowerCase())) {
            allMatches.add(_MentionMatch(index, index + 1 + name.length, isMe: false));
            matched = true;
            break;
          }
        }
      }

      if (matched) continue;

      // 1.3 Generic match (Single word) if no specific match found (for Plaza/Public)
      final genericPattern = RegExp(r'^([a-zA-Z0-9_]{2,30})');
      final match = genericPattern.firstMatch(chunk);
      if (match != null) {
        allMatches.add(_MentionMatch(index, index + 1 + match.group(1)!.length, isMe: false));
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
}

class _MentionMatch {
  final int start;
  final int end;
  final bool isMe;
  _MentionMatch(this.start, this.end, {required this.isMe});
}
