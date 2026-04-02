import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';

/// Duolingo-style achievement badge with unlock animation
class DuoBadge extends StatelessWidget {
  final String emoji;
  final String name;
  final bool isUnlocked;
  final bool isNew;
  final VoidCallback? onTap;

  const DuoBadge({
    super.key,
    required this.emoji,
    required this.name,
    this.isUnlocked = false,
    this.isNew = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
                padding: const EdgeInsets.all(4.0),
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isUnlocked ? Colors.white : Colors.grey[50]!,
                    border: Border.all(
                      color: isUnlocked
                          ? AppTheme.duoPurple.withValues(alpha: 0.8)
                          : Colors.grey[200]!,
                      width: isNew ? 3.0 : 2.5,
                    ),
                    boxShadow: isUnlocked
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Center(
                        child: ColorFiltered(
                          colorFilter: isUnlocked
                              ? const ColorFilter.mode(
                                  Colors.transparent,
                                  BlendMode.multiply,
                                )
                              : const ColorFilter.matrix([
                                  0.2126,
                                  0.7152,
                                  0.0722,
                                  0,
                                  0,
                                  0.2126,
                                  0.7152,
                                  0.0722,
                                  0,
                                  0,
                                  0.2126,
                                  0.7152,
                                  0.0722,
                                  0,
                                  0,
                                  0,
                                  0,
                                  0,
                                  1,
                                  0,
                                ]),
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 32),
                          ),
                        ),
                      ),
                      if (!isUnlocked)
                        Positioned(
                          bottom: -4,
                          right: -4,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.lock_rounded,
                              color: Colors.grey[400],
                              size: 12,
                            ),
                          ),
                        ),
                      if (isNew)
                        Positioned(
                          top: 2,
                          right: 2,
                          child:
                              Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: AppTheme.duoRed,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.1,
                                          ),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  )
                                  .animate(
                                    onPlay: (c) => c.repeat(reverse: true),
                                  )
                                  .scale(
                                    duration: 1.seconds,
                                    begin: const Offset(0.8, 0.8),
                                    end: const Offset(1.1, 1.1),
                                    curve: Curves.easeInOut,
                                  ),
                        ),
                    ],
                  ),
                ),
              )
              .animate(onPlay: (c) => isNew ? c.repeat() : null)
              .shimmer(duration: 2.seconds, angle: -0.5, color: Colors.white24)
              .animate()
              .scale(
                begin: const Offset(0.95, 0.95),
                end: const Offset(1.0, 1.0),
                duration: 400.ms,
                curve: Curves.elasticOut,
              ),
          const SizedBox(height: AppTheme.duoSpacingSmall),
          // Badge name
          SizedBox(
            width: 90,
            child: Text(
              name,
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'Rubik',
                fontWeight: isUnlocked ? FontWeight.w800 : FontWeight.w600,
                color: isUnlocked ? Colors.black87 : Colors.grey[500],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
