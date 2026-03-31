import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:talktive_client/talktive_client.dart';
import '../../config/theme.dart';
import '../../helpers/date_formatter.dart';
import '../../helpers/url_helper.dart';
import 'duo_card.dart';
import 'duo_avatar.dart';

/// Duolingo-style moment card for the social feed
class DuoMomentCard extends StatelessWidget {
  final Moment moment;
  final int index;
  final bool isLiked;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onAuthorTap;

  const DuoMomentCard({
    super.key,
    required this.moment,
    this.index = 0,
    required this.isLiked,
    required this.onLike,
    required this.onComment,
    required this.onAuthorTap,
    this.onTap,
  });

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return DuoCard(
          onTap: onTap,
          margin: const EdgeInsets.only(bottom: AppTheme.duoSpacingMedium),
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author Header
              Padding(
                padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
                child: Row(
                  children: [
                    DuoAvatar(
                      imageUrl: moment.authorAvatar,
                      size: 40,
                      mood: moment.authorMood,
                      floorLevel: moment.authorFloor,
                      showRing: true,
                      onTap: onAuthorTap,
                    ),
                    const SizedBox(width: AppTheme.duoSpacingSmall),
                    Expanded(
                      child: GestureDetector(
                        onTap: onAuthorTap,
                        behavior: HitTestBehavior.opaque,
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
                              formatTimestamp(moment.createdAt),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                fontFamily: 'Rubik',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Photo
              if (moment.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppTheme.duoRadiusMedium),
                  ),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(
                      minHeight: 200,
                      maxHeight: 450,
                    ),
                    color: AppTheme.lightBackground,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Blurred background
                        Positioned.fill(
                          child: ImageFiltered(
                            imageFilter: ImageFilter.blur(
                              sigmaX: 20,
                              sigmaY: 20,
                            ),
                            child: Image.network(
                              UrlHelper.resolve(moment.imageUrl),
                              fit: BoxFit.cover,
                              opacity: const AlwaysStoppedAnimation(0.3),
                              errorBuilder: (_, _, _) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ),
                        // Main sharp image
                        Hero(
                          tag: 'moment_image_${moment.id}',
                          child: Image.network(
                            UrlHelper.resolve(moment.imageUrl),
                            width: double.infinity,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => Container(
                              height: 220,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTheme.secondaryColor.withValues(
                                      alpha: 0.15,
                                    ),
                                    AppTheme.secondaryColor.withValues(
                                      alpha: 0.05,
                                    ),
                                  ],
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '📷',
                                    style: TextStyle(
                                      fontSize: 48,
                                      color: AppTheme.secondaryColor.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Image unavailable',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.secondaryColor.withValues(
                                        alpha: 0.7,
                                      ),
                                      fontFamily: 'Rubik',
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
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

              // Actions
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.duoSpacingMedium,
                  vertical: AppTheme.duoSpacingSmall,
                ),
                child: Row(
                  children: [
                    _buildActionButton(
                      icon: isLiked ? Icons.favorite : Icons.favorite_border,
                      count: moment.likesCount,
                      isActive: isLiked,
                      onTap: onLike,
                      color: AppTheme.duoRed,
                      shouldAnimate: true,
                    ),
                    const SizedBox(width: AppTheme.duoSpacingMedium),
                    _buildActionButton(
                      icon: Icons.chat_bubble_outline,
                      count: moment.commentsCount,
                      isActive: false,
                      onTap: onComment,
                      color: AppTheme.duoBlue,
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
    required int count,
    required bool isActive,
    required VoidCallback onTap,
    required Color color,
    bool shouldAnimate = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.duoRadiusSmall),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? color : AppTheme.textSecondary,
            )
                .animate(target: shouldAnimate && isActive ? 1 : 0)
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.2, 1.2),
                  duration: 200.ms,
                  curve: Curves.easeOutBack,
                )
                .then()
                .scale(
                  begin: const Offset(1.2, 1.2),
                  end: const Offset(1, 1),
                  duration: 100.ms,
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
}
