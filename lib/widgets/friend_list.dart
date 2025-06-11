import 'package:flutter/material.dart';
import 'package:talktive/models/follow.dart';

import 'friend_item.dart';

class FriendList extends StatelessWidget {
  final List<Follow> friends;

  const FriendList({super.key, required this.friends});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      itemCount: friends.length,
      itemBuilder: (context, index) {
        return FriendItem(friend: friends[index]);
      },
    );
  }
}
