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
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        destinations: const [
          NavigationDestination(
            label: 'Users',
            icon: Icon(Icons.person_add),
          ),
          NavigationDestination(
            label: 'Chats',
            icon: Icon(Icons.chat),
          ),
          NavigationDestination(
            label: 'Profile',
            icon: Icon(Icons.face),
          ),
        ],
        onDestinationSelected: _goBranch,
      ),
    );
  }
}
