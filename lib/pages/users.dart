import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat.dart';
import '../models/user.dart';
import '../services/cache.dart';
import '../services/fireauth.dart';
import '../services/firedata.dart';
import '../widgets/info.dart';
import '../widgets/user_list.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  late Fireauth fireauth;
  late Firedata firedata;
  late Cache cache;
  late List<User> _users;

  bool _isPopulated = false;

  @override
  void initState() {
    super.initState();

    fireauth = context.read<Fireauth>();
    firedata = context.read<Firedata>();
    cache = context.read<Cache>();
    _users = [];

    _fetchUsers(cache.chats);
  }

  Future<void> _fetchUsers(List<Chat> chats) async {
    final inactiveIds = _inactiveIds(chats);
    final users = await firedata.fetchUsers(
      excludedUserIds: inactiveIds,
    );

    setState(() {
      _users = users;
      _isPopulated = true;
    });
  }

  List<User> _filterUsers(List<Chat> chats) {
    final inactiveIds = _inactiveIds(chats);
    final users = _users.where((user) {
      return !inactiveIds.contains(user.id);
    }).toList();
    return users;
  }

  List<String> _inactiveIds(List<Chat> chats) {
    final userId = fireauth.instance.currentUser!.uid;
    final partnerIds = _partnerIds(userId, chats);
    return [userId, ...partnerIds];
  }

  List<String> _partnerIds(String userId, List<Chat> chats) {
    return chats.map((chat) {
      return chat.id.replaceFirst(userId, '');
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const lines = ['No more users here.', 'Try once again.', ''];

    final chats = context.select((Cache cache) => cache.chats);
    final users = _filterUsers(chats);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surfaceContainerLow,
        title: const Text('Users'),
      ),
      body: SafeArea(
        child: users.isEmpty
            ? (_isPopulated
                ? const Center(child: Info(lines: lines))
                : const SizedBox())
            : _buildLayout(users),
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
                borderRadius: const BorderRadius.all(Radius.circular(24)),
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
