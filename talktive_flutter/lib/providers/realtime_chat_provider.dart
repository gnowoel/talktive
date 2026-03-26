import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talktive_client/talktive_client.dart';
import 'client_provider.dart';
import 'private_chat_provider.dart';
import '../services/local_chat_cache.dart';

part 'realtime_chat_provider.g.dart';

/// Provider for real-time chat with WebSocket streaming.
/// Automatically subscribes to channel updates and maintains message list.
/// State for the real-time chat provider.
class RealtimeChatState {
  final List<Message> messages;
  final Set<String> typingUsers; // usernames of people typing
  final Map<String, DateTime> lastReadStatus; // userId -> lastReadAt
  final bool isLoadingMore;
  final bool hasMore;

  RealtimeChatState({
    required this.messages,
    required this.typingUsers,
    required this.lastReadStatus,
    this.isLoadingMore = false,
    this.hasMore = true,
  });

  RealtimeChatState copyWith({
    List<Message>? messages,
    Set<String>? typingUsers,
    Map<String, DateTime>? lastReadStatus,
    bool? isLoadingMore,
    bool? hasMore,
  }) {
    return RealtimeChatState(
      messages: messages ?? this.messages,
      typingUsers: typingUsers ?? this.typingUsers,
      lastReadStatus: lastReadStatus ?? this.lastReadStatus,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
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
  FutureOr<RealtimeChatState> build(
    int channelId, {
    bool prewarmOnly = false,
  }) async {
    _channelId = channelId;

    // Cleanup when provider is disposed
    ref.onDispose(() {
      _unsubscribe();
      _typingTimer?.cancel();
    });

    // 1. Try to load from cache first for instant UI
    final cachedMessages = await LocalChatCache.getCachedMessages(_channelId);

    // Initial state (potentially from cache)
    final initialState = RealtimeChatState(
      messages: cachedMessages,
      typingUsers: {},
      lastReadStatus: {},
      hasMore:
          true, // Optimistically assume there's more until fetch fails/finishes
    );

    // Try to get other user's last read from details (for private chats)
    try {
      final details = await ref.read(
        privateChatDetailsProvider(_channelId).future,
      );

      if (details != null) {
        if (details.otherUserLastReadAt != null) {
          initialState.lastReadStatus[details.otherResident.userInfoId
                  .toString()] =
              details.otherUserLastReadAt!;
        }

        // Optimization: If pre-warming, check if cache is already fresh
        if (prewarmOnly && cachedMessages.isNotEmpty) {
          final lastKnown = await LocalChatCache.getLastMessageAt(_channelId);
          if (lastKnown != null && details.chat.lastMessageAt != null) {
            // If the last message timestamp matches, skip the fetch
            if (!details.chat.lastMessageAt!.isAfter(lastKnown)) {
              debugPrint(
                'RealtimeChat: Skipping pre-warm fetch for $_channelId (Cache Fresh)',
              );
              _subscribe(); // Still subscribe for real-time updates
              return initialState;
            }
          }
        }
      }
    } catch (_) {
      // Not a private chat or details not available
    }

    // 2. Fetch fresh messages in background and update state
    _fetchAndSyncMessages();

    // Subscribe to real-time updates
    _subscribe();

    return initialState;
  }

  /// Fetches fresh messages and updates state/cache.
  Future<void> _fetchAndSyncMessages() async {
    try {
      final freshMessages = await _fetchMessages();

      // Update state with fresh messages
      if (!ref.mounted) return;
      if (state.value != null) {
        state = AsyncValue.data(
          state.value!.copyWith(
            messages: freshMessages,
            hasMore: freshMessages.length >= 50,
          ),
        );
      }

      // Update cache
      await LocalChatCache.cacheMessages(_channelId, freshMessages);
      if (!ref.mounted) return;
    } catch (e) {
      if (!ref.mounted) return;
      debugPrint('RealtimeChat: Fetch/sync error: $e');
      // If we already have cached data, don't show an error screen entirely
      if (state.value?.messages.isEmpty ?? true) {
        // Re-throw if no data at all
        rethrow;
      }
    }
  }

  /// Fetches message history from the server.
  Future<List<Message>> _fetchMessages({int offset = 0}) async {
    final client = ref.read(clientProvider);
    try {
      return await client.message.listMessages(
        _channelId,
        limit: 50,
        offset: offset,
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

      if (!ref.mounted) return;
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
    try {
      final messages = await _fetchMessages();
      state = AsyncValue.data(
        RealtimeChatState(
          messages: messages,
          typingUsers: state.value?.typingUsers ?? {},
          lastReadStatus: state.value?.lastReadStatus ?? {},
          hasMore: messages.length >= 50,
        ),
      );
      // Update cache
      await LocalChatCache.cacheMessages(_channelId, messages);
    } catch (e, stack) {
      if (state.value?.messages.isEmpty ?? true) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  /// Loads more messages (pagination).
  Future<void> loadMore() async {
    if (state.value == null ||
        !state.value!.hasMore ||
        state.value!.isLoadingMore) {
      return;
    }

    final currentState = state.value!;

    // Set loading flag
    state = AsyncValue.data(currentState.copyWith(isLoadingMore: true));

    try {
      final olderMessages = await _fetchMessages(
        offset: currentState.messages.length,
      );

      if (ref.mounted) {
        final newHasMore = olderMessages.length >= 50;
        state = AsyncValue.data(
          currentState.copyWith(
            messages: [...currentState.messages, ...olderMessages],
            isLoadingMore: false,
            hasMore: newHasMore,
          ),
        );
      }
    } catch (e) {
      debugPrint('RealtimeChat: Load more error: $e');
      if (ref.mounted) {
        state = AsyncValue.data(currentState.copyWith(isLoadingMore: false));
      }
    }
  }
}
