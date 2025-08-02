import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';

import '../models/chat_message.dart';
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

  // Use LinkedHashMap for ordered, efficient deduplication
  final LinkedHashMap<String, ChatMessage> _messageMap = LinkedHashMap();

  int? oldestTimestamp; // For loading older messages
  int? newestTimestamp; // For real-time updates
  StreamSubscription<List<ChatMessage>>? subscription;

  // Memory management
  static int maxMessagesInMemory = 200;
  static int messagesToRemoveOnCleanup = 50;
  DateTime lastAccessed = DateTime.now();

  // Track actual total message count from server
  int? totalMessageCount;

  SimpleChatPaginationState(this.chatId);

  List<ChatMessage> get messages {
    lastAccessed = DateTime.now();
    final list = _messageMap.values.toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  void addMessages(List<ChatMessage> newMessages) {
    for (final message in newMessages) {
      if (message.id != null) {
        _messageMap[message.id!] = message;
      }
    }

    // Update timestamps
    if (newMessages.isNotEmpty) {
      final sorted = newMessages.toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      final oldestNew = sorted.first.createdAt;
      final newestNew = sorted.last.createdAt;

      if (oldestTimestamp == null || oldestNew < oldestTimestamp!) {
        oldestTimestamp = oldestNew;
      }

      if (newestTimestamp == null || newestNew > newestTimestamp!) {
        newestTimestamp = newestNew;
      }
    }

    // Clean up old messages if we exceed the limit
    if (_messageMap.length > maxMessagesInMemory) {
      _trimOldMessages();
    }
  }

  void _trimOldMessages() {
    final sorted = messages; // Already sorted
    if (sorted.length <= maxMessagesInMemory) return;

    // Keep the newest messages
    final toKeep = sorted
        .skip(sorted.length - (maxMessagesInMemory - messagesToRemoveOnCleanup))
        .toList();

    _messageMap.clear();
    for (final message in toKeep) {
      if (message.id != null) {
        _messageMap[message.id!] = message;
      }
    }

    // Update oldest timestamp
    if (toKeep.isNotEmpty) {
      oldestTimestamp = toKeep.first.createdAt;
    }
  }

  void reset() {
    isLoading = false;
    hasMore = true;
    _messageMap.clear();
    oldestTimestamp = null;
    newestTimestamp = null;
    subscription?.cancel();
    subscription = null;
    lastAccessed = DateTime.now();
    totalMessageCount = null;
  }

  void dispose() {
    subscription?.cancel();
    subscription = null;
    _messageMap.clear();
  }
}

/// Simple pagination state for topics
class SimpleTopicPaginationState {
  final String topicId;
  bool isLoading = false;
  bool hasMore = true;

  // Use LinkedHashMap for ordered, efficient deduplication
  final LinkedHashMap<String, TopicMessage> _messageMap = LinkedHashMap();

  Timestamp? oldestTimestamp; // For loading older messages
  Timestamp? newestTimestamp; // For real-time updates
  StreamSubscription? subscription;

  // Memory management
  static int maxMessagesInMemory = 200;
  static int messagesToRemoveOnCleanup = 50;
  DateTime lastAccessed = DateTime.now();

  // Track actual total message count from server
  int? totalMessageCount;

  SimpleTopicPaginationState(this.topicId);

  List<TopicMessage> get messages {
    lastAccessed = DateTime.now();
    final list = _messageMap.values.toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  void addMessages(List<TopicMessage> newMessages) {
    for (final message in newMessages) {
      if (message.id != null) {
        _messageMap[message.id!] = message;
      }
    }

    // Update timestamps
    if (newMessages.isNotEmpty) {
      final sorted = newMessages.toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      final oldestNew = sorted.first.createdAt;
      final newestNew = sorted.last.createdAt;

      if (oldestTimestamp == null ||
          oldestNew.compareTo(oldestTimestamp!) < 0) {
        oldestTimestamp = oldestNew;
      }

      if (newestTimestamp == null ||
          newestNew.compareTo(newestTimestamp!) > 0) {
        newestTimestamp = newestNew;
      }
    }

    // Clean up old messages if we exceed the limit
    if (_messageMap.length > maxMessagesInMemory) {
      _trimOldMessages();
    }
  }

  void _trimOldMessages() {
    final sorted = messages; // Already sorted
    if (sorted.length <= maxMessagesInMemory) return;

    // Keep the newest messages
    final toKeep = sorted
        .skip(sorted.length - (maxMessagesInMemory - messagesToRemoveOnCleanup))
        .toList();

    _messageMap.clear();
    for (final message in toKeep) {
      if (message.id != null) {
        _messageMap[message.id!] = message;
      }
    }

    // Update oldest timestamp
    if (toKeep.isNotEmpty) {
      oldestTimestamp = toKeep.first.createdAt;
    }
  }

  void reset() {
    isLoading = false;
    hasMore = true;
    _messageMap.clear();
    oldestTimestamp = null;
    newestTimestamp = null;
    subscription?.cancel();
    subscription = null;
    lastAccessed = DateTime.now();
    totalMessageCount = null;
  }

  void dispose() {
    subscription?.cancel();
    subscription = null;
    _messageMap.clear();
  }
}

/// Simplified paginated message service for chat and topic messages
class PaginatedMessageService extends ChangeNotifier {
  final Firedata _firedata;
  final Firestore _firestore;

