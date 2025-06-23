import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../models/topic_message.dart';
import '../models/chat.dart';
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

    // Get existing state or create new one
    final state = _chatStates[chatId] ?? ChatPaginationState(chatId: chatId);
    _chatStates[chatId] = state;

    try {
      // First, try to load from cache
      final cachedMessages = await _cache.getChatMessages(
        chatId,
        limit: loadSize,
        offset: state.currentOffset,
        minCreatedAt: chatCreatedAt,
      );

      final totalCachedCount = await _cache.getChatMessageCount(
        chatId,
        minCreatedAt: chatCreatedAt,
      );

      // If we have enough cached messages, return them
      if (cachedMessages.length == loadSize ||
          state.currentOffset + loadSize >= totalCachedCount) {
        state.currentOffset += cachedMessages.length;
        state.hasMoreMessages = cachedMessages.length == loadSize;

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
      await _loadMoreChatMessagesFromFirebase(chatId, loadSize, chatCreatedAt);

      // Now get the requested messages from cache
      final messages = await _cache.getChatMessages(
        chatId,
        limit: loadSize,
        offset: state.currentOffset,
        minCreatedAt: chatCreatedAt,
      );

      state.currentOffset += messages.length;
      state.hasMoreMessages = messages.length == loadSize;

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
    final oldestCachedMessage = await _cache.getChatMessages(
      chatId,
      limit: 1,
      minCreatedAt: chatCreatedAt,
    );

    int? endBefore;
    if (oldestCachedMessage.isNotEmpty) {
      endBefore = oldestCachedMessage.first.createdAt;
    }

    // Create a Firebase query to get older messages
    final messages = await _fetchChatMessagesFromFirebase(
      chatId,
      limit: limit,
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
          notifyListeners();
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

    try {
      // First, try to load from cache
      final cachedMessages = await _cache.getTopicMessages(
        topicId,
        limit: loadSize,
        offset: state.currentOffset,
      );

      final totalCachedCount = await _cache.getTopicMessageCount(topicId);

      // If we have enough cached messages, return them
      if (cachedMessages.length == loadSize ||
          state.currentOffset + loadSize >= totalCachedCount) {
        state.currentOffset += cachedMessages.length;
        state.hasMoreMessages = cachedMessages.length == loadSize;

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
        offset: state.currentOffset,
      );

      state.currentOffset += messages.length;
      state.hasMoreMessages = messages.length == loadSize;

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
    final oldestCachedMessage = await _cache.getTopicMessages(
      topicId,
      limit: 1,
    );

    int? endBefore;
    if (oldestCachedMessage.isNotEmpty) {
      endBefore = oldestCachedMessage.first.createdAt.millisecondsSinceEpoch;
    }

    // Create a Firebase query to get older messages
    final messages = await _fetchTopicMessagesFromFirebase(
      topicId,
      limit: limit,
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
        notifyListeners();
      }
    });
  }

  // Utility Methods

  void resetChatPagination(String chatId) {
    _chatStates[chatId]?.reset();
    notifyListeners();
  }

  void resetTopicPagination(String topicId) {
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
