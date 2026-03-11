import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import '../../providers/achievement_provider.dart';
import '../../config/theme.dart';
import '../../widgets/duo/duo_badge.dart';
import '../../widgets/duo/duo_card.dart';
import '../../widgets/duo/duo_refresh_button.dart';

/// Achievements screen showing all unlockable badges
class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final achievementsAsync = ref.watch(userAchievementsProvider);

    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Achievements',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          DuoRefreshButton(
            color: Colors.black,
            onRefresh: () async {
              await ref.read(userAchievementsProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          achievementsAsync.when(
            data: (achievements) =>
                _buildAchievementsList(context, achievements),
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            ),
            error: (error, stack) => _buildErrorState(context, error),
          ),
          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.2,
              shouldLoop: false,
              colors: const [
                AppTheme.primaryColor,
                AppTheme.secondaryColor,
                AppTheme.accentColor,
                AppTheme.duoGreen,
                AppTheme.duoYellow,
                AppTheme.duoOrange,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsList(
    BuildContext context,
    List<Map<String, dynamic>> achievements,
  ) {
    // Check for new achievements and trigger confetti
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final newAchievements = achievements
          .where((a) => a['isNew'] == true)
          .toList();
      if (newAchievements.isNotEmpty) {
        _confettiController.play();

        // Mark as notified
        final achievementIds = newAchievements
            .map((a) => (a['achievement'] as dynamic).id as int)
            .toList();
        ref
            .read(userAchievementsProvider.notifier)
            .markAsNotified(achievementIds);
      }
    });

    // Group by category
    final categories = <String, List<Map<String, dynamic>>>{};
    for (final achievement in achievements) {
      final category =
          (achievement['achievement'] as dynamic).category as String;
      categories.putIfAbsent(category, () => []);
      categories[category]!.add(achievement);
    }

    // Calculate stats
    final unlockedCount = achievements
        .where((a) => a['unlocked'] == true)
        .length;
    final totalPoints = achievements
        .where((a) => a['unlocked'] == true)
        .fold<int>(
          0,
          (sum, a) => sum + ((a['achievement'] as dynamic).points as int),
        );

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(userAchievementsProvider.notifier).refresh();
      },
      color: AppTheme.primaryColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats card
            _buildStatsCard(
              context,
              unlockedCount,
              achievements.length,
              totalPoints,
            ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0),
            const SizedBox(height: AppTheme.duoSpacingLarge),

            // Achievement categories
            ...categories.entries.map((entry) {
              return _buildCategorySection(
                context,
                entry.key,
                entry.value,
              ).animate(delay: 100.ms).fadeIn(duration: 300.ms);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(
    BuildContext context,
    int unlocked,
    int total,
    int points,
  ) {
    return DuoCard(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.duoSpacingLarge),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.duoYellow.withValues(alpha: 0.3),
                    AppTheme.duoOrange.withValues(alpha: 0.3),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🏆', style: TextStyle(fontSize: 32)),
              ),
            ),
            const SizedBox(width: AppTheme.duoSpacingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Progress',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$unlocked / $total achievements unlocked',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 16,
                        color: AppTheme.duoYellow,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$points points earned',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.duoYellow,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    String category,
    List<Map<String, dynamic>> achievements,
  ) {
    final categoryNames = {
      'social': '👥 Social',
      'moments': '📸 Moments',
      'progression': '📈 Progression',
      'behavior': '✅ Behavior',
      'special': '⭐ Special',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          categoryNames[category] ?? category.toUpperCase(),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppTheme.duoSpacingMedium),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: AppTheme.duoSpacingMedium,
            mainAxisSpacing: AppTheme.duoSpacingMedium,
            childAspectRatio: 0.8,
          ),
          itemCount: achievements.length,
          itemBuilder: (context, index) {
            final achievement = achievements[index];
            final achievementData = achievement['achievement'] as dynamic;
            final isUnlocked = achievement['unlocked'] as bool;
            final isNew = achievement['isNew'] as bool;
            final progress = achievement['progress'] as int;

            return DuoBadge(
              emoji: achievementData.emoji as String,
              name: achievementData.name as String,
              isUnlocked: isUnlocked,
              isNew: isNew,
              onTap: () {
                HapticFeedback.lightImpact();
                _showAchievementDetails(
                  context,
                  achievementData,
                  isUnlocked,
                  progress,
                );
              },
            );
          },
        ),
        const SizedBox(height: AppTheme.duoSpacingLarge),
      ],
    );
  }

  void _showAchievementDetails(
    BuildContext context,
    dynamic achievement,
    bool isUnlocked,
    int progress,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.duoRadiusLarge),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.duoSpacingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isUnlocked
                      ? LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.secondaryColor,
                          ],
                        )
                      : null,
                  color: isUnlocked ? null : Colors.grey[300],
                ),
                child: Center(
                  child: Text(
                    achievement.emoji as String,
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.duoSpacingMedium),
              Text(
                achievement.name as String,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.duoSpacingSmall),
              Text(
                achievement.description as String,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.duoSpacingMedium),
              if (!isUnlocked) ...[
                LinearProgressIndicator(
                  value: progress / (achievement.targetValue as int),
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$progress / ${achievement.targetValue}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
              if (isUnlocked) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.duoGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: AppTheme.duoGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Unlocked!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.duoGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.duoSpacingSmall),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, size: 20, color: AppTheme.duoYellow),
                  const SizedBox(width: 4),
                  Text(
                    '${achievement.points} points',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.duoYellow,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppTheme.duoRed),
          const SizedBox(height: AppTheme.duoSpacingMedium),
          Text(
            'Failed to load achievements',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppTheme.duoSpacingSmall),
          Text(
            error.toString(),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
