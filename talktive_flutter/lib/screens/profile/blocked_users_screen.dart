import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/blocked_users_provider.dart';
import '../../providers/resident_provider.dart';
import '../../config/theme.dart';
import '../../widgets/duo/duo_card.dart';
import '../../widgets/duo/duo_empty_state.dart';
import '../../helpers/snackbar_helper.dart';
import '../../utils/floor_utils.dart';

/// Screen to manage blocked users
class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockedUsersAsync = ref.watch(blockedUsersProvider);

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Blocked Users',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: blockedUsersAsync.when(
        data: (blockedUserIds) {
          if (blockedUserIds.isEmpty) {
            return DuoEmptyState(
              emoji: '🚫',
              title: 'No blocked users',
              subtitle: 'You haven\'t blocked anyone yet',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: blockedUserIds.length,
            itemBuilder: (context, index) {
              final userId = blockedUserIds[index];
              return _buildBlockedUserCard(context, ref, userId, index);
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
        error: (error, stack) => DuoEmptyState(
          emoji: '😕',
          title: 'Error loading blocked users',
          subtitle: error.toString(),
        ),
      ),
    );
  }

  Widget _buildBlockedUserCard(
    BuildContext context,
    WidgetRef ref,
    String userId,
    int index,
  ) {
    final residentAsync = ref.watch(residentByIdProvider(userId));

    return residentAsync.when(
      data: (resident) {
        if (resident == null) {
          return const SizedBox.shrink();
        }

        return DuoCard(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.secondaryColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'R',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // User info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Resident',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Floor ${FloorUtils.computeFloor(resident)} • ⭐ ${resident.trustScore}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Unblock button
                    ElevatedButton(
                      onPressed: () =>
                          _unblockUser(context, ref, userId, 'Resident'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.duoGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text('Unblock'),
                    ),
                  ],
                ),
              ),
            )
            .animate(delay: Duration(milliseconds: index * 50))
            .fadeIn()
            .slideX(begin: -0.1, end: 0);
      },
      loading: () => const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  Future<void> _unblockUser(
    BuildContext context,
    WidgetRef ref,
    String userId,
    String userName,
  ) async {
    try {
      await ref.read(blockedUsersProvider.notifier).unblock(userId);
      if (context.mounted) {
        HapticFeedback.mediumImpact();
        SnackBarHelper.showSuccess(context, '$userName has been unblocked');
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarHelper.showError(context, 'Failed to unblock user: $e');
      }
    }
  }
}
