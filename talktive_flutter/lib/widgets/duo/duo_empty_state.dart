import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import 'duo_button.dart';

/// Duolingo-style empty state with emoji, title, subtitle, and optional CTA
class DuoEmptyState extends StatelessWidget {
  final String? emoji;
  final IconData? icon;
  final String title;
  final String subtitle;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const DuoEmptyState({
    super.key,
    this.emoji,
    this.icon,
    required this.title,
    String? subtitle,
    String? message, // Alias for subtitle
    String? buttonText,
    String? actionLabel, // Alias for buttonText
    VoidCallback? onButtonPressed,
    VoidCallback? onActionPressed, // Alias for onButtonPressed
  }) : subtitle = subtitle ?? message ?? '',
       buttonText = buttonText ?? actionLabel,
       onButtonPressed = onButtonPressed ?? onActionPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.duoSpacingXLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Emoji icon with circular background
            Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withValues(alpha: 0.1),
                        AppTheme.secondaryColor.withValues(alpha: 0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: icon != null
                      ? Icon(icon, size: 64, color: AppTheme.primaryColor)
                      : Text(emoji ?? '', style: const TextStyle(fontSize: 64)),
                  ),
                )
                .animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                )
                .scale(
                  duration: 2000.ms,
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.1, 1.1),
                  curve: Curves.easeInOut,
                ),
            const SizedBox(height: AppTheme.duoSpacingLarge),
            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: AppTheme.duoSpacingSmall),
            // Subtitle
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
                fontFamily: 'Rubik',
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
            // Optional button
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: AppTheme.duoSpacingXLarge),
              DuoButton(text: buttonText!, onPressed: onButtonPressed)
                  .animate()
                  .fadeIn(delay: 300.ms)
                  .scale(begin: const Offset(0.8, 0.8)),
            ],
          ],
        ),
      ),
    );
  }
}
