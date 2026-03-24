import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talktive_client/talktive_client.dart';
import 'client_provider.dart';
import 'private_chat_provider.dart';
import 'dart:async';

part 'realtime_chat_provider.g.dart';

/// Provider for real-time chat with WebSocket streaming.
/// Automatically subscribes to channel updates and maintains message list.
/// State for the real-time chat provider.
class RealtimeChatState {
  final List<Message> messages;
  final Set<String> typingUsers; // usernames of people typing
  final Map<String, DateTime> lastReadStatus; // userId -> lastReadAt

  RealtimeChatState({
    required this.messages,
    required this.typingUsers,
    required this.lastReadStatus,
  });

  RealtimeChatState copyWith({
    List<Message>? messages,
    Set<String>? typingUsers,
    Map<String, DateTime>? lastReadStatus,
  }) {
    return RealtimeChatState(
      messages: messages ?? this.messages,
      typingUsers: typingUsers ?? this.typingUsers,
      lastReadStatus: lastReadStatus ?? this.lastReadStatus,
    );
  }
}

/// Provider for real-time chat with WebSocket streaming.
/// Automatically subscribes to channel updates and maintains message list.
@riverpod
class RealtimeChat extends _$RealtimeChat {
  late int _channelId;
  StreamSubscription? _messageSubscription;
  bool _isSubscribed = false;
  Timer? _typingTimer;

  @override
  FutureOr<RealtimeChatState> build(int channelId) async {
    _channelId = channelId;

    // Cleanup when provider is disposed
    ref.onDispose(() {
      _unsubscribe();
      _typingTimer?.cancel();
    });

    // Fetch initial messages
    final messages = await _fetchMessages();

    // Initial state
    final initialState = RealtimeChatState(
      messages: messages,
      typingUsers: {},
      lastReadStatus: {},
    );

    // Try to get other user's last read from details (for private chats)
    try {
      final details = await ref.read(
        privateChatDetailsProvider(_channelId).future,
      );
      if (details.otherUserLastReadAt != null) {
        initialState.lastReadStatus[details.otherResident.userInfoId
                .toString()] =
            details.otherUserLastReadAt!;
      }
    } catch (_) {
      // Not a private chat or details not available
    }

    // Subscribe to real-time updates
    _subscribe();

    return initialState;
  }

  /// Fetches message history from the server.
  Future<List<Message>> _fetchMessages() async {
    final client = ref.read(clientProvider);
    try {
      return await client.message.listMessages(
        _channelId,
        limit: 50,
        offset: 0,
      );
    } catch (e) {
      debugPrint('RealtimeChat: Fetch error: $e');
      rethrow;
    }
  }

  /// Subscribes to real-time updates via WebSocket.
  void _subscribe() {
    if (_isSubscribed) return;

    final client = ref.read(clientProvider);

    try {
      final stream = client.message.subscribe(_channelId);

      _messageSubscription = stream.listen(
        (event) {
          if (event is Message) {
            _handleNewMessage(event);
          } else if (event is TypingIndicator) {
            _handleTypingIndicator(event);
          } else if (event is ReadReceiptEvent) {
            _handleReadReceipt(event);
          }
        },
        onError: (error) => debugPrint('RealtimeChat: Stream error: $error'),
        onDone: () {
          debugPrint('RealtimeChat: Stream closed');
          _isSubscribed = false;
        },
      );

      _isSubscribed = true;
    } catch (e) {
      debugPrint('RealtimeChat: Subscribe error: $e');
    }
  }

  void _unsubscribe() {
    _messageSubscription?.cancel();
    _messageSubscription = null;
    _isSubscribed = false;
  }

  void _handleNewMessage(Message newMessage) {
    if (state.value == null) return;

    final currentState = state.value!;
    final exists = currentState.messages.any((m) => m.id == newMessage.id);
    if (exists) return;

    state = AsyncValue.data(
      currentState.copyWith(messages: [newMessage, ...currentState.messages]),
    );

    // Clear typing indicator for this sender
    _removeTypingUser(newMessage.senderName);
  }

  void _handleTypingIndicator(TypingIndicator indicator) {
    if (state.value == null) return;
    final currentState = state.value!;

    // Don't show our own typing status
    // (Assuming we know our userId context - we can skip if name matches or just let it be)

    final updatedTyping = Set<String>.from(currentState.typingUsers);
    if (indicator.isTyping) {
      updatedTyping.add(indicator.userName);
    } else {
      updatedTyping.remove(indicator.userName);
    }

    state = AsyncValue.data(currentState.copyWith(typingUsers: updatedTyping));
  }

  void _handleReadReceipt(ReadReceiptEvent event) {
    if (state.value == null) return;
    final currentState = state.value!;

    final updatedReadStatus = Map<String, DateTime>.from(
      currentState.lastReadStatus,
    );
    updatedReadStatus[event.userId.toString()] = event.lastReadAt;

    state = AsyncValue.data(
      currentState.copyWith(lastReadStatus: updatedReadStatus),
    );
  }

  void _removeTypingUser(String userName) {
    if (state.value == null) return;
    final currentState = state.value!;
    if (currentState.typingUsers.contains(userName)) {
      final updatedTyping = Set<String>.from(currentState.typingUsers)
        ..remove(userName);
      state = AsyncValue.data(
        currentState.copyWith(typingUsers: updatedTyping),
      );
    }
  }

  /// Sends a message to the channel.
  Future<void> sendMessage({
    String? content,
    String? imageUrl,
    String? mediaUrl,
    String? mediaType,
    int? duration,
    int? fileSize,
  }) async {
    if ((content == null || content.trim().isEmpty) &&
        imageUrl == null &&
        mediaUrl == null) {
      return;
    }

    final client = ref.read(clientProvider);

    try {
      final savedMessage = await client.message.sendMessage(
        _channelId,
        content: content?.trim(),
        imageUrl: imageUrl,
        mediaUrl: mediaUrl,
        mediaType: mediaType,
        duration: duration,
        fileSize: fileSize,
        isSystem: false,
      );

      if (state.value != null) {
        final currentState = state.value!;
        final exists = currentState.messages.any(
          (m) => m.id == savedMessage.id,
        );
        if (!exists) {
          state = AsyncValue.data(
            currentState.copyWith(
              messages: [savedMessage, ...currentState.messages],
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('RealtimeChat: Send error: $e');
      rethrow;
    }
  }

  /// Updates our typing status.
  Future<void> setTyping(bool isTyping) async {
    final client = ref.read(clientProvider);
    try {
      await client.message.sendTypingIndicator(_channelId, isTyping);
    } catch (_) {}
  }

  /// Refreshes the message list.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final messages = await _fetchMessages();
      state = AsyncValue.data(
        RealtimeChatState(
          messages: messages,
          typingUsers: {},
          lastReadStatus: {},
        ),
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Loads more messages (pagination).
  Future<void> loadMore() async {
    if (state.value == null) return;
    final currentState = state.value!;

    final client = ref.read(clientProvider);

    try {
      final olderMessages = await client.message.listMessages(
        _channelId,
        limit: 50,
        offset: currentState.messages.length,
      );

      if (olderMessages.isNotEmpty) {
        state = AsyncValue.data(
          currentState.copyWith(
            messages: [...currentState.messages, ...olderMessages],
          ),
        );
      }
    } catch (e) {
      debugPrint('RealtimeChat: Load more error: $e');
    }
  }
}
