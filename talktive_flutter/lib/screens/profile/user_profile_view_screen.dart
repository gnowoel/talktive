import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../widgets/duo/duo_avatar.dart';
import '../../providers/client_provider.dart';
import '../../providers/blocked_users_provider.dart';
import '../../providers/user_likes_provider.dart';

/// Simple user profile view screen
/// Shows basic user info when tapping on an avatar
class UserProfileViewScreen extends ConsumerStatefulWidget {
  final String userId;
  final String? userName;
  final String? userAvatar;
  final int? userFloor;

  const UserProfileViewScreen({
    super.key,
    required this.userId,
    this.userName,
    this.userAvatar,
    this.userFloor,
  });

  @override
  ConsumerState<UserProfileViewScreen> createState() =>
      _UserProfileViewScreenState();
}

class _UserProfileViewScreenState extends ConsumerState<UserProfileViewScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final client = ref.read(clientProvider);
      final profile = await client.userProfile.getUserProfile(widget.userId);

      if (mounted) {
        setState(() {
          _profile = profile;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final blockedIds = ref.watch(blockedUsersProvider).value ?? [];
    final isBlocked = blockedIds.contains(widget.userId);

    final likedIds = ref.watch(userLikesProvider).value ?? [];
    final isLiked = likedIds.contains(widget.userId);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Vouch / Like button
          IconButton(
            icon: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              color: isLiked ? AppTheme.errorColor : AppTheme.textPrimary,
            ),
            onPressed: () async {
              try {
                if (isLiked) {
                  await ref
                      .read(userLikesProvider.notifier)
                      .unlikeUser(widget.userId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vouch removed.')),
                  );
                } else {
                  await ref
                      .read(userLikesProvider.notifier)
                      .likeUser(widget.userId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('User vouched! Trust Score increased.'),
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
          ),
          // Block / Unblock menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppTheme.textPrimary),
            onSelected: (value) async {
              if (value == 'block') {
                await _confirmBlock(context, isBlocked);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(
                      isBlocked ? Icons.person_add : Icons.block,
                      color: isBlocked
                          ? AppTheme.duoGreen
                          : AppTheme.errorColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isBlocked ? 'Unblock user' : 'Block user',
                      style: TextStyle(
                        color: isBlocked
                            ? AppTheme.duoGreen
                            : AppTheme.errorColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Could not load profile',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontFamily: 'Rubik',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : _buildProfile(),
    );
  }

  Future<void> _confirmBlock(BuildContext context, bool isBlocked) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isBlocked ? 'Unblock user?' : 'Block user?',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          isBlocked
              ? 'You will be able to see their messages again.'
              : 'You will no longer see their messages, and they cannot start a chat with you.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: isBlocked
                  ? AppTheme.duoGreen
                  : AppTheme.errorColor,
            ),
            child: Text(isBlocked ? 'Unblock' : 'Block'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        if (isBlocked) {
          await ref.read(blockedUsersProvider.notifier).unblock(widget.userId);
        } else {
          await ref.read(blockedUsersProvider.notifier).block(widget.userId);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isBlocked ? 'User unblocked.' : 'User blocked.',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: isBlocked
                  ? AppTheme.duoGreen
                  : AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  Widget _buildProfile() {
    if (_profile == null) {
      return const Center(child: Text('Profile not found'));
    }

    final name = _profile!['name'] as String? ?? widget.userName ?? 'Unknown';
    final avatar = _profile!['avatar'] as String? ?? widget.userAvatar;
    final floor = _profile!['floor'] as int? ?? widget.userFloor ?? 0;
    final bio = _profile!['bio'] as String?;
    final gender = _profile!['gender'] as String?;
    final country = _profile!['country'] as String?;
    final interests = _profile!['interests'] as List<dynamic>?;
    final languages = _profile!['languages'] as List<dynamic>?;
    final messageCount = _profile!['messageCount'] as int? ?? 0;
    final momentCount = _profile!['momentCount'] as int? ?? 0;
    final achievementCount = _profile!['achievementCount'] as int? ?? 0;
    final streakDays = _profile!['streakDays'] as int? ?? 0;
    final mutualGroups = _profile!['mutualGroups'] as int? ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Avatar and basic info
          DuoAvatar(
            imageUrl: avatar,
            initials: name[0],
            size: 120,
            floorLevel: floor,
            showRing: true,
          ),
          const SizedBox(height: 16),
          Text(
            name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          if (bio != null) ...[
            const SizedBox(height: 8),
            Text(
              bio,
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Rubik',
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),

          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStat('Floor', '$floor'),
              _buildStat('Messages', '$messageCount'),
              _buildStat('Moments', '$momentCount'),
              _buildStat('Streak', '$streakDays🔥'),
            ],
          ),
          const SizedBox(height: 24),

          // Info cards
          if (gender != null || country != null)
            _buildInfoCard('About', [
              if (gender != null)
                _buildInfoRow(Icons.person, _formatGender(gender)),
              if (country != null) _buildInfoRow(Icons.flag, country),
              if (mutualGroups > 0)
                _buildInfoRow(Icons.group, '$mutualGroups mutual groups'),
            ]),

          if (interests != null && interests.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoCard('Interests', [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: interests
                    .map(
                      (i) => Chip(
                        label: Text(i.toString()),
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        labelStyle: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.primaryColor,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    )
                    .toList(),
              ),
            ]),
          ],

          if (languages != null && languages.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildInfoCard('Languages', [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: languages
                    .map(
                      (l) => Chip(
                        label: Text(l.toString()),
                        backgroundColor: AppTheme.accentColor.withOpacity(0.1),
                        labelStyle: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.accentColor,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    )
                    .toList(),
              ),
            ]),
          ],

          if (achievementCount > 0) ...[
            const SizedBox(height: 16),
            _buildInfoCard('Achievements', [
              Text(
                '$achievementCount achievements unlocked',
                style: const TextStyle(fontSize: 16, fontFamily: 'Rubik'),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontFamily: 'Rubik',
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 16, fontFamily: 'Rubik')),
        ],
      ),
    );
  }

  String _formatGender(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
        return 'Male';
      case 'female':
        return 'Female';
      case 'non-binary':
        return 'Non-binary';
      case 'prefer-not-to-say':
        return 'Prefer not to say';
      default:
        return gender;
    }
  }
}
