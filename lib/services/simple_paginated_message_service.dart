import 'dart:async';

import 'package:flutter/material.dart';

import '../models/message.dart';
import '../models/topic_message.dart';
import '../services/firedata.dart';
import '../services/firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Simplified paginated result without cache indicators
class SimplePaginatedResult<T> {
  final List<T> items;
  final bool hasMore;

  const SimplePaginatedResult({
    required this.items,
    required this.hasMore,
  });
}

/// Simple pagination state for chats
class SimpleChatPaginationState {
  final String chatId;
  bool isLoading = false;
  bool hasMore = true;
  List<Message> messages = [];
  int? oldestTimestamp; // For loading older messages
  int? newestTimestamp; // For real-time updates
  StreamSubscription<List<Message>>? subscription;

  SimpleChatPaginationState(this.chatId);

  void reset() {
    isLoading = false;
    hasMore = true;
    messages.clear();
    oldestTimestamp = null;
    newestTimestamp = null;
    subscription?.cancel();
    subscription = null;
  }

  void dispose() {
    subscription?.cancel();
    subscription = null;
  }
}

/// Simple pagination state for topics
class SimpleTopicPaginationState {
  final String topicId;
  bool isLoading = false;
  bool hasMore = true;
  List<TopicMessage> messages = [];
  Timestamp? oldestTimestamp; // For loading older messages
  Timestamp? newestTimestamp; // For real-time updates
  StreamSubscription? subscription;

  SimpleTopicPaginationState(this.topicId);

  void reset() {
    isLoading = false;
    hasMore = true;
    messages.clear();
    oldestTimestamp = null;
    newestTimestamp = null;
    subscription?.cancel();
    subscription = null;
  }

  void dispose() {
    subscription?.cancel();
    subscription = null;
  }
}

/// Simplified paginated message service without SQLite caching
///
/// This service manages paginated message loading and real-time updates for both
/// chat and topic conversations. It follows a streamlined approach:
///
/// **For Chats:**
/// 1. Load recent messages (25-50) on room entry
/// 2. Subscribe to real-time updates for new messages
/// 3. Load older messages on-demand when user scrolls up
/// 4. Handle optimistic updates for sent messages
///
/// **For Topics:**
/// 1. Load recent topic messages on entry
/// 2. Subscribe to real-time updates for new topic messages
/// 3. Support pagination for older topic messages
///
/// **Key Features:**
/// - No SQLite caching (simplified architecture)
/// - Real-time message subscriptions
/// - Pagination support for both message types
/// - Build-safe notification system
/// - Memory-efficient state management
class SimplePaginatedMessageService extends ChangeNotifier {
  final Firedata _firedata;
  final Firestore _firestore;

  // Pagination states
  final Map<String, SimpleChatPaginationState> _chatStates = {};
  final Map<String, SimpleTopicPaginationState> _topicStates = {};

  // Configuration
  static const int _initialLoadSize = 25;
  static const int _paginationLoadSize = 25;

  SimplePaginatedMessageService(this._firedata, this._firestore);

