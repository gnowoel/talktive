import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../plaza/plaza_screen.dart';
import '../moments/moments_screen.dart';
import '../chats/chats_screen.dart';
import '../groups/groups_screen.dart';
import '../profile/profile_screen.dart';

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
    PlazaScreen(),
    const MomentsScreen(),
    const ChatsScreen(),
    const GroupsScreen(),
    const ProfileScreen(),
  ];

  final List<_NavItem> _navItems = const [
    _NavItem(emoji: '🏛️', label: 'Plaza', color: AppTheme.primaryColor),
    _NavItem(emoji: '📸', label: 'Moments', color: AppTheme.secondaryColor),
    _NavItem(emoji: '💬', label: 'Chats', color: AppTheme.duoOrange),
    _NavItem(emoji: '👥', label: 'Groups', color: AppTheme.duoBlue),
    _NavItem(emoji: '👤', label: 'Profile', color: AppTheme.duoGreen),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: false,
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTheme.lightBackground,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildDuoBottomNav(),
    );
  }

  Widget _buildDuoBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 2)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppTheme.bottomNavHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (index) {
              final item = _navItems[index];
              final isSelected = _currentIndex == index;

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  child: AnimatedContainer(
                    duration: AppTheme.duoAnimationQuick,
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? item.color.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? item.color.withValues(alpha: 0.2)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Emoji icon
                        AnimatedOpacity(
                              duration: 150.ms,
                              opacity: isSelected ? 1.0 : 0.5,
                              child: ColorFiltered(
                                colorFilter: isSelected
                                    ? const ColorFilter.mode(
                                        Colors.transparent,
                                        BlendMode.dst,
                                      )
                                    : const ColorFilter.matrix(<double>[
                                        0.2126,
                                        0.7152,
                                        0.0722,
                                        0,
                                        0,
                                        0.2126,
                                        0.7152,
                                        0.0722,
                                        0,
                                        0,
                                        0.2126,
                                        0.7152,
                                        0.0722,
                                        0,
                                        0,
                                        0,
                                        0,
                                        0,
                                        1,
                                        0,
                                      ]),
                                child: Text(
                                  item.emoji,
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            )
                            .animate(target: isSelected ? 1 : 0)
                            .scale(
                              begin: const Offset(0.85, 0.85),
                              end: const Offset(1.0, 1.0),
                              duration: 150.ms,
                              curve: Curves.easeOutBack,
                            ),
                        const SizedBox(height: 2),
                        // Label
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: isSelected
                                ? item.color
                                : AppTheme.textSecondary.withValues(alpha: 0.7),
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
        ),
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
