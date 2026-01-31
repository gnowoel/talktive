import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../models/topic_message.dart';
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
        'TopicState[$topicId]: Trimming messages from ${_messageMap.length} to $maxMessagesInMemory');

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

/// Simplified paginated message service for topic messages
class PaginatedMessageService extends ChangeNotifier {
  final Firestore _firestore;

  // Pagination states
  final Map<String, SimpleTopicPaginationState> _topicStates = {};

  // Configuration
  static int _initialLoadSize = 25;
  static int _paginationLoadSize = 25;
  static const int _maxCachedStates = 3;
  static const Duration _stateExpirationDuration = Duration(minutes: 5);

  // Cleanup timer
  Timer? _cleanupTimer;

  PaginatedMessageService(this._firestore) {
    // Adjust for low-end devices
    // On web, assume it's a low-end device for conservative memory usage
    if (kIsWeb || Platform.numberOfProcessors <= 2) {
      _initialLoadSize = 15;
      _paginationLoadSize = 15;
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
    // Clean up oldest topic states if we exceed the limit
    if (_topicStates.length > _maxCachedStates) {
      final sortedEntries = _topicStates.entries.toList()
        ..sort((a, b) => a.value.lastAccessed.compareTo(b.value.lastAccessed));

      final toRemove =
          sortedEntries.take(_topicStates.length - _maxCachedStates);
      for (final entry in toRemove) {
        debugPrint(
            'Removing old topic state: ${entry.key} (messages: ${entry.value.messages.length})');
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

  // Get or create topic pagination state
  SimpleTopicPaginationState _getTopicState(String topicId) {
    final isNewState = !_topicStates.containsKey(topicId);
    final state = _topicStates.putIfAbsent(
        topicId, () => SimpleTopicPaginationState(topicId));

    if (isNewState) {
      debugPrint('Creating new topic state for $topicId');
    }

    // Always enforce state limits when getting a state
    _enforceMaxCachedStates();

    return state;
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
            'Topic[${state.topicId}]: Received ${newMessages.length} new messages');
        state.addMessages(newMessages);
        _safeNotifyListeners();
      }
    }, onError: (error) {
      debugPrint('Topic subscription error: $error');
    });
  }

  // Reset topic pagination state to initial conditions
  void resetTopicPagination(String topicId) {
    final state = _topicStates[topicId];
    state?.reset();
  }

  // Get current topic state (for debugging/monitoring)
  SimpleTopicPaginationState? getTopicState(String topicId) {
    return _topicStates[topicId];
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

  // Update total message count for a topic
  void updateTopicTotalMessageCount(String topicId, int totalCount) {
    final state = _topicStates[topicId];
    if (state != null) {
      state.totalMessageCount = totalCount;
      _safeNotifyListeners();
    }
  }

  // Get total message count for a topic
  int? getTopicTotalMessageCount(String topicId) {
    return _topicStates[topicId]?.totalMessageCount;
  }

  // Dispose a single topic state when leaving the topic
  void disposeTopicState(String topicId) {
    final state = _topicStates[topicId];
    if (state != null) {
      debugPrint('Disposing topic state: $topicId');
      state.subscription?.cancel();
      state.dispose();
      _topicStates.remove(topicId);
      _safeNotifyListeners();
    }
  }

  @override
  void dispose() {
    _cleanupTimer?.cancel();
    for (final state in _topicStates.values) {
      state.dispose();
    }
    _topicStates.clear();
    super.dispose();
  }
}
