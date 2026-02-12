import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../widgets/duo/duo_card.dart';
import '../../../widgets/duo/duo_button.dart';
import '../../../widgets/duo/duo_stat_card.dart';
import '../../../providers/client_provider.dart';

/// Provider for user profile data
final userProfileProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, userId) async {
      try {
        final client = ref.read(clientProvider);
        final profile = await client.userProfile.getUserProfile(userId);
        return profile;
      } catch (e) {
        debugPrint('Error loading user profile: $e');
        return null;
      }
    });

class UserProfileScreen extends ConsumerWidget {
  final String userId;
  final String? userName;

  const UserProfileScreen({super.key, required this.userId, this.userName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var profileAsync = ref.watch(
      userProfileProvider(userId),
    ); // removed invalid const if any? No const here.

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return _buildErrorState(context);
          }
          return _buildProfileContent(context, ref, profile);
        },
        loading: () => _buildLoadingState(),
        error: (error, stack) => _buildErrorState(context),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: AppTheme.primaryColor),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('😕', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text(
            'User not found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 24),
          DuoButton(text: 'Go Back', onPressed: () => context.pop()),
        ],
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> profile,
  ) {
    final isBlocked = profile['isBlocked'] as bool? ?? false;
    final hasBlockedMe = profile['hasBlockedMe'] as bool? ?? false;

    return CustomScrollView(
      slivers: [
        // Header with gradient background
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor: AppTheme.primaryColor,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.secondaryColor.withOpacity(0.8),
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    // Avatar
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppTheme.primaryColor, AppTheme.accentColor],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          profile['userAvatar'] ?? '👤',
                          style: const TextStyle(fontSize: 48),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Name
                    Text(
                      profile['userName'] ?? 'Anonymous',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    // Floor badge
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Floor ${profile['floor']}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Content
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Blocked warning
              if (hasBlockedMe)
                DuoCard(
                  child: Row(
                    children: [
                      const Icon(Icons.block, color: AppTheme.duoRed),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'This user has blocked you',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (hasBlockedMe) const SizedBox(height: 16),

              // Stats Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  DuoStatCard(
                    icon: Icons.chat_bubble_outline,
                    label: 'Messages',
                    value: profile['totalMessages'].toString(),
                    gradientColors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.7),
                    ],
                  ),
                  DuoStatCard(
                    icon: Icons.camera_alt_outlined,
                    label: 'Moments',
                    value: profile['totalMoments'].toString(),
                    gradientColors: [
                      AppTheme.secondaryColor,
                      AppTheme.secondaryColor.withOpacity(0.7),
                    ],
                  ),
                  DuoStatCard(
                    icon: Icons.emoji_events_outlined,
                    label: 'Achievements',
                    value: profile['achievementsUnlocked'].toString(),
                    gradientColors: [
                      AppTheme.duoYellow,
                      AppTheme.duoYellow.withOpacity(0.7),
                    ],
                  ),
                  DuoStatCard(
                    icon: Icons.local_fire_department_outlined,
                    label: 'Streak',
                    value: profile['currentStreak'].toString(),
                    gradientColors: [
                      AppTheme.duoOrange,
                      AppTheme.duoOrange.withOpacity(0.7),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Action Buttons
              if (!hasBlockedMe) ...[
                Row(
                  children: [
                    Expanded(
                      child: DuoButton(
                        text: 'Start Chat',
                        icon: Icons.chat_bubble_outline,
                        onPressed: () => _startChat(context, ref, profile),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DuoButton(
                      text: isBlocked ? 'Unblock' : 'Block',
                      icon: isBlocked
                          ? Icons.check_circle_outline
                          : Icons.block,
                      color: isBlocked ? AppTheme.duoGreen : AppTheme.duoRed,
                      onPressed: () =>
                          _toggleBlock(context, ref, profile, isBlocked),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DuoButton(
                  text: 'Report User',
                  icon: Icons.flag_outlined,
                  color: AppTheme.duoRed,
                  onPressed: () => _reportUser(context, profile),
                ),
              ],

              const SizedBox(height: 24),

              // Recent Moments
              if (profile['recentMoments'] != null &&
                  (profile['recentMoments'] as List).isNotEmpty) ...[
                const Text(
                  'Recent Moments',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 12),
                ..._buildRecentMoments(profile['recentMoments'] as List),
              ],
            ]),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildRecentMoments(List moments) {
    return moments.map((moment) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: DuoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (moment['imageUrl'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.duoRadiusMedium),
                  child: Image.network(
                    moment['imageUrl'],
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              if (moment['caption'] != null) ...[
                const SizedBox(height: 12),
                Text(
                  moment['caption'],
                  style: const TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.favorite_border,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${moment['likesCount'] ?? 0}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.comment_outlined,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${moment['commentsCount'] ?? 0}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  void _startChat(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> profile,
  ) {
    // TODO: Implement start chat functionality
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Starting chat...')));
  }

  Future<void> _toggleBlock(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> profile,
    bool isBlocked,
  ) async {
    try {
      final client = ref.read(clientProvider);
      if (isBlocked) {
        await client.userProfile.unblockUser(userId);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User unblocked')));
      } else {
        await client.userProfile.blockUser(userId);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User blocked')));
      }
      // Refresh profile
      ref.invalidate(userProfileProvider(userId));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _reportUser(BuildContext context, Map<String, dynamic> profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report User'),
        content: const Text(
          'Are you sure you want to report this user for inappropriate behavior?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement report functionality
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('User reported')));
            },
            child: const Text(
              'Report',
              style: TextStyle(color: AppTheme.duoRed),
            ),
          ),
        ],
      ),
    );
  }
}
