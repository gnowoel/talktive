import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/theme.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/duo/duo_card.dart';
import '../../widgets/duo/duo_page_scaffold.dart';

/// Duolingo-style Plaza screen - entry point for public areas
class PlazaScreen extends ConsumerWidget {
  const PlazaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DuoPageScaffold(
      icon: Icons.apartment_rounded,
      title: 'The Plaza',
      subtitle: 'Your digital apartment lobby',
      gradient: AppTheme.primaryGradient,
      trailingHeader: const SizedBox.shrink(),
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
          
          // Recommending Global Lounge
          _buildLoungeCard(context)
              .animate()
              .fadeIn(delay: 200.ms)
              .slideX(begin: -0.1, end: 0),
          
          const SizedBox(height: AppTheme.duoSpacingMedium),
          _buildInfoCards()
              .animate()
              .fadeIn(delay: 300.ms)
              .slideX(begin: -0.1, end: 0),
          
          const SizedBox(height: AppTheme.duoSpacingLarge),
          _buildOldVersionInfo()
              .animate()
              .fadeIn(delay: 400.ms)
              .slideX(begin: -0.1, end: 0),
        ],
      ),
    );
  }

  Widget _buildOldVersionInfo() {
    return DuoCard(
      padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
      child: Column(
        children: [
          const Text(
            'Still need the old version?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You can visit the web version here:',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, fontFamily: 'Rubik'),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              HapticFeedback.lightImpact();
              final uri = Uri.parse('https://open.talktive.app/');
              try {
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              } catch (_) {
                // Silently fail or show snackbar if needed
              }
            },
            child: const Text(
              'https://open.talktive.app/',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Row(
      children: [
        const Icon(
          Icons.waving_hand_rounded,
          size: 48,
          color: AppTheme.duoOrange,
        ),
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
                'We recommend starting in the Global Lounge to meet your neighbors.',
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
        context.push('/plaza/chat');
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
                child: Icon(Icons.public_rounded, size: 36, color: Colors.white),
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
                      const Icon(Icons.groups_rounded, size: 20, color: AppTheme.primaryColor),
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
            const Icon(Icons.chevron_right_rounded, size: 32, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCards() {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildSmallCard(
                  icon: Icons.description_rounded,
                  title: 'Rules',
                  subtitle: 'Be nice and respectful',
                  color: AppTheme.duoBlue,
                ),
              ),
              const SizedBox(width: AppTheme.duoSpacingMedium),
              Expanded(
                child: _buildSmallCard(
                  icon: Icons.layers_rounded,
                  title: 'Floors',
                  subtitle: 'Level up by chatting',
                  color: AppTheme.duoYellow,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSmallCard({
    String? emoji,
    IconData? icon,
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
            child: SizedBox(
              width: 32,
              height: 32,
              child: Center(
                child: icon != null 
                  ? Icon(icon, color: color, size: 24)
                  : Text(
                      emoji ?? '', 
                      style: const TextStyle(fontSize: 24, height: 1.0),
                    ),
              ),
            ),
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
