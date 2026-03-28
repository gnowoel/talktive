import 'package:flutter/material.dart';
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
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Badge circle
          Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isUnlocked
                      ? LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.secondaryColor,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isUnlocked ? null : Colors.grey[300],
                  boxShadow: isUnlocked
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        emoji,
                        style: TextStyle(
                          fontSize: 28,
                          color: isUnlocked ? null : Colors.grey[400],
                        ),
                      ),
                    ),
                    if (!isUnlocked)
                      Center(
                        child: Icon(
                          Icons.lock,
                          color: Colors.grey[600],
                          size: 24,
                        ),
                      ),
                    if (isNew)
                      Positioned(
                        top: 0,
                        right: 0,
                        child:
                            Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.duoRed,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '!',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                )
                                .animate(
                                  onPlay: (controller) => controller.repeat(),
                                )
                                .scale(
                                  duration: 1000.ms,
                                  begin: const Offset(1.0, 1.0),
                                  end: const Offset(1.2, 1.2),
                                )
                                .then()
                                .scale(
                                  duration: 1000.ms,
                                  begin: const Offset(1.2, 1.2),
                                  end: const Offset(1.0, 1.0),
                                ),
                      ),
                  ],
                ),
              )
              .animate(target: isNew ? 1 : 0)
              .scale(
                duration: 500.ms,
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.1, 1.1),
                curve: Curves.easeInOut,
              )
              .then()
              .scale(
                duration: 500.ms,
                begin: const Offset(1.1, 1.1),
                end: const Offset(1.0, 1.0),
                curve: Curves.easeInOut,
              ),
          const SizedBox(height: 8),
          // Badge name
          Text(
            name,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isUnlocked ? Colors.black : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
