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

/// Optimized pagination state for chats with memory management
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

  SimpleChatPaginationState(this.chatId);

  List<ChatMessage> get messages {
    lastAccessed = DateTime.now();
    return _messageMap.values.toList();
  }

  void addMessages(List<ChatMessage> newMessages, {bool prepend = false}) {
    for (final message in newMessages) {
      if (message.id != null) {
        _messageMap[message.id!] = message;
      }
    }

    // Maintain sorted order
    final sortedEntries = _messageMap.entries.toList()
      ..sort((a, b) => a.value.createdAt.compareTo(b.value.createdAt));

    _messageMap.clear();
    _messageMap.addEntries(sortedEntries);

    // Clean up old messages if we exceed the limit
    if (_messageMap.length > maxMessagesInMemory) {
      _trimOldMessages();
    }
  }

  void _trimOldMessages() {
    if (_messageMap.length <= maxMessagesInMemory) return;

    final entriesToKeep = _messageMap.entries
        .toList()
        .skip(_messageMap.length -
            (maxMessagesInMemory - messagesToRemoveOnCleanup))
        .toList();

    _messageMap.clear();
    _messageMap.addEntries(entriesToKeep);

    // Update oldest timestamp to reflect trimmed messages
    if (_messageMap.isNotEmpty) {
      oldestTimestamp = _messageMap.values.first.createdAt;
      hasMore = true; // We know there are older messages since we trimmed
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
  }

  void dispose() {
    subscription?.cancel();
    subscription = null;
    _messageMap.clear();
  }
}

/// Optimized pagination state for topics with memory management
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

  SimpleTopicPaginationState(this.topicId);

  List<TopicMessage> get messages {
    lastAccessed = DateTime.now();
    return _messageMap.values.toList();
  }

  void addMessages(List<TopicMessage> newMessages, {bool prepend = false}) {
    for (final message in newMessages) {
      if (message.id != null) {
        _messageMap[message.id!] = message;
      }
    }

    // Maintain sorted order
    final sortedEntries = _messageMap.entries.toList()
      ..sort((a, b) => a.value.createdAt.compareTo(b.value.createdAt));

    _messageMap.clear();
    _messageMap.addEntries(sortedEntries);

    // Clean up old messages if we exceed the limit
    if (_messageMap.length > maxMessagesInMemory) {
      _trimOldMessages();
    }
  }

  void _trimOldMessages() {
    if (_messageMap.length <= maxMessagesInMemory) return;

    final entriesToKeep = _messageMap.entries
        .toList()
        .skip(_messageMap.length -
            (maxMessagesInMemory - messagesToRemoveOnCleanup))
        .toList();

    _messageMap.clear();
    _messageMap.addEntries(entriesToKeep);

    // Update oldest timestamp to reflect trimmed messages
    if (_messageMap.isNotEmpty) {
      oldestTimestamp = _messageMap.values.first.createdAt;
      hasMore = true; // We know there are older messages since we trimmed
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
  }

  void dispose() {
    subscription?.cancel();
    subscription = null;
    _messageMap.clear();
  }
}

// Optimized paginated message service with better memory management
class PaginatedMessageService extends ChangeNotifier {
  final Firedata _firedata;
  final Firestore _firestore;

  // Pagination states with LRU-style cleanup
  final Map<String, SimpleChatPaginationState> _chatStates = {};
  final Map<String, SimpleTopicPaginationState> _topicStates = {};

  // Configuration with adaptive load sizes
  static int _initialLoadSize = 25;
  static int _paginationLoadSize = 25;
  static const int _maxCachedStates = 10; // Limit cached states
  static const Duration _stateExpirationDuration = Duration(minutes: 5);

  // Device performance levels
  static bool _performanceDetected = false;
  static bool _isLowEndDevice = false;

  // Cleanup timer
  Timer? _cleanupTimer;

