import 'package:flutter/foundation.dart';

import '../models/follow.dart';

class FollowCache extends ChangeNotifier {
  final Map<String, Follow> _followees = {};
  final Map<String, Follow> _followers = {};

  FollowCache._();
  static final FollowCache _instance = FollowCache._();
  factory FollowCache() => _instance;

  List<Follow> get followees => _followees.values.toList();
  List<Follow> get foloowers => _followers.values.toList();

  bool isFollowing(String userId) => _followees.containsKey(userId);
  bool isFollowedBy(String userId) => _followers.containsKey(userId);
  bool isMutualFriend(String userId) =>
      isFollowing(userId) && isFollowedBy(userId);

  // Get earlier timestamp for mutual friends
  int getMutualFriendshipStartTime(String userId) {
    if (!isMutualFriend(userId)) return 0;
    return [
      _followees[userId]!.createdAt,
      _followers[userId]!.createdAt,
    ].reduce((a, b) => a < b ? a : b);
  }

  void updateFollowees(List<Follow> followees) {
    _followees.clear();
    for (final followee in followees) {
      _followees[followee.id] = followee;
    }
    notifyListeners();
  }

  void updateFollowers(List<Follow> followers) {
    _followers.clear();
    for (final follower in followers) {
      _followers[follower.id] = follower;
    }
    notifyListeners();
  }

  List<Follow> getMergedFriends() {
    final merged = <String, Follow>{};

    // Add all followees
    for (final followee in _followees.values) {
      merged[followee.id] = followee;
    }

    // Add followers (or update existing entries for mutual friends)
    for (final follower in _followers.values) {
      if (merged.containsKey(follower.id)) {
        // For mutual friends, use the earlier timestamp
        final existingFollow = merged[follower.id]!;
        if (follower.createdAt < existingFollow.createdAt) {
          merged[follower.id] = follower;
        }
      } else {
        merged[follower.id] = follower;
      }
    }

    return merged.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}
