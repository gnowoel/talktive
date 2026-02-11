import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';

/// Duolingo-style streak card showing current streak and daily reward
class DuoStreakCard extends StatelessWidget {
  final int currentStreak;
  final int longestStreak;
  final bool canClaimReward;
  final VoidCallback onClaimReward;

  const DuoStreakCard({
    super.key,
    required this.currentStreak,
    required this.longestStreak,
    required this.canClaimReward,
    required this.onClaimReward,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.duoOrange, AppTheme.duoYellow],
        ),
        borderRadius: BorderRadius.circular(AppTheme.duoRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppTheme.duoOrange.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canClaimReward
              ? () {
                  HapticFeedback.mediumImpact();
                  onClaimReward();
                }
              : null,
          borderRadius: BorderRadius.circular(AppTheme.duoRadiusMedium),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.duoSpacingLarge),
            child: Row(
              children: [
                // Flame icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('🔥', style: const TextStyle(fontSize: 32))
                        .animate(onPlay: (controller) => controller.repeat())
                        .scale(
                          duration: 1000.ms,
                          begin: const Offset(1.0, 1.0),
                          end: const Offset(1.1, 1.1),
                          curve: Curves.easeInOut,
                        ),
                  ),
                ),
                const SizedBox(width: AppTheme.duoSpacingMedium),
                // Streak info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$currentStreak day streak!',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Longest: $longestStreak days',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontFamily: 'Rubik',
                        ),
                      ),
                      if (canClaimReward) ...[
                        const SizedBox(height: 8),
                        Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    '🎁',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Claim reward',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.duoOrange,
                                      fontFamily: 'Rubik',
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .animate(
                              onPlay: (controller) => controller.repeat(),
                            )
                            .shimmer(
                              duration: 2000.ms,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
