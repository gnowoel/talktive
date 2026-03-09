import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:talktive_client/talktive_client.dart';
import '../../config/theme.dart';
import '../../providers/moments_provider.dart';
import '../../widgets/duo/duo_moment_card.dart';
import '../../widgets/duo/duo_page_scaffold.dart';
import '../../widgets/duo/duo_empty_state.dart';
import '../../widgets/duo/duo_loading_indicator.dart';
import '../../widgets/duo/duo_card.dart';

class UserMomentsScreen extends ConsumerWidget {
  final String userId;
  final String userName;

  const UserMomentsScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final momentsAsync = ref.watch(userMomentsProvider(userId));
    final likedMoments = ref.watch(momentLikesProvider).value ?? {};

    return DuoPageScaffold(
      emoji: '🖼️',
      title: 'Moments',
      subtitle: '$userName\'s collection',
      gradient: AppTheme.secondaryGradient,
      body: momentsAsync.when(
        data: (moments) {
          if (moments.isEmpty) {
            return Center(
              child: DuoEmptyState(
                emoji: '🏜️',
                title: 'No moments yet',
                subtitle: 'This resident hasn\'t shared any snippets of their life yet.',
              ),
            );
          }
          return ListView.builder(
            padding: EdgeInsets.all(AppTheme.duoSpacingMedium),
            itemCount: moments.length,
            itemBuilder: (context, index) {
              final moment = moments[index];
              final isLiked = likedMoments.contains(moment.id);
              return DuoMomentCard(
                moment: moment,
                index: index,
                isLiked: isLiked,
                onLike: () {
                  HapticFeedback.lightImpact();
                  // Optimistic UI update
                  ref.read(momentLikesProvider.notifier).toggleLike(moment.id!);
                  ref.read(momentsProvider.notifier).toggleLike(moment.id!, isLiked).catchError((_) {
                    // Revert on error
                    ref.read(momentLikesProvider.notifier).toggleLike(moment.id!);
                  });
                },
                onComment: () {
                  HapticFeedback.lightImpact();
                  context.push('/moments/detail', extra: moment);
                },
                onAuthorTap: () {
                  // Already on the user's collection, but we can navigate to profile
                  context.push('/user/$userId');
                },
              );
            },
          );
        },
        loading: () => const DuoLoadingIndicator(),
        error: (error, stack) => Center(
          child: DuoCard(
            margin: EdgeInsets.all(AppTheme.duoSpacingLarge),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 48),
                const SizedBox(height: AppTheme.duoSpacingMedium),
                Text('Error: $error'),
                const SizedBox(height: AppTheme.duoSpacingMedium),
                TextButton(
                  onPressed: () => ref.invalidate(userMomentsProvider(userId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
