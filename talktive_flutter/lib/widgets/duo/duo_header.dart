import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';

/// Duolingo-style screen header with emoji and title
class DuoHeader extends StatelessWidget {
  final String emoji;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const DuoHeader({
    super.key,
    required this.emoji,
    required this.title,
    this.subtitle,
    this.trailing,
    this.textColor = AppTheme.textPrimary,
  });

  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.duoSpacingLarge),
      child: Row(
        children: [
          // Emoji icon
          Text(
            emoji,
            style: const TextStyle(fontSize: 32),
          ).animate().scale(duration: 300.ms, curve: Curves.elasticOut),
          const SizedBox(width: AppTheme.duoSpacingMedium),
          // Title and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontFamily: 'Poppins',
                  ),
                ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor.withOpacity(0.8),
                      fontFamily: 'Rubik',
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1, end: 0),
                ],
              ],
            ),
          ),
          // Optional trailing widget
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
