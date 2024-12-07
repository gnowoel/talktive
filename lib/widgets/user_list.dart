import 'package:flutter/material.dart';

import '../models/user.dart';
import 'user_item.dart';

class UserList extends StatelessWidget {
  final List<User> users;
  final void Function(User) hideUser;

  const UserList({
    super.key,
    required this.users,
    required this.hideUser,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        return UserItem(user: users[index], hideUser: hideUser);
      },
    );
  }
}
