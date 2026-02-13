import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talktive_client/talktive_client.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../providers/user_profile_provider.dart';
import '../../config/theme.dart';
import '../../widgets/duo/duo_avatar.dart';

class MessageBubbleModern extends ConsumerWidget {
  final Message message;
  final bool isCurrentUser;
  final Resident? currentResident;

  const MessageBubbleModern({
    super.key,
    required this.message,
    required this.isCurrentUser,
    required this.currentResident,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = !isCurrentUser
        ? ref.watch(userProfileProvider(message.senderId.toString()))
        : null;

    final profile = profileAsync?.value;
    final senderName = profile?['userName'] as String? ?? 'Resident';
    final senderAvatar = profile?['userAvatar'] as String?;
    final senderFloor = profile?['floor'] as int? ?? 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.duoSpacingSmall),
      child: Row(
        mainAxisAlignment: isCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[
            GestureDetector(
              onTap: () {
                context.push('/user/${message.senderId}');
              },
              child: DuoAvatar(
                imageUrl: senderAvatar,
                initials: senderName.isNotEmpty ? senderName[0] : '?',
                size: 36,
                showRing: true,
                floorLevel: senderFloor,
              ),
            ),
            const SizedBox(width: AppTheme.duoSpacingSmall),
          ],

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isCurrentUser
                    ? LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          AppTheme.primaryColor.withOpacity(0.8),
                        ],
                      )
                    : null,
                color: isCurrentUser ? null : Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.duoRadiusMedium),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isCurrentUser)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        senderName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  if (message.imageUrl != null &&
                      message.imageUrl!.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                        AppTheme.duoRadiusSmall,
                      ),
                      child: CachedNetworkImage(
                        imageUrl: message.imageUrl!,
                        placeholder: (context, url) => Container(
                          width: 200,
                          height: 200,
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 200,
                          height: 200,
                          color: Colors.grey[200],
                          child: const Icon(Icons.error),
                        ),
                        fit: BoxFit.cover,
                        width: 200,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (message.content != null &&
                      message.content!.isNotEmpty) ...[
                    Text(
                      message.content!,
                      style: TextStyle(
                        fontSize: 15,
                        color: isCurrentUser
                            ? Colors.white
                            : AppTheme.textPrimary,
                        fontFamily: 'Rubik',
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    _formatTimestamp(message.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: isCurrentUser
                          ? Colors.white.withOpacity(0.7)
                          : AppTheme.textLight,
                      fontFamily: 'Rubik',
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: AppTheme.duoSpacingSmall),
            DuoAvatar(
              imageUrl: currentResident?.avatar,
              initials: 'ME',
              size: 36,
              showRing: false,
            ),
          ],
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
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.month}/${timestamp.day} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}
