import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';

/// A Duolingo-style typing indicator with animated dots and soft labels.
class DuoTypingIndicator extends StatelessWidget {
  final List<String> typingUsers;
  final bool isPrivate;

  const DuoTypingIndicator({
    super.key,
    required this.typingUsers,
    this.isPrivate = false,
  });

  @override
  Widget build(BuildContext context) {
    if (typingUsers.isEmpty) return const SizedBox.shrink();

    final text = isPrivate
        ? '${typingUsers[0]} is typing...'
        : typingUsers.length == 1
        ? '${typingUsers[0]} is typing...'
        : typingUsers.length == 2
        ? '${typingUsers[0]} and ${typingUsers[1]} are typing...'
        : '${typingUsers[0]} and ${typingUsers.length - 1} others typing...';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.duoSpacingLarge,
        vertical: 6,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildAnimatedDots(),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary.withValues(alpha: 0.8),
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                fontFamily: 'Rubik',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildAnimatedDots() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          return Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .fadeIn(delay: (index * 200).ms, duration: 400.ms)
              .then()
              .fadeOut(duration: 400.ms);
        }),
      ),
    );
  }
}
