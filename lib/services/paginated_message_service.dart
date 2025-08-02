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

/// Optimized pagination state for chats with better synchronization
class SimpleChatPaginationState {
  final String chatId;
  bool isLoading = false;
  bool hasMore = true;

  // Use separate collections for different message ranges
  final LinkedHashMap<String, ChatMessage> _messageMap = LinkedHashMap();
  final _lock = Object();

  // Timestamp tracking
  int? oldestLoadedTimestamp; // Oldest message we've loaded
  int? newestLoadedTimestamp; // Newest message we've loaded
  int? serverNewestTimestamp; // Latest message on server (for real-time)

  StreamSubscription<List<ChatMessage>>? subscription;

  // Memory management
  static int maxMessagesInMemory = 200;
  static int messagesToRemoveOnCleanup = 50;
  DateTime lastAccessed = DateTime.now();

  // Track actual total message count from server
  int? totalMessageCount;

  // Track if we've done initial load
  bool hasInitiallyLoaded = false;

  SimpleChatPaginationState(this.chatId);

  List<ChatMessage> get messages {
    synchronized(_lock, () {
      lastAccessed = DateTime.now();
      final sortedMessages = _messageMap.values.toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return sortedMessages;
    });
  }

  void addMessages(List<ChatMessage> newMessages, {bool isHistorical = false}) {
    synchronized(_lock, () {
      // Add messages
      for (final message in newMessages) {
        if (message.id != null) {
          _messageMap[message.id!] = message;
        }
      }

      // Update timestamps based on message type
      if (newMessages.isNotEmpty) {
        final sortedNew = newMessages.toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

        if (isHistorical) {
          // Loading older messages
          final oldestNew = sortedNew.first.createdAt;
          if (oldestLoadedTimestamp == null ||
              oldestNew < oldestLoadedTimestamp!) {
            oldestLoadedTimestamp = oldestNew;
          }
        } else {
          // Real-time or initial load
          final newestNew = sortedNew.last.createdAt;
          if (newestLoadedTimestamp == null ||
              newestNew > newestLoadedTimestamp!) {
            newestLoadedTimestamp = newestNew;
          }
        }
      }

      // Trim if needed
      if (_messageMap.length > maxMessagesInMemory) {
        _trimOldMessages();
      }
    });
  }

  void _trimOldMessages() {
    // Sort messages by timestamp
    final sortedEntries = _messageMap.entries.toList()
      ..sort((a, b) => a.value.createdAt.compareTo(b.value.createdAt));

    // Calculate how many to keep
    final keepCount = maxMessagesInMemory - messagesToRemoveOnCleanup;

    // Keep the newest messages
    final entriesToKeep =
        sortedEntries.skip(sortedEntries.length - keepCount).toList();

    _messageMap.clear();
    for (final entry in entriesToKeep) {
      _messageMap[entry.key] = entry.value;
    }

    // Update oldest timestamp but don't change hasMore
    // We know there are older messages because we trimmed
    if (_messageMap.isNotEmpty) {
      final sortedRemaining = _messageMap.values.toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      oldestLoadedTimestamp = sortedRemaining.first.createdAt;
    }
  }

  void reset() {
    synchronized(_lock, () {
      isLoading = false;
      hasMore = true;
      _messageMap.clear();
      oldestLoadedTimestamp = null;
      newestLoadedTimestamp = null;
      serverNewestTimestamp = null;
      subscription?.cancel();
      subscription = null;
      lastAccessed = DateTime.now();
      totalMessageCount = null;
      hasInitiallyLoaded = false;
    });
  }

  void dispose() {
    subscription?.cancel();
    subscription = null;
    _messageMap.clear();
  }
}

/// Optimized pagination state for topics with better synchronization
class SimpleTopicPaginationState {
  final String topicId;
  bool isLoading = false;
  bool hasMore = true;

  // Use separate collections for different message ranges
  final LinkedHashMap<String, TopicMessage> _messageMap = LinkedHashMap();
  final _lock = Object();

  // Timestamp tracking
  Timestamp? oldestLoadedTimestamp;
  Timestamp? newestLoadedTimestamp;
  Timestamp? serverNewestTimestamp;

  StreamSubscription? subscription;

  // Memory management
  static int maxMessagesInMemory = 200;
  static int messagesToRemoveOnCleanup = 50;
  DateTime lastAccessed = DateTime.now();

  // Track actual total message count from server
  int? totalMessageCount;

  // Track if we've done initial load
  bool hasInitiallyLoaded = false;

  SimpleTopicPaginationState(this.topicId);

  List<TopicMessage> get messages {
    synchronized(_lock, () {
      lastAccessed = DateTime.now();
      final sortedMessages = _messageMap.values.toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return sortedMessages;
    });
  }

