import 'package:flutter/foundation.dart';

import '../models/friend.dart';

class FriendCache extends ChangeNotifier {
  final Map<String, Friend> _friends = {};

  FriendCache._();
  static final FriendCache _instance = FriendCache._();
  factory FriendCache() => _instance;

  List<Friend> get friends => _friends.values.toList();

  void updateFriends(List<Friend> friends) {
    _friends.clear();
    for (final friend in friends) {
      _friends[friend.id] = friend;
    }
    notifyListeners();
  }
}
