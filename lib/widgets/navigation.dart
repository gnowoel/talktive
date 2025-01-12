import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../helpers/messages.dart';
import '../services/cache.dart';

class Navigation extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const Navigation({
    super.key,
    required this.navigationShell,
  });

  void _goBranch(int index) {
    navigationShell.goBranch(index);
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;
    final chats = context.select((Cache cache) => cache.chats);
    final unreadCount = chatsUnreadMessageCount(chats);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
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
