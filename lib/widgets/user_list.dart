import 'package:flutter/material.dart';

import '../models/user.dart';
import 'user_item.dart';

class UserList extends StatelessWidget {
  final List<User> users;
  final List<String> knownUserIds;
  final List<String> seenUserIds;

  const UserList({
    super.key,
    required this.users,
    required this.knownUserIds,
    required this.seenUserIds,
  });

  bool _hasKnown(User user) {
    return knownUserIds.contains(user.id);
  }

  bool _hasSeen(User user) {
    return seenUserIds.contains(user.id);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return UserItem(
          // key: ValueKey(user.id),
          user: users[index],
          hasKnown: _hasKnown(user),
          hasSeen: _hasSeen(user),
        );
      },
    );
  }
}
