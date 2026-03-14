import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart' as protocol;

class MentionService {
  /// Extracts user IDs mentioned in the content using @name format.
  /// Handles spaces in names using a greedy (longest-match) approach.
  /// Deduplicates names by filtering for channel members.
  static Future<List<UuidValue>> getMentionedUserIds(
    Session session,
    int channelId,
    String content,
  ) async {
    if (!content.contains('@')) return [];

    final mentionedIds = <UuidValue>{};
    final channel = await protocol.Channel.db.findById(session, channelId);
    if (channel == null) return [];
    
    final isPlaza = channel.type == protocol.ChannelType.plaza;

    // 1. Split by @ to find potential mention starts
    // We use a regex to find all @ indices manually to handle overlapping potential chunks
    final atIndices = <int>[];
    for (int i = 0; i < content.length; i++) {
      if (content[i] == '@') atIndices.add(i);
    }

    if (atIndices.isEmpty) return [];

    for (final index in atIndices) {
      // 2. Extract a chunk of text after the @ (up to max name length)
      final remaining = content.substring(index + 1);
      final chunk = remaining.length > 50 ? remaining.substring(0, 50) : remaining;
      if (chunk.isEmpty) continue;

      // 3. Simple heuristic: Grab the first "word" to narrow down search
      final firstWord = chunk.split(RegExp(r'\s|[.,!?;:]')).first;
      if (firstWord.length < 2) continue;

      // 4. Query residents whose names START with the first word
      // This allows us to find "Leo Smith" if we search for "Leo"
      final residents = await protocol.Resident.db.find(
        session,
        where: (t) => t.userName.ilike('$firstWord%'),
      );

      if (residents.isEmpty) continue;

      // 5. Greedy matching: find the resident whose name matches the longest part of our chunk
      protocol.Resident? bestMatch;
      int longestMatchLength = 0;

      for (final resident in residents) {
        final name = resident.userName;
        if (name == null || name.isEmpty) continue;

        // Case-insensitive check for full name match at start of chunk
        if (chunk.toLowerCase().startsWith(name.toLowerCase())) {
          // If names are identical, we have a tie (duplicate names)
          // We'll filter these by membership shortly.
          if (name.length > longestMatchLength) {
            longestMatchLength = name.length;
            bestMatch = resident;
          }
        }
      }

      if (bestMatch != null) {
        // 6. Handle Duplicates & Membership
        // If it's a private group, we only care about the one in the group
        if (!isPlaza) {
          final members = await protocol.ChannelMember.db.find(
            session,
            where: (t) => t.channelId.equals(channelId) & t.userInfoId.equals(bestMatch!.userInfoId),
          );
          if (members.isNotEmpty) {
            mentionedIds.add(bestMatch.userInfoId);
          }
        } else {
          // In Plaza, if names are duplicates, it's ambiguous.
          // For now, we notify the one found. 
          // (In a future version, residents should have unique handles).
          mentionedIds.add(bestMatch.userInfoId);
        }
      }
    }

    return mentionedIds.toList();
  }

  /// Checks if a specific user is mentioned in the content.
  static bool isUserMentioned(String content, String userName) {
    if (!content.contains('@')) return false;
    final mentionTag = '@$userName';
    // Case-insensitive check with boundary logic
    final pattern = RegExp(
      '@' + RegExp.escape(userName) + r'(?=\s|$|[.,!?;:])',
      caseSensitive: false,
    );
    return pattern.hasMatch(content);
  }
}
