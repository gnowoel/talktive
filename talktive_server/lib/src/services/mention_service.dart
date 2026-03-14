import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart' as protocol;

class MentionService {
  /// Extracts user IDs mentioned in the content using @name format.
  /// Only checks against current members of the channel.
  static Future<List<UuidValue>> getMentionedUserIds(
    Session session,
    int channelId,
    String content,
  ) async {
    if (!content.contains('@')) return [];

    // 1. Get all members of the channel
    final members = await protocol.ChannelMember.db.find(
      session,
      where: (t) => t.channelId.equals(channelId),
    );

    if (members.isEmpty) return [];

    // 2. Get resident profiles for these members to get their usernames
    final memberUserIds = members.map((m) => m.userInfoId).toSet();
    final residents = await protocol.Resident.db.find(
      session,
      where: (t) => t.userInfoId.inSet(memberUserIds),
    );

    final mentionedIds = <UuidValue>[];

    // 3. Simple matching: for each resident, check if '@UserName' exists in content
    // We sort by name length descending to handle nested names like '@Leo' vs '@Leo Smith'
    final sortedResidents = residents.toList()
      ..sort((a, b) => (b.userName?.length ?? 0).compareTo(a.userName?.length ?? 0));

    // We use a copy of the content to mark matched portions
    String remainingContent = content;
    
    for (final resident in sortedResidents) {
      final name = resident.userName;
      if (name == null || name.isEmpty) continue;

      final mentionTag = '@$name';
      // Case-insensitive check might be better for mentions
      // Using a regex with word boundaries is safer to avoid matching @Leo inside @Leonard
      // However, names can have spaces, so we can't just use \b
      if (remainingContent.toLowerCase().contains(mentionTag.toLowerCase())) {
        mentionedIds.add(resident.userInfoId);
        
        // Remove the matched part to avoid sub-matches (e.g. @John from @John Doe)
        // We replace with a placeholder to keep length/indices if we ever needed them, 
        // but for just finding IDs, simple replacement is fine.
        remainingContent = remainingContent.replaceAll(RegExp(RegExp.escape(mentionTag), caseSensitive: false), '___');
      }
    }

    return mentionedIds;
  }

  /// Checks if a specific user is mentioned in the content.
  static bool isUserMentioned(String content, String userName) {
    if (!content.contains('@')) return false;
    final mentionTag = '@$userName';
    return content.toLowerCase().contains(mentionTag.toLowerCase());
  }
}
