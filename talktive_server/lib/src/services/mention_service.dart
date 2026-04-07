import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;

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

    final channel = await protocol.Channel.db.findById(session, channelId);
    if (channel == null || channel.type == protocol.ChannelType.plaza) {
      // Mentions are disabled in the public Plaza to ensure reliability and performance.
      return [];
    }

    // 1. Fetch all members of this channel to use as a "whitelist" for parsing.
    // We fetch Resident records for those who are joined members of this channel.
    final members = await protocol.ChannelMember.db.find(
      session,
      where: (t) =>
          t.channelId.equals(channelId) &
          t.status.equals(protocol.ChannelMemberStatus.joined),
    );

    if (members.isEmpty) return [];

    final joinedUserIds = members.map((m) => m.userInfoId).toSet();
    final residents = await protocol.Resident.db.find(
      session,
      where: (t) => t.userInfoId.inSet(joinedUserIds),
    );

    if (residents.isEmpty) return [];

    // Map names to IDs for easier lookup
    final nameMap = <String, Set<UuidValue>>{};
    for (final resident in residents) {
      final name = resident.userName?.toLowerCase();
      if (name == null || name.isEmpty) continue;
      nameMap.putIfAbsent(name, () => {}).add(resident.userInfoId);
    }

    final atIndices = <int>[];
    for (int i = 0; i < content.length; i++) {
      if (content[i] == '@') atIndices.add(i);
    }

    final detectedIds = <UuidValue>{};
    final sortedNames = nameMap.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final index in atIndices) {
      // Check if @ is preceded by space or start of string
      if (index > 0 && content[index - 1] != ' ') continue;

      final chunk = content.substring(index + 1).toLowerCase();
      if (chunk.isEmpty) continue;

      for (final name in sortedNames) {
        // Match name followed by space, punctuation, or end of string
        if (chunk.startsWith(name)) {
          final nextCharIdx = name.length;
          final bool isWordBoundary = nextCharIdx >= chunk.length ||
              RegExp(r'[\s.,!?;:]').hasMatch(chunk[nextCharIdx]);

          if (isWordBoundary) {
            detectedIds.addAll(nameMap[name]!);
            break; // Longest match wins for this @ index
          }
        }
      }
    }

    return detectedIds.toList();
  }

  /// Checks if a specific user is mentioned in the content.
  /// Consistent with the regex used in the frontend.
  static bool isUserMentioned(String content, String userName) {
    if (userName.isEmpty || !content.contains('@')) return false;
    // Case-insensitive check with boundary logic
    final pattern = RegExp(
      '(?:^|\\s)@${RegExp.escape(userName)}(?=\\s|\$|[.,!?;:])',
      caseSensitive: false,
    );
    return pattern.hasMatch(content);
  }
}
