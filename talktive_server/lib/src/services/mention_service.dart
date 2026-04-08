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
    if (channel == null) return [];

    final Set<UuidValue> whitelistUserIds = {};

    if (channel.type == protocol.ChannelType.plaza) {
      // For Plaza, we use a dynamic whitelist of the last 100 unique senders
      final lastMessages = await protocol.Message.db.find(
        session,
        where: (t) => t.channelId.equals(channelId),
        orderBy: (t) => t.createdAt,
        orderDescending: true,
        limit: 200, // Look at last 200 messages to find ~100 unique users
      );
      whitelistUserIds.addAll(lastMessages.map((m) => m.senderId));
    } else {
      // For Lounges and Private chats, use the joined members list
      final members = await protocol.ChannelMember.db.find(
        session,
        where: (t) =>
            t.channelId.equals(channelId) &
            t.status.equals(protocol.ChannelMemberStatus.joined),
      );
      whitelistUserIds.addAll(members.map((m) => m.userInfoId));
    }

    if (whitelistUserIds.isEmpty) return [];

    final residents = await protocol.Resident.db.find(
      session,
      where: (t) => t.userInfoId.inSet(whitelistUserIds),
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
          final bool isWordBoundary =
              nextCharIdx >= chunk.length ||
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