  PaginatedMessageService(this._firedata, this._firestore) {
    // Detect device performance on first initialization
    if (!_performanceDetected) {
      _detectDevicePerformance();
      _performanceDetected = true;
    }

    // Start periodic cleanup
    _cleanupTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _performStateCleanup();
    });
  }

  // Detect device performance and adjust configuration
  void _detectDevicePerformance() {
    try {
      // Get available memory (in MB)
      final totalMemory = Platform.numberOfProcessors;

      // Simple heuristic: consider devices with <= 2 cores as low-end
      // Also check if we're on older Android/iOS versions
      _isLowEndDevice = totalMemory <= 2;

      // Adjust load sizes based on device performance
      if (_isLowEndDevice) {
        _initialLoadSize = 15; // Reduced from 25
        _paginationLoadSize = 15; // Reduced from 25
        SimpleChatPaginationState.maxMessagesInMemory = 100; // Reduced from 200
        SimpleChatPaginationState.messagesToRemoveOnCleanup =
            25; // Reduced from 50
        SimpleTopicPaginationState.maxMessagesInMemory =
            100; // Reduced from 200
        SimpleTopicPaginationState.messagesToRemoveOnCleanup =
            25; // Reduced from 50
      }

      debugPrint(
          'Device performance detected: ${_isLowEndDevice ? "Low-end" : "Normal"} device');
      debugPrint(
          'Initial load size: $_initialLoadSize, Pagination size: $_paginationLoadSize');
    } catch (e) {
      // If detection fails, keep default values
      debugPrint('Failed to detect device performance: $e');
    }
  }

  // Cleanup old/unused states to free memory
  void _performStateCleanup() {
    final now = DateTime.now();

    // Clean up chat states
    final chatStatesToRemove = <String>[];
    _chatStates.forEach((id, state) {
      if (now.difference(state.lastAccessed) > _stateExpirationDuration) {
        state.dispose();
        chatStatesToRemove.add(id);
      }
    });
    chatStatesToRemove.forEach(_chatStates.remove);

    // Clean up topic states
    final topicStatesToRemove = <String>[];
    _topicStates.forEach((id, state) {
      if (now.difference(state.lastAccessed) > _stateExpirationDuration) {
        state.dispose();
        topicStatesToRemove.add(id);
      }
    });
    topicStatesToRemove.forEach(_topicStates.remove);

    // If we still have too many states, remove least recently used
    if (_chatStates.length > _maxCachedStates) {
      final sortedEntries = _chatStates.entries.toList()
        ..sort((a, b) => a.value.lastAccessed.compareTo(b.value.lastAccessed));

      final toRemove =
          sortedEntries.take(_chatStates.length - _maxCachedStates);
      for (final entry in toRemove) {
        entry.value.dispose();
        _chatStates.remove(entry.key);
      }
    }

    if (_topicStates.length > _maxCachedStates) {
      final sortedEntries = _topicStates.entries.toList()
        ..sort((a, b) => a.value.lastAccessed.compareTo(b.value.lastAccessed));

      final toRemove =
          sortedEntries.take(_topicStates.length - _maxCachedStates);
      for (final entry in toRemove) {
        entry.value.dispose();
        _topicStates.remove(entry.key);
      }
    }
  }

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
      List<ChatMessage> newMessages;

      if (isInitialLoad || state._messageMap.isEmpty) {
        // Load most recent messages
        newMessages = await _firedata.fetchMessagesPage(
          chatId,
          limit: _initialLoadSize,
          minCreatedAt: chatCreatedAt,
        );

        // Clear and add new messages
        state._messageMap.clear();
        state.addMessages(newMessages);

        // Update timestamps
        if (newMessages.isNotEmpty) {
          state.oldestTimestamp = newMessages.first.createdAt;
          state.newestTimestamp = newMessages.last.createdAt;

          // Start real-time subscription for new messages
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
      // On error, return current state
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
        // Add older messages
        state.addMessages(olderMessages, prepend: true);
        state.oldestTimestamp = state.messages.first.createdAt;

        // Update hasMore
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

    state.subscription = _firedata
        .subscribeToMessages(
      state.chatId,
      state.newestTimestamp,
    )
        .listen((newMessages) {
      if (newMessages.isNotEmpty) {
        // Add new messages efficiently
        state.addMessages(newMessages);

        // Update newest timestamp
        if (state._messageMap.isNotEmpty) {
          state.newestTimestamp = state.messages.last.createdAt;
        }

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
      List<TopicMessage> newMessages;

      if (isInitialLoad || state._messageMap.isEmpty) {
        // Load most recent messages
        newMessages = await _firestore.fetchTopicMessagesPage(
          topicId,
          limit: _initialLoadSize,
        );

        // Clear and add new messages
        state._messageMap.clear();
        state.addMessages(newMessages);

        // Update timestamps
        if (newMessages.isNotEmpty) {
          state.oldestTimestamp = newMessages.first.createdAt;
          state.newestTimestamp = newMessages.last.createdAt;

          // Start real-time subscription for new messages
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
        // Add older messages
        state.addMessages(olderMessages, prepend: true);
        state.oldestTimestamp = state.messages.first.createdAt;

        // Update hasMore
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

    // Convert Timestamp to milliseconds for the subscription
    final newestTimestampMs = state.newestTimestamp?.millisecondsSinceEpoch;

    state.subscription = _firestore
        .subscribeToTopicMessages(
      state.topicId,
      newestTimestampMs,
    )
        .listen((newMessages) {
      if (newMessages.isNotEmpty) {
        // Add new messages efficiently
        state.addMessages(newMessages);

        // Update newest timestamp
        if (state._messageMap.isNotEmpty) {
          state.newestTimestamp = state.messages.last.createdAt;
        }

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
      state.newestTimestamp = message.createdAt;
      _safeNotifyListeners();
    }
  }

  // Add a new message to topic state for optimistic updates
  void addTopicMessage(String topicId, TopicMessage message) {
    final state = _topicStates[topicId];
    if (state != null && message.id != null) {
      state.addMessages([message]);
      state.newestTimestamp = message.createdAt;
      _safeNotifyListeners();
    }
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
