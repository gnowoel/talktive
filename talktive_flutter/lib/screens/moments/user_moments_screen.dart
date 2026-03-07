import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    return DuoPageScaffold(
      emoji: '🖼️',
      title: 'Moments',
      subtitle: '$userName\'s collection',
      gradient: AppTheme.secondaryGradient,
      body: momentsAsync.when(
        data: (moments) {
          if (moments.isEmpty) {
            return const Center(
              child: DuoEmptyState(
                emoji: '🏜️',
                title: 'No moments yet',
                subtitle: 'This resident hasn\'t shared any snippets of their life yet.',
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
            itemCount: moments.length,
            itemBuilder: (context, index) {
              final moment = moments[index];
              return DuoMomentCard(
                moment: moment,
                isLiked: false, // We'd need a separate provider for user-specific like states if we want full interactive here
                onLike: () {
                  ref.read(momentsProvider.notifier).toggleLike(
                    moment.id!, 
                    false, // Simple implementation for profile view
                  );
                },
                onComment: () {}, // TODO: Show comments
                onAuthorTap: () {}, // Already on the user's collection
              );
            },
          );
        },
        loading: () => const DuoLoadingIndicator(),
        error: (error, stack) => Center(
          child: DuoCard(
            margin: const EdgeInsets.all(AppTheme.duoSpacingLarge),
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
