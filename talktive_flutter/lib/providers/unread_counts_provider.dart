import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talktive_client/talktive_client.dart';
import 'private_chat_provider.dart';
import 'group_provider.dart';

part 'unread_counts_provider.g.dart';

class UnreadCounts {
  final int privateChats;
  final int lounges;

  UnreadCounts({
    required this.privateChats,
    required this.lounges,
  });

  int get total => privateChats + lounges;
}

@riverpod
class TotalUnreadCounts extends _$TotalUnreadCounts {
  @override
  UnreadCounts build() {
    final privateChats = ref.watch(privateChatListProvider);
    final lounges = ref.watch(groupListProvider);

    int privateCount = 0;
    int loungeCount = 0;

    privateChats.whenData((chats) {
      for (final chat in chats) {
        privateCount += chat.unreadCount;
      }
    });

    lounges.whenData((groups) {
      for (final group in groups) {
        // Requirement 2: total unread message count for group chats, except for muted lounges
        if (group.isMuted != true) {
          loungeCount += group.unreadCount;
        }
      }
    });

    return UnreadCounts(
      privateChats: privateCount,
      lounges: loungeCount,
    );
  }
}
