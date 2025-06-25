import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../models/topic_message.dart';
import '../services/firedata.dart';
import '../services/firestore.dart';
import 'cache/sqlite_message_cache.dart';

class PaginatedMessageService extends ChangeNotifier {
  static const int defaultPageSize = 25;
  static const int initialLoadSize = 50; // Load more initially for better UX

  final Firedata _firedata;
  final Firestore _firestore;
  final SqliteMessageCache _cache;

  // Pagination state for chats
  final Map<String, ChatPaginationState> _chatStates = {};

  // Pagination state for topics
  final Map<String, TopicPaginationState> _topicStates = {};

  // Real-time subscriptions
  final Map<String, StreamSubscription> _chatSubscriptions = {};
  final Map<String, StreamSubscription> _topicSubscriptions = {};

  PaginatedMessageService({
    required Firedata firedata,
    required Firestore firestore,
    required SqliteMessageCache cache,
  })  : _firedata = firedata,
        _firestore = firestore,
        _cache = cache;

  // Chat Messages Methods

  /// Load chat messages - handles both initial load and pagination
  Future<PaginatedResult<Message>> loadChatMessages(
    String chatId, {
    bool isInitialLoad = false,
    int? chatCreatedAt,
  }) async {
    debugPrint(
        'PaginatedMessageService: loadChatMessages - chatId: $chatId, isInitialLoad: $isInitialLoad');

    // Get or create state
    final state = _chatStates[chatId] ?? ChatPaginationState(chatId: chatId);
    _chatStates[chatId] = state;

    if (isInitialLoad) {
      state.reset();
      return await _performInitialChatLoad(chatId, chatCreatedAt);
    } else {
      return await _loadMoreChatMessages(chatId, chatCreatedAt);
    }
  }

  /// Perform initial load of most recent messages
  Future<PaginatedResult<Message>> _performInitialChatLoad(
    String chatId,
    int? chatCreatedAt,
  ) async {
    final state = _chatStates[chatId]!;

    try {
      // First, try to get recent messages from cache
      List<Message> cachedMessages = [];
      try {
        cachedMessages = await _cache.getChatMessages(
          chatId,
          limit: initialLoadSize,
          minCreatedAt: chatCreatedAt,
        );
      } catch (e) {
        debugPrint('Cache error during initial load: $e');
      }

      // If we have enough cached messages, use them
      if (cachedMessages.length >= initialLoadSize) {
        // Find the oldest message timestamp from the loaded messages
        if (cachedMessages.isNotEmpty) {
          state.oldestLoadedTimestamp = cachedMessages.last.createdAt;
        }

        // Check if there are older messages available in cache
        final olderCount = await _countOlderCachedMessages(
            chatId, state.oldestLoadedTimestamp, chatCreatedAt);
        state.hasMoreMessages = olderCount > 0;

        // Start real-time subscription
        await _startChatRealtimeSubscription(chatId, chatCreatedAt);

        debugPrint(
            'PaginatedMessageService: Initial load from cache - messages: ${cachedMessages.length}, hasMore: ${state.hasMoreMessages}');

        return PaginatedResult(
          items: cachedMessages,
          hasMore: state.hasMoreMessages,
          isFromCache: true,
        );
      }

      // Need to fetch from Firebase
      final messages = await _firedata.fetchMessagesPage(
        chatId,
        limit: initialLoadSize,
        minCreatedAt: chatCreatedAt,
      );

      // Cache the fetched messages
      if (messages.isNotEmpty) {
        try {
          await _cache.storeChatMessages(chatId, messages);
        } catch (e) {
          debugPrint('Cache store error during initial load: $e');
        }

        // Update state with oldest timestamp
        state.oldestLoadedTimestamp = messages.last.createdAt;
      }

      // Check if there are more messages (if we got exactly what we asked for, there might be more)
      state.hasMoreMessages = messages.length == initialLoadSize;

      // Start real-time subscription
      await _startChatRealtimeSubscription(chatId, chatCreatedAt);

      debugPrint(
          'PaginatedMessageService: Initial load from Firebase - messages: ${messages.length}, hasMore: ${state.hasMoreMessages}');

      return PaginatedResult(
        items: messages,
        hasMore: state.hasMoreMessages,
        isFromCache: false,
      );
    } catch (e) {
      state.hasError = true;
      state.errorMessage = e.toString();
      rethrow;
    }
  }

