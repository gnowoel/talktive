import 'package:flutter/material.dart';

import '../models/user.dart';
import 'user_item.dart';

class UserList extends StatefulWidget {
  final List<User> users;

  const UserList({
    super.key,
    required this.users,
  });

  @override
  State<UserList> createState() => _UserListState();
}

class _UserListState extends State<UserList> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      itemCount: widget.users.length,
      itemBuilder: (context, index) {
        return UserItem(user: widget.users[index]);
      },
    );
  }
}
