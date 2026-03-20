import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../helpers/duo_mention_helper.dart';
import '../../helpers/resident_ext.dart';
import '../../helpers/duo_snackbar_helper.dart';
import '../../providers/client_provider.dart';
import 'voice_message_player.dart';

class MessageBubble extends ConsumerWidget {
  final Message message;
  final bool isCurrentUser;
  final Resident? currentResident;
  final Function(String)? onMention;
  final List<String>? otherMemberNames;
  final bool isRead;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    required this.currentResident,
    this.onMention,
    this.otherMemberNames,
    this.isRead = false,
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
              onLongPress: onMention != null
                  ? () {
                      HapticFeedback.mediumImpact();
                      onMention!(senderName);
                    }
                  : null,
              child: DuoAvatar(
                imageUrl: senderAvatar,
                size: 36,
                mood: message.senderMood,
                trustScore: message.senderTrustScore,
                showRing: true,
              ),
            ),
            const SizedBox(width: AppTheme.duoSpacingSmall),
          ],

          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(
                context,
                ref,
                senderName,
                message.senderId.toString(),
              ),
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
                  border: (!isCurrentUser && 
                          message.content != null && 
                          DuoMentionHelper.containsMention(message.content!, currentResident?.userName ?? ''))
                      ? Border.all(color: AppTheme.accentColor, width: 2)
                      : null,
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
                            if (message.content != null && DuoMentionHelper.containsMention(message.content!, currentResident?.userName ?? '')) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'MENTION',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.accentColor,
                                  ),
                                ),
                              ),
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
                    if (message.mediaType == 'voice' && message.mediaUrl != null) ...[
                      VoiceMessagePlayer(
                        url: message.mediaUrl!,
                        isCurrentUser: isCurrentUser,
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (message.content != null &&
                        message.content!.isNotEmpty) ...[
                      RichText(
                        text: DuoMentionHelper.buildMessageSpan(
                          content: message.content!,
                          baseStyle: TextStyle(
                            fontSize: 15,
                            color: isCurrentUser
                                ? Colors.white
                                : AppTheme.textPrimary,
                            fontFamily: 'Rubik',
                            height: 1.4,
                          ),
                          mentionColor: isCurrentUser 
                              ? Colors.white 
                              : AppTheme.primaryColor,
                          currentUserName: currentResident?.userName,
                          otherMemberNames: otherMemberNames,
                          isCurrentUserSender: isCurrentUser,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                        if (isRead && isCurrentUser) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.done_all_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: AppTheme.duoSpacingSmall),
            DuoAvatar(
              imageUrl: currentResident?.customAvatarUrl ?? currentResident?.avatar,
              placeholderEmoji: currentResident?.avatar,
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
            if (currentResident?.isStaff ?? false) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: AppTheme.errorColor),
                title: const Text(
                  'Delete Message (Staff)',
                  style: TextStyle(
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
                      title: const Text('Delete message?'),
                      content: const Text(
                        'This will permanently remove the message from the conversation.',
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
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && context.mounted) {
                    try {
                      final client = ref.read(clientProvider);
                      await client.admin.deleteMessage(messageId: message.id!);
                      if (context.mounted) {
                        DuoSnackBarHelper.showSuccess(
                            context, 'Message deleted.');
                      }
                    } catch (e) {
                      if (context.mounted) DuoSnackBarHelper.showError(context, e);
                    }
                  }
                },
              ),
            ],
            const SizedBox(height: AppTheme.duoSpacingMedium),
          ],
        ),
      ),
    );
  }
}
