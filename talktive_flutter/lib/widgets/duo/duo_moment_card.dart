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
              ],
            ),
          ),
          
          // Photo
          if (moment.imageUrl.isNotEmpty)
            Stack(
              children: [
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
                    color: AppTheme.lightBackground, // Simple letterbox background
                    child: Hero(
                      tag: 'moment_image_${moment.id}',
                      child: Image.network(
                        UrlHelper.resolve(moment.imageUrl),
                        width: double.infinity,
                        fit: BoxFit.contain, // Preserve aspect ratio
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
                  ),
                ),
                // Floor level indicator badge (optional but nice)
                Positioned(
                  top: AppTheme.duoSpacingSmall,
                  right: AppTheme.duoSpacingSmall,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '🏢 Floor ${moment.authorFloor}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Rubik',
                      ),
                    ),
                  ),
                ),
              ],
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
                  icon: Icons.favorite_border,
                  activeIcon: Icons.favorite,
                  count: moment.likesCount,
                  isActive: isLiked,
                  onTap: onLike,
                  color: AppTheme.duoRed,
                ),
                const SizedBox(width: AppTheme.duoSpacingMedium),
                _buildActionButton(
                  icon: Icons.chat_bubble_outline,
                  activeIcon: Icons.chat_bubble,
                  count: moment.commentsCount,
                  isActive: false,
                  onTap: onComment,
                  color: AppTheme.primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 50)).slideX(
      begin: -0.1,
      end: 0,
    );
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
}
