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

    // 1. Fetch all members of this channel to use as a "whitelist" for parsing
    // This solves the "@Rick Novak this morning" ambiguity because we only look for actual names.
    final members = await protocol.ChannelMember.db.find(
      session,
      where: (t) =>
          t.channelId.equals(channelId) &
          t.status.equals(protocol.ChannelMemberStatus.joined),
    );
    if (members.isEmpty) return [];

    // Map names to IDs for easier lookup
    final nameMap = <String, Set<UuidValue>>{};

    final memberIds = members.map((m) => m.userInfoId).toSet();
    final residents = await protocol.Resident.db.find(
      session,
      where: (t) => t.userInfoId.inSet(memberIds),
    );

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
      final chunk = content.substring(index + 1).toLowerCase();
      if (chunk.isEmpty) continue;

      for (final name in sortedNames) {
        if (chunk.startsWith(name)) {
          // Found a match! Add all users with this name in the channel
          detectedIds.addAll(nameMap[name]!);
          break; // Longest match wins
        }
      }
    }

    return detectedIds.toList();
  }

  /// Checks if a specific user is mentioned in the content.
  static bool isUserMentioned(String content, String userName) {
    if (!content.contains('@')) return false;
    // Case-insensitive check with boundary logic
    final pattern = RegExp(
      '@${RegExp.escape(userName)}(?=\\s|\$|[.,!?;:])',
      caseSensitive: false,
    );
    return pattern.hasMatch(content);
  }
}
