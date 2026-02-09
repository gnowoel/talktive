import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../serverpod_client.dart';
import '../../providers/chat_provider.dart';

class ChatScreen extends ConsumerWidget {
  final int channelId;
  final String title;

  const ChatScreen({super.key, required this.channelId, required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(chatProvider(channelId));

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                return Column(
                  children: [
                    Container(
                      color: Colors.red,
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        'DEBUG: Count: ${messages.length}\nChannel: $channelId',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          // Force visible logic for debug
                          // Check if message is from me
                          final currentUserId = sessionManager
                              .authInfo
                              ?.authUserId
                              .toString();
                          final isMe =
                              currentUserId != null &&
                              msg.senderId.toString() == currentUserId;
                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.blue : Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    msg.content ?? '<EMPTY CONTENT>',
                                    style: TextStyle(
                                      color: isMe ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  Text(
                                    msg.createdAt.toString(),
                                    style: TextStyle(
                                      color: isMe
                                          ? Colors.white70
                                          : Colors.black54,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
              error: (err, stack) => Center(child: Text('Error: $err')),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
          ),
          _buildMessageInput(ref),
        ],
      ),
    );
  }

  Widget _buildMessageInput(WidgetRef ref) {
    return _ChatInput(channelId: channelId);
  }
}

class _ChatInput extends ConsumerStatefulWidget {
  final int channelId;
  const _ChatInput({required this.channelId});

  @override
  ConsumerState<_ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends ConsumerState<_ChatInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    debugPrint('ChatScreen: _sendMessage triggered with: "$text"');
    if (text.isEmpty) return;

    try {
      debugPrint('ChatScreen: calling provider.sendMessage');
      // Await the send operation to catch errors!
      await ref.read(chatProvider(widget.channelId).notifier).sendMessage(text);
      debugPrint('ChatScreen: provider.sendMessage success');
      _controller.clear();
    } catch (e, stack) {
      debugPrint('ChatScreen: Error invoking sendMessage: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Send Failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Copy',
              onPressed: () {
                // TODO: Copy to clipboard if needed
              },
            ),
          ),
        );
      }
    }
  }
}
