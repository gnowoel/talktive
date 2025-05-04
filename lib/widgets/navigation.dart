import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../helpers/time.dart';
import '../models/private_chat.dart';
import '../services/chat_cache.dart';
import '../services/topic_cache.dart';

class Navigation extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const Navigation({super.key, required this.navigationShell});

  @override
  State<Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  late ChatCache chatCache;
  late TopicCache topicCache;
  List<PrivateChat> _chats = [];
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    chatCache = Provider.of<ChatCache>(context);
    topicCache = Provider.of<TopicCache>(context);
    _setChatsAgain();
  }

  void _setChatsAgain() {
    _chats = chatCache.chats.where((chat) => chat.isActive).toList();

    final nextTime = getNextTime(_chats);

    if (nextTime == null) return;

    final duration = Duration(milliseconds: nextTime);

    _timer?.cancel();

    _timer = Timer(duration, () {
      setState(() {
        _setChatsAgain();
      });
    });
  }

  void _goBranch(int index) {
    widget.navigationShell.goBranch(index);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;
    final unreadCount = chatCache.unreadCount + topicCache.unreadCount;

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
        destinations: [
          NavigationDestination(
            label: 'Users',
            icon: Icon(currentIndex == 0 ? Icons.face : Icons.face_outlined),
          ),
          NavigationDestination(
            label: 'Topics',
            icon: Icon(
              currentIndex == 1 ? Icons.workspaces : Icons.workspaces_outlined,
            ),
          ),
          NavigationDestination(
            label: 'Chats',
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text('$unreadCount'),
              child: Icon(currentIndex == 2 ? Icons.chat : Icons.chat_outlined),
            ),
          ),
          NavigationDestination(
            label: 'Friends',
            icon: Icon(
              currentIndex == 3 ? Icons.polyline : Icons.polyline_outlined,
            ),
          ),
          NavigationDestination(
            label: 'Profile',
            icon: Icon(
              currentIndex == 4
                  ? Icons.account_circle
                  : Icons.account_circle_outlined,
            ),
          ),
        ],
        onDestinationSelected: _goBranch,
      ),
    );
  }
}
