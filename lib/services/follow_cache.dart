import 'package:flutter/foundation.dart';

import '../models/follow.dart';

class FollowCache extends ChangeNotifier {
  final Map<String, Follow> _followees = {};

  FollowCache._();
  static final FollowCache _instance = FollowCache._();
  factory FollowCache() => _instance;

  List<Follow> get followees => _followees.values.toList();
  bool isFollowing(String userId) => _followees.containsKey(userId);

  void updateFollowees(List<Follow> followees) {
    _followees.clear();
    for (final followee in followees) {
      _followees[followee.id] = followee;
    }
    notifyListeners();
  }
}
