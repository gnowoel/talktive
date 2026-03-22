import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/current_resident_provider.dart';
import '../../config/theme.dart';
import '../../widgets/duo/duo_card.dart';
import '../../widgets/duo/duo_page_scaffold.dart';
import '../../widgets/duo/duo_button.dart';

/// The Plaza (Home) screen - The building's social heart.
class PlazaScreen extends ConsumerWidget {
  const PlazaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DuoPageScaffold(
      icon: Icons.apartment,
      title: 'Plaza',
      subtitle: 'Your digital apartment lobby',
      gradient: AppTheme.primaryGradient,
      trailingHeader: const SizedBox.shrink(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Welcome Header
            _buildWelcomeBanner(context, ref),
            
            // Feature Cards
            Padding(
              padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
              child: Column(
                children: [
                  _buildQuickActions(context),
                  const SizedBox(height: AppTheme.duoSpacingMedium),
                  _buildInfoCards(),
                  const SizedBox(height: AppTheme.duoSpacingMedium),
                  _buildOldVersionInfo(context),
                ],
              ),
            ),
            
            // Padding for FAB if needed
            const SizedBox(height: AppTheme.contentBottomPadding),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(BuildContext context, WidgetRef ref) {
    final residentAsync = ref.watch(currentResidentProvider);

    return residentAsync.when(
      data: (resident) {
        if (resident == null) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.all(AppTheme.duoSpacingMedium),
          padding: const EdgeInsets.all(AppTheme.duoSpacingLarge),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.duoRadiusLarge),
            border: Border.all(color: Colors.grey[200]!, width: 2),
            boxShadow: AppTheme.duoCardShadow,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome Home,',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontFamily: 'Rubik',
                      ),
                    ),
                    Text(
                      resident.userName ?? 'Resident',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.waving_hand,
                  color: AppTheme.primaryColor,
                  size: 32,
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
               .shake(duration: 1500.ms, hz: 2),
            ],
          ),
        ).animate().fadeIn().slideY(begin: 0.2);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Explore',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                title: 'Global Chat',
                subtitle: 'Chat with everyone',
                icon: Icons.language,
                color: AppTheme.primaryColor,
                onTap: () => context.push('/plaza/global'),
              ),
            ),
            const SizedBox(width: AppTheme.duoSpacingMedium),
            Expanded(
              child: _buildActionCard(
                context,
                title: 'Help Center',
                subtitle: 'Get assistance',
                icon: Icons.help_outline,
                color: AppTheme.duoGreen,
                onTap: () => context.push('/plaza/support'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return DuoCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              fontFamily: 'Poppins',
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontFamily: 'Rubik',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSmallCard(
            icon: Icons.article,
            title: 'Rules',
            subtitle: 'Be nice and respectful',
            color: AppTheme.duoBlue,
          ),
        ),
        const SizedBox(width: AppTheme.duoSpacingMedium),
        Expanded(
          child: _buildSmallCard(
            icon: Icons.apartment,
            title: 'Floors',
            subtitle: 'Level up by chatting',
            color: AppTheme.duoYellow,
          ),
        ),
      ],
    );
  }

  Widget _buildSmallCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return DuoCard(
      padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontFamily: 'Rubik',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOldVersionInfo(BuildContext context) {
    return DuoCard(
      padding: const EdgeInsets.all(AppTheme.duoSpacingLarge),
      color: Colors.grey[50],
      child: Column(
        children: [
          const Icon(Icons.history, color: Colors.grey, size: 32),
          const SizedBox(height: 12),
          const Text(
            'Looking for the old version?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'The legacy Firebase version is still available via web.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
              fontFamily: 'Rubik',
            ),
          ),
          const SizedBox(height: 16),
          DuoButton(
            text: 'Open Web App',
            onPressed: () async {
              final url = Uri.parse('https://open.talktive.app/');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
    );
  }
}