  /// Safely notify listeners with build-phase protection
  ///
  /// This method attempts to notify listeners immediately, but if called during
  /// a build phase (which would cause a Flutter error), it defers the notification
  /// to the next frame using a post-frame callback.
  void _safeNotifyListeners() {
    try {
      notifyListeners();
    } catch (e) {
      // If we're in build phase, defer the notification
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (hasListeners) {
          notifyListeners();
        }
      });
    }
  }

  /// Get or create chat pagination state for the given chat ID
  SimpleChatPaginationState _getChatState(String chatId) {
    return _chatStates.putIfAbsent(
        chatId, () => SimpleChatPaginationState(chatId));
  }

  /// Get or create topic pagination state for the given topic ID
  SimpleTopicPaginationState _getTopicState(String topicId) {
    return _topicStates.putIfAbsent(
        topicId, () => SimpleTopicPaginationState(topicId));
  }

  /// Load chat messages (initial load or refresh)
  ///
  /// This method loads the most recent messages for a chat and sets up real-time
  /// subscriptions for new messages. It handles both initial loading and refresh
  /// scenarios.
  ///
  /// Parameters:
  /// - [chatId]: The unique identifier for the chat
  /// - [isInitialLoad]: Whether this is the first load (affects caching behavior)
  /// - [chatCreatedAt]: Optional timestamp to filter messages (for new chats)
  Future<SimplePaginatedResult<Message>> loadChatMessages(
    String chatId, {
    bool isInitialLoad = false,
    int? chatCreatedAt,
  }) async {
    final state = _getChatState(chatId);

    if (state.isLoading) {
      return SimplePaginatedResult(
          items: state.messages, hasMore: state.hasMore);
    }

    state.isLoading = true;
    _safeNotifyListeners();

    try {
      List<Message> newMessages;

      if (isInitialLoad || state.messages.isEmpty) {
        // Load most recent messages
        newMessages = await _firedata.fetchMessagesPage(
          chatId,
          limit: _initialLoadSize,
          minCreatedAt: chatCreatedAt,
        );

        // Replace existing messages
        state.messages = newMessages;

        // Update timestamps
        if (newMessages.isNotEmpty) {
          state.oldestTimestamp = newMessages.first.createdAt;
          state.newestTimestamp = newMessages.last.createdAt;

          // Start real-time subscription for new messages
          _startChatRealtimeSubscription(state);
        }

        // Check if there are more older messages
        if (newMessages.length < _initialLoadSize) {
          state.hasMore = false;
        } else {
          // Check if there might be older messages
          final olderMessages = await _firedata.fetchMessagesBeforeTimestamp(
            chatId,
            state.oldestTimestamp!,
            limit: 1,
            minCreatedAt: chatCreatedAt,
          );
          state.hasMore = olderMessages.isNotEmpty;
        }
      }

      return SimplePaginatedResult(
        items: List.from(state.messages),
        hasMore: state.hasMore,
      );
    } catch (e) {
      debugPrint('Error loading chat messages: $e');
      rethrow;
    } finally {
      state.isLoading = false;
      _safeNotifyListeners();
    }
  }

  /// Load more older chat messages for pagination
  ///
  /// Called when user scrolls to the top and more historical messages are needed.
  /// Loads messages before the current oldest timestamp in the state.
  Future<SimplePaginatedResult<Message>> loadMoreChatMessages(
      String chatId) async {
    final state = _getChatState(chatId);

    if (state.isLoading || !state.hasMore || state.oldestTimestamp == null) {
      return SimplePaginatedResult(
          items: state.messages, hasMore: state.hasMore);
    }

    state.isLoading = true;
    _safeNotifyListeners();

    try {
      final olderMessages = await _firedata.fetchMessagesBeforeTimestamp(
        chatId,
        state.oldestTimestamp!,
        limit: _paginationLoadSize,
      );

      if (olderMessages.isNotEmpty) {
        // Insert older messages at the beginning
        state.messages.insertAll(0, olderMessages);
        state.oldestTimestamp = olderMessages.first.createdAt;

        // Check if there are even more older messages
        if (olderMessages.length < _paginationLoadSize) {
          state.hasMore = false;
        } else {
          final evenOlderMessages =
              await _firedata.fetchMessagesBeforeTimestamp(
            chatId,
            state.oldestTimestamp!,
            limit: 1,
          );
          state.hasMore = evenOlderMessages.isNotEmpty;
        }
      } else {
        state.hasMore = false;
      }

      return SimplePaginatedResult(
        items: List.from(state.messages),
        hasMore: state.hasMore,
      );
    } catch (e) {
      debugPrint('Error loading more chat messages: $e');
      rethrow;
    } finally {
      state.isLoading = false;
      _safeNotifyListeners();
    }
  }

  /// Start real-time subscription for new chat messages
  ///
  /// Subscribes to messages created after the newest message in the current state.
  /// New messages are automatically added to the state and UI is updated.
  void _startChatRealtimeSubscription(SimpleChatPaginationState state) {
    state.subscription?.cancel();

    state.subscription = _firedata
        .subscribeToMessages(
      state.chatId,
      state.newestTimestamp,
    )
        .listen((newMessages) {
      if (newMessages.isNotEmpty) {
        // Add new messages and update timestamp
        for (final message in newMessages) {
          // Avoid duplicates
          if (!state.messages.any((m) => m.id == message.id)) {
            state.messages.add(message);
          }
        }

        // Keep messages sorted
        state.messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

        // Update newest timestamp
        state.newestTimestamp = state.messages.last.createdAt;

        _safeNotifyListeners();
      }
    });
  }

  /// Load topic messages (initial load or refresh)
  ///
  /// Similar to chat message loading but for topic conversations. Sets up both
  /// initial message loading and real-time subscriptions for new topic messages.
  ///
  /// Parameters:
  /// - [topicId]: The unique identifier for the topic
  /// - [isInitialLoad]: Whether this is the first load for this topic
  Future<SimplePaginatedResult<TopicMessage>> loadTopicMessages(
    String topicId, {
    bool isInitialLoad = false,
  }) async {
    final state = _getTopicState(topicId);

    if (state.isLoading) {
      return SimplePaginatedResult(
          items: state.messages, hasMore: state.hasMore);
    }

    state.isLoading = true;
    _safeNotifyListeners();

    try {
      List<TopicMessage> newMessages;

      if (isInitialLoad || state.messages.isEmpty) {
        // Load most recent messages
        newMessages = await _firestore.fetchTopicMessagesPage(
          topicId,
          limit: _initialLoadSize,
        );

        // Replace existing messages
        state.messages = newMessages;

        // Update timestamps
        if (newMessages.isNotEmpty) {
          state.oldestTimestamp = newMessages.first.createdAt;
          state.newestTimestamp = newMessages.last.createdAt;

          // Start real-time subscription for new messages
          _startTopicRealtimeSubscription(state);
        }

        // Check if there are more older messages
        if (newMessages.length < _initialLoadSize) {
          state.hasMore = false;
        } else {
          // Check if there might be older messages
          final olderMessages =
              await _firestore.fetchTopicMessagesBeforeTimestamp(
            topicId,
            state.oldestTimestamp!.toDate(),
            limit: 1,
          );
          state.hasMore = olderMessages.isNotEmpty;
        }
      }

      return SimplePaginatedResult(
        items: List.from(state.messages),
        hasMore: state.hasMore,
      );
    } catch (e) {
      debugPrint('Error loading topic messages: $e');
      rethrow;
    } finally {
      state.isLoading = false;
      _safeNotifyListeners();
    }
  }

  /// Load more older topic messages for pagination
  ///
  /// Loads historical topic messages when user scrolls up, similar to chat pagination.
  Future<SimplePaginatedResult<TopicMessage>> loadMoreTopicMessages(
      String topicId) async {
    final state = _getTopicState(topicId);

    if (state.isLoading || !state.hasMore || state.oldestTimestamp == null) {
      return SimplePaginatedResult(
          items: state.messages, hasMore: state.hasMore);
    }

    state.isLoading = true;
    _safeNotifyListeners();

    try {
      final olderMessages = await _firestore.fetchTopicMessagesBeforeTimestamp(
        topicId,
        state.oldestTimestamp!.toDate(),
        limit: _paginationLoadSize,
      );

      if (olderMessages.isNotEmpty) {
        // Insert older messages at the beginning
        state.messages.insertAll(0, olderMessages);
        state.oldestTimestamp = olderMessages.first.createdAt;

        // Check if there are even more older messages
        if (olderMessages.length < _paginationLoadSize) {
          state.hasMore = false;
        } else {
          final evenOlderMessages =
              await _firestore.fetchTopicMessagesBeforeTimestamp(
            topicId,
            state.oldestTimestamp!.toDate(),
            limit: 1,
          );
          state.hasMore = evenOlderMessages.isNotEmpty;
        }
      } else {
        state.hasMore = false;
      }

      return SimplePaginatedResult(
        items: List.from(state.messages),
        hasMore: state.hasMore,
      );
    } catch (e) {
      debugPrint('Error loading more topic messages: $e');
      rethrow;
    } finally {
      state.isLoading = false;
      _safeNotifyListeners();
    }
  }

  /// Reset chat pagination state to initial conditions
  ///
  /// Clears all cached messages, cancels subscriptions, and resets pagination flags.
  /// Called when entering a chat to ensure fresh loading state.
  void resetChatPagination(String chatId) {
    final state = _chatStates[chatId];
    state?.reset();
    // No notification needed - listeners will be notified when data loads
  }

  /// Reset topic pagination state to initial conditions
  ///
  /// Clears all cached messages, cancels subscriptions, and resets pagination flags.
  /// Called when entering a topic to ensure fresh loading state.
  void resetTopicPagination(String topicId) {
    final state = _topicStates[topicId];
    state?.reset();
    // No notification needed - listeners will be notified when data loads
  }

  /// Get current chat state (for debugging/monitoring)
  SimpleChatPaginationState? getChatState(String chatId) {
    return _chatStates[chatId];
  }

  /// Get current topic state (for debugging/monitoring)
  SimpleTopicPaginationState? getTopicState(String topicId) {
    return _topicStates[topicId];
  }

  /// Clear chat data and subscription completely
  ///
  /// Removes all cached data for a chat and cancels its real-time subscription.
  /// Used for memory management when a chat is no longer needed.
  void clearChatData(String chatId) {
    final state = _chatStates[chatId];
    if (state != null) {
      state.dispose();
      _chatStates.remove(chatId);
      _safeNotifyListeners();
    }
  }

  /// Clear topic data and subscription completely
  ///
  /// Removes all cached data for a topic and cancels its real-time subscription.
  /// Used for memory management when a topic is no longer needed.
  void clearTopicData(String topicId) {
    final state = _topicStates[topicId];
    if (state != null) {
      state.dispose();
      _topicStates.remove(topicId);
      _safeNotifyListeners();
    }
  }

  /// Start real-time subscription for topic messages
  void _startTopicRealtimeSubscription(SimpleTopicPaginationState state) {
    state.subscription?.cancel();

    // Convert Timestamp to milliseconds for the subscription
    final newestTimestampMs = state.newestTimestamp?.millisecondsSinceEpoch;

    state.subscription = _firestore
        .subscribeToTopicMessages(
      state.topicId,
      newestTimestampMs,
    )
        .listen((newMessages) {
      if (newMessages.isNotEmpty) {
        // Add new messages and update timestamp
        for (final message in newMessages) {
          // Avoid duplicates
          if (!state.messages.any((m) => m.id == message.id)) {
            state.messages.add(message);
          }
        }

        // Keep messages sorted
        state.messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

        // Update newest timestamp
        state.newestTimestamp = state.messages.last.createdAt;

        _safeNotifyListeners();
      }
    });
  }

  /// Add a new message to chat state for optimistic updates
  ///
  /// Used to immediately show sent messages in the UI before server confirmation.
  /// Includes duplicate detection to prevent message duplication.
  void addChatMessage(String chatId, Message message) {
    final state = _chatStates[chatId];
    if (state != null && !state.messages.any((m) => m.id == message.id)) {
      state.messages.add(message);
      state.messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      state.newestTimestamp = message.createdAt;
      _safeNotifyListeners();
    }
  }

  /// Add a new message to topic state for optimistic updates
  ///
  /// Used to immediately show sent topic messages in the UI before server confirmation.
  /// Includes duplicate detection to prevent message duplication.
  void addTopicMessage(String topicId, TopicMessage message) {
    final state = _topicStates[topicId];
    if (state != null && !state.messages.any((m) => m.id == message.id)) {
      state.messages.add(message);
      state.messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      state.newestTimestamp = message.createdAt;
      _safeNotifyListeners();
    }
  }

  @override
  void dispose() {
    // Clean up all subscriptions and clear state maps
    for (final state in _chatStates.values) {
      state.dispose();
    }
    for (final state in _topicStates.values) {
      state.dispose();
    }
    _chatStates.clear();
    _topicStates.clear();
    super.dispose();
  }
}
