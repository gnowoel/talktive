import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:talktive_client/talktive_client.dart';
import '../../config/theme.dart';
import '../../providers/blocked_users_provider.dart';
import '../../providers/moments_provider.dart';
import '../../providers/current_resident_provider.dart';
import '../../helpers/snackbar_helper.dart';
import '../../widgets/duo/duo_page_scaffold.dart';
import '../../widgets/duo/duo_card.dart';
import '../../widgets/duo/duo_avatar.dart';
import '../../widgets/duo/duo_input.dart';
import '../../widgets/duo/duo_button.dart';
import '../../widgets/duo/duo_empty_state.dart';
import '../../widgets/duo/duo_loading_indicator.dart';
import '../../widgets/duo/duo_moment_card.dart';
import '../profile/user_profile_view_screen.dart';

/// Duolingo-style Moments screen - Photo feed
class MomentsScreen extends ConsumerStatefulWidget {
  const MomentsScreen({super.key});

  @override
  ConsumerState<MomentsScreen> createState() => _MomentsScreenState();
}

class _MomentsScreenState extends ConsumerState<MomentsScreen> {
  final _captionController = TextEditingController();
  final _urlController = TextEditingController(text: 'https://picsum.photos/400/300');

  @override
  void dispose() {
    _captionController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _postMoment() async {
    final caption = _captionController.text.trim();
    final imageUrl = _urlController.text.trim();
    
    if (imageUrl.isEmpty) return;

    try {
      await ref.read(momentsProvider.notifier).postMoment(
        imageUrl: imageUrl, 
        caption: caption,
      );
      if (mounted) {
        Navigator.pop(context);
        _captionController.clear();
        SnackBarHelper.showSuccess(context, 'Moment posted! 🎉');
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString();
        if (errorMessage.contains('Level 10')) {
          _showLevelRequirementDialog(errorMessage);
        } else {
          SnackBarHelper.showError(context, e.toString());
        }
      }
    }
  }

  void _showLevelRequirementDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: DuoCard(
          padding: const EdgeInsets.all(AppTheme.duoSpacingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏢', style: TextStyle(fontSize: 48)),
              const SizedBox(height: AppTheme.duoSpacingMedium),
              const Text(
                'High-Rise Access Required',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.duoSpacingSmall),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  fontFamily: 'Rubik',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.duoSpacingLarge),
              DuoButton(
                text: 'Got it',
                onPressed: () => Navigator.pop(context),
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.duoRadiusLarge),
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppTheme.duoSpacingLarge),
              decoration: BoxDecoration(
                gradient: AppTheme.secondaryGradient,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.duoRadiusLarge),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    const Text('📸', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: AppTheme.duoSpacingSmall),
                    const Expanded(
                      child: Text(
                        'New Moment',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.duoSpacingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DuoInput(
                      controller: _urlController,
                      labelText: 'Image URL',
                      hintText: 'https://example.com/image.jpg',
                      prefixIcon: Icons.link,
                    ),
                    const SizedBox(height: AppTheme.duoSpacingLarge),
                    DuoInput(
                      controller: _captionController,
                      labelText: 'Caption',
                      hintText: "What's happening?",
                      maxLines: 4,
                      maxLength: 200,
                    ),
                  ],
                ),
              ),
            ),
            // Post button
            Padding(
              padding: const EdgeInsets.all(AppTheme.duoSpacingLarge),
              child: SafeArea(
                top: false,
                child: DuoButton(
                  text: 'Post Moment',
                  icon: Icons.send,
                  secondaryIcon: Icons.auto_awesome,
                  width: double.infinity,
                  onPressed: _postMoment,
                ),
              ),
            ),
          ],
        ),
      ).animate().slideY(begin: 1, end: 0, duration: 300.ms),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DuoPageScaffold(
      emoji: '📸',
      title: 'Moments',
      subtitle: 'Share your day',
      gradient: AppTheme.secondaryGradient,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.secondaryColor,
              AppTheme.secondaryColor.withValues(alpha: 0.8),
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.secondaryColor.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          heroTag: 'moments_fab',
          onPressed: _showCreateDialog,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add_a_photo, color: Colors.white),
        ),
      ).animate().scale(delay: 300.ms, duration: 200.ms),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final momentsAsync = ref.watch(momentsProvider);
    final blockedUsers = ref.watch(blockedUsersProvider).value ?? [];
    final likedMoments = ref.watch(momentLikesProvider).value ?? {};

    return momentsAsync.when(
      data: (moments) {
        if (moments.isEmpty) {
          return DuoEmptyState(
            emoji: '📷',
            title: 'No moments yet',
            subtitle: 'Share your first photo!',
            buttonText: 'Create Moment',
            onButtonPressed: _showCreateDialog,
          );
        }

        final filteredMoments = moments
            .where((m) => !blockedUsers.contains(m.authorId.toString()))
            .toList();

        if (filteredMoments.isEmpty && moments.isNotEmpty) {
          return const DuoEmptyState(
            emoji: '🙈',
            title: 'No moments to show',
            subtitle: 'The only moments available are from users you have blocked.',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(momentsProvider);
            ref.invalidate(momentLikesProvider);
          },
          color: AppTheme.primaryColor,
          child: ListView.builder(
            padding: const EdgeInsets.only(
              left: AppTheme.duoSpacingMedium,
              right: AppTheme.duoSpacingMedium,
              bottom: AppTheme.contentBottomPadding,
            ),
            itemCount: filteredMoments.length,
            itemBuilder: (context, index) {
              final moment = filteredMoments[index];
              return DuoMomentCard(
                moment: moment,
                index: index,
                isLiked: likedMoments.contains(moment.id),
                onLike: () => _toggleLike(moment, likedMoments.contains(moment.id)),
                onComment: () => _showComments(moment),
                onAuthorTap: () => _navigateToProfile(moment),
              );
            },
          ),
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
              Text(
                'Error: $error',
                style: const TextStyle(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.duoSpacingMedium),
              DuoButton(
                text: 'Retry', 
                onPressed: () => ref.invalidate(momentsProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleLike(Moment moment, bool currentlyLiked) async {
    if (moment.id == null) return;
    
    // Use optimistic UI update
    ref.read(momentLikesProvider.notifier).toggleLike(moment.id!);
    
    try {
      await ref.read(momentsProvider.notifier).toggleLike(moment.id!, currentlyLiked);
    } catch (e) {
      // Revert if error
      ref.read(momentLikesProvider.notifier).toggleLike(moment.id!);
      if (mounted) SnackBarHelper.showError(context, e.toString());
    }
  }

  void _showComments(Moment moment) {
    if (moment.id == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CommentsSheet(momentId: moment.id!),
    );
  }

  void _navigateToProfile(Moment moment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileViewScreen(
          userId: moment.authorId.toString(),
          userName: moment.authorName,
          userFloor: moment.authorFloor,
        ),
      ),
    );
  }
}

/// Comments bottom sheet
class _CommentsSheet extends ConsumerStatefulWidget {
  final int momentId;

  const _CommentsSheet({required this.momentId});

  @override
  ConsumerState<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<_CommentsSheet> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    try {
      await ref.read(momentCommentsProvider(widget.momentId).notifier).addComment(
        widget.momentId, 
        text,
      );
      _commentController.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(momentCommentsProvider(widget.momentId));

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                const Text(
                  'Comments',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Comments list
          Expanded(
            child: commentsAsync.when(
              data: (comments) {
                if (comments.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('💬', style: TextStyle(fontSize: 48)),
                        SizedBox(height: 8),
                        Text(
                          'No comments yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.textSecondary,
                            fontFamily: 'Rubik',
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return _buildCommentItem(comment);
                  },
                );
              },
              loading: () => const DuoLoadingIndicator(),
              error: (error, _) => Center(child: Text(error.toString())),
            ),
          ),
          // Input area
          Container(
            padding: EdgeInsets.only(
              left: AppTheme.duoSpacingMedium,
              right: AppTheme.duoSpacingMedium,
              top: AppTheme.duoSpacingSmall,
              bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.duoSpacingMedium,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addComment,
                  icon: const Icon(Icons.send),
                  color: AppTheme.primaryColor,
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(MomentComment comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.duoSpacingMedium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DuoAvatar(
            imageUrl: comment.userAvatar,
            size: 32,
            mood: comment.userMood,
            floorLevel: comment.userFloor,
            showRing: false,
          ),
          const SizedBox(width: AppTheme.duoSpacingSmall),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.userName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatTimestamp(comment.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontFamily: 'Rubik',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.text,
                  style: const TextStyle(fontSize: 14, fontFamily: 'Rubik'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
