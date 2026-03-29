import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../widgets/duo/duo_button.dart';

class DuoCelebration {
  static void show(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String emoji,
    String? buttonText,
    VoidCallback? onConfirm,
  }) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) => _CelebrationDialog(
        title: title,
        subtitle: subtitle,
        emoji: emoji,
        buttonText: buttonText,
        onConfirm: onConfirm,
      ),
    );
  }
}

class _CelebrationDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final String emoji;
  final String? buttonText;
  final VoidCallback? onConfirm;

  const _CelebrationDialog({
    required this.title,
    required this.subtitle,
    required this.emoji,
    this.buttonText,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(AppTheme.duoSpacingLarge),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background "Confetti"
          ...List.generate(30, (index) {
            final random = Random(index);
            final color = [
              AppTheme.duoGreen,
              AppTheme.duoYellow,
              AppTheme.duoRed,
              AppTheme.duoBlue,
              AppTheme.duoPurple,
              AppTheme.duoOrange,
            ][random.nextInt(6)];
            final shape = random.nextBool(); // True = Square, False = Circle

            return _ConfettiPiece(
              color: color,
              isCircle: shape,
              random: random,
            );
          }),

          // The Card
          Container(
            padding: const EdgeInsets.all(AppTheme.duoSpacingXLarge),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.duoRadiusLarge),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.2),
                  blurRadius: 40,
                  spreadRadius: 20,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.duoYellow.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 70, height: 1.0),
                    )
                        .animate(onPlay: (c) => c.repeat())
                        .shake(duration: 800.ms, hz: 4)
                        .scale(
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1.2, 1.2),
                          curve: Curves.elasticOut,
                        ),
                  ),
                ),
                const SizedBox(height: AppTheme.duoSpacingLarge),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 12),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                    fontFamily: 'Rubik',
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: AppTheme.duoSpacingXLarge),
                DuoButton(
                  text: buttonText ?? 'AWESOME!',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                    onConfirm?.call();
                  },
                  width: double.infinity,
                ).animate().fadeIn(delay: 600.ms).scale(begin: const Offset(0.8, 0.8)),
              ],
            ),
          ).animate().scale(
                duration: 400.ms,
                begin: const Offset(0, 0),
                end: const Offset(1, 1),
                curve: Curves.elasticOut,
              ),
        ],
      ),
    );
  }
}

class _ConfettiPiece extends StatelessWidget {
  final Color color;
  final bool isCircle;
  final Random random;

  const _ConfettiPiece({
    required this.color,
    required this.isCircle,
    required this.random,
  });

  @override
  Widget build(BuildContext context) {
    final startX = random.nextDouble() * 400 - 200;
    final startY = random.nextDouble() * 400 - 200;
    final endX = startX + (random.nextDouble() * 200 - 100);
    final endY = startY + (random.nextDouble() * 200 - 100);

    return Container(
      width: 10 + random.nextDouble() * 10,
      height: 10 + random.nextDouble() * 10,
      decoration: BoxDecoration(
        color: color,
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(2),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .move(
          begin: Offset(startX, startY),
          end: Offset(endX, endY),
          duration: Duration(milliseconds: 2000 + random.nextInt(2000)),
          curve: Curves.linear,
        )
        .rotate(
          begin: 0,
          end: 2,
          duration: Duration(milliseconds: 1000 + random.nextInt(1000)),
        )
        .fadeOut(duration: Duration(milliseconds: 2000 + random.nextInt(2000)));
  }
}