  /// Load more (older) messages for pagination
  Future<PaginatedResult<Message>> _loadMoreChatMessages(
    String chatId,
    int? chatCreatedAt,
  ) async {
    final state = _chatStates[chatId]!;

    if (!state.hasMoreMessages || state.isLoading) {
      return PaginatedResult(items: [], hasMore: false, isFromCache: true);
    }

    state.isLoading = true;
    notifyListeners();

    try {
      List<Message> messages = [];

      // First, try to get older messages from cache
      if (state.oldestLoadedTimestamp != null) {
        try {
          // Get messages older than our oldest loaded timestamp
          messages = await _getOlderMessagesFromCache(
            chatId,
            state.oldestLoadedTimestamp!,
            defaultPageSize,
            chatCreatedAt,
          );
        } catch (e) {
          debugPrint('Cache error during pagination: $e');
        }
      }

      // If cache has enough messages, use them
      if (messages.length >= defaultPageSize) {
        state.oldestLoadedTimestamp = messages.last.createdAt;

        // Check if there are even older messages
        final olderCount = await _countOlderCachedMessages(
            chatId, state.oldestLoadedTimestamp, chatCreatedAt);
        state.hasMoreMessages = olderCount > 0;

        state.isLoading = false;
        notifyListeners();

        debugPrint(
            'PaginatedMessageService: Pagination from cache - messages: ${messages.length}, hasMore: ${state.hasMoreMessages}');

        return PaginatedResult(
          items: messages,
          hasMore: state.hasMoreMessages,
          isFromCache: true,
        );
      }

      // Need to fetch older messages from Firebase
      if (state.oldestLoadedTimestamp != null) {
        final fetchedMessages = await _firedata.fetchMessagesBeforeTimestamp(
          chatId,
          state.oldestLoadedTimestamp!,
          limit: defaultPageSize * 2, // Fetch more to reduce Firebase calls
          minCreatedAt: chatCreatedAt,
        );

        // Cache the newly fetched messages
        if (fetchedMessages.isNotEmpty) {
          try {
            await _cache.storeChatMessages(chatId, fetchedMessages);
          } catch (e) {
            debugPrint('Cache store error during pagination: $e');
          }
        }

        // Now get the requested page from cache
        try {
          messages = await _getOlderMessagesFromCache(
            chatId,
            state.oldestLoadedTimestamp!,
            defaultPageSize,
            chatCreatedAt,
          );
        } catch (e) {
          debugPrint('Cache error after Firebase fetch: $e');
          // Use fetched messages directly, but limit to requested page size
          messages = fetchedMessages.take(defaultPageSize).toList();
        }
      }

      // Update state
      if (messages.isNotEmpty) {
        state.oldestLoadedTimestamp = messages.last.createdAt;
      }

      state.hasMoreMessages = messages.length == defaultPageSize;
      state.isLoading = false;
      notifyListeners();

      debugPrint(
          'PaginatedMessageService: Pagination from Firebase - messages: ${messages.length}, hasMore: ${state.hasMoreMessages}');

      return PaginatedResult(
        items: messages,
        hasMore: state.hasMoreMessages,
        isFromCache: false,
      );
    } catch (e) {
      state.isLoading = false;
      state.hasError = true;
      state.errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Public method for loading more chat messages (called by UI)
  Future<PaginatedResult<Message>> loadMoreChatMessages(String chatId) async {
    final state = _chatStates[chatId];
    if (state == null) {
      return PaginatedResult(items: [], hasMore: false, isFromCache: true);
    }

    return await loadChatMessages(chatId, isInitialLoad: false);
  }

  /// Helper method to get older messages from cache
  Future<List<Message>> _getOlderMessagesFromCache(
    String chatId,
    int beforeTimestamp,
    int limit,
    int? minCreatedAt,
  ) async {
    return await _cache.getChatMessagesBeforeTimestamp(
      chatId,
      beforeTimestamp,
      limit: limit,
      minCreatedAt: minCreatedAt,
    );
  }

  /// Helper method to count older cached messages
  Future<int> _countOlderCachedMessages(
    String chatId,
    int? beforeTimestamp,
    int? minCreatedAt,
  ) async {
    if (beforeTimestamp == null) return 0;

    try {
      final olderMessages = await _cache.getChatMessagesBeforeTimestamp(
        chatId,
        beforeTimestamp,
        limit: 1, // Just checking if any exist
        minCreatedAt: minCreatedAt,
      );
      return olderMessages.isNotEmpty ? 1 : 0; // Simple check for pagination
    } catch (e) {
      debugPrint('Error counting older cached messages: $e');
      return 0;
    }
  }

  /// Start real-time subscription for new chat messages
  Future<void> _startChatRealtimeSubscription(
    String chatId,
    int? chatCreatedAt,
  ) async {
    // Cancel existing subscription
    await _chatSubscriptions[chatId]?.cancel();

    // Get the latest message timestamp for subscription
    int? lastTimestamp;
    try {
      lastTimestamp = await _cache.getLastChatMessageTimestamp(chatId);
    } catch (e) {
      debugPrint('Cache error getting last timestamp: $e');
    }

    // Subscribe to new messages only
    _chatSubscriptions[chatId] = _firedata
        .subscribeToMessages(chatId, lastTimestamp)
        .listen((messages) async {
      if (messages.isNotEmpty) {
        // Filter messages that are newer than what we have
        final filteredMessages = messages
            .where((message) =>
                chatCreatedAt == null || message.createdAt >= chatCreatedAt)
            .toList();

        if (filteredMessages.isNotEmpty) {
          try {
            await _cache.storeChatMessages(chatId, filteredMessages);
            // Notify listeners for real-time updates
            Future.delayed(const Duration(milliseconds: 100), () {
              if (!(_chatStates[chatId]?.isLoading ?? false)) {
                notifyListeners();
              }
            });
          } catch (e) {
            debugPrint('Cache error in real-time subscription: $e');
            notifyListeners();
          }
        }
      }
    });
  }

  // Topic Messages Methods

  /// Load topic messages - handles both initial load and pagination
  Future<PaginatedResult<TopicMessage>> loadTopicMessages(
    String topicId, {
    bool isInitialLoad = false,
  }) async {
    debugPrint(
        'PaginatedMessageService: loadTopicMessages - topicId: $topicId, isInitialLoad: $isInitialLoad');

    // Get or create state
    final state =
        _topicStates[topicId] ?? TopicPaginationState(topicId: topicId);
    _topicStates[topicId] = state;

    if (isInitialLoad) {
      state.reset();
      return await _performInitialTopicLoad(topicId);
    } else {
      return await _loadMoreTopicMessages(topicId);
    }
  }

  /// Perform initial load of most recent topic messages
  Future<PaginatedResult<TopicMessage>> _performInitialTopicLoad(
      String topicId) async {
    final state = _topicStates[topicId]!;

    try {
      // First, try to get recent messages from cache
      List<TopicMessage> cachedMessages = [];
      try {
        cachedMessages = await _cache.getTopicMessages(
          topicId,
          limit: initialLoadSize,
        );
      } catch (e) {
        debugPrint('Cache error during topic initial load: $e');
      }

      // If we have enough cached messages, use them
      if (cachedMessages.length >= initialLoadSize) {
        if (cachedMessages.isNotEmpty) {
          state.oldestLoadedTimestamp =
              cachedMessages.last.createdAt.millisecondsSinceEpoch;
        }

        final olderCount = await _countOlderCachedTopicMessages(
            topicId, state.oldestLoadedTimestamp);
        state.hasMoreMessages = olderCount > 0;

        await _startTopicRealtimeSubscription(topicId);

        debugPrint(
            'PaginatedMessageService: Topic initial load from cache - messages: ${cachedMessages.length}, hasMore: ${state.hasMoreMessages}');

        return PaginatedResult(
          items: cachedMessages,
          hasMore: state.hasMoreMessages,
          isFromCache: true,
        );
      }

      // Need to fetch from Firebase
      final messages = await _firestore.fetchTopicMessagesPage(
        topicId,
        limit: initialLoadSize,
      );

      // Cache the fetched messages
      if (messages.isNotEmpty) {
        try {
          await _cache.storeTopicMessages(topicId, messages);
        } catch (e) {
          debugPrint('Cache store error during topic initial load: $e');
        }

        state.oldestLoadedTimestamp =
            messages.last.createdAt.millisecondsSinceEpoch;
      }

      state.hasMoreMessages = messages.length == initialLoadSize;
      await _startTopicRealtimeSubscription(topicId);

      debugPrint(
          'PaginatedMessageService: Topic initial load from Firebase - messages: ${messages.length}, hasMore: ${state.hasMoreMessages}');

      return PaginatedResult(
        items: messages,
        hasMore: state.hasMoreMessages,
        isFromCache: false,
      );
    } catch (e) {
      state.hasError = true;
      state.errorMessage = e.toString();
      rethrow;
    }
  }

  /// Load more (older) topic messages for pagination
  Future<PaginatedResult<TopicMessage>> _loadMoreTopicMessages(
      String topicId) async {
    final state = _topicStates[topicId]!;

    if (!state.hasMoreMessages || state.isLoading) {
      return PaginatedResult(items: [], hasMore: false, isFromCache: true);
    }

    state.isLoading = true;
    notifyListeners();

    try {
      List<TopicMessage> messages = [];

      // First, try to get older messages from cache
      if (state.oldestLoadedTimestamp != null) {
        try {
          messages = await _getOlderTopicMessagesFromCache(
            topicId,
            state.oldestLoadedTimestamp!,
            defaultPageSize,
          );
        } catch (e) {
          debugPrint('Cache error during topic pagination: $e');
        }
      }

      // If cache has enough messages, use them
      if (messages.length >= defaultPageSize) {
        state.oldestLoadedTimestamp =
            messages.last.createdAt.millisecondsSinceEpoch;

        final olderCount = await _countOlderCachedTopicMessages(
            topicId, state.oldestLoadedTimestamp);
        state.hasMoreMessages = olderCount > 0;

        state.isLoading = false;
        notifyListeners();

        debugPrint(
            'PaginatedMessageService: Topic pagination from cache - messages: ${messages.length}, hasMore: ${state.hasMoreMessages}');

        return PaginatedResult(
          items: messages,
          hasMore: state.hasMoreMessages,
          isFromCache: true,
        );
      }

      // Need to fetch older messages from Firebase
      if (state.oldestLoadedTimestamp != null) {
        final beforeTimestamp =
            DateTime.fromMillisecondsSinceEpoch(state.oldestLoadedTimestamp!);
        final fetchedMessages =
            await _firestore.fetchTopicMessagesBeforeTimestamp(
          topicId,
          beforeTimestamp,
          limit: defaultPageSize * 2,
        );

        // Cache the newly fetched messages
        if (fetchedMessages.isNotEmpty) {
          try {
            await _cache.storeTopicMessages(topicId, fetchedMessages);
          } catch (e) {
            debugPrint('Cache store error during topic pagination: $e');
          }
        }

        // Now get the requested page from cache
        try {
          messages = await _getOlderTopicMessagesFromCache(
            topicId,
            state.oldestLoadedTimestamp!,
            defaultPageSize,
          );
        } catch (e) {
          debugPrint('Cache error after topic Firebase fetch: $e');
          messages = fetchedMessages.take(defaultPageSize).toList();
        }
      }

      // Update state
      if (messages.isNotEmpty) {
        state.oldestLoadedTimestamp =
            messages.last.createdAt.millisecondsSinceEpoch;
      }

      state.hasMoreMessages = messages.length == defaultPageSize;
      state.isLoading = false;
      notifyListeners();

      debugPrint(
          'PaginatedMessageService: Topic pagination from Firebase - messages: ${messages.length}, hasMore: ${state.hasMoreMessages}');

      return PaginatedResult(
        items: messages,
        hasMore: state.hasMoreMessages,
        isFromCache: false,
      );
    } catch (e) {
      state.isLoading = false;
      state.hasError = true;
      state.errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Public method for loading more topic messages (called by UI)
  Future<PaginatedResult<TopicMessage>> loadMoreTopicMessages(
      String topicId) async {
    final state = _topicStates[topicId];
    if (state == null) {
      return PaginatedResult(items: [], hasMore: false, isFromCache: true);
    }

    return await loadTopicMessages(topicId, isInitialLoad: false);
  }

  /// Helper method to get older topic messages from cache
  Future<List<TopicMessage>> _getOlderTopicMessagesFromCache(
    String topicId,
    int beforeTimestampMs,
    int limit,
  ) async {
    return await _cache.getTopicMessagesBeforeTimestamp(
      topicId,
      beforeTimestampMs,
      limit: limit,
    );
  }

  /// Helper method to count older cached topic messages
  Future<int> _countOlderCachedTopicMessages(
    String topicId,
    int? beforeTimestampMs,
  ) async {
    if (beforeTimestampMs == null) return 0;

    try {
      final olderMessages = await _cache.getTopicMessagesBeforeTimestamp(
        topicId,
        beforeTimestampMs,
        limit: 1, // Just checking if any exist
      );
      return olderMessages.isNotEmpty ? 1 : 0; // Simple check for pagination
    } catch (e) {
      debugPrint('Error counting older cached topic messages: $e');
      return 0;
    }
  }

  /// Start real-time subscription for new topic messages
  Future<void> _startTopicRealtimeSubscription(String topicId) async {
    // Cancel existing subscription
    await _topicSubscriptions[topicId]?.cancel();

    // Get the latest message timestamp for subscription
    int? lastTimestampMs;
    try {
      lastTimestampMs = await _cache.getLastTopicMessageTimestamp(topicId);
    } catch (e) {
      debugPrint('Cache error getting last topic timestamp: $e');
    }

    // Subscribe to new messages only
    _topicSubscriptions[topicId] = _firestore
        .subscribeToTopicMessages(topicId, lastTimestampMs)
        .listen((messages) async {
      if (messages.isNotEmpty) {
        try {
          await _cache.storeTopicMessages(topicId, messages);
          Future.delayed(const Duration(milliseconds: 100), () {
            if (!(_topicStates[topicId]?.isLoading ?? false)) {
              notifyListeners();
            }
          });
        } catch (e) {
          debugPrint('Cache error in topic real-time subscription: $e');
          notifyListeners();
        }
      }
    });
  }

  // Utility Methods

  void resetChatPagination(String chatId) {
    debugPrint(
        'PaginatedMessageService: Resetting chat pagination for chatId: $chatId');
    _chatStates[chatId]?.reset();
  }

  void resetTopicPagination(String topicId) {
    debugPrint(
        'PaginatedMessageService: Resetting topic pagination for topicId: $topicId');
    _topicStates[topicId]?.reset();
  }

  ChatPaginationState? getChatState(String chatId) {
    return _chatStates[chatId];
  }

  TopicPaginationState? getTopicState(String topicId) {
    return _topicStates[topicId];
  }

  Future<void> clearChatData(String chatId) async {
    await _chatSubscriptions[chatId]?.cancel();
    _chatSubscriptions.remove(chatId);
    _chatStates.remove(chatId);
    try {
      await _cache.clearChatMessages(chatId);
    } catch (e) {
      debugPrint('Cache error clearing chat data: $e');
    }
    notifyListeners();
  }

  Future<void> clearTopicData(String topicId) async {
    await _topicSubscriptions[topicId]?.cancel();
    _topicSubscriptions.remove(topicId);
    _topicStates.remove(topicId);
    try {
      await _cache.clearTopicMessages(topicId);
    } catch (e) {
      debugPrint('Cache error clearing topic data: $e');
    }
    notifyListeners();
  }

  @override
  void dispose() {
    // Cancel all subscriptions
    for (final subscription in _chatSubscriptions.values) {
      subscription.cancel();
    }
    for (final subscription in _topicSubscriptions.values) {
      subscription.cancel();
    }

    _chatSubscriptions.clear();
    _topicSubscriptions.clear();
    _chatStates.clear();
    _topicStates.clear();

    super.dispose();
  }
}

// Data Classes

class PaginatedResult<T> {
  final List<T> items;
  final bool hasMore;
  final bool isFromCache;

  const PaginatedResult({
    required this.items,
    required this.hasMore,
    required this.isFromCache,
  });
}

class ChatPaginationState {
  final String chatId;
  int? oldestLoadedTimestamp;
  bool hasMoreMessages = true;
  bool isLoading = false;
  bool hasError = false;
  String? errorMessage;

  ChatPaginationState({required this.chatId});

  void reset() {
    oldestLoadedTimestamp = null;
    hasMoreMessages = true;
    isLoading = false;
    hasError = false;
    errorMessage = null;
  }
}

class TopicPaginationState {
  final String topicId;
  int? oldestLoadedTimestamp;
  bool hasMoreMessages = true;
  bool isLoading = false;
  bool hasError = false;
  String? errorMessage;

  TopicPaginationState({required this.topicId});

  void reset() {
    oldestLoadedTimestamp = null;
    hasMoreMessages = true;
    isLoading = false;
    hasError = false;
    errorMessage = null;
  }
}
