import 'package:flutter/material.dart';
import 'package:talktive/models/friend.dart';

import 'friend_item.dart';

class FriendList extends StatelessWidget {
  final List<Friend> friends;

  const FriendList({super.key, required this.friends});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: friends.length,
      itemBuilder: (context, index) {
        return FriendItem(friend: friends[index]);
      },
    );
  }
}
