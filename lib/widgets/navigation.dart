import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../helpers/messages.dart';
import '../helpers/time.dart';
import '../models/chat.dart';
import '../services/cache.dart';

class Navigation extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const Navigation({
    super.key,
    required this.navigationShell,
  });

  @override
  State<Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  late Cache cache;
  List<Chat> _chats = [];
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    cache = Provider.of<Cache>(context);
    _setChatsAgain();
  }

  void _setChatsAgain() {
    _chats = cache.chats.where((chat) => chat.isActive).toList();

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
    final unreadCount = chatsUnreadMessageCount(_chats);

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
        destinations: [
          NavigationDestination(
            label: 'Users',
            icon: Icon(
              currentIndex == 0 ? Icons.person_add : Icons.person_add_outlined,
            ),
          ),
          NavigationDestination(
            label: 'Chats',
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text('$unreadCount'),
              child: Icon(
                currentIndex == 1 ? Icons.chat : Icons.chat_outlined,
              ),
            ),
          ),
          NavigationDestination(
            label: 'Profile',
            icon: Icon(
              currentIndex == 2 ? Icons.face : Icons.face_outlined,
            ),
          ),
        ],
        onDestinationSelected: _goBranch,
      ),
    );
  }
}
