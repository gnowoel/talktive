import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MessageMeta {
  final String messageId;
  final bool isRecalled;
  final DateTime? recalledAt;
  final String? recalledBy;
  final int? reportCount;
  final DateTime? lastReportedAt;

  const MessageMeta({
    required this.messageId,
    this.isRecalled = false,
    this.recalledAt,
    this.recalledBy,
    this.reportCount,
    this.lastReportedAt,
  });

  factory MessageMeta.fromJson(String messageId, Map<String, dynamic> json) {
    return MessageMeta(
      messageId: messageId,
      isRecalled: json['isRecalled'] as bool? ?? false,
      recalledAt: json['recalledAt'] != null
          ? (json['recalledAt'] as Timestamp).toDate()
          : null,
      recalledBy: json['recalledBy'] as String?,
      reportCount: json['reportCount'] as int?,
      lastReportedAt: json['lastReportedAt'] != null
          ? (json['lastReportedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isRecalled': isRecalled,
      if (recalledAt != null) 'recalledAt': Timestamp.fromDate(recalledAt!),
      if (recalledBy != null) 'recalledBy': recalledBy,
      if (reportCount != null) 'reportCount': reportCount,
      if (lastReportedAt != null)
        'lastReportedAt': Timestamp.fromDate(lastReportedAt!),
    };
  }

  MessageMeta copyWith({
    String? messageId,
    bool? isRecalled,
    DateTime? recalledAt,
    String? recalledBy,
    int? reportCount,
    DateTime? lastReportedAt,
  }) {
    return MessageMeta(
      messageId: messageId ?? this.messageId,
      isRecalled: isRecalled ?? this.isRecalled,
      recalledAt: recalledAt ?? this.recalledAt,
      recalledBy: recalledBy ?? this.recalledBy,
      reportCount: reportCount ?? this.reportCount,
      lastReportedAt: lastReportedAt ?? this.lastReportedAt,
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
    if (!_isValidMessageId(messageId)) {
      if (kDebugMode) {
        debugPrint(
            'MessageMetaCache: Invalid messageId provided to isMessageRecalled: "$messageId"');
      }
      return false;
    }

    if (_disposed) {
      if (kDebugMode) {
        debugPrint(
            'MessageMetaCache: Accessed after disposal, returning false');
      }
      return false;
    }

    return _messageMeta[messageId]?.isRecalled ?? false;
  }

  /// Check if a message is recalled with fallback support and debug logging
  bool isMessageRecalledWithFallback(String messageId, bool fallbackValue) {
    if (!_isValidMessageId(messageId)) {
      if (kDebugMode) {
        debugPrint(
            'MessageMetaCache: Invalid messageId provided to isMessageRecalledWithFallback: "$messageId"');
      }
      return fallbackValue;
    }

    // Check if we're disposed
    if (_disposed) {
      if (kDebugMode) {
        debugPrint(
            'MessageMetaCache: Accessed after disposal, returning fallback value');
      }
      return fallbackValue;
    }

    final cachedMeta = _messageMeta[messageId];
    if (cachedMeta != null) {
      // Cache hit - return cached value
      return cachedMeta.isRecalled;
    } else {
      // Cache miss - use fallback and log for debugging
      if (kDebugMode && fallbackValue && _currentCollectionId != null) {
        debugPrint(
            'MessageMetaCache: Cache miss for message $messageId in $_currentCollectionType $_currentCollectionId, using fallback value: $fallbackValue');
      }
      return fallbackValue;
    }
  }

  /// Check if a message has a specific report count
  int getMessageReportCount(String messageId) {
    if (!_isValidMessageId(messageId)) {
      if (kDebugMode) {
        debugPrint(
            'MessageMetaCache: Invalid messageId provided to getMessageReportCount: "$messageId"');
      }
      return 0;
    }

    if (_disposed) {
      if (kDebugMode) {
        debugPrint('MessageMetaCache: Accessed after disposal, returning 0');
      }
      return 0;
    }

    return _messageMeta[messageId]?.reportCount ?? 0;
  }

  /// Check if a message has a report count with fallback support
  int getMessageReportCountWithFallback(String messageId, int fallbackValue) {
    if (!_isValidMessageId(messageId)) {
      if (kDebugMode) {
        debugPrint(
            'MessageMetaCache: Invalid messageId provided to getMessageReportCountWithFallback: "$messageId"');
      }
      return fallbackValue;
    }

    // Check if we're disposed
    if (_disposed) {
      if (kDebugMode) {
        debugPrint(
            'MessageMetaCache: Accessed after disposal, returning fallback value');
      }
      return fallbackValue;
    }

    final cachedMeta = _messageMeta[messageId];
    if (cachedMeta != null && cachedMeta.reportCount != null) {
      // Cache hit - return cached value
      return cachedMeta.reportCount!;
    } else {
      // Cache miss - use fallback and log for debugging
      if (kDebugMode && fallbackValue > 0 && _currentCollectionId != null) {
        debugPrint(
            'MessageMetaCache: Cache miss for message $messageId report count in $_currentCollectionType $_currentCollectionId, using fallback value: $fallbackValue');
      }
      return fallbackValue;
    }
  }

  /// Get metadata for a specific message
  MessageMeta? getMessageMeta(String messageId) {
    if (!_isValidMessageId(messageId) || _disposed) {
      return null;
    }
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
    // Validate parameters with more detailed error handling
    if (collectionId.isEmpty || collectionType.isEmpty) {
      debugPrint(
          'MessageMetaCache: Invalid parameters - collectionId: "$collectionId", type: "$collectionType"');
      return;
    }

    if (!['chat', 'topic'].contains(collectionType)) {
      debugPrint(
          'MessageMetaCache: Invalid collection type: "$collectionType". Must be "chat" or "topic"');
      return;
    }

    try {
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
          // Attempt to recover by clearing current state
          _handleSubscriptionError(error, collectionPath);
        },
        cancelOnError: false, // Don't cancel on error, allow recovery
      );
    } catch (e) {
      debugPrint(
          'MessageMetaCache: Failed to subscribe to $collectionType $collectionId: $e');
      // Reset state on subscription failure
      _currentCollectionId = null;
      _currentCollectionType = null;
    }
  }

  void _handleMessageMetaUpdate(QuerySnapshot snapshot) {
    if (_disposed) {
      debugPrint('MessageMetaCache: Received update after disposal, ignoring');
      return;
    }

    _totalUpdatesReceived++;
    bool hasChanges = false;
    int changesProcessed = 0;
    int errorsEncountered = 0;

    try {
      // Process changes in batches for better performance
      final changes = snapshot.docChanges;

      if (kDebugMode && changes.isNotEmpty) {
        debugPrint(
            'MessageMetaCache: Processing ${changes.length} changes for $_currentCollectionType $_currentCollectionId');
      }

      for (final change in changes) {
        final messageId = change.doc.id;

        if (messageId.isEmpty) {
          debugPrint('MessageMetaCache: Skipping document with empty ID');
          errorsEncountered++;
          continue;
        }

        try {
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
                      existingMeta.recalledBy != messageMeta.recalledBy ||
                      existingMeta.reportCount != messageMeta.reportCount ||
                      existingMeta.lastReportedAt !=
                          messageMeta.lastReportedAt) {
                    _messageMeta[messageId] = messageMeta;
                    hasChanges = true;
                    changesProcessed++;

                    if (kDebugMode &&
                        (messageMeta.isRecalled ||
                            (messageMeta.reportCount != null &&
                                messageMeta.reportCount! > 0))) {
                      debugPrint(
                          'MessageMetaCache: Message $messageId marked as recalled');
                    }
                  }
                } catch (e) {
                  debugPrint(
                      'MessageMetaCache: Error parsing message meta for $messageId: $e');
                  errorsEncountered++;
                }
              } else {
                debugPrint(
                    'MessageMetaCache: Null data for message $messageId');
                errorsEncountered++;
              }
              break;
            case DocumentChangeType.removed:
              if (_messageMeta.remove(messageId) != null) {
                hasChanges = true;
                changesProcessed++;
                if (kDebugMode) {
                  debugPrint(
                      'MessageMetaCache: Removed message meta for $messageId');
                }
              }
              break;
          }
        } catch (e) {
          debugPrint(
              'MessageMetaCache: Error processing change for message $messageId: $e');
          errorsEncountered++;
        }
      }

      // Enforce cache size limits after processing updates
      if (hasChanges) {
        _enforceCacheSize();
      }

      if (kDebugMode && (changesProcessed > 0 || errorsEncountered > 0)) {
        debugPrint(
            'MessageMetaCache: Processed $changesProcessed changes, $errorsEncountered errors from ${changes.length} total changes');
      }
    } catch (e) {
      debugPrint(
          'MessageMetaCache: Critical error handling message meta update: $e');
      // On critical errors, try to recover by clearing potentially corrupted state
      if (_messageMeta.length > _maxCacheSize ~/ 2) {
        debugPrint(
            'MessageMetaCache: Attempting recovery by clearing half the cache');
        final keysToRemove =
            _messageMeta.keys.take(_messageMeta.length ~/ 2).toList();
        for (final key in keysToRemove) {
          _messageMeta.remove(key);
        }
        hasChanges = true;
      }
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

  /// Handle subscription errors with recovery attempts
  void _handleSubscriptionError(Object error, String collectionPath) {
    debugPrint(
        'MessageMetaCache: Subscription error for $collectionPath: $error');

    // Clear potentially stale data on subscription errors
    if (_messageMeta.isNotEmpty) {
      debugPrint('MessageMetaCache: Clearing cache due to subscription error');
      _messageMeta.clear();
      _deferredNotifyListeners();
    }

    // Reset connection state but keep collection info for potential retry
    _subscription?.cancel();
    _subscription = null;
  }

  /// Validate message ID before operations
  bool _isValidMessageId(String messageId) {
    return messageId.isNotEmpty &&
        messageId.trim().isNotEmpty &&
        messageId.length <= 100; // Reasonable limit
  }

  @override
  void dispose() {
    if (_disposed) {
      debugPrint(
          'MessageMetaCache: Already disposed, ignoring duplicate dispose call');
      return;
    }

    _disposed = true;

    try {
      // Cancel timers and subscriptions
      _debounceTimer?.cancel();
      _debounceTimer = null;
      _subscription?.cancel();
      _subscription = null;

      // Clear cache and reset state
      final cacheSize = _messageMeta.length;
      _messageMeta.clear();
      _currentCollectionId = null;
      _currentCollectionType = null;

      // Log final metrics in debug mode
      if (kDebugMode) {
        debugPrint(
            'MessageMetaCache disposed. Final metrics: ${getMetrics()}, cleared $cacheSize cached items');
      }
    } catch (e) {
      debugPrint('MessageMetaCache: Error during disposal: $e');
    }

    super.dispose();
  }
}
