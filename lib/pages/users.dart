import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../services/firedata.dart';
import '../widgets/info.dart';
import '../widgets/user_list.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  late Firedata firedata;
  late List<User> _users;

  @override
  void initState() {
    super.initState();
    firedata = Provider.of<Firedata>(context, listen: false);
    _users = [];
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    final users = await firedata.getUsers();
    setState(() => _users = [..._users, ...users]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const lines = ['No more users here.', 'Try again later.', ''];

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surfaceContainerLow,
        title: const Text('Users'),
      ),
      body: SafeArea(
        child: _users.isEmpty
            ? const Center(child: Info(lines: lines))
            : _buildLayout(_users),
      ),
    );
  }

  LayoutBuilder _buildLayout(List<User> users) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = Theme.of(context);
        if (constraints.maxWidth >= 600) {
          return Align(
            alignment: Alignment.center,
            child: Container(
              margin: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.all(
                  Radius.circular(24),
                ),
                border: Border.all(color: theme.colorScheme.secondaryContainer),
              ),
              constraints: const BoxConstraints(minWidth: 324, maxWidth: 576),
              child: UserList(users: _users),
            ),
          );
        } else {
          return Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
            ),
            child: UserList(users: _users),
          );
        }
      },
    );
  }
}
