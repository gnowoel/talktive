import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:talktive_client/talktive_client.dart';
import 'package:talktive/serverpod_client.dart';
import '../../config/theme.dart';
import '../../widgets/duo/duo_page_scaffold.dart';
import '../../widgets/duo/duo_card.dart';
import '../../widgets/duo/duo_avatar.dart';
import '../../widgets/duo/duo_input.dart';
import '../../widgets/duo/duo_button.dart';
import '../../widgets/duo/duo_empty_state.dart';

/// Duolingo-style Moments screen - Photo feed
class MomentsScreenModern extends ConsumerStatefulWidget {
  const MomentsScreenModern({super.key});

  @override
  ConsumerState<MomentsScreenModern> createState() =>
      _MomentsScreenModernState();
}

class _MomentsScreenModernState extends ConsumerState<MomentsScreenModern> {
  List<Moment>? _moments;
  bool _isLoading = true;
  String? _error;
  final Set<int> _likedMoments = {}; // Track liked moments

  @override
  void initState() {
    super.initState();
    _loadMoments();
  }

  Future<void> _loadMoments() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final moments = await client.moment.listMoments(limit: 20);

      // Check which moments are liked
      _likedMoments.clear();
      for (final moment in moments) {
        final isLiked = await client.moment.hasLikedMoment(moment.id!);
        if (isLiked) {
          _likedMoments.add(moment.id!);
        }
      }

      setState(() {
        _moments = moments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _postMoment(String caption, String imageUrl) async {
    try {
      await client.moment.postMoment(imageUrl: imageUrl, caption: caption);
      if (mounted) {
        Navigator.pop(context);
        _loadMoments();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Moment posted! 🎉'),
            backgroundColor: AppTheme.duoGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.duoRadiusMedium),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Parse error message to remove "Exception: " prefix
        String errorMessage = e.toString().replaceAll('Exception: ', '');

        if (errorMessage.contains('Floor 2')) {
          // Show a nice dialog for the floor restriction
          showDialog(
            context: context,
            builder: (context) => Dialog(
              backgroundColor: Colors.transparent,
              child: DuoCard(
                padding: const EdgeInsets.all(AppTheme.duoSpacingLarge),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔒', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: AppTheme.duoSpacingMedium),
                    const Text(
                      'Level Up Required!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.duoSpacingSmall),
                    Text(
                      errorMessage,
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
        } else {
          // Standard error snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.duoRadiusMedium),
              ),
            ),
          );
        }
      }
    }
  }

  void _showCreateDialog() {
    final captionController = TextEditingController();
    final urlController = TextEditingController(
      text: 'https://picsum.photos/400/300',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
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
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                ),
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
                      controller: urlController,
                      labelText: 'Image URL',
                      hintText: 'https://example.com/image.jpg',
                      prefixIcon: Icons.link,
                    ),
                    const SizedBox(height: AppTheme.duoSpacingLarge),
                    DuoInput(
                      controller: captionController,
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
                  width: double.infinity,
                  onPressed: () {
                    if (urlController.text.isNotEmpty) {
                      _postMoment(captionController.text, urlController.text);
                    }
                  },
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
              AppTheme.secondaryColor.withOpacity(0.8),
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.secondaryColor.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          heroTag: 'moments_modern_fab',
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
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: DuoCard(
          margin: const EdgeInsets.all(AppTheme.duoSpacingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: AppTheme.errorColor,
                size: 48,
              ),
              const SizedBox(height: AppTheme.duoSpacingMedium),
              Text(
                'Error: $_error',
                style: const TextStyle(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.duoSpacingMedium),
              DuoButton(text: 'Retry', onPressed: _loadMoments),
            ],
          ),
        ),
      );
    }

    if (_moments == null || _moments!.isEmpty) {
      return DuoEmptyState(
        emoji: '📷',
        title: 'No moments yet',
        subtitle: 'Share your first photo!',
        buttonText: 'Create Moment',
        onButtonPressed: _showCreateDialog,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMoments,
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.only(
          left: AppTheme.duoSpacingMedium,
          right: AppTheme.duoSpacingMedium,
          bottom: 100,
        ),
        itemCount: _moments!.length,
        itemBuilder: (context, index) {
          final moment = _moments![index];
          return _buildMomentCard(moment, index);
        },
      ),
    );
  }

