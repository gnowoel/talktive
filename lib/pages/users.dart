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

  List<User> _filterUsers(List<Chat> chats) {
    final knownUserIds = _knownUserIds(chats);
    final users = _users.where((user) {
      return !knownUserIds.contains(user.id);
    }).toList();
    return users;
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

  Future<void> _greetUsers(List<User> users) async {
    if (!mounted) return;

    final user = cache.user!;
    final message = "Hi! I'm ${user.displayName!}. ${user.description}";
    final info =
        "The following message will be sent. Change the content by updating your profile.\n\n> $message";

    final shouldSend = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Say hi to everyone'),
            content: Text(info),
            actions: [
              TextButton(
                child: const Text('Not Now'),
                onPressed: () => Navigator.pop(context, false),
              ),
              TextButton(
                child: const Text('Send'),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldSend) return;

    await firedata.greetUsers(user, users, message);
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
        title: const Text('Top users'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.waving_hand,
              // color: theme.colorScheme.tertiary,
            ),
            tooltip: 'Greet all',
            onPressed: users.isEmpty ? null : () => _greetUsers(users),
          ),
        ],
      ),
      body: SafeArea(
        child: users.isEmpty
            ? (_isPopulated
                ? const Center(child: Info(lines: lines))
                : const SizedBox())
            : Layout(
                child: Column(
                  children: [
                    Card(
                      elevation: 0,
                      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      color: theme.colorScheme.secondaryContainer,
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
                              color: theme.colorScheme.onSecondaryContainer,
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
                      child: UserList(users: users, hideUser: _hideUser),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
