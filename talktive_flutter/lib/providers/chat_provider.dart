import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talktive_client/talktive_client.dart';
import 'client_provider.dart'; // Ensure this import is correct

part 'chat_provider.g.dart';

@riverpod
class Chat extends _$Chat {
  late int _channelId;

  @override
  FutureOr<List<Message>> build(int channelId) async {
    _channelId = channelId;
    return fetchMessages();
  }

  Future<List<Message>> fetchMessages() async {
    final client = ref.read(clientProvider);
    try {
      // Backend returns DESC order (newest first).
      return await client.message.listMessages(
        _channelId,
        limit: 20,
        offset: 0,
      );
    } catch (e) {
      debugPrint('ChatProvider: Fetch error: $e');
      // Return empty list on error to avoid crashing UI, or rethrow?
      // AsyncValue handles error state if we throw.
      // Let's rethrow so UI shows error.
      rethrow;
    }
  }

  Future<void> sendMessage(String content) async {
    if (content.isEmpty) return;

    final client = ref.read(clientProvider);

    try {
      final savedMessage = await client.message.sendMessage(
        _channelId,
        content: content,
      );

      // Optimistic update logic is tricky without ID, so valid strategy is:
      // 1. Wait for response (savedMessage).
      // 2. Prepend to state.

      final previousState = state.value ?? [];
      final newState = [savedMessage, ...previousState];
      debugPrint(
        'ChatProvider: Updating state with ${newState.length} messages. Newest: ${savedMessage.content}',
      );
      state = AsyncValue.data(newState);
    } catch (e) {
      debugPrint('ChatProvider: Send error: $e');
      rethrow;
    }
  }
}