  // Pagination states
  final Map<String, SimpleChatPaginationState> _chatStates = {};
  final Map<String, SimpleTopicPaginationState> _topicStates = {};

  // Configuration
  static int _initialLoadSize = 25;
  static int _paginationLoadSize = 25;
  static const int _maxCachedStates = 10;
  static const Duration _stateExpirationDuration = Duration(minutes: 5);

  // Cleanup timer
  Timer? _cleanupTimer;

  PaginatedMessageService(this._firedata, this._firestore) {
    // Adjust for low-end devices
    if (Platform.numberOfProcessors <= 2) {
      _initialLoadSize = 15;
      _paginationLoadSize = 15;
      SimpleChatPaginationState.maxMessagesInMemory = 100;
      SimpleChatPaginationState.messagesToRemoveOnCleanup = 25;
      SimpleTopicPaginationState.maxMessagesInMemory = 100;
      SimpleTopicPaginationState.messagesToRemoveOnCleanup = 25;
    }

    // Start periodic cleanup
    _cleanupTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      _performStateCleanup();
    });
  }

  // Cleanup old/unused states to free memory
  void _performStateCleanup() {
    final now = DateTime.now();

    // Clean up chat states
    _chatStates.removeWhere((id, state) {
      final shouldRemove =
          now.difference(state.lastAccessed) > _stateExpirationDuration;
      if (shouldRemove) {
        state.dispose();
      }
      return shouldRemove;
    });

    // Clean up topic states
    _topicStates.removeWhere((id, state) {
      final shouldRemove =
          now.difference(state.lastAccessed) > _stateExpirationDuration;
      if (shouldRemove) {
        state.dispose();
      }
      return shouldRemove;
    });

    // Enforce max cached states (LRU)
    _enforceMaxCachedStates();
  }

  void _enforceMaxCachedStates() {
    if (_chatStates.length > _maxCachedStates) {
      final sorted = _chatStates.entries.toList()
        ..sort((a, b) => a.value.lastAccessed.compareTo(b.value.lastAccessed));

      final toRemove = sorted.take(_chatStates.length - _maxCachedStates);
      for (final entry in toRemove) {
        entry.value.dispose();
        _chatStates.remove(entry.key);
      }
    }

    if (_topicStates.length > _maxCachedStates) {
      final sorted = _topicStates.entries.toList()
        ..sort((a, b) => a.value.lastAccessed.compareTo(b.value.lastAccessed));

      final toRemove = sorted.take(_topicStates.length - _maxCachedStates);
      for (final entry in toRemove) {
        entry.value.dispose();
        _topicStates.remove(entry.key);
      }
    }
  }

  // Safely notify listeners
  void _safeNotifyListeners() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hasListeners) {
        notifyListeners();
      }
    });
  }

  // Get or create chat pagination state
  SimpleChatPaginationState _getChatState(String chatId) {
    return _chatStates.putIfAbsent(
        chatId, () => SimpleChatPaginationState(chatId));
  }

  // Get or create topic pagination state
  SimpleTopicPaginationState _getTopicState(String topicId) {
    return _topicStates.putIfAbsent(
        topicId, () => SimpleTopicPaginationState(topicId));
  }

  // Load chat messages (initial load or refresh)
  Future<SimplePaginatedResult<ChatMessage>> loadChatMessages(
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
      if (isInitialLoad || state._messageMap.isEmpty) {
        // Cancel existing subscription
        state.subscription?.cancel();

        // Load most recent messages
        final newMessages = await _firedata.fetchMessagesPage(
          chatId,
          limit: _initialLoadSize,
          minCreatedAt: chatCreatedAt,
        );

        // Clear and add new messages
        state._messageMap.clear();
        state.oldestTimestamp = null;
        state.newestTimestamp = null;

        state.addMessages(newMessages);

        // Start real-time subscription if we have messages
        if (newMessages.isNotEmpty) {
          _startChatRealtimeSubscription(state);
        }

        // Check if there are more older messages
        state.hasMore = newMessages.length >= _initialLoadSize;
      }

      return SimplePaginatedResult(
        items: state.messages,
        hasMore: state.hasMore,
      );
    } catch (e) {
      debugPrint('Error loading chat messages: $e');
      return SimplePaginatedResult(
        items: state.messages,
        hasMore: state.hasMore,
      );
    } finally {
      state.isLoading = false;
      _safeNotifyListeners();
    }
  }

  // Load more older chat messages for pagination
  Future<SimplePaginatedResult<ChatMessage>> loadMoreChatMessages(
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
        state.addMessages(olderMessages);
        state.hasMore = olderMessages.length >= _paginationLoadSize;
      } else {
        state.hasMore = false;
      }

      return SimplePaginatedResult(
        items: state.messages,
        hasMore: state.hasMore,
      );
    } catch (e) {
      debugPrint('Error loading more chat messages: $e');
      return SimplePaginatedResult(
        items: state.messages,
        hasMore: state.hasMore,
      );
    } finally {
      state.isLoading = false;
      _safeNotifyListeners();
    }
  }

  // Start real-time subscription for new chat messages
  void _startChatRealtimeSubscription(SimpleChatPaginationState state) {
    state.subscription?.cancel();

    if (state.newestTimestamp == null) return;

    state.subscription = _firedata
        .subscribeToMessages(state.chatId, state.newestTimestamp!)
        .listen((newMessages) {
      if (newMessages.isNotEmpty) {
        state.addMessages(newMessages);
        _safeNotifyListeners();
      }
    }, onError: (error) {
      debugPrint('Chat subscription error: $error');
    });
  }

  // Load topic messages (initial load or refresh)
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
      if (isInitialLoad || state._messageMap.isEmpty) {
        // Cancel existing subscription
        state.subscription?.cancel();

        // Load most recent messages
        final newMessages = await _firestore.fetchTopicMessagesPage(
          topicId,
          limit: _initialLoadSize,
        );

        // Clear and add new messages
        state._messageMap.clear();
        state.oldestTimestamp = null;
        state.newestTimestamp = null;

        state.addMessages(newMessages);

        // Start real-time subscription if we have messages
        if (newMessages.isNotEmpty) {
          _startTopicRealtimeSubscription(state);
        }

        // Check if there are more older messages
        state.hasMore = newMessages.length >= _initialLoadSize;
      }

      return SimplePaginatedResult(
        items: state.messages,
        hasMore: state.hasMore,
      );
    } catch (e) {
      debugPrint('Error loading topic messages: $e');
      return SimplePaginatedResult(
        items: state.messages,
        hasMore: state.hasMore,
      );
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
        state.addMessages(olderMessages);
        state.hasMore = olderMessages.length >= _paginationLoadSize;
      } else {
        state.hasMore = false;
      }

      return SimplePaginatedResult(
        items: state.messages,
        hasMore: state.hasMore,
      );
    } catch (e) {
      debugPrint('Error loading more topic messages: $e');
      return SimplePaginatedResult(
        items: state.messages,
        hasMore: state.hasMore,
      );
    } finally {
      state.isLoading = false;
      _safeNotifyListeners();
    }
  }

  // Start real-time subscription for topic messages
  void _startTopicRealtimeSubscription(SimpleTopicPaginationState state) {
    state.subscription?.cancel();

    final newestTimestampMs = state.newestTimestamp?.millisecondsSinceEpoch;
    if (newestTimestampMs == null) return;

    state.subscription = _firestore
        .subscribeToTopicMessages(state.topicId, newestTimestampMs)
        .listen((newMessages) {
      if (newMessages.isNotEmpty) {
        state.addMessages(newMessages);
        _safeNotifyListeners();
      }
    }, onError: (error) {
      debugPrint('Topic subscription error: $error');
    });
  }

  // Reset chat pagination state to initial conditions
  void resetChatPagination(String chatId) {
    final state = _chatStates[chatId];
    state?.reset();
  }

  // Reset topic pagination state to initial conditions
  void resetTopicPagination(String topicId) {
    final state = _topicStates[topicId];
    state?.reset();
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

  // Add a new message to chat state for optimistic updates
  void addChatMessage(String chatId, ChatMessage message) {
    final state = _chatStates[chatId];
    if (state != null && message.id != null) {
      state.addMessages([message]);
      // Increment total message count for optimistic updates
      if (state.totalMessageCount != null) {
        state.totalMessageCount = state.totalMessageCount! + 1;
      }
      _safeNotifyListeners();
    }
  }

  // Add a new message to topic state for optimistic updates
  void addTopicMessage(String topicId, TopicMessage message) {
    final state = _topicStates[topicId];
    if (state != null && message.id != null) {
      state.addMessages([message]);
      // Increment total message count for optimistic updates
      if (state.totalMessageCount != null) {
        state.totalMessageCount = state.totalMessageCount! + 1;
      }
      _safeNotifyListeners();
    }
  }

  // Update total message count for a chat
  void updateChatTotalMessageCount(String chatId, int totalCount) {
    final state = _chatStates[chatId];
    if (state != null) {
      state.totalMessageCount = totalCount;
      _safeNotifyListeners();
    }
  }

  // Update total message count for a topic
  void updateTopicTotalMessageCount(String topicId, int totalCount) {
    final state = _topicStates[topicId];
    if (state != null) {
      state.totalMessageCount = totalCount;
      _safeNotifyListeners();
    }
  }

  // Get total message count for a chat
  int? getChatTotalMessageCount(String chatId) {
    return _chatStates[chatId]?.totalMessageCount;
  }

  // Get total message count for a topic
  int? getTopicTotalMessageCount(String topicId) {
    return _topicStates[topicId]?.totalMessageCount;
  }

  @override
  void dispose() {
    // Cancel cleanup timer
    _cleanupTimer?.cancel();

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
