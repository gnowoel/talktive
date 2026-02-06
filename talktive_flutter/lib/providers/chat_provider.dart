import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talktive_client/talktive_client.dart';
import 'client_provider.dart';

part 'chat_provider.g.dart';

@riverpod
class Chat extends _$Chat {
  late int _channelId;

  @override
  FutureOr<List<Message>> build(int channelId) async {
    _channelId = channelId;
    // initial fetch
    return fetchMessages();
  }

  Future<List<Message>> fetchMessages() async {
    // ref is available in AsyncNotifier
    final client = ref.read(clientProvider);
    // TODO: Implement actual fetch when endpoint is ready
    // final messages = await client.message.list(_channelId);
    // return messages;

    // Mock for now
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      Message(
        channelId: _channelId,
        senderId: 1, // Mock sender
        content: 'Welcome to channel $_channelId!',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    ];
  }

  Future<void> sendMessage(String content) async {
    print(
      'ChatProvider: sendMessage called with: $content for channel $_channelId',
    );
    if (content.isEmpty) return;

    // final client = ref.read(clientProvider);

    // Mock optimist update
    final newMessage = Message(
      channelId: _channelId,
      senderId: 1, // Me
      content: content,
      createdAt: DateTime.now(),
    );

    final previousState = state.value ?? [];
    state = AsyncValue.data([...previousState, newMessage]);

    try {
      // TODO: await client.message.send(_channelId, content);
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      state = AsyncValue.data(previousState); // Revert
      throw e;
    }
  }
}
