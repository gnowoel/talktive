import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../helpers/time.dart';

import '../services/topic_cache.dart';

class Navigation extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const Navigation({super.key, required this.navigationShell});

  @override
  State<Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  late TopicCache topicCache;
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    topicCache = Provider.of<TopicCache>(context);
    _refreshActiveItems();
  }

  void _refreshActiveItems() {
    final nextTime = getNextTime(topicCache.getTimeLeft());

    if (nextTime == null) return;

    final duration = Duration(milliseconds: nextTime);

    _timer?.cancel();

    _timer = Timer(duration, () {
      setState(() {
        _refreshActiveItems();
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
    final unreadCount = topicCache.unreadCount;

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
            label: 'Moments',
            icon: Icon(
              currentIndex == 1
                  ? Icons.auto_awesome
                  : Icons.auto_awesome_outlined,
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
