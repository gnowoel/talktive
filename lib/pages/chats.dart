import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../helpers/permissions.dart';
import '../helpers/time.dart';
import '../models/room.dart';
import '../services/chat_cache.dart';
import '../services/follow_cache.dart';
import '../services/settings.dart';
import '../services/topic_cache.dart';
import '../services/tribe_cache.dart';
import '../services/user_cache.dart';
import '../widgets/chat_list.dart';
import '../widgets/info.dart';
import '../widgets/info_notice.dart';
import '../widgets/layout.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  late Settings settings;
  late ChatCache chatCache;
  late TopicCache topicCache;
  late FollowCache followCache;
  late UserCache userCache;
  late TribeCache tribeCache;
  List<Room> _items = []; // Stores both chats and topics
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    settings = context.read<Settings>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    chatCache = Provider.of<ChatCache>(context);
    topicCache = Provider.of<TopicCache>(context);
    followCache = Provider.of<FollowCache>(context);
    userCache = Provider.of<UserCache>(context);
    tribeCache = Provider.of<TribeCache>(context);
    _setItemsAgain();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _setItemsAgain() {
    final activeChats = List<Room>.from(chatCache.activeChats);
    final activeTopics = List<Room>.from(topicCache.activeTopics);

    _items = [...activeChats, ...activeTopics]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final nextTime = getNextTime(
      chatCache.getTimeLeft(),
      topicCache.getTimeLeft(),
    );

    if (nextTime == null) return;

    final duration = Duration(milliseconds: nextTime);
    _timer?.cancel();
    _timer = Timer(duration, () {
      if (mounted) {
        setState(() {
          _setItemsAgain();
        });
      }
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
              'Chats expire over time and are permanently deleted to protect your privacy.',
              style: TextStyle(height: 1.5),
            ),
            SizedBox(height: 16),
            Text(
              'SWIPE LEFT on any chat to leave it if you no longer wish to participate.',
              style: TextStyle(height: 1.5),
            ),
            SizedBox(height: 16),
            Text(
              'LONG-PRESS a message to report inappropriate content.',
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

  bool _canCreateTopic() {
    final user = userCache.user;
    return canCreateTopic(user, followCache);
  }

  String get _fabTooltip {
    if (!_canCreateTopic()) {
      return 'Account Restricted';
    }

    return 'Share a moment';
  }

  Future<void> _showRestrictionDialog() async {
    final colorScheme = Theme.of(context).colorScheme;

    String title = 'Cannot Create Moment';
    List<Widget> content = [
      Text(
        'Sorry, you need level 6, followers, good reputation and no restrictions to create moments.',
        style: TextStyle(height: 1.5, color: colorScheme.error),
      ),
      const SizedBox(height: 16),
      const Text(
        'This helps maintain quality discussions in our community.',
        style: TextStyle(height: 1.5),
      ),
    ];

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const lines = ['Please add some', 'more users first.', ''];
    const info = 'Report by LONG-PRESSING a message and selecting "Report".';

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surfaceContainerLow,
        title: const Text('My Chats'),
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
        tooltip: _fabTooltip,
        heroTag: "chats_fab",
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: _items.isEmpty
            ? Center(child: Info(lines: lines))
            : Layout(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    if (settings.shouldShowChatsPageNotice)
                      InfoNotice(
                        content: info,
                        onDismiss: () => settings.saveChatsPageVersion(),
                      ),
                    Expanded(child: ChatList(items: _items)),
                  ],
                ),
              ),
      ),
    );
  }
}
