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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnreadCounts &&
          runtimeType == other.runtimeType &&
          privateChats == other.privateChats &&
          lounges == other.lounges;

  @override
  int get hashCode => privateChats.hashCode ^ lounges.hashCode;
}

@riverpod
class TotalUnreadCounts extends _$TotalUnreadCounts {
  int _lastPrivateCount = 0;
  int _lastLoungeCount = 0;

  @override
  UnreadCounts build() {
    final privateChats = ref.watch(privateChatListProvider);
    final lounges = ref.watch(groupListProvider);

    privateChats.whenData((chats) {
      int count = 0;
      for (final chat in chats) {
        count += (chat.unreadCount as num).toInt();
      }
      _lastPrivateCount = count;
    });

    lounges.whenData((groups) {
      int count = 0;
      for (final group in groups) {
        // Requirement 2: total unread message count for group chats, except for muted lounges
        if (group.isMuted != true) {
          count += (group.unreadCount as num).toInt();
        }
      }
      _lastLoungeCount = count;
    });

    return UnreadCounts(
      privateChats: _lastPrivateCount,
      lounges: _lastLoungeCount,
    );
  }
}
