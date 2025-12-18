import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/topic_message.dart';
import 'firestore.dart';
import 'firedata.dart'; // Kept if needed, though likely unused for Topics if exclusive to Firestore

class SimplePaginatedResult {
  final List<dynamic> items;
  final bool hasMore;

  SimplePaginatedResult(this.items, this.hasMore);
}

class PaginatedState {
  final List<dynamic> messages;
  final bool hasMore;
  final bool isLoading;
  final DocumentSnapshot? lastDocument; // For Firestore pagination

  PaginatedState({
    required this.messages,
    required this.hasMore,
    this.isLoading = false,
    this.lastDocument,
  });

  PaginatedState copyWith({
    List<dynamic>? messages,
    bool? hasMore,
    bool? isLoading,
    DocumentSnapshot? lastDocument,
  }) {
    return PaginatedState(
      messages: messages ?? this.messages,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      lastDocument: lastDocument ?? this.lastDocument,
    );
  }
}

class PaginatedMessageService extends ChangeNotifier {
  // ignore: unused_field
  final Firedata _firedata;
  final Firestore _firestore;

  // Cache state for topics only
  final Map<String, PaginatedState> _topicStates = {};

  PaginatedMessageService(this._firedata, this._firestore);

  // --- Topic Methods ---

  PaginatedState? getTopicState(String topicId) => _topicStates[topicId];

  void disposeTopicState(String topicId) {
    _topicStates.remove(topicId);
    // notifyListeners(); // Usually not needed on dispose to avoid errors
  }

  Future<SimplePaginatedResult> loadTopicMessages(
    String topicId, {
    bool isInitialLoad = false,
  }) async {
    if (isInitialLoad) {
      _topicStates.remove(topicId);
    }

    final currentState = _topicStates[topicId];
    if (currentState?.isLoading == true) {
      return SimplePaginatedResult(
          currentState?.messages ?? [], currentState?.hasMore ?? true);
    }

    // Set loading
    _updateTopicState(
        topicId,
        (s) =>
            s?.copyWith(isLoading: true) ??
            PaginatedState(messages: [], hasMore: true, isLoading: true));

    try {
      const limit = 20;
      var query = _firestore.instance
          .collection('topics')
          .doc(topicId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (currentState?.lastDocument != null && !isInitialLoad) {
        query = query.startAfterDocument(currentState!.lastDocument!);
      }

      final snapshot = await query.get();

      final newMessages = snapshot.docs.map((doc) {
        // Assuming TopicMessage.fromJson exists and handles the doc
        final data = doc.data();
        data['id'] = doc.id; // Ensure ID is present
        return TopicMessage.fromJson(data);
      }).toList();

      final hasMore = newMessages.length == limit;
      final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

      final allMessages = isInitialLoad
          ? newMessages
          : [...(currentState?.messages ?? []), ...newMessages];

      // Update state
      final newState = PaginatedState(
        messages: allMessages,
        hasMore: hasMore,
        isLoading: false,
        lastDocument: lastDoc,
      );

      _topicStates[topicId] = newState;
      notifyListeners();

      return SimplePaginatedResult(allMessages, hasMore);
    } catch (e) {
      debugPrint('Error loading topic messages: $e');
      _updateTopicState(topicId, (s) => s?.copyWith(isLoading: false));
      rethrow;
    }
  }

  Future<SimplePaginatedResult> loadMoreTopicMessages(String topicId) {
    return loadTopicMessages(topicId, isInitialLoad: false);
  }

  void _updateTopicState(
      String topicId, PaginatedState? Function(PaginatedState?) update) {
    final newState = update(_topicStates[topicId]);
    if (newState != null) {
      _topicStates[topicId] = newState;
      notifyListeners();
    }
  }
  // --- Helper Methods to satisfy legacy/page contracts ---

  Future<void> resetTopicPagination(String topicId) async {
    await loadTopicMessages(topicId, isInitialLoad: true);
  }

  void updateTopicTotalMessageCount(String topicId, int count) {
    // Current implementation derives count from loaded messages
    // This might be a no-op or used for external sync if needed
  }

  void clearTopicData(String topicId) {
    disposeTopicState(topicId);
  }

  int getTopicTotalMessageCount(String topicId) {
    return _topicStates[topicId]?.messages.length ?? 0;
  }
}
