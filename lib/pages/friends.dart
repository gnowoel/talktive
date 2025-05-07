import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/follow.dart';
import '../services/firestore.dart';
import '../services/follow_cache.dart';
import '../services/user_cache.dart';
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
  late UserCache userCache;

  List<Follow> _friends = [];

  @override
  void initState() {
    super.initState();
    firestore = context.read<Firestore>();
    userCache = context.read<UserCache>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    followCache = Provider.of<FollowCache>(context);
    _friends = followCache.getMergedFriends();
  }

  bool _canCreateTopic() {
    final user = userCache.user;
    if (user == null) return false;

    return !user.isTrainee &&
        !user.withAlert &&
        followCache.followers.isNotEmpty;
  }

  Future<void> _showRestrictionDialog() async {
    final user = userCache.user!;
    final colorScheme = Theme.of(context).colorScheme;

    String title;
    List<Widget> content;

    if (user.withAlert) {
      title = 'Temporarily Restricted';
      content = [
        Text(
          'Your account has been restricted due to reported inappropriate behavior.',
          style: TextStyle(height: 1.5, color: colorScheme.error),
        ),
        const SizedBox(height: 16),
        const Text(
          'You cannot create topics until this restriction expires.',
          style: TextStyle(height: 1.5),
        ),
      ];
    } else if (user.isTrainee) {
      title = 'Account Too New';
      content = [
        Text(
          'Your account needs to be at least 24 hours old and have reached level 4 experience to create topics.',
          style: TextStyle(height: 1.5, color: colorScheme.error),
        ),
        const SizedBox(height: 16),
        const Text(
          'This restriction helps maintain quality discussions in our community.',
          style: TextStyle(height: 1.5),
        ),
      ];
    } else {
      title = 'No Followers Yet';
      content = [
        Text(
          'You need at least one follower to create topics.',
          style: TextStyle(height: 1.5, color: colorScheme.error),
        ),
        const SizedBox(height: 16),
        const Text(
          'Make some friend first! Topics are meant for sharing with your followers.',
          style: TextStyle(height: 1.5),
        ),
      ];
    }

    await showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: content,
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

  void _handleCreateTopic() {
    if (!_canCreateTopic()) {
      _showRestrictionDialog();
      return;
    }

    context.push('/topics/create');
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
      floatingActionButton: FloatingActionButton(
        onPressed: _handleCreateTopic,
        tooltip:
            _canCreateTopic()
                ? 'Start a topic'
                : (userCache.user?.withAlert == true
                    ? 'Account restricted'
                    : (userCache.user?.isTrainee == true
                        ? 'Account too new'
                        : 'Need followers')),
        child: const Icon(Icons.campaign),
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
