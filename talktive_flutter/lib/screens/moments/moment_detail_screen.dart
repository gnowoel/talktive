import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talktive_client/talktive_client.dart';
import '../../config/theme.dart';
import '../../providers/moments_provider.dart';
import '../../widgets/duo/duo_avatar.dart';
import '../../widgets/duo/duo_floor_badge.dart';
import '../../widgets/duo/duo_loading_indicator.dart';
import '../../widgets/duo/duo_chat_layout.dart';
import '../../helpers/date_formatter.dart';
import '../../helpers/url_helper.dart';
import 'package:talktive_flutter/helpers/duo_snackbar_helper.dart';

class MomentDetailScreen extends ConsumerStatefulWidget {
  final Moment moment;

  const MomentDetailScreen({super.key, required this.moment});

  @override
  ConsumerState<MomentDetailScreen> createState() => _MomentDetailScreenState();
}

class _MomentDetailScreenState extends ConsumerState<MomentDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _isLiking = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    setState(() => _isLiking = true);
    try {
      final likedMoments = ref.read(momentLikesProvider).value ?? {};
      final isLiked = likedMoments.contains(widget.moment.id!);

      if (isLiked) {
        await ref
            .read(momentsProvider.notifier)
            .toggleLike(widget.moment.id!, true);
        ref.read(momentLikesProvider.notifier).toggleLike(widget.moment.id!);
      } else {
        await ref
            .read(momentsProvider.notifier)
            .toggleLike(widget.moment.id!, false);
        ref.read(momentLikesProvider.notifier).toggleLike(widget.moment.id!);
      }
      HapticFeedback.mediumImpact();
    } catch (e) {
      if (mounted) {
        DuoSnackBarHelper.showError(context, 'Failed to update like: $e');
      }
    } finally {
      if (mounted) setState(() => _isLiking = false);
    }
  }

  Future<void> _postComment(String text) async {
    if (text.trim().isEmpty) return;
    try {
      await ref
          .read(momentCommentsProvider(widget.moment.id!).notifier)
          .addComment(widget.moment.id!, text);
      _commentController.clear();
      HapticFeedback.lightImpact();
      if (mounted) {
        FocusScope.of(context).unfocus();
        DuoSnackBarHelper.showSuccess(context, 'Comment posted! 💬');
      }
    } catch (e) {
      if (mounted) {
        DuoSnackBarHelper.showError(context, 'Failed to post comment: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(momentCommentsProvider(widget.moment.id!));
    final isLikedAsync = ref.watch(momentLikesProvider);
    final isLiked = isLikedAsync.value?.contains(widget.moment.id!) ?? false;

    return DuoChatInputLayout(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Moment',
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      controller: _commentController,
      onSend: () => _postComment(_commentController.text),
      hintText: 'Add a comment...',
      content: CustomScrollView(
        slivers: [
          // Moment Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAuthorHeader(),
                _buildImage(context),
                _buildCaption(),
                _buildStats(isLiked),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppTheme.duoBorder,
                ),
              ],
            ),
          ),

          // Comments Section
          _buildCommentsList(commentsAsync),
        ],
      ),
    );
  }

  Widget _buildAuthorHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
      child: Row(
        children: [
          DuoAvatar(
            imageUrl: widget.moment.authorAvatar,
            mood: widget.moment.authorMood,
            trustScore: widget.moment.authorTrustScore,
            size: 44,
            showRing: true,
          ),
          const SizedBox(width: AppTheme.duoSpacingSmall),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.moment.authorName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  DuoFloorBadge(floor: widget.moment.authorFloor),
                ],
              ),
              Text(
                formatTimestamp(widget.moment.createdAt),
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push('/gallery', extra: widget.moment.imageUrl);
      },
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 500, minHeight: 200),
        color: AppTheme.lightBackground,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Blurred background
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Image.network(
                  UrlHelper.resolve(widget.moment.imageUrl),
                  fit: BoxFit.cover,
                  opacity: const AlwaysStoppedAnimation(0.4),
                ),
              ),
            ),
            // Hero Image
            Hero(
              tag: 'moment_image_${widget.moment.id}',
              child: Image.network(
                UrlHelper.resolve(widget.moment.imageUrl),
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: DuoLoadingIndicator());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaption() {
    if (widget.moment.caption == null || widget.moment.caption!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
      child: Text(
        widget.moment.caption!,
        style: const TextStyle(fontSize: 16, height: 1.5),
      ),
    );
  }

  Widget _buildStats(bool isLiked) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.duoSpacingMedium,
        vertical: AppTheme.duoSpacingSmall,
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              color: isLiked ? AppTheme.duoRed : AppTheme.textSecondary,
            ),
            onPressed: _isLiking ? null : _toggleLike,
          ),
          Text(
            '${widget.moment.likesCount} likes',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: AppTheme.duoSpacingMedium),
          const Icon(Icons.chat_bubble_outline, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(
            '${widget.moment.commentsCount} comments',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsList(AsyncValue<List<MomentComment>> commentsAsync) {
    return commentsAsync.when(
      data: (comments) {
        if (comments.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                'No comments yet. Be the first! 💬',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          );
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final comment = comments[index];
            return ListTile(
              leading: DuoAvatar(
                imageUrl: comment.userAvatar,
                mood: comment.userMood,
                trustScore: comment.userTrustScore,
                size: 32,
              ),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    comment.userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  DuoFloorBadge(
                    floor: comment.userFloor,
                    fontSize: 8,
                    padding: 4,
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comment.text,
                    style: const TextStyle(color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatTimestamp(comment.createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            );
          }, childCount: comments.length),
        );
      },
      loading: () => const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: DuoLoadingIndicator()),
      ),
      error: (e, _) => SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text('Error loading comments: $e')),
      ),
    );
  }
}
