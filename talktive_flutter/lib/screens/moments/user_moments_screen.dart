import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/moments_provider.dart';
import '../../widgets/duo/duo_moment_card.dart';
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '$userName\'s Moments',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontFamily: 'Poppins',
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(userMomentsProvider(userId));
              ref.invalidate(momentLikesProvider);
            },
            color: AppTheme.primaryColor,
            child: ListView.builder(
              padding: const EdgeInsets.only(
                left: AppTheme.duoSpacingMedium,
                right: AppTheme.duoSpacingMedium,
                bottom: AppTheme.contentBottomPadding,
              ),
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
                    if (userId != moment.authorId.toString()) {
                       context.push('/user/${moment.authorId}');
                    }
                  },
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.push('/moments/detail', extra: moment);
                  },
                );
              },
            ),
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
