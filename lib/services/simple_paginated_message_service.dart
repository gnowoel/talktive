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
/// This service follows a simpler approach:
/// 1. Fetch recent messages (25-50) on room entry
/// 2. Subscribe to real-time updates for new messages
/// 3. Load older messages on-demand when user scrolls up
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

  /// Safely notify listeners, deferring if called during build phase
  void _safeNotifyListeners() {
    // Check if we're in a build phase by examining the widget binding state
    if (WidgetsBinding.instance.debugDoingBuild) {
      // Defer the notification if we're in build phase
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    } else {
      try {
        notifyListeners();
      } catch (e) {
        // Fallback: if we still get an error, defer the notification
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
      }
    }
  }

  /// Get or create chat pagination state
  SimpleChatPaginationState _getChatState(String chatId) {
    return _chatStates.putIfAbsent(
        chatId, () => SimpleChatPaginationState(chatId));
  }

  /// Get or create topic pagination state
  SimpleTopicPaginationState _getTopicState(String topicId) {
    return _topicStates.putIfAbsent(
        topicId, () => SimpleTopicPaginationState(topicId));
  }

  /// Load chat messages (initial load or refresh)
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

  /// Load more older chat messages
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

  /// Start real-time subscription for chat messages
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

  /// Load more older topic messages
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

  /// Reset chat pagination state
  void resetChatPagination(String chatId) {
    final state = _chatStates[chatId];
    state?.reset();
    // No notification needed for reset - listeners will be notified when data loads
  }

  /// Reset topic pagination state
  void resetTopicPagination(String topicId) {
    final state = _topicStates[topicId];
    state?.reset();
    // No notification needed for reset - listeners will be notified when data loads
  }

  /// Get current chat state (for debugging/monitoring)
  SimpleChatPaginationState? getChatState(String chatId) {
    return _chatStates[chatId];
  }

  /// Get current topic state (for debugging/monitoring)
  SimpleTopicPaginationState? getTopicState(String topicId) {
    return _topicStates[topicId];
  }

  /// Clear chat data and subscription
  void clearChatData(String chatId) {
    final state = _chatStates[chatId];
    if (state != null) {
      state.dispose();
      _chatStates.remove(chatId);
      _safeNotifyListeners();
    }
  }

  /// Clear topic data and subscription
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

  /// Add a new message to chat state (for optimistic updates)
  void addChatMessage(String chatId, Message message) {
    final state = _chatStates[chatId];
    if (state != null) {
      // Avoid duplicates
      if (!state.messages.any((m) => m.id == message.id)) {
        state.messages.add(message);
        state.messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        state.newestTimestamp = message.createdAt;
        _safeNotifyListeners();
      }
    }
  }

  /// Add a new message to topic state (for optimistic updates)
  void addTopicMessage(String topicId, TopicMessage message) {
    final state = _topicStates[topicId];
    if (state != null) {
      // Avoid duplicates
      if (!state.messages.any((m) => m.id == message.id)) {
        state.messages.add(message);
        state.messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        state.newestTimestamp = message.createdAt;
        _safeNotifyListeners();
      }
    }
  }

  @override
  void dispose() {
    // Clean up all subscriptions
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
