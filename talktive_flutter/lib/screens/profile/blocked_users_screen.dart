import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/blocked_users_provider.dart';
import '../../providers/current_resident_provider.dart';
import '../../config/theme.dart';
import '../../widgets/duo/duo_card.dart';
import '../../widgets/duo/duo_page_scaffold.dart';
import '../../widgets/duo/duo_avatar.dart';
import '../../widgets/duo/duo_empty_state.dart';
import '../../widgets/duo/duo_button.dart';
import 'package:talktive_flutter/helpers/duo_snackbar_helper.dart';
import 'package:talktive_flutter/helpers/duo_floor_helper.dart';

/// Screen to manage blocked users
class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockedUsersAsync = ref.watch(blockedUsersProvider);

    return DuoPageScaffold(
      emoji: '🚫',
      title: 'Blocked Users',
      subtitle: 'Peace & quiet',
      gradient: AppTheme.duoOrangeGradient,
      hasBackButton: true,
      body: blockedUsersAsync.when(
        data: (blockedUserIds) {
          if (blockedUserIds.isEmpty) {
            return const DuoEmptyState(
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
                    DuoAvatar(
                      imageUrl: resident.avatar,
                      size: 48,
                      mood: resident.mood,
                      floorLevel: DuoFloorHelper.computeFloor(resident),
                      showRing: false,
                    ),
                    const SizedBox(width: 12),
                    // User info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            resident.userName ?? 'Resident',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Floor ${DuoFloorHelper.computeFloor(resident)} • ⭐ ${resident.trustScore}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                              fontFamily: 'Rubik',
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Unblock button
                    DuoButton(
                      text: 'Unblock',
                      onPressed: () => _unblockUser(
                        context,
                        ref,
                        userId,
                        resident.userName ?? 'Resident',
                      ),
                      variant: DuoButtonVariant.secondary,
                      size: DuoButtonSize.small,
                      color: AppTheme.duoGreen,
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
        DuoSnackBarHelper.showSuccess(context, '$userName has been unblocked');
      }
    } catch (e) {
      if (context.mounted) {
        DuoSnackBarHelper.showError(context, 'Failed to unblock user: $e');
      }
    }
  }
}
