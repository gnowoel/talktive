import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../plaza/plaza_screen.dart';
import '../moments/moments_screen.dart';
import '../chats/chats_screen.dart';
import '../groups/groups_screen.dart';
import '../profile/profile_screen.dart';

import '../../config/theme.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    // Tab 1: Plaza (We pass a dummy onExit because the main nav handles exit now)
    PlazaScreen(),
    // Tab 2: Moments
    const MomentsScreen(),
    // Tab 3: Chats
    const ChatsScreen(),
    // Tab 4: Groups
    const GroupsScreen(),
    // Tab 5: Profile
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Allow body to extend behind nav bar
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withOpacity(0.1),
              AppTheme.secondaryColor.withOpacity(0.1),
            ],
          ),
        ),
        child: IndexedStack(index: _currentIndex, children: _screens),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        decoration: BoxDecoration(
          // Glassmorphism effect
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: NavigationBar(
            height: 65,
            backgroundColor: Colors.transparent,
            indicatorColor: Colors.white.withOpacity(0.2),
            selectedIndex: _currentIndex,
            labelBehavior:
                NavigationDestinationLabelBehavior.alwaysHide, // Cleaner look
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.apartment, color: Colors.white70),
                selectedIcon: Icon(Icons.apartment, color: Colors.white),
                label: 'Plaza',
              ),
              NavigationDestination(
                icon: Icon(Icons.local_activity, color: Colors.white70),
                selectedIcon: Icon(Icons.local_activity, color: Colors.white),
                label: 'Moments',
              ),
              NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline, color: Colors.white70),
                selectedIcon: Icon(Icons.chat_bubble, color: Colors.white),
                label: 'Chats',
              ),
              NavigationDestination(
                icon: Icon(Icons.groups_outlined, color: Colors.white70),
                selectedIcon: Icon(Icons.groups, color: Colors.white),
                label: 'Groups',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline, color: Colors.white70),
                selectedIcon: Icon(Icons.person, color: Colors.white),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