  Widget _buildMomentCard(Moment moment, int index) {
    return DuoCard(
          margin: const EdgeInsets.only(bottom: AppTheme.duoSpacingMedium),
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author header
              Padding(
                padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
                child: Row(
                  children: [
                    DuoAvatar(
                      initials: moment.authorName.isNotEmpty
                          ? moment.authorName[0].toUpperCase()
                          : '?',
                      size: 40,
                      floorLevel: moment.authorFloor,
                      showRing: false,
                    ),
                    const SizedBox(width: AppTheme.duoSpacingSmall),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            moment.authorName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          Text(
                            _formatTimestamp(moment.createdAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              fontFamily: 'Rubik',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Image
              if (moment.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppTheme.duoRadiusMedium),
                  ),
                  child: Image.network(
                    moment.imageUrl,
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 300,
                      color: AppTheme.lightBackground,
                      child: const Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 64,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ),
                  ),
                ),
              // Caption
              if (moment.caption != null && moment.caption!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
                  child: Text(
                    moment.caption!,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppTheme.textPrimary,
                      fontFamily: 'Rubik',
                      height: 1.4,
                    ),
                  ),
                ),
              // Like and Comment buttons
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.duoSpacingMedium,
                  vertical: AppTheme.duoSpacingSmall,
                ),
                child: Row(
                  children: [
                    // Like button
                    _buildActionButton(
                      icon: Icons.favorite_border,
                      activeIcon: Icons.favorite,
                      count: moment.likesCount,
                      isActive: _likedMoments.contains(moment.id),
                      onTap: () => _toggleLike(moment),
                      color: AppTheme.duoRed,
                    ),
                    const SizedBox(width: AppTheme.duoSpacingMedium),
                    // Comment button
                    _buildActionButton(
                      icon: Icons.chat_bubble_outline,
                      activeIcon: Icons.chat_bubble,
                      count: moment.commentsCount,
                      isActive: false,
                      onTap: () => _showComments(moment),
                      color: AppTheme.primaryColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: Duration(milliseconds: index * 50))
        .slideX(begin: -0.1, end: 0);
  }

  Widget _buildActionButton({
    required IconData icon,
    required IconData activeIcon,
    required int count,
    required bool isActive,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.duoRadiusSmall),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 20,
              color: isActive ? color : AppTheme.textSecondary,
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isActive ? color : AppTheme.textSecondary,
                  fontFamily: 'Rubik',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _toggleLike(Moment moment) async {
    if (moment.id == null) return;

    final isLiked = _likedMoments.contains(moment.id);

    try {
      // Optimistic update
      setState(() {
        if (isLiked) {
          _likedMoments.remove(moment.id);
          moment.likesCount = (moment.likesCount - 1).clamp(0, 999999);
        } else {
          _likedMoments.add(moment.id!);
          moment.likesCount += 1;
        }
      });

      // API call
      if (isLiked) {
        await client.moment.unlikeMoment(moment.id!);
      } else {
        await client.moment.likeMoment(moment.id!);
      }
    } catch (e) {
      // Revert on error
      setState(() {
        if (isLiked) {
          _likedMoments.add(moment.id!);
          moment.likesCount += 1;
        } else {
          _likedMoments.remove(moment.id);
          moment.likesCount = (moment.likesCount - 1).clamp(0, 999999);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${isLiked ? 'unlike' : 'like'}: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _showComments(Moment moment) async {
    if (moment.id == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CommentsSheet(momentId: moment.id!),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}

/// Comments bottom sheet
class _CommentsSheet extends StatefulWidget {
  final int momentId;

  const _CommentsSheet({required this.momentId});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  List<MomentComment>? _comments;
  bool _isLoading = true;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      setState(() => _isLoading = true);
      final comments = await client.moment.getMomentComments(
        widget.momentId,
        limit: 50,
      );
      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    try {
      await client.moment.addComment(widget.momentId, text);
      _commentController.clear();
      _loadComments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add comment: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  )
                : _comments == null || _comments!.isEmpty
                ? const Center(
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
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
                    itemCount: _comments!.length,
                    itemBuilder: (context, index) {
                      final comment = _comments![index];
                      return _buildCommentItem(comment);
                    },
                  ),
          ),
          // Input area
          Container(
            padding: EdgeInsets.only(
              left: AppTheme.duoSpacingMedium,
              right: AppTheme.duoSpacingMedium,
              top: AppTheme.duoSpacingSmall,
              bottom:
                  MediaQuery.of(context).viewInsets.bottom +
                  AppTheme.duoSpacingMedium,
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
                    backgroundColor: AppTheme.primaryColor.withValues(
                      alpha: 0.1,
                    ),
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
            initials: comment.userName.isNotEmpty
                ? comment.userName[0].toUpperCase()
                : '?',
            size: 32,
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
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTimestamp(comment.createdAt),
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
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                    fontFamily: 'Rubik',
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}
