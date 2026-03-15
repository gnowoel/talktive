import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talktive_client/talktive_client.dart';
import 'private_chat_provider.dart';
import 'group_provider.dart';
import 'notification_provider.dart';

part 'unread_counts_provider.g.dart';

class UnreadCounts {
  final int privateChats;
  final int lounges;
  final int activity;

  UnreadCounts({
    required this.privateChats,
    required this.lounges,
    required this.activity,
  });

  int get total => privateChats + lounges + activity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnreadCounts &&
          runtimeType == other.runtimeType &&
          privateChats == other.privateChats &&
          lounges == other.lounges &&
          activity == other.activity;

  @override
  int get hashCode => privateChats.hashCode ^ lounges.hashCode ^ activity.hashCode;
}

@riverpod
class TotalUnreadCounts extends _$TotalUnreadCounts {
  int _lastPrivateCount = 0;
  int _lastLoungeCount = 0;
  int _lastActivityCount = 0;

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
        if (group.isMuted != true) {
          count += (group.unreadCount as num).toInt();
        }
      }
      _lastLoungeCount = count;
    });

    final activity = ref.watch(activityHistoryProvider);
    activity.whenData((notifications) {
      _lastActivityCount = notifications.where((n) => !n.read).length;
    });

    return UnreadCounts(
      privateChats: _lastPrivateCount,
      lounges: _lastLoungeCount,
      activity: _lastActivityCount,
    );
  }
}
