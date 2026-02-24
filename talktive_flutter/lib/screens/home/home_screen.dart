import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../plaza/plaza_screen_modern.dart';
import '../moments/moments_screen_modern.dart';
import '../chats/chats_screen_modern.dart';
import '../groups/groups_screen_modern.dart';
import '../profile/profile_screen_modern.dart';

import '../../config/theme.dart';
import '../../services/serverpod_notification_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _checkPendingNotifications();
  }

  void _checkPendingNotifications() {
    // Check if there's a pending notification to handle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notificationData = ServerpodNotificationService()
          .getPendingNotificationData();
      if (notificationData != null && mounted) {
        ServerpodNotificationService().navigateFromNotification(
          context,
          notificationData,
        );
      }
    });
  }

  final List<Widget> _screens = [
    PlazaScreenModern(),
    const MomentsScreenModern(),
    const ChatsScreenModern(),
    const GroupsScreenModern(),
    const ProfileScreenModern(),
  ];

  final List<_NavItem> _navItems = const [
    _NavItem(emoji: '🏛️', label: 'Plaza', color: AppTheme.primaryColor),
    _NavItem(emoji: '📸', label: 'Moments', color: AppTheme.secondaryColor),
    _NavItem(emoji: '💬', label: 'Chats', color: AppTheme.duoOrange),
    _NavItem(emoji: '👥', label: 'Groups', color: AppTheme.duoYellow),
    _NavItem(emoji: '👤', label: 'Profile', color: AppTheme.duoGreen),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset:
          false, // Prevents bottom nav from floating above keyboard
      backgroundColor: AppTheme.lightBackground,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildDuoBottomNav(),
    );
  }

  Widget _buildDuoBottomNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, AppTheme.bottomNavMargin),
      height: AppTheme.bottomNavHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.bottomNavHeight / 2),
        boxShadow: AppTheme.duoCardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_navItems.length, (index) {
          final item = _navItems[index];
          final isSelected = _currentIndex == index;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _currentIndex = index;
                });
              },
              child: AnimatedContainer(
                duration: AppTheme.duoAnimationNormal,
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? item.color.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Emoji icon
                    Text(
                          item.emoji,
                          style: TextStyle(fontSize: isSelected ? 28 : 24),
                        )
                        .animate(target: isSelected ? 1 : 0)
                        .scale(duration: 200.ms, curve: Curves.elasticOut),
                    const SizedBox(height: 2),
                    // Label
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected ? item.color : AppTheme.textSecondary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _NavItem {
  final String emoji;
  final String label;
  final Color color;

  const _NavItem({
    required this.emoji,
    required this.label,
    required this.color,
  });
}
