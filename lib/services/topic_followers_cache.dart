import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TopicFollower {
  final String userId;
  final bool muted;
  final bool isBlocked;
  final DateTime? blockedAt;

  const TopicFollower({
    required this.userId,
    this.muted = false,
    this.isBlocked = false,
    this.blockedAt,
  });

  factory TopicFollower.fromJson(String userId, Map<String, dynamic> json) {
    return TopicFollower(
      userId: userId,
      muted: json['muted'] as bool? ?? false,
      isBlocked: json['isBlocked'] as bool? ?? false,
      blockedAt: json['blockedAt'] != null
          ? (json['blockedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'muted': muted,
      'isBlocked': isBlocked,
      if (blockedAt != null) 'blockedAt': Timestamp.fromDate(blockedAt!),
    };
  }

  TopicFollower copyWith({
    String? userId,
    bool? muted,
    bool? isBlocked,
    DateTime? blockedAt,
  }) {
    return TopicFollower(
      userId: userId ?? this.userId,
      muted: muted ?? this.muted,
      isBlocked: isBlocked ?? this.isBlocked,
      blockedAt: blockedAt ?? this.blockedAt,
    );
  }
}

class TopicFollowersCache extends ChangeNotifier {
  final Map<String, TopicFollower> _followers = {};
  StreamSubscription<QuerySnapshot>? _subscription;
  String? _currentTopicId;

  List<TopicFollower> get followers => _followers.values.toList();

  List<TopicFollower> get activeFollowers =>
      _followers.values.where((f) => !f.isBlocked).toList();

  List<TopicFollower> get blockedFollowers =>
      _followers.values.where((f) => f.isBlocked).toList();

  /// Check if a specific user is blocked from the current topic
  bool isUserBlocked(String userId) {
    return _followers[userId]?.isBlocked ?? false;
  }

  /// Check if a specific user is muted in the current topic
  bool isUserMuted(String userId) {
    return _followers[userId]?.muted ?? false;
  }

  /// Get follower data for a specific user
  TopicFollower? getFollower(String userId) {
    return _followers[userId];
  }

  /// Check if a user is a follower of the current topic
  bool isFollower(String userId) {
    return _followers.containsKey(userId);
  }

  /// Subscribe to followers of a specific topic
  void subscribeToTopic(String topicId) {
    // Cancel existing subscription if switching topics
    if (_currentTopicId != topicId) {
      unsubscribe();
    }

    _currentTopicId = topicId;

    _subscription = FirebaseFirestore.instance
        .collection('topics')
        .doc(topicId)
        .collection('followers')
        .snapshots()
        .listen(
      _handleFollowersUpdate,
      onError: (error) {
        debugPrint('Error listening to topic followers: $error');
      },
    );
  }

  void _handleFollowersUpdate(QuerySnapshot snapshot) {
    bool hasChanges = false;

    for (final change in snapshot.docChanges) {
      final userId = change.doc.id;
      final data = change.doc.data() as Map<String, dynamic>?;

      switch (change.type) {
        case DocumentChangeType.added:
        case DocumentChangeType.modified:
          if (data != null) {
            final follower = TopicFollower.fromJson(userId, data);
            final existingFollower = _followers[userId];

            // Only update if there's actually a change
            if (existingFollower == null ||
                existingFollower.isBlocked != follower.isBlocked ||
                existingFollower.muted != follower.muted) {
              _followers[userId] = follower;
              hasChanges = true;
            }
          }
          break;
        case DocumentChangeType.removed:
          if (_followers.remove(userId) != null) {
            hasChanges = true;
          }
          break;
      }
    }

    if (hasChanges) {
      _deferredNotifyListeners();
    }
  }

  /// Get the current topic ID being monitored
  String? get currentTopicId => _currentTopicId;

  /// Unsubscribe from current topic without disposing the entire cache
  void unsubscribe() {
    _subscription?.cancel();
    _subscription = null;
    _followers.clear();
    _currentTopicId = null;
    _deferredNotifyListeners();
  }

  /// Clear followers data without disposing the entire cache
  void clear() {
    _followers.clear();
    _deferredNotifyListeners();
  }

  /// Get count of active (non-blocked) followers
  int get activeFollowerCount => activeFollowers.length;

  /// Get count of blocked followers
  int get blockedFollowerCount => blockedFollowers.length;

  /// Get total follower count
  int get totalFollowerCount => _followers.length;

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
    _followers.clear();
    _currentTopicId = null;
    super.dispose();
  }
}
