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
  int _selectedFilterIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    followCache = Provider.of<FollowCache>(context);
    _updateFriendsList();
  }

  void _updateFriendsList() {
    switch (_selectedFilterIndex) {
      case 0: // All
        _friends = followCache.getMergedFriends();
        break;
      case 1: // Following
        _friends = followCache.followees
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 2: // Followers
        _friends = followCache.followers
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 3: // Mutual Friends
        _friends = followCache
            .getMergedFriends()
            .where((friend) => followCache.isMutualFriend(friend.id))
            .toList()
          ..sort((a, b) {
            final aTime = followCache.getMutualFriendshipStartTime(a.id);
            final bTime = followCache.getMutualFriendshipStartTime(b.id);
            return bTime.compareTo(aTime);
          });
        break;
    }
  }

  void _onFilterChanged(int index) {
    setState(() {
      _selectedFilterIndex = index;
      _updateFriendsList();
    });
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Tips'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Follow people to stay connected, even after chats expire.',
              style: TextStyle(height: 1.5),
            ),
            SizedBox(height: 16),
            Text(
              'Have something to share with your followers? Head over to the Topics tab!',
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
    final lines = ['Make more friends by', 'being more talk*tive!', ''];

    final filterLabels = ['All', 'Following', 'Followers', 'Mutual Friends'];

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
      body: SafeArea(
        child: Column(
          children: [
            // Filter tabs
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(filterLabels.length, (index) {
                    final isSelected = _selectedFilterIndex == index;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(filterLabels[index]),
                        selected: isSelected,
                        onSelected: (_) => _onFilterChanged(index),
                        selectedColor: theme.colorScheme.primaryContainer,
                        checkmarkColor: theme.colorScheme.onPrimaryContainer,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            // Friends list
            Expanded(
              child: _friends.isEmpty
                  ? Center(child: Info(lines: lines))
                  : Layout(child: FriendList(friends: _friends)),
            ),
          ],
        ),
      ),
    );
  }
}
