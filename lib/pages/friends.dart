import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/friend.dart';
import '../services/friend_cache.dart';
import '../widgets/friend_list.dart';
import '../widgets/info.dart';
import '../widgets/layout.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  late FriendCache friendCache;

  List<Friend> _friends = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    friendCache = Provider.of<FriendCache>(context);
    _friends = friendCache.friends;
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
