import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/follow.dart';
import '../services/firestore.dart';
import '../services/follow_cache.dart';
import '../widgets/friend_list.dart';
import '../widgets/info.dart';
import '../widgets/layout.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  late Firestore firestore;
  late FollowCache followCache;

  List<Follow> _friends = [];

  @override
  void initState() {
    super.initState();
    firestore = context.read<Firestore>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    followCache = Provider.of<FollowCache>(context);
    _friends = followCache.followees;
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Quick Tips'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add your partners as friends to stay connected, even after chats expire.',
                  style: TextStyle(height: 1.5),
                ),
                SizedBox(height: 16),
                Text(
                  'Friends will always be available here until you remove them manually.',
                  style: TextStyle(height: 1.5),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Got it'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = [
      'Add some friends by tapping',
      'on your partner\'s avatar.',
      '',
    ];

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surfaceContainerLow,
        title: const Text('My Friends'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
            tooltip: 'Help',
          ),
        ],
      ),
      floatingActionButton:
          _friends.isEmpty
              ? null
              : FloatingActionButton(
                onPressed: () => context.push('/topics/create'),
                tooltip: 'Start a topic',
                child: const Icon(Icons.add_comment),
              ),
      body: SafeArea(
        child:
            _friends.isEmpty
                ? Center(child: Info(lines: lines))
                : Layout(child: FriendList(friends: _friends)),
      ),
    );
  }
}
