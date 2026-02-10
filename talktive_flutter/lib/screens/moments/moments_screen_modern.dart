import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:talktive_client/talktive_client.dart';
import 'package:talktive/serverpod_client.dart';
import '../../config/theme.dart';
import '../../widgets/duo/duo_header.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post: $e'),
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
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            DuoHeader(
              emoji: '📸',
              title: 'Moments',
              subtitle: 'Share your day',
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
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
          onPressed: _showCreateDialog,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add_a_photo, color: Colors.white),
        ),
      ).animate().scale(delay: 300.ms, duration: 200.ms),
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
            ],
          ),
        )
        .animate()
        .fadeIn(delay: Duration(milliseconds: index * 50))
        .slideX(begin: -0.1, end: 0);
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
