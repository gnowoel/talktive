import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat.dart';
import '../models/user.dart';
import '../services/cache.dart';
import '../services/fireauth.dart';
import '../services/firedata.dart';
import '../widgets/info.dart';
import '../widgets/layout.dart';
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

  List<User> _users = [];
  bool _isPopulated = false;

  @override
  void initState() {
    super.initState();

    fireauth = context.read<Fireauth>();
    firedata = context.read<Firedata>();
    cache = context.read<Cache>();

    _fetchUsers(cache.chats);
  }

  Future<void> _fetchUsers(List<Chat> chats) async {
    final users = await firedata.fetchUsers(
      excludedUserIds: _knownUserIds(chats),
    );

    setState(() {
      _users = users;
      _isPopulated = true;
    });
  }

  List<String> _knownUserIds(List<Chat> chats) {
    final userId = fireauth.instance.currentUser!.uid;
    final partnerIds = _partnerIds(userId, chats);
    return [userId, ...partnerIds];
  }

  List<String> _partnerIds(String userId, List<Chat> chats) {
    return chats.map((chat) {
      return chat.id.replaceFirst(userId, '');
    }).toList();
  }

  void _hideUser(User user) {
    setState(() {
      _users.remove(user);
    });
  }

  Future<void> _greetUsers() async {
    await firedata.greetUsers(cache.user!, _users);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const lines = ['No more users here.', 'Try once again.', ''];

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surfaceContainerLow,
        title: const Text('Top users'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.waving_hand,
              color: theme.colorScheme.tertiary,
            ),
            tooltip: 'Say hi to everyone',
            onPressed: _users.isEmpty ? null : _greetUsers,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _users.isEmpty
            ? (_isPopulated
                ? const Center(child: Info(lines: lines))
                : const SizedBox())
            : Layout(
                child: Column(
                  children: [
                    Card(
                      elevation: 0,
                      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      color: theme.colorScheme.tertiaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              size: 16,
                              color: theme.colorScheme.onTertiaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tap the Hand button to say hi to everyone!',
                                style: TextStyle(
                                  color: theme.colorScheme.onSecondaryContainer,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: UserList(users: _users, hideUser: _hideUser),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
