import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talktive_client/talktive_client.dart';
import '../providers/private_chat_provider.dart';
import '../providers/realtime_chat_provider.dart';

/// A utility widget that pre-warms the chat cache for important threads.
/// It sits in the background of the main navigation or specific screens.
class TalktivePrewarmer extends ConsumerWidget {
  final Widget child;
  
  const TalktivePrewarmer({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Get the top active chats
    final chatsAsync = ref.watch(privateChatListProvider);
    final topChannelIds = chatsAsync.when(
      data: (chats) => chats
          .where((c) => c.currentMemberStatus != ChannelMemberStatus.invited)
          .take(3)
          .map((c) => c.chat.channelId)
          .toList(),
      loading: () => <int>[],
      error: (_, __) => <int>[],
    );

    // 2. "Watch" (listen) to them to keep them alive while this widget is mounted.
    // By listening with an empty callback, we create a subscription that triggers 'build'
    // in the target provider and keeps it alive.
    for (final channelId in topChannelIds) {
      ref.listen(realtimeChatProvider(channelId), (_, __) {});
    }

    return child;
  }
}
