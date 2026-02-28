import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../config/languages.dart';
import '../../../widgets/duo/duo_card.dart';
import '../../../widgets/duo/duo_button.dart';
import '../../../widgets/duo/duo_stat_card.dart';
import '../../../providers/client_provider.dart';
import '../../../providers/private_chat_provider.dart';
import '../../../providers/user_profile_provider.dart';
import 'package:talktive_client/talktive_client.dart';

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
        error: (error, stack) => _buildErrorState(context, error: error),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(color: AppTheme.primaryColor),
    );
  }

  Widget _buildErrorState(BuildContext context, {Object? error}) {
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
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
          const SizedBox(height: 24),
          DuoButton(text: 'Go Back', onPressed: () => context.pop()),
        ],
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    WidgetRef ref,
    UserProfileView profile,
  ) {
    final isBlocked = profile.isBlocked;
    final hasBlockedMe = profile.hasBlockedMe;

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
                    AppTheme.secondaryColor.withValues(alpha: 0.8),
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
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          profile.userAvatar ?? '👤',
                          style: const TextStyle(fontSize: 48),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Name
                    Text(
                      profile.userName ?? 'Anonymous',
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
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Floor ${profile.floor}',
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
                    value: profile.totalMessages.toString(),
                    gradientColors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withValues(alpha: 0.7),
                    ],
                  ),
                  DuoStatCard(
                    icon: Icons.camera_alt_outlined,
                    label: 'Moments',
                    value: profile.totalMoments.toString(),
                    gradientColors: [
                      AppTheme.secondaryColor,
                      AppTheme.secondaryColor.withValues(alpha: 0.7),
                    ],
                  ),
                  DuoStatCard(
                    icon: Icons.emoji_events_outlined,
                    label: 'Achievements',
                    value: profile.achievementsUnlocked.toString(),
                    gradientColors: [
                      AppTheme.duoYellow,
                      AppTheme.duoYellow.withValues(alpha: 0.7),
                    ],
                  ),
                  DuoStatCard(
                    icon: Icons.local_fire_department_outlined,
                    label: 'Streak',
                    value: profile.currentStreak.toString(),
                    gradientColors: [
                      AppTheme.duoOrange,
                      AppTheme.duoOrange.withValues(alpha: 0.7),
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
                        onPressed: () => _startChat(context, ref),
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
                  onPressed: () => _reportUser(context, ref, profile),
                ),
              ],

              const SizedBox(height: 24),

              // Languages
              if (profile.languages != null)
                _buildLanguagesSection(profile.languages!),

              // Interests
              if (profile.interests != null)
                _buildInterestsSection(profile.interests!),

              // Recent Moments
              if (profile.recentMoments != null &&
                  profile.recentMoments!.isNotEmpty) ...[
                const Text(
                  'Recent Moments',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 12),
                ..._buildRecentMoments(profile.recentMoments!),
              ],
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguagesSection(List languages) {
    if (languages.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Languages',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: languages.map((code) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.duoGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.duoGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLanguages.getFlag(code as String),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppLanguages.getName(code),
                      style: const TextStyle(
                        color: AppTheme.duoGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsSection(List interests) {
    if (interests.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Interests',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: interests.map((interest) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.accentColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  interest as String,
                  style: const TextStyle(
                    color: AppTheme.accentColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
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

  void _startChat(BuildContext context, WidgetRef ref) {
    final chatList = ref.read(privateChatListProvider.notifier);
    chatList
        .getOrCreateChat(userId)
        .then((chat) {
          if (context.mounted) context.push('/chat/${chat.channelId}');
        })
        .catchError((error) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to start chat: $error')),
            );
          }
        });
  }

  Future<void> _toggleBlock(
    BuildContext context,
    WidgetRef ref,
    UserProfileView profile,
    bool isBlocked,
  ) async {
    try {
      final client = ref.read(clientProvider);
      if (isBlocked) {
        await client.userProfile.unblockUser(userId);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('User unblocked')));
        }
      } else {
        await client.userProfile.blockUser(userId);
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('User blocked')));
        }
      }
      // Refresh profile
      ref.invalidate(userProfileProvider(userId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _reportUser(
    BuildContext context,
    WidgetRef ref,
    UserProfileView profile,
  ) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please tell us what happened. Reports help keep Talktive safe.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Reason for report',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please add a reason.')),
                );
                return;
              }
              Navigator.pop(context);
              try {
                final client = ref.read(clientProvider);
                await client.report.reportUser(
                  targetUserId: userId,
                  reason: reason,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report submitted')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
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
