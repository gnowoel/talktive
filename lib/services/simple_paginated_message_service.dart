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

// Simplified paginated message service for chat and topic messages
// Handles loading, pagination, real-time updates, and optimistic updates for both workflows
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

  // Safely notify listeners with build-phase protection
  void _safeNotifyListeners() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) {
        notifyListeners();
      }
    });
  }

  // Get or create chat pagination state for the given chat ID
  SimpleChatPaginationState _getChatState(String chatId) {
    return _chatStates.putIfAbsent(
        chatId, () => SimpleChatPaginationState(chatId));
  }

  // Get or create topic pagination state for the given topic ID
  SimpleTopicPaginationState _getTopicState(String topicId) {
    return _topicStates.putIfAbsent(
        topicId, () => SimpleTopicPaginationState(topicId));
  }

  // Load chat messages (initial load or refresh)
  // Sets up real-time subscriptions for new messages
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

  // Load more older chat messages for pagination
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

  // Start real-time subscription for new chat messages
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

  // Load topic messages (initial load or refresh)
  // Sets up real-time subscriptions for new messages
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

  // Load more older topic messages for pagination
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

  // Reset chat pagination state to initial conditions
  void resetChatPagination(String chatId) {
    final state = _chatStates[chatId];
    state?.reset();
    // No notification needed - listeners will be notified when data loads
  }

  // Reset topic pagination state to initial conditions
  void resetTopicPagination(String topicId) {
    final state = _topicStates[topicId];
    state?.reset();
    // No notification needed - listeners will be notified when data loads
  }

  // Get current chat state (for debugging/monitoring)
  SimpleChatPaginationState? getChatState(String chatId) {
    return _chatStates[chatId];
  }

  // Get current topic state (for debugging/monitoring)
  SimpleTopicPaginationState? getTopicState(String topicId) {
    return _topicStates[topicId];
  }

  // Clear chat data and subscription completely
  void clearChatData(String chatId) {
    final state = _chatStates[chatId];
    if (state != null) {
      state.dispose();
      _chatStates.remove(chatId);
      _safeNotifyListeners();
    }
  }

  // Clear topic data and subscription completely
  void clearTopicData(String topicId) {
    final state = _topicStates[topicId];
    if (state != null) {
      state.dispose();
      _topicStates.remove(topicId);
      _safeNotifyListeners();
    }
  }

  // Start real-time subscription for topic messages
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

  // Add a new message to chat state for optimistic updates
  // Used to immediately show sent messages before server confirmation
  void addChatMessage(String chatId, Message message) {
    final state = _chatStates[chatId];
    if (state != null && !state.messages.any((m) => m.id == message.id)) {
      state.messages.add(message);
      state.messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      state.newestTimestamp = message.createdAt;
      _safeNotifyListeners();
    }
  }

  // Add a new message to topic state for optimistic updates
  // Used to immediately show sent topic messages before server confirmation
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
