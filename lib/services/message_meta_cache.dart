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

  List<MessageMeta> get allMessageMeta => _messageMeta.values.toList();

  List<MessageMeta> get recalledMessages =>
      _messageMeta.values.where((m) => m.isRecalled).toList();

  /// Check if a specific message is recalled
  bool isMessageRecalled(String messageId) {
    return _messageMeta[messageId]?.isRecalled ?? false;
  }

  /// Get metadata for a specific message
  MessageMeta? getMessageMeta(String messageId) {
    return _messageMeta[messageId];
  }

  /// Subscribe to message metadata for a chat
  void subscribeToChat(String chatId) {
    _subscribeToCollection(chatId, 'chat');
  }

  /// Subscribe to message metadata for a topic
  void subscribeToTopic(String topicId) {
    _subscribeToCollection(topicId, 'topic');
  }

  void _subscribeToCollection(String collectionId, String collectionType) {
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

    _subscription = FirebaseFirestore.instance
        .collection(collectionPath)
        .snapshots()
        .listen(
      _handleMessageMetaUpdate,
      onError: (error) {
        debugPrint('Error listening to message metadata: $error');
      },
    );
  }

  void _handleMessageMetaUpdate(QuerySnapshot snapshot) {
    bool hasChanges = false;

    for (final change in snapshot.docChanges) {
      final messageId = change.doc.id;
      final data = change.doc.data() as Map<String, dynamic>?;

      switch (change.type) {
        case DocumentChangeType.added:
        case DocumentChangeType.modified:
          if (data != null) {
            final messageMeta = MessageMeta.fromJson(messageId, data);
            final existingMeta = _messageMeta[messageId];

            // Only update if there's actually a change
            if (existingMeta == null ||
                existingMeta.isRecalled != messageMeta.isRecalled ||
                existingMeta.recalledAt != messageMeta.recalledAt ||
                existingMeta.recalledBy != messageMeta.recalledBy) {
              _messageMeta[messageId] = messageMeta;
              hasChanges = true;
            }
          }
          break;
        case DocumentChangeType.removed:
          if (_messageMeta.remove(messageId) != null) {
            hasChanges = true;
          }
          break;
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed) {
        notifyListeners();
      }
    });
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    _subscription = null;
    _messageMeta.clear();
    _currentCollectionId = null;
    _currentCollectionType = null;
    super.dispose();
  }
}
