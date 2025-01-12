import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
            icon: Icon(
              currentIndex == 1 ? Icons.chat : Icons.chat_outlined,
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
