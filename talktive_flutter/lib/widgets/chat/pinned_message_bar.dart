import 'package:flutter/material.dart';
import 'package:talktive_client/talktive_client.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';

class PinnedMessageBar extends StatelessWidget {
  final Message message;
  final VoidCallback? onTap;
  final VoidCallback? onUnpin;

  const PinnedMessageBar({
    super.key,
    required this.message,
    this.onTap,
    this.onUnpin,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        if (onTap != null) onTap!();
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.duoSpacingMedium,
          vertical: AppTheme.duoSpacingSmall,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.duoSpacingMedium,
          vertical: AppTheme.duoSpacingSmall,
        ),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppTheme.duoRadiusMedium),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.push_pin, color: AppTheme.primaryColor, size: 20),
            const SizedBox(width: AppTheme.duoSpacingSmall),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PINNED BY ${message.senderName.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    message.content ??
                        (message.imageUrl != null ? '📷 Image' : 'Media'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                      fontFamily: 'Rubik',
                    ),
                  ),
                ],
              ),
            ),
            if (onUnpin != null)
              IconButton(
                onPressed: () {
                  HapticFeedback.heavyImpact();
                  onUnpin!();
                },
                icon: const Icon(
                  Icons.close,
                  color: AppTheme.textSecondary,
                  size: 20,
                ),
                tooltip: 'Unpin message',
              ),
          ],
        ),
      ).animate().fadeIn().slideY(begin: -0.2, end: 0),
    );
  }
}
