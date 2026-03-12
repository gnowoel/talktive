import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talktive_client/talktive_client.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/blocked_users_provider.dart';
import '../../widgets/duo/duo_avatar.dart';
import '../../widgets/duo/duo_floor_badge.dart';
import '../../helpers/date_formatter.dart';
import '../../helpers/url_helper.dart';

class MessageBubble extends ConsumerWidget {
  final Message message;
  final bool isCurrentUser;
  final Resident? currentResident;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    required this.currentResident,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final senderName = message.senderName.isNotEmpty
        ? message.senderName
        : 'Resident';
    final senderAvatar = message.senderAvatar;
    final senderFloor = message.senderFloor;

    if (message.isSystem == true) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppTheme.duoSpacingMedium,
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              message.content ?? '',
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'Rubik',
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

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
                size: 36,
                mood: message.senderMood,
                trustScore: message.senderTrustScore,
                showRing: true,
                // floorLevel removed here to hide it on avatar
              ),
            ),
            const SizedBox(width: AppTheme.duoSpacingSmall),
          ],

          Flexible(
            child: GestureDetector(
              onLongPress: !isCurrentUser
                  ? () => _showMessageOptions(
                      context,
                      ref,
                      senderName,
                      message.senderId.toString(),
                    )
                  : null,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.70,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: isCurrentUser
                      ? LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.primaryColor.withValues(alpha: 0.8),
                          ],
                        )
                      : null,
                  color: isCurrentUser ? null : Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.duoRadiusMedium),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
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
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              senderName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textSecondary,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            ...[
                              const SizedBox(width: 6),
                              DuoFloorBadge(floor: senderFloor),
                            ],
                          ],
                        ),
                      ),
                    if (message.imageUrl != null &&
                        message.imageUrl!.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppTheme.duoRadiusSmall,
                        ),
                        child: GestureDetector(
                          onTap: () {
                            context.push('/gallery', extra: message.imageUrl);
                          },
                          child: Hero(
                            tag: 'moment_image_${message.imageUrl.hashCode}',
                            child: CachedNetworkImage(
                              imageUrl: UrlHelper.resolve(message.imageUrl!),
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
                      formatTimestamp(message.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: isCurrentUser
                            ? Colors.white.withValues(alpha: 0.7)
                            : AppTheme.textLight,
                        fontFamily: 'Rubik',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: AppTheme.duoSpacingSmall),
            DuoAvatar(
              imageUrl: currentResident?.avatar,
              size: 36,
              trustScore: currentResident?.trustScore,
              showRing:
                  true, // Show the ring for current user too to reflect their status
            ),
          ],
        ],
      ),
    );
  }

  void _showMessageOptions(
    BuildContext context,
    WidgetRef ref,
    String senderName,
    String senderId,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(AppTheme.duoSpacingMedium),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.duoRadiusLarge),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.block, color: AppTheme.errorColor),
              title: Text(
                'Block $senderName',
                style: const TextStyle(
                  color: AppTheme.errorColor,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text('Block user?'),
                    content: const Text(
                      'You will no longer see their messages, and they cannot start a chat with you.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.errorColor,
                        ),
                        child: const Text('Block'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  ref.read(blockedUsersProvider.notifier).block(senderId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$senderName blocked.'),
                      backgroundColor: AppTheme.errorColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: AppTheme.duoSpacingMedium),
          ],
        ),
      ),
    );
  }
}
