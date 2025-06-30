import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MessageMeta {
  final String messageId;
  final bool isRecalled;
  final DateTime? recalledAt;
  final String? recalledBy;

  const MessageMeta({
    required this.messageId,
    this.isRecalled = false,
    this.recalledAt,
    this.recalledBy,
  });

  factory MessageMeta.fromJson(String messageId, Map<String, dynamic> json) {
    return MessageMeta(
      messageId: messageId,
      isRecalled: json['isRecalled'] as bool? ?? false,
      recalledAt: json['recalledAt'] != null
          ? (json['recalledAt'] as Timestamp).toDate()
          : null,
      recalledBy: json['recalledBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isRecalled': isRecalled,
      if (recalledAt != null) 'recalledAt': Timestamp.fromDate(recalledAt!),
      if (recalledBy != null) 'recalledBy': recalledBy,
    };
  }

  MessageMeta copyWith({
    String? messageId,
    bool? isRecalled,
    DateTime? recalledAt,
    String? recalledBy,
  }) {
    return MessageMeta(
      messageId: messageId ?? this.messageId,
      isRecalled: isRecalled ?? this.isRecalled,
      recalledAt: recalledAt ?? this.recalledAt,
      recalledBy: recalledBy ?? this.recalledBy,
    );
  }
}

class MessageMetaCache extends ChangeNotifier {
  final Map<String, MessageMeta> _messageMeta = {};
  StreamSubscription<QuerySnapshot>? _subscription;
  String? _currentCollectionId;
  String? _currentCollectionType; // 'chat' or 'topic'

  // Performance optimizations
  static const int _maxCacheSize = 1000;
  static const Duration _debounceDelay = Duration(milliseconds: 100);
  Timer? _debounceTimer;
  bool _hasPendingNotification = false;

  // Performance metrics
  int _totalUpdatesReceived = 0;
  int _totalNotificationsSent = 0;

  List<MessageMeta> get allMessageMeta => _messageMeta.values.toList();

  List<MessageMeta> get recalledMessages =>
      _messageMeta.values.where((m) => m.isRecalled).toList();

  /// Check if a specific message is recalled
  bool isMessageRecalled(String messageId) {
    if (messageId.isEmpty) {
      debugPrint(
          'MessageMetaCache: Empty messageId provided to isMessageRecalled');
      return false;
    }
    return _messageMeta[messageId]?.isRecalled ?? false;
  }

  /// Get metadata for a specific message
  MessageMeta? getMessageMeta(String messageId) {
    return _messageMeta[messageId];
  }

  /// Subscribe to message metadata for a chat
  void subscribeToChat(String chatId) {
    if (chatId.isEmpty) {
      debugPrint('MessageMetaCache: Cannot subscribe to empty chatId');
      return;
    }
    _subscribeToCollection(chatId, 'chat');
  }

  /// Subscribe to message metadata for a topic
  void subscribeToTopic(String topicId) {
    if (topicId.isEmpty) {
      debugPrint('MessageMetaCache: Cannot subscribe to empty topicId');
      return;
    }
    _subscribeToCollection(topicId, 'topic');
  }

  void _subscribeToCollection(String collectionId, String collectionType) {
    // Validate parameters
    if (collectionId.isEmpty || collectionType.isEmpty) {
      debugPrint(
          'MessageMetaCache: Invalid parameters - collectionId: $collectionId, type: $collectionType');
      return;
    }

    if (!['chat', 'topic'].contains(collectionType)) {
      debugPrint('MessageMetaCache: Invalid collection type: $collectionType');
      return;
    }

    // Cancel existing subscription if switching collections
    if (_currentCollectionId != collectionId ||
        _currentCollectionType != collectionType) {
      unsubscribe();
    }

    _currentCollectionId = collectionId;
    _currentCollectionType = collectionType;

    final collectionPath = collectionType == 'chat'
        ? 'chats/$collectionId/messageMeta'
        : 'topics/$collectionId/messageMeta';

    debugPrint('MessageMetaCache: Subscribing to $collectionPath');

    _subscription = FirebaseFirestore.instance
        .collection(collectionPath)
        .snapshots()
        .listen(
      _handleMessageMetaUpdate,
      onError: (error) {
        debugPrint(
            'MessageMetaCache: Error listening to $collectionPath: $error');
      },
    );
  }

  void _handleMessageMetaUpdate(QuerySnapshot snapshot) {
    if (_disposed) {
      debugPrint('MessageMetaCache: Received update after disposal, ignoring');
      return;
    }

    _totalUpdatesReceived++;
    bool hasChanges = false;
    int changesProcessed = 0;

    try {
      // Process changes in batches for better performance
      final changes = snapshot.docChanges;

      for (final change in changes) {
        final messageId = change.doc.id;

        if (messageId.isEmpty) {
          debugPrint('MessageMetaCache: Skipping document with empty ID');
          continue;
        }

        final data = change.doc.data() as Map<String, dynamic>?;

        switch (change.type) {
          case DocumentChangeType.added:
          case DocumentChangeType.modified:
            if (data != null) {
              try {
                final messageMeta = MessageMeta.fromJson(messageId, data);
                final existingMeta = _messageMeta[messageId];

                // Only update if there's actually a change
                if (existingMeta == null ||
                    existingMeta.isRecalled != messageMeta.isRecalled ||
                    existingMeta.recalledAt != messageMeta.recalledAt ||
                    existingMeta.recalledBy != messageMeta.recalledBy) {
                  _messageMeta[messageId] = messageMeta;
                  hasChanges = true;
                  changesProcessed++;
                }
              } catch (e) {
                debugPrint(
                    'MessageMetaCache: Error parsing message meta for $messageId: $e');
              }
            } else {
              debugPrint('MessageMetaCache: Null data for message $messageId');
            }
            break;
          case DocumentChangeType.removed:
            if (_messageMeta.remove(messageId) != null) {
              hasChanges = true;
              changesProcessed++;
            }
            break;
        }
      }

      // Enforce cache size limits after processing updates
      if (hasChanges) {
        _enforceCacheSize();
      }

      if (kDebugMode && changesProcessed > 0) {
        debugPrint(
            'MessageMetaCache: Processed $changesProcessed changes from ${changes.length} total changes');
      }
    } catch (e) {
      debugPrint('MessageMetaCache: Error handling message meta update: $e');
    }

    if (hasChanges) {
      _deferredNotifyListeners();
    }
  }

  /// Get the current collection ID being monitored
  String? get currentCollectionId => _currentCollectionId;

  /// Get the current collection type being monitored
  String? get currentCollectionType => _currentCollectionType;

  /// Unsubscribe from current collection without disposing the entire cache
  void unsubscribe() {
    if (_currentCollectionId != null) {
      debugPrint(
          'MessageMetaCache: Unsubscribing from $_currentCollectionType $_currentCollectionId');
    }
    _subscription?.cancel();
    _subscription = null;
    _messageMeta.clear();
    _currentCollectionId = null;
    _currentCollectionType = null;
    _deferredNotifyListeners();
  }

  /// Clear message metadata without disposing the entire cache
  void clear() {
    _messageMeta.clear();
    _deferredNotifyListeners();
  }

  /// Get count of recalled messages
  int get recalledMessageCount => recalledMessages.length;

  /// Get total message metadata count
  int get totalMessageMetaCount => _messageMeta.length;

  /// Defer notifyListeners to avoid calling during build phase
  void _deferredNotifyListeners() {
    if (_disposed) return;

    // Use debouncing to avoid excessive notifications
    _hasPendingNotification = true;
    _debounceTimer?.cancel();

    _debounceTimer = Timer(_debounceDelay, () {
      if (_disposed || !_hasPendingNotification) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_disposed && _hasPendingNotification) {
          _hasPendingNotification = false;
          _totalNotificationsSent++;
          notifyListeners();
        }
      });
    });
  }

  /// Enforce cache size limits to prevent memory issues
  void _enforceCacheSize() {
    if (_messageMeta.length <= _maxCacheSize) return;

    // Remove oldest entries (simple LRU-like behavior)
    // In a real implementation, you might want to track access times
    final entriesToRemove = _messageMeta.length - _maxCacheSize;
    final keysToRemove = _messageMeta.keys.take(entriesToRemove).toList();

    for (final key in keysToRemove) {
      _messageMeta.remove(key);
    }

    debugPrint(
        'MessageMetaCache: Cache size limit enforced, removed $entriesToRemove entries');
  }

  /// Get performance metrics for debugging
  Map<String, dynamic> getMetrics() {
    return {
      'totalCachedMessages': _messageMeta.length,
      'maxCacheSize': _maxCacheSize,
      'totalUpdatesReceived': _totalUpdatesReceived,
      'totalNotificationsSent': _totalNotificationsSent,
      'currentCollection': _currentCollectionId,
      'collectionType': _currentCollectionType,
      'hasActiveSubscription': _subscription != null,
    };
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;

    // Cancel timers and subscriptions
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _subscription?.cancel();
    _subscription = null;

    // Clear cache and reset state
    _messageMeta.clear();
    _currentCollectionId = null;
    _currentCollectionType = null;

    // Log final metrics in debug mode
    if (kDebugMode) {
      debugPrint('MessageMetaCache disposed. Final metrics: ${getMetrics()}');
    }

    super.dispose();
  }
}
