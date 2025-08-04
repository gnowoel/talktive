import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
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
    debugPrint('ChatState[$chatId]: Adding ${newMessages.length} messages');

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

      debugPrint(
          'ChatState[$chatId]: New messages range: $oldestNew - $newestNew');

      if (oldestTimestamp == null || oldestNew < oldestTimestamp!) {
        oldestTimestamp = oldestNew;
      }

      if (newestTimestamp == null || newestNew > newestTimestamp!) {
        newestTimestamp = newestNew;
      }

      debugPrint(
          'ChatState[$chatId]: Updated timestamps - oldest: $oldestTimestamp, newest: $newestTimestamp');
    }

    // Clean up old messages if we exceed the limit
    if (_messageMap.length > maxMessagesInMemory) {
      _trimOldMessages();
    }

    debugPrint(
        'ChatState[$chatId]: Total messages in memory: ${_messageMap.length}');
  }

  void _trimOldMessages() {
    // Don't trim if we're below the limit
    if (_messageMap.length <= maxMessagesInMemory) return;

    debugPrint(
        'ChatState[$chatId]: Trimming messages from ${_messageMap.length} to ${maxMessagesInMemory}');

    // Sort all messages to maintain proper order
    final sorted = messages; // This gets sorted messages
    final toRemove = sorted.length - maxMessagesInMemory;

    // Remove oldest messages
    final messagesToRemove = sorted.take(toRemove).toList();
    for (final msg in messagesToRemove) {
      if (msg.id != null) {
        _messageMap.remove(msg.id);
      }
    }

    // Update oldest timestamp to reflect the new oldest message
    if (_messageMap.isNotEmpty) {
      final remaining = messages;
      if (remaining.isNotEmpty) {
        oldestTimestamp = remaining.first.createdAt;
      }
    }

    debugPrint(
        'ChatState[$chatId]: After trim - messages: ${_messageMap.length}');
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
    debugPrint('TopicState[$topicId]: Adding ${newMessages.length} messages');

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

      debugPrint(
          'TopicState[$topicId]: New messages range: ${oldestNew.toDate()} - ${newestNew.toDate()}');

      if (oldestTimestamp == null ||
          oldestNew.compareTo(oldestTimestamp!) < 0) {
        oldestTimestamp = oldestNew;
      }

      if (newestTimestamp == null ||
          newestNew.compareTo(newestTimestamp!) > 0) {
        newestTimestamp = newestNew;
      }

      debugPrint(
          'TopicState[$topicId]: Updated timestamps - oldest: ${oldestTimestamp?.toDate()}, newest: ${newestTimestamp?.toDate()}');
    }

    // Clean up old messages if we exceed the limit
    if (_messageMap.length > maxMessagesInMemory) {
      _trimOldMessages();
    }

    debugPrint(
        'TopicState[$topicId]: Total messages in memory: ${_messageMap.length}');
  }

  void _trimOldMessages() {
    // Don't trim if we're below the limit
    if (_messageMap.length <= maxMessagesInMemory) return;

    debugPrint(
        'TopicState[$topicId]: Trimming messages from ${_messageMap.length} to ${maxMessagesInMemory}');

    // Sort all messages to maintain proper order
    final sorted = messages; // This gets sorted messages
    final toRemove = sorted.length - maxMessagesInMemory;

    // Remove oldest messages
    final messagesToRemove = sorted.take(toRemove).toList();
    for (final msg in messagesToRemove) {
      if (msg.id != null) {
        _messageMap.remove(msg.id);
      }
    }

    // Update oldest timestamp to reflect the new oldest message
    if (_messageMap.isNotEmpty) {
      final remaining = messages;
      if (remaining.isNotEmpty) {
        oldestTimestamp = remaining.first.createdAt;
      }
    }

    debugPrint(
        'TopicState[$topicId]: After trim - messages: ${_messageMap.length}');
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
  static const int _maxCachedStates = 3;
  static const Duration _stateExpirationDuration = Duration(minutes: 5);

  // Cleanup timer
  Timer? _cleanupTimer;

  PaginatedMessageService(this._firedata, this._firestore) {
    // Adjust for low-end devices
    // On web, assume it's a low-end device for conservative memory usage
    if (kIsWeb || Platform.numberOfProcessors <= 2) {
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
    // Clean up oldest chat states if we exceed the limit
    if (_chatStates.length > _maxCachedStates) {
      final sortedEntries = _chatStates.entries.toList()
        ..sort(
            (a, b) => a.value.lastAccessTime.compareTo(b.value.lastAccessTime));

      final toRemove =
          sortedEntries.take(_chatStates.length - _maxCachedStates);
      for (final entry in toRemove) {
        debugPrint(
            'PAGINATION: CLEANUP - Removing old chat state: ${entry.key} (last accessed: ${entry.value.lastAccessTime})');
        entry.value.subscription?.cancel();
        entry.value.dispose();
        _chatStates.remove(entry.key);
      }
    }

    // Clean up oldest topic states if we exceed the limit
    if (_topicStates.length > _maxCachedStates) {
      final sortedEntries = _topicStates.entries.toList()
        ..sort(
            (a, b) => a.value.lastAccessTime.compareTo(b.value.lastAccessTime));

      final toRemove =
          sortedEntries.take(_topicStates.length - _maxCachedStates);
      for (final entry in toRemove) {
        debugPrint('Removing old topic state: ${entry.key}');
        entry.value.subscription?.cancel();
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
    final isNewState = !_chatStates.containsKey(chatId);
    final state = _chatStates.putIfAbsent(
        chatId, () => SimpleChatPaginationState(chatId));

    debugPrint(
        'PAGINATION: Getting chat state for $chatId - ${isNewState ? "CREATING NEW" : "REUSING EXISTING"} (total states: ${_chatStates.length})');

    // Always enforce state limits when getting a state
    _enforceMaxCachedStates();

    return state;
  }

  // Get or create topic pagination state
  SimpleTopicPaginationState _getTopicState(String topicId) {
    final isNewState = !_topicStates.containsKey(topicId);
    final state = _topicStates.putIfAbsent(
        topicId, () => SimpleTopicPaginationState(topicId));

    debugPrint(
        'PAGINATION: Getting topic state for $topicId - ${isNewState ? "CREATING NEW" : "REUSING EXISTING"} (total states: ${_topicStates.length})');

    // Always enforce state limits when getting a state
    _enforceMaxCachedStates();

    return state;
  }

  // Load chat messages (initial load or refresh)
  Future<SimplePaginatedResult<ChatMessage>> loadChatMessages(
    String chatId, {
    bool isInitialLoad = false,
    int? chatCreatedAt,
  }) async {
    final state = _getChatState(chatId);

    debugPrint(
        'PAGINATION: loadChatMessages - chatId=$chatId, isInitialLoad=$isInitialLoad, existingMessages=${state.messages.length}');

    if (state.isLoading) {
      debugPrint(
          'loadChatMessages: Already loading, returning cached messages');
      return SimplePaginatedResult(
          items: state.messages, hasMore: state.hasMore);
    }

    state.isLoading = true;
    _safeNotifyListeners();

    try {
      if (isInitialLoad || state._messageMap.isEmpty) {
        debugPrint('loadChatMessages: Performing initial load');

        // Cancel existing subscription
        state.subscription?.cancel();

        // Load most recent messages
        debugPrint(
            'PAGINATION: Fetching initial messages from database - limit=$_initialLoadSize');
        final newMessages = await _firedata.fetchMessagesPage(
          chatId,
          limit: _initialLoadSize,
          minCreatedAt: chatCreatedAt,
        );

        debugPrint(
            'PAGINATION: DATABASE DOWNLOAD - Fetched ${newMessages.length} initial messages for chat $chatId');

        // Clear existing messages only on initial load
        state._messageMap.clear();
        state.oldestTimestamp = null;
        state.newestTimestamp = null;

        // Add new messages (should be the latest messages now)
        state.addMessages(newMessages);

        // Start real-time subscription if we have messages
        if (newMessages.isNotEmpty) {
          _startChatRealtimeSubscription(state);
        }

        // Check if there are more older messages
        state.hasMore = newMessages.length >= _initialLoadSize;

        debugPrint(
            'loadChatMessages: Initial load complete - hasMore=${state.hasMore}');
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

    debugPrint(
        'loadMoreChatMessages: chatId=$chatId, oldestTimestamp=${state.oldestTimestamp}');

    if (state.isLoading || !state.hasMore || state.oldestTimestamp == null) {
      debugPrint(
          'loadMoreChatMessages: Skipping - isLoading=${state.isLoading}, hasMore=${state.hasMore}');
      return SimplePaginatedResult(
          items: state.messages, hasMore: state.hasMore);
    }

    state.isLoading = true;
    _safeNotifyListeners();

    try {
      debugPrint(
          'PAGINATION: Fetching older messages from database - limit=$_paginationLoadSize, beforeTimestamp=${state.oldestTimestamp}');
      final olderMessages = await _firedata.fetchMessagesBeforeTimestamp(
        chatId,
        state.oldestTimestamp!,
        limit: _paginationLoadSize,
      );

      debugPrint(
          'PAGINATION: DATABASE DOWNLOAD - Fetched ${olderMessages.length} older messages for chat $chatId');

      if (olderMessages.isNotEmpty) {
        state.addMessages(olderMessages);
        state.hasMore = olderMessages.length >= _paginationLoadSize;
      } else {
        state.hasMore = false;
      }

      debugPrint(
          'loadMoreChatMessages: Complete - total messages=${state.messages.length}, hasMore=${state.hasMore}');

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

    debugPrint(
        'PAGINATION: Starting realtime subscription for chat ${state.chatId} from timestamp ${state.newestTimestamp}');
    state.subscription = _firedata
        .subscribeToMessages(state.chatId, state.newestTimestamp!)
        .listen((newMessages) {
      if (newMessages.isNotEmpty) {
        debugPrint(
            'PAGINATION: REALTIME SUBSCRIPTION - Received ${newMessages.length} new messages for chat ${state.chatId}');
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

        // Clear existing messages only on initial load
        state._messageMap.clear();
        state.oldestTimestamp = null;
        state.newestTimestamp = null;

        // Add new messages (should be the latest messages now)
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
        debugPrint(
            'PAGINATION: REALTIME SUBSCRIPTION - Received ${newMessages.length} new messages for topic ${state.topicId}');
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

  // Dispose a single chat state when leaving the chat
  void disposeChatState(String chatId) {
    final state = _chatStates[chatId];
    if (state != null) {
      debugPrint(
          'PAGINATION: MANUAL DISPOSAL - Disposing chat state: $chatId (had ${state.messages.length} messages)');
      state.subscription?.cancel();
      state.dispose();
      _chatStates.remove(chatId);
      _safeNotifyListeners();
    }
  }

  // Dispose a single topic state when leaving the topic
  void disposeTopicState(String topicId) {
    final state = _topicStates[topicId];
    if (state != null) {
      debugPrint(
          'PAGINATION: MANUAL DISPOSAL - Disposing topic state: $topicId (had ${state.messages.length} messages)');
      state.subscription?.cancel();
      state.dispose();
      _topicStates.remove(topicId);
      _safeNotifyListeners();
    }
  }

  @override
  void dispose() {
    _cleanupTimer?.cancel();

    // Cancel all subscriptions and dispose all states
    for (final state in _chatStates.values) {
      state.subscription?.cancel();
      state.dispose();
    }
    for (final state in _topicStates.values) {
      state.subscription?.cancel();
      state.dispose();
    }

    _chatStates.clear();
    _topicStates.clear();

    super.dispose();
  }
}