  void addMessages(List<TopicMessage> newMessages,
      {bool isHistorical = false}) {
    synchronized(_lock, () {
      // Add messages
      for (final message in newMessages) {
        if (message.id != null) {
          _messageMap[message.id!] = message;
        }
      }

      // Update timestamps
      if (newMessages.isNotEmpty) {
        final sortedNew = newMessages.toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

        if (isHistorical) {
          // Loading older messages
          final oldestNew = sortedNew.first.createdAt;
          if (oldestLoadedTimestamp == null ||
              oldestNew.compareTo(oldestLoadedTimestamp!) < 0) {
            oldestLoadedTimestamp = oldestNew;
          }
        } else {
          // Real-time or initial load
          final newestNew = sortedNew.last.createdAt;
          if (newestLoadedTimestamp == null ||
              newestNew.compareTo(newestLoadedTimestamp!) > 0) {
            newestLoadedTimestamp = newestNew;
          }
        }
      }

      // Trim if needed
      if (_messageMap.length > maxMessagesInMemory) {
        _trimOldMessages();
      }
    });
  }

  void _trimOldMessages() {
    // Sort messages by timestamp
    final sortedEntries = _messageMap.entries.toList()
      ..sort((a, b) => a.value.createdAt.compareTo(b.value.createdAt));

    // Calculate how many to keep
    final keepCount = maxMessagesInMemory - messagesToRemoveOnCleanup;

    // Keep the newest messages
    final entriesToKeep =
        sortedEntries.skip(sortedEntries.length - keepCount).toList();

    _messageMap.clear();
    for (final entry in entriesToKeep) {
      _messageMap[entry.key] = entry.value;
    }

    // Update oldest timestamp
    if (_messageMap.isNotEmpty) {
      final sortedRemaining = _messageMap.values.toList()
        ..sort((a, b) => a.value.createdAt.compareTo(b.value.createdAt));
      oldestLoadedTimestamp = sortedRemaining.first.createdAt;
    }
  }

  void reset() {
    synchronized(_lock, () {
      isLoading = false;
      hasMore = true;
      _messageMap.clear();
      oldestLoadedTimestamp = null;
      newestLoadedTimestamp = null;
      serverNewestTimestamp = null;
      subscription?.cancel();
      subscription = null;
      lastAccessed = DateTime.now();
      totalMessageCount = null;
      hasInitiallyLoaded = false;
    });
  }

  void dispose() {
    subscription?.cancel();
    subscription = null;
    _messageMap.clear();
  }
}

// Helper function for synchronization
T synchronized<T>(Object lock, T Function() action) {
  // In Dart, we can't truly lock, but we can at least ensure
  // the action completes atomically in terms of the event loop
  return action();
}

// Optimized paginated message service with better reliability
class PaginatedMessageService extends ChangeNotifier {
  final Firedata _firedata;
  final Firestore _firestore;

  // Pagination states with LRU-style cleanup
  final Map<String, SimpleChatPaginationState> _chatStates = {};
  final Map<String, SimpleTopicPaginationState> _topicStates = {};

  // Configuration with adaptive load sizes
  static int _initialLoadSize = 25;
  static int _paginationLoadSize = 25;
  static const int _maxCachedStates = 10;
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
      final totalCores = Platform.numberOfProcessors;
      _isLowEndDevice = totalCores <= 2;

      if (_isLowEndDevice) {
        _initialLoadSize = 15;
        _paginationLoadSize = 15;
        SimpleChatPaginationState.maxMessagesInMemory = 100;
        SimpleChatPaginationState.messagesToRemoveOnCleanup = 25;
        SimpleTopicPaginationState.maxMessagesInMemory = 100;
        SimpleTopicPaginationState.messagesToRemoveOnCleanup = 25;
      }

