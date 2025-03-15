import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/follow.dart';
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
  late FollowCache followCache;

  List<Follow> _friends = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    followCache = Provider.of<FollowCache>(context);
    _friends = followCache.followees;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = ['No friends yet. Add some', 'friends to chat with!', ''];

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surfaceContainerLow,
        title: const Text('My Friends'),
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
