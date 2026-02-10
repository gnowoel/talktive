import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talktive_client/talktive_client.dart';
import 'client_provider.dart';

part 'realtime_chat_provider.g.dart';

/// Provider for real-time chat with WebSocket streaming.
/// Automatically subscribes to channel updates and maintains message list.
@riverpod
class RealtimeChat extends _$RealtimeChat {
  late int _channelId;
  StreamSubscription? _messageSubscription;
  bool _isSubscribed = false;

  @override
  FutureOr<List<Message>> build(int channelId) async {
    _channelId = channelId;

    // Cleanup when provider is disposed
    ref.onDispose(() {
      _unsubscribe();
    });

    // Fetch initial messages
    final messages = await _fetchMessages();

    // Subscribe to real-time updates
    _subscribe();

    return messages;
  }

  /// Fetches message history from the server.
  Future<List<Message>> _fetchMessages() async {
    final client = ref.read(clientProvider);
    try {
      // Backend returns DESC order (newest first)
      return await client.message.listMessages(
        _channelId,
        limit: 50,
        offset: 0,
      );
    } catch (e) {
      print('RealtimeChat: Fetch error: $e');
      rethrow;
    }
  }

  /// Subscribes to real-time message updates via WebSocket.
  void _subscribe() {
    if (_isSubscribed) return;

    final client = ref.read(clientProvider);

    try {
      // Connect to the stream using the new Serverpod 3.x streaming method
      final stream = client.message.subscribe(_channelId);

      // Listen for incoming messages
      _messageSubscription = stream.listen(
        (message) {
          _handleNewMessage(message);
        },
        onError: (error) {
          print('RealtimeChat: Stream error: $error');
        },
        onDone: () {
          print('RealtimeChat: Stream closed');
          _isSubscribed = false;
        },
      );

      _isSubscribed = true;
      print('RealtimeChat: Subscribed to channel $_channelId');
    } catch (e) {
      print('RealtimeChat: Subscribe error: $e');
    }
  }

  /// Unsubscribes from real-time updates.
  void _unsubscribe() {
    _messageSubscription?.cancel();
    _messageSubscription = null;
    _isSubscribed = false;
    print('RealtimeChat: Unsubscribed from channel $_channelId');
  }

  /// Handles a new message received via WebSocket.
  void _handleNewMessage(Message newMessage) {
    final currentState = state.value;
    if (currentState == null) return;

    // Check if message already exists (avoid duplicates)
    final exists = currentState.any((m) => m.id == newMessage.id);
    if (exists) return;

    // Prepend new message to the list (newest first)
    final updatedMessages = [newMessage, ...currentState];
    state = AsyncValue.data(updatedMessages);

    print('RealtimeChat: New message received: ${newMessage.content}');
  }

  /// Sends a message to the channel.
  Future<void> sendMessage(String content, {String? imageUrl}) async {
    if (content.trim().isEmpty && imageUrl == null) return;

    final client = ref.read(clientProvider);

    try {
      // Send message to server
      final savedMessage = await client.message.sendMessage(
        _channelId,
        content.trim(),
        imageUrl: imageUrl,
      );

      // The message will be received via WebSocket stream,
      // but we can optimistically add it to avoid delay
      final currentState = state.value ?? [];
      final exists = currentState.any((m) => m.id == savedMessage.id);

      if (!exists) {
        final updatedMessages = [savedMessage, ...currentState];
        state = AsyncValue.data(updatedMessages);
      }

      print('RealtimeChat: Message sent: ${savedMessage.content}');
    } catch (e) {
      print('RealtimeChat: Send error: $e');
      rethrow;
    }
  }

  /// Refreshes the message list from the server.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final messages = await _fetchMessages();
      state = AsyncValue.data(messages);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Loads more messages (pagination).
  Future<void> loadMore() async {
    final currentState = state.value;
    if (currentState == null || currentState.isEmpty) return;

    final client = ref.read(clientProvider);

    try {
      final olderMessages = await client.message.listMessages(
        _channelId,
        limit: 50,
        offset: currentState.length,
      );

      if (olderMessages.isNotEmpty) {
        final updatedMessages = [...currentState, ...olderMessages];
        state = AsyncValue.data(updatedMessages);
      }
    } catch (e) {
      print('RealtimeChat: Load more error: $e');
    }
  }
}
