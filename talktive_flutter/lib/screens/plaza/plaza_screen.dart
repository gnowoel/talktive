import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:talktive_client/talktive_client.dart';
import '../../providers/current_resident_provider.dart';
import '../../config/theme.dart';
import '../../utils/floor_utils.dart';

import '../../widgets/duo/duo_card.dart';
import '../../widgets/duo/duo_page_scaffold.dart';
import 'plaza_chat_screen.dart';

/// Duolingo-style Plaza screen - entry point for public areas
class PlazaScreen extends ConsumerWidget {
  const PlazaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentResidentAsync = ref.watch(currentResidentProvider);
    final currentResident = currentResidentAsync.value;

    return DuoPageScaffold(
      emoji: '🏛️',
      title: 'The Plaza',
      subtitle: 'Your digital apartment lobby',
      gradient: AppTheme.primaryGradient,
      trailingHeader: currentResident != null
          ? _buildStatsChip(currentResident)
          : null,
      body: ListView(
        padding: const EdgeInsets.only(
          left: AppTheme.duoSpacingMedium,
          right: AppTheme.duoSpacingMedium,
          bottom: AppTheme.contentBottomPadding,
          top: AppTheme.duoSpacingLarge,
        ),
        children: [
          _buildWelcomeBanner()
              .animate()
              .fadeIn(delay: 100.ms)
              .slideX(begin: -0.1, end: 0),
          const SizedBox(height: AppTheme.duoSpacingLarge),
          _buildLoungeCard(
            context,
          ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1, end: 0),
          const SizedBox(height: AppTheme.duoSpacingMedium),
          _buildInfoCards()
              .animate()
              .fadeIn(delay: 300.ms)
              .slideX(begin: -0.1, end: 0),
        ],
      ),
    );
  }

  Widget _buildStatsChip(Resident currentResident) {
    return DuoCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.duoSpacingMedium,
        vertical: AppTheme.duoSpacingSmall,
      ),
      borderRadius: AppTheme.duoRadiusPill,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '🏢 ${FloorUtils.computeFloor(currentResident)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(width: AppTheme.duoSpacingSmall),
          Container(width: 1, height: 16, color: AppTheme.textLight),
          const SizedBox(width: AppTheme.duoSpacingSmall),
          Text(
            '⭐ ${currentResident.trustScore}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: currentResident.trustScore > 50
                  ? AppTheme.duoGreen
                  : currentResident.trustScore >= 20
                  ? AppTheme.duoYellow
                  : AppTheme.errorColor,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildWelcomeBanner() {
    return Row(
      children: [
        const Text('👋', style: TextStyle(fontSize: 48)),
        const SizedBox(width: AppTheme.duoSpacingMedium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome home!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Explore the building, meet neighbors, and find community.',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Rubik',
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoungeCard(BuildContext context) {
    return DuoCard(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PlazaChatScreen(),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.duoSpacingLarge),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppTheme.primaryGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppTheme.duoRadiusMedium),
              ),
              child: const Center(
                child: Text('🌍', style: TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(width: AppTheme.duoSpacingLarge),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Global Lounge',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Join the main public chat to talk with everyone in the building.',
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'Rubik',
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Public Chat',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.duoSpacingSmall),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCards() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildSmallCard(
                emoji: '📜',
                title: 'Rules',
                subtitle: 'Be nice and respectful',
                color: AppTheme.duoBlue,
              ),
            ),
            const SizedBox(width: AppTheme.duoSpacingMedium),
            Expanded(
              child: _buildSmallCard(
                emoji: '⭐',
                title: 'Floors',
                subtitle: 'Level up by chatting',
                color: AppTheme.duoYellow,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSmallCard({
    required String emoji,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return DuoCard(
      padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTheme.duoRadiusSmall),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(height: AppTheme.duoSpacingMedium),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'Rubik',
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
