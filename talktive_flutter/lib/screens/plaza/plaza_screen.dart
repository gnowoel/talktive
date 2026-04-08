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
import '../../helpers/duo_floor_helper.dart';

/// The Plaza (Home) screen - The building's social heart.
class PlazaScreen extends ConsumerWidget {
  const PlazaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DuoPageScaffold(
      emoji: '🏛️',
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

        final xpProgress = DuoFloorHelper.getXPProgress(resident);
        final xpNeeded = DuoFloorHelper.getXPNeeded(resident);
        final progressPercent = (xpProgress / xpNeeded).clamp(0.0, 1.0);

        return DuoCard(
          margin: const EdgeInsets.all(AppTheme.duoSpacingMedium),
          padding: const EdgeInsets.all(AppTheme.duoSpacingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome Home,',
                          style: TextStyle(
                            fontSize: 14,
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
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Text('👋', style: TextStyle(fontSize: 28)),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .shake(duration: 1500.ms, hz: 4),
                ],
              ),
              const SizedBox(height: AppTheme.duoSpacingLarge),

              // XP Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Floor ${resident.level}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      Text(
                        '$xpProgress / $xpNeeded XP',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: 'Rubik',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          Container(
                            height: 12,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          AnimatedContainer(
                            duration: 800.ms,
                            curve: Curves.easeOutCubic,
                            height: 12,
                            width: constraints.maxWidth * progressPercent,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.duoOrange,
                                  AppTheme.duoOrange.withValues(alpha: 0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.duoOrange.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ).animate().shimmer(
                            delay: 1.seconds,
                            duration: 2.seconds,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: AppTheme.duoSpacingLarge),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.duoBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppTheme.duoRadiusSmall,
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 14,
                          color: AppTheme.duoBlue,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'PRO TIP',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.duoBlue,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'We recommend starting in the Global Lounge to meet your neighbors.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontFamily: 'Rubik',
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn().slideY(begin: 0.2);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
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
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildActionCard(
                  context,
                  title: 'Global Lounge',
                  subtitle:
                      'Join the main public chat to talk with everyone in the building.',
                  emoji: '🌏',
                  color: AppTheme.primaryColor,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  onTap: () => context.push('/plaza/chat'),
                ),
              ),
              const SizedBox(width: AppTheme.duoSpacingMedium),
              Expanded(
                child: _buildActionCard(
                  context,
                  title: 'Help Center',
                  subtitle: 'Get assistance',
                  emoji: '❓',
                  color: AppTheme.duoGreen,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.push('/plaza/help');
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    IconData? icon,
    String? emoji,
    required Color color,
    required VoidCallback onTap,
    Color? backgroundColor,
  }) {
    return DuoCard(
      onTap: onTap,
      color: backgroundColor,
      padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null)
            Icon(icon, color: color, size: 32)
          else if (emoji != null)
            Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
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
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
              emoji: '🏢',
              title: 'Floor',
              subtitle: 'Level up by chatting',
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallCard({
    IconData? icon,
    String? emoji,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return DuoCard(
      padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
      child: Row(
        children: [
          if (icon != null)
            Icon(icon, color: color, size: 24)
          else if (emoji != null)
            Text(emoji, style: const TextStyle(fontSize: 24)),
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
                const SizedBox(height: 2),
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
    return Container(
      padding: const EdgeInsets.all(AppTheme.duoSpacingLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.duoYellow.withValues(alpha: 0.12),
            AppTheme.duoOrange.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(AppTheme.duoRadiusLarge),
        border: Border.all(
          color: AppTheme.duoYellow.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: AppTheme.duoCardShadow,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🕰️', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Text(
                'Looking for the old version?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  fontFamily: 'Poppins',
                  color: Colors.brown[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'The legacy web version is still available.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.brown[400],
              fontFamily: 'Rubik',
            ),
          ),
          const SizedBox(height: 14),
          DuoButton(
            text: 'Open Web App',
            color: AppTheme.duoOrange,
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
