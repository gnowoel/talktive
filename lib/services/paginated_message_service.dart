import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../models/topic_message.dart';
import 'cache/sqlite_message_cache.dart';
import 'firedata.dart';
import 'firestore.dart';

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

  Future<PaginatedResult<Message>> loadChatMessages(
    String chatId, {
    int pageSize = defaultPageSize,
    bool isInitialLoad = false,
    int? chatCreatedAt,
  }) async {
    final loadSize = isInitialLoad ? initialLoadSize : pageSize;
    print('PaginatedMessageService: loadChatMessages - chatId: $chatId, isInitialLoad: $isInitialLoad, loadSize: $loadSize');

    // Get existing state or create new one
    final state = _chatStates[chatId] ?? ChatPaginationState(chatId: chatId);
    _chatStates[chatId] = state;

    // Reset state for initial load to ensure we start fresh
    if (isInitialLoad) {
      print('PaginatedMessageService: Resetting state for initial load - chatId: $chatId');
      state.reset();
    }

    try {
      // For initial load, always get the most recent messages from cache
      final offset = isInitialLoad ? 0 : state.currentOffset;

      // First, try to load from cache
      final cachedMessages = await _cache.getChatMessages(
        chatId,
        limit: loadSize,
        offset: offset,
        minCreatedAt: chatCreatedAt,
      );

      final totalCachedCount = await _cache.getChatMessageCount(
        chatId,
        minCreatedAt: chatCreatedAt,
      );

      // Check if we have sufficient messages or if we've reached the end
      final hasEnoughFromCache = cachedMessages.length >= loadSize ||
          offset + cachedMessages.length >= totalCachedCount;

      if (hasEnoughFromCache && cachedMessages.isNotEmpty) {
        if (!isInitialLoad) {
          state.currentOffset += cachedMessages.length;
        } else {
          state.currentOffset = cachedMessages.length;
        }
        state.hasMoreMessages = cachedMessages.length == loadSize &&
            state.currentOffset < totalCachedCount;

        print('PaginatedMessageService: Returning from cache - chatId: $chatId, messages: ${cachedMessages.length}, offset: ${state.currentOffset}, hasMore: ${state.hasMoreMessages}, totalCached: $totalCachedCount');

        // Start real-time subscription for new messages if this is initial load
        if (isInitialLoad) {
          await _startChatRealtimeSubscription(chatId, chatCreatedAt);
        }

        return PaginatedResult(
          items: cachedMessages,
          hasMore: state.hasMoreMessages,
          isFromCache: true,
        );
      }

      // If cache doesn't have enough, load from Firebase
      print('PaginatedMessageService: Loading from Firebase - chatId: $chatId, cached: ${cachedMessages.length}, needed: $loadSize');
      await _loadMoreChatMessagesFromFirebase(chatId, loadSize, chatCreatedAt);

      // Now get the requested messages from cache
      final messages = await _cache.getChatMessages(
        chatId,
        limit: loadSize,
        offset: offset,
        minCreatedAt: chatCreatedAt,
      );

      if (!isInitialLoad) {
        state.currentOffset += messages.length;
      } else {
        state.currentOffset = messages.length;
      }

      final updatedTotalCount = await _cache.getChatMessageCount(
        chatId,
        minCreatedAt: chatCreatedAt,
      );
      state.hasMoreMessages = messages.length == loadSize &&
          state.currentOffset < updatedTotalCount;

      print('PaginatedMessageService: Returning from Firebase - chatId: $chatId, messages: ${messages.length}, offset: ${state.currentOffset}, hasMore: ${state.hasMoreMessages}, totalCached: $updatedTotalCount');

      // Start real-time subscription for new messages if this is initial load
      if (isInitialLoad) {
        await _startChatRealtimeSubscription(chatId, chatCreatedAt);
      }

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

  Future<PaginatedResult<Message>> loadMoreChatMessages(String chatId) async {
    final state = _chatStates[chatId];
    if (state == null || !state.hasMoreMessages || state.isLoading) {
      return PaginatedResult(items: [], hasMore: false, isFromCache: true);
    }

    state.isLoading = true;
    notifyListeners();

    try {
      final result = await loadChatMessages(chatId);
      state.isLoading = false;

      notifyListeners();
      return result;
    } catch (e) {
      state.isLoading = false;
      state.hasError = true;
      state.errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _loadMoreChatMessagesFromFirebase(
    String chatId,
    int limit,
    int? chatCreatedAt,
  ) async {
    // Get the oldest message timestamp from cache to use as pagination cursor
    final oldestCachedMessages = await _cache.getChatMessages(
      chatId,
      limit: 1,
      offset: 0, // Get the oldest message (first in chronological order)
      minCreatedAt: chatCreatedAt,
    );

    int? endBefore;
    if (oldestCachedMessages.isNotEmpty) {
      endBefore = oldestCachedMessages.first.createdAt;
    }

    // Create a Firebase query to get older messages
    final messages = await _fetchChatMessagesFromFirebase(
      chatId,
      limit: limit * 2, // Fetch more to reduce Firebase calls
      endBefore: endBefore,
      minCreatedAt: chatCreatedAt,
    );

    // Store the fetched messages in cache
    if (messages.isNotEmpty) {
      await _cache.storeChatMessages(chatId, messages);
    }
  }

  Future<List<Message>> _fetchChatMessagesFromFirebase(
    String chatId, {
    int? limit,
    int? endBefore,
    int? minCreatedAt,
  }) async {
    if (endBefore != null) {
      // Load older messages (before the given timestamp)
      return await _firedata.fetchMessagesBeforeTimestamp(
        chatId,
        endBefore,
        limit: limit ?? defaultPageSize,
        minCreatedAt: minCreatedAt,
      );
    } else {
      // Load recent messages
      return await _firedata.fetchMessagesPage(
        chatId,
        limit: limit ?? defaultPageSize,
        minCreatedAt: minCreatedAt,
      );
    }
  }

  Future<void> _startChatRealtimeSubscription(
    String chatId,
    int? chatCreatedAt,
  ) async {
    // Cancel existing subscription
    await _chatSubscriptions[chatId]?.cancel();

    // Get the latest message timestamp for subscription
    final lastTimestamp = await _cache.getLastChatMessageTimestamp(chatId);

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
          await _cache.storeChatMessages(chatId, filteredMessages);
          // Don't notify immediately to avoid interference with initial load
          Future.delayed(const Duration(milliseconds: 100), () {
            if (!(_chatStates[chatId]?.isLoading ?? false)) {
              notifyListeners();
            }
          });
        }
      }
    });
  }

  // Topic Messages Methods

  Future<PaginatedResult<TopicMessage>> loadTopicMessages(
    String topicId, {
    int pageSize = defaultPageSize,
    bool isInitialLoad = false,
  }) async {
    final loadSize = isInitialLoad ? initialLoadSize : pageSize;

    // Get existing state or create new one
    final state =
        _topicStates[topicId] ?? TopicPaginationState(topicId: topicId);
    _topicStates[topicId] = state;

    // Reset state for initial load to ensure we start fresh
    if (isInitialLoad) {
      state.reset();
    }

    try {
      // For initial load, always get the most recent messages from cache
      final offset = isInitialLoad ? 0 : state.currentOffset;

      // First, try to load from cache
      final cachedMessages = await _cache.getTopicMessages(
        topicId,
        limit: loadSize,
        offset: offset,
      );

      final totalCachedCount = await _cache.getTopicMessageCount(topicId);

      // Check if we have sufficient messages or if we've reached the end
      final hasEnoughFromCache = cachedMessages.length >= loadSize ||
          offset + cachedMessages.length >= totalCachedCount;

      if (hasEnoughFromCache && cachedMessages.isNotEmpty) {
        if (!isInitialLoad) {
          state.currentOffset += cachedMessages.length;
        } else {
          state.currentOffset = cachedMessages.length;
        }
        state.hasMoreMessages = cachedMessages.length == loadSize &&
                               state.currentOffset < totalCachedCount;

        // Start real-time subscription for new messages if this is initial load
        if (isInitialLoad) {
          await _startTopicRealtimeSubscription(topicId);
        }

        return PaginatedResult(
          items: cachedMessages,
          hasMore: state.hasMoreMessages,
          isFromCache: true,
        );
      }

      // If cache doesn't have enough, load from Firebase
      await _loadMoreTopicMessagesFromFirebase(topicId, loadSize);

      // Now get the requested messages from cache
      final messages = await _cache.getTopicMessages(
        topicId,
        limit: loadSize,
        offset: offset,
      );

      if (!isInitialLoad) {
        state.currentOffset += messages.length;
      } else {
        state.currentOffset = messages.length;
      }

      final updatedTotalCount = await _cache.getTopicMessageCount(topicId);
      state.hasMoreMessages = messages.length == loadSize &&
                             state.currentOffset < updatedTotalCount;

      // Start real-time subscription for new messages if this is initial load
      if (isInitialLoad) {
        await _startTopicRealtimeSubscription(topicId);
      }

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

  Future<PaginatedResult<TopicMessage>> loadMoreTopicMessages(
      String topicId) async {
    final state = _topicStates[topicId];
    if (state == null || !state.hasMoreMessages || state.isLoading) {
      return PaginatedResult(items: [], hasMore: false, isFromCache: true);
    }

    state.isLoading = true;
    notifyListeners();

    try {
      final result = await loadTopicMessages(topicId);
      state.isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      state.isLoading = false;
      state.hasError = true;
      state.errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _loadMoreTopicMessagesFromFirebase(
    String topicId,
    int limit,
  ) async {
    // Get the oldest message timestamp from cache to use as pagination cursor
    final oldestCachedMessages = await _cache.getTopicMessages(
      topicId,
      limit: 1,
      offset: 0, // Get the oldest message (first in chronological order)
    );

    int? endBefore;
    if (oldestCachedMessages.isNotEmpty) {
      endBefore = oldestCachedMessages.first.createdAt.millisecondsSinceEpoch;
    }

    // Create a Firebase query to get older messages
    final messages = await _fetchTopicMessagesFromFirebase(
      topicId,
      limit: limit * 2, // Fetch more to reduce Firebase calls
      endBefore: endBefore,
    );

    // Store the fetched messages in cache
    if (messages.isNotEmpty) {
      await _cache.storeTopicMessages(topicId, messages);
    }
  }

  Future<List<TopicMessage>> _fetchTopicMessagesFromFirebase(
    String topicId, {
    int? limit,
    int? endBefore,
  }) async {
    if (endBefore != null) {
      // Load older messages (before the given timestamp)
      final beforeTimestamp = DateTime.fromMillisecondsSinceEpoch(endBefore);
      return await _firestore.fetchTopicMessagesBeforeTimestamp(
        topicId,
        beforeTimestamp,
        limit: limit ?? defaultPageSize,
      );
    } else {
      // Load recent messages
      return await _firestore.fetchTopicMessagesPage(
        topicId,
        limit: limit ?? defaultPageSize,
      );
    }
  }

  Future<void> _startTopicRealtimeSubscription(String topicId) async {
    // Cancel existing subscription
    await _topicSubscriptions[topicId]?.cancel();

    // Get the latest message timestamp for subscription
    final lastTimestamp = await _cache.getLastTopicMessageTimestamp(topicId);

    // Subscribe to new messages only
    _topicSubscriptions[topicId] = _firestore
        .subscribeToTopicMessages(topicId, lastTimestamp)
        .listen((messages) async {
      if (messages.isNotEmpty) {
        await _cache.storeTopicMessages(topicId, messages);
        // Don't notify immediately to avoid interference with initial load
        Future.delayed(const Duration(milliseconds: 100), () {
          if (!(_topicStates[topicId]?.isLoading ?? false)) {
            notifyListeners();
          }
        });
      }
    });
  }

  // Utility Methods

  void resetChatPagination(String chatId) {
    print('PaginatedMessageService: Resetting chat pagination for chatId: $chatId');
    _chatStates[chatId]?.reset();
    notifyListeners();
  }

  void resetTopicPagination(String topicId) {
    print('PaginatedMessageService: Resetting topic pagination for topicId: $topicId');
    _topicStates[topicId]?.reset();
    notifyListeners();
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
    await _cache.clearChatMessages(chatId);
    notifyListeners();
  }

  Future<void> clearTopicData(String topicId) async {
    await _topicSubscriptions[topicId]?.cancel();
    _topicSubscriptions.remove(topicId);
    _topicStates.remove(topicId);
    await _cache.clearTopicMessages(topicId);
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
  int currentOffset = 0;
  bool hasMoreMessages = true;
  bool isLoading = false;
  bool hasError = false;
  String? errorMessage;

  ChatPaginationState({required this.chatId});

  void reset() {
    currentOffset = 0;
    hasMoreMessages = true;
    isLoading = false;
    hasError = false;
    errorMessage = null;
  }
}

class TopicPaginationState {
  final String topicId;
  int currentOffset = 0;
  bool hasMoreMessages = true;
  bool isLoading = false;
  bool hasError = false;
  String? errorMessage;

  TopicPaginationState({required this.topicId});

  void reset() {
    currentOffset = 0;
    hasMoreMessages = true;
    isLoading = false;
    hasError = false;
    errorMessage = null;
  }
}