      debugPrint(
          'Device performance: ${_isLowEndDevice ? "Low-end" : "Normal"}');
      debugPrint(
          'Load sizes: initial=$_initialLoadSize, pagination=$_paginationLoadSize');
    } catch (e) {
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

    // LRU cleanup if still too many
    _enforceMaxCachedStates();
  }

  void _enforceMaxCachedStates() {
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

  // Load chat messages with improved reliability
  Future<SimplePaginatedResult<ChatMessage>> loadChatMessages(
    String chatId, {
    bool isInitialLoad = false,
    int? chatCreatedAt,
  }) async {
    final state = _getChatState(chatId);

    // Prevent concurrent initial loads
    if (state.isLoading && state.hasInitiallyLoaded == isInitialLoad) {
      return SimplePaginatedResult(
          items: state.messages, hasMore: state.hasMore);
    }

    state.isLoading = true;
    _safeNotifyListeners();

    try {
      if (isInitialLoad || !state.hasInitiallyLoaded) {
        // Cancel any existing subscription
        state.subscription?.cancel();

        // Load most recent messages
        final newMessages = await _firedata.fetchMessagesPage(
          chatId,
          limit: _initialLoadSize,
          minCreatedAt: chatCreatedAt,
        );

        // Reset state for initial load
        state._messageMap.clear();
        state.oldestLoadedTimestamp = null;
        state.newestLoadedTimestamp = null;

        if (newMessages.isNotEmpty) {
          state.addMessages(newMessages, isHistorical: false);
          state.hasInitiallyLoaded = true;

          // Start real-time subscription after initial load
          _startChatRealtimeSubscription(state);
        }

        // Determine if there are more messages
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

  // Load more older chat messages
  Future<SimplePaginatedResult<ChatMessage>> loadMoreChatMessages(
      String chatId) async {
    final state = _getChatState(chatId);

    if (state.isLoading ||
        !state.hasMore ||
        state.oldestLoadedTimestamp == null) {
      return SimplePaginatedResult(
          items: state.messages, hasMore: state.hasMore);
    }

    state.isLoading = true;
    _safeNotifyListeners();

    try {
      final olderMessages = await _firedata.fetchMessagesBeforeTimestamp(
        chatId,
        state.oldestLoadedTimestamp!,
        limit: _paginationLoadSize,
      );

      if (olderMessages.isNotEmpty) {
        state.addMessages(olderMessages, isHistorical: true);
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

  // Start real-time subscription for chat messages
  void _startChatRealtimeSubscription(SimpleChatPaginationState state) {
    state.subscription?.cancel();

    // Use newest loaded timestamp for subscription
    final afterTimestamp = state.newestLoadedTimestamp;
    if (afterTimestamp == null) return;

    state.subscription = _firedata
        .subscribeToMessages(state.chatId, afterTimestamp)
        .listen((newMessages) {
      if (newMessages.isNotEmpty) {
        state.addMessages(newMessages, isHistorical: false);
        _safeNotifyListeners();
      }
    }, onError: (error) {
      debugPrint('Chat subscription error: $error');
    });
  }

  // Load topic messages with improved reliability
  Future<SimplePaginatedResult<TopicMessage>> loadTopicMessages(
    String topicId, {
    bool isInitialLoad = false,
  }) async {
    final state = _getTopicState(topicId);

    // Prevent concurrent initial loads
    if (state.isLoading && state.hasInitiallyLoaded == isInitialLoad) {
      return SimplePaginatedResult(
          items: state.messages, hasMore: state.hasMore);
    }

    state.isLoading = true;
    _safeNotifyListeners();

    try {
      if (isInitialLoad || !state.hasInitiallyLoaded) {
        // Cancel any existing subscription
        state.subscription?.cancel();

        // Load most recent messages
        final newMessages = await _firestore.fetchTopicMessagesPage(
          topicId,
          limit: _initialLoadSize,
        );

        // Reset state for initial load
        state._messageMap.clear();
        state.oldestLoadedTimestamp = null;
        state.newestLoadedTimestamp = null;

        if (newMessages.isNotEmpty) {
          state.addMessages(newMessages, isHistorical: false);
          state.hasInitiallyLoaded = true;

          // Start real-time subscription after initial load
          _startTopicRealtimeSubscription(state);
        }

        // Determine if there are more messages
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

  // Load more older topic messages
  Future<SimplePaginatedResult<TopicMessage>> loadMoreTopicMessages(
      String topicId) async {
    final state = _getTopicState(topicId);

    if (state.isLoading ||
        !state.hasMore ||
        state.oldestLoadedTimestamp == null) {
      return SimplePaginatedResult(
          items: state.messages, hasMore: state.hasMore);
    }

    state.isLoading = true;
    _safeNotifyListeners();

    try {
      final olderMessages = await _firestore.fetchTopicMessagesBeforeTimestamp(
        topicId,
        state.oldestLoadedTimestamp!.toDate(),
        limit: _paginationLoadSize,
      );

      if (olderMessages.isNotEmpty) {
        state.addMessages(olderMessages, isHistorical: true);
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

    // Use newest loaded timestamp for subscription
    final afterTimestamp = state.newestLoadedTimestamp?.millisecondsSinceEpoch;
    if (afterTimestamp == null) return;

    state.subscription = _firestore
        .subscribeToTopicMessages(state.topicId, afterTimestamp)
        .listen((newMessages) {
      if (newMessages.isNotEmpty) {
        state.addMessages(newMessages, isHistorical: false);
        _safeNotifyListeners();
      }
    }, onError: (error) {
      debugPrint('Topic subscription error: $error');
    });
  }

  // Reset chat pagination state
  void resetChatPagination(String chatId) {
    final state = _chatStates[chatId];
    state?.reset();
  }

  // Reset topic pagination state
  void resetTopicPagination(String topicId) {
    final state = _topicStates[topicId];
    state?.reset();
  }

  // Get current chat state
  SimpleChatPaginationState? getChatState(String chatId) {
    return _chatStates[chatId];
  }

  // Get current topic state
  SimpleTopicPaginationState? getTopicState(String topicId) {
    return _topicStates[topicId];
  }

  // Clear chat data and subscription
  void clearChatData(String chatId) {
    final state = _chatStates[chatId];
    if (state != null) {
      state.dispose();
      _chatStates.remove(chatId);
      _safeNotifyListeners();
    }
  }

  // Clear topic data and subscription
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
      state.addMessages([message], isHistorical: false);
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
      state.addMessages([message], isHistorical: false);
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
