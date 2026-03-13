import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../plaza/plaza_screen.dart';
import '../moments/moments_screen.dart';
import '../chats/chats_screen.dart';
import '../groups/groups_screen.dart';
import '../profile/profile_screen.dart';
import '../../providers/private_chat_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/unread_counts_provider.dart';

import '../../config/theme.dart';

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
    // Handled natively by FCMManager initializing background messages
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
    _NavItem(emoji: '🏘️', label: 'Lounges', color: AppTheme.duoBlue),
    _NavItem(emoji: '👤', label: 'Profile', color: AppTheme.duoGreen),
  ];

  @override
  Widget build(BuildContext context) {
    final unreadCounts = ref.watch(totalUnreadCountsProvider);

    return Scaffold(
      extendBody: false,
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildDuoBottomNav(unreadCounts),
    );
  }

  int _getUnreadCount(UnreadCounts counts, int index) {
    if (index == 2) return counts.privateChats;
    if (index == 3) return counts.lounges;
    return 0;
  }

  Widget _buildDuoBottomNav(UnreadCounts unreadCounts) {
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

                    // Refresh target list when switching to a dynamic tab
                    if (index == 2) {
                      ref.read(privateChatListProvider.notifier).refresh();
                    } else if (index == 3) {
                      ref.read(groupListProvider.notifier).refresh();
                    }
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
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
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
                                        0.2126, 0.7152, 0.0722, 0, 0,
                                        0.2126, 0.7152, 0.0722, 0, 0,
                                        0.2126, 0.7152, 0.0722, 0, 0,
                                        0, 0, 0, 1, 0,
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
                            
                            // Badge
                            if (_getUnreadCount(unreadCounts, index) > 0)
                              Positioned(
                                right: -4,
                                top: -4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.duoRed,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Center(
                                    child: Text(
                                      _getUnreadCount(index) > 9 ? '9+' : _getUnreadCount(index).toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ).animate().scale(curve: Curves.easeOutBack),
                              ),
                          ],
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
