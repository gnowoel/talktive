import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talktive_client/talktive_client.dart';
import '../providers/private_chat_provider.dart';
import '../providers/realtime_chat_provider.dart';

/// A utility widget that pre-warms the chat cache for important threads.
/// It sits in the background of the main navigation or specific screens.
class TalktivePrewarmer extends ConsumerStatefulWidget {
  final Widget child;

  const TalktivePrewarmer({super.key, required this.child});

  @override
  ConsumerState<TalktivePrewarmer> createState() => _TalktivePrewarmerState();
}

class _TalktivePrewarmerState extends ConsumerState<TalktivePrewarmer> {
  bool _canPrewarm = false;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    // Delay pre-warming by 10 seconds after app start/mount to prioritize
    // the current active screen and reduce initial server burst.
    _delayTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() => _canPrewarm = true);
      }
    });
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_canPrewarm) {
      // 1. Get the top active chats
      final chatsAsync = ref.watch(privateChatListProvider);
      final topChannelIds = chatsAsync.when(
        data: (chats) => chats
            .where((c) => c.currentMemberStatus != ChannelMemberStatus.invited)
            .take(2) // Reduced from 3 to 2 to save resources
            .map((c) => c.chat.channelId)
            .toList(),
        loading: () => <int>[],
        error: (_, _) => <int>[],
      );

      // 2. Proactively listen to them.
      for (final channelId in topChannelIds) {
        // Use prewarmOnly: true to skip message fetch if cache is fresh.
        // This still keeps the WebSocket alive.
        ref.listen(
          realtimeChatProvider(channelId, prewarmOnly: true),
          (_, _) {},
        );
      }
    }

    return widget.child;
  }
}
