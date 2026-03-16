import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/current_resident_provider.dart';
import '../../widgets/duo/duo_card.dart';
import '../../widgets/duo/duo_button.dart';
import '../../helpers/duo_snackbar_helper.dart';
import '../../serverpod_client.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final residentAsync = ref.watch(currentResidentProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: residentAsync.when(
        data: (resident) {
          if (resident == null) return const Center(child: Text('Please log in'));

          return ListView(
            padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
            children: [
              _buildSectionHeader(context, 'Privacy 🛡️'),
              DuoCard(
                child: SwitchListTile(
                  title: const Text(
                    'Show Online Status',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Let others see when you are active'),
                  value: resident.showOnlineStatus,
                  activeColor: AppTheme.duoGreen,
                  onChanged: (value) async {
                    HapticFeedback.selectionClick();
                    try {
                      await client.resident.updateOnlineSettings(
                        showOnlineStatus: value,
                      );
                      ref.invalidate(currentResidentProvider);
                      DuoSnackBarHelper.showSuccess(
                        context,
                        value ? 'Online status visible! 🟢' : 'Incognito mode active! 👻',
                      );
                    } catch (e) {
                      DuoSnackBarHelper.showError(context, 'Failed to update settings');
                    }
                  },
                ),
              ),
              const SizedBox(height: AppTheme.duoSpacingLarge),
              _buildSectionHeader(context, 'Premium Features ✨'),
              _buildPremiumCard(context, ref, resident.isPremium),
              const SizedBox(height: AppTheme.duoSpacingMedium),
              _buildFeatureRow(
                context,
                icon: '🟢',
                title: 'Online Indicator',
                description: 'See when your friends are active in real-time.',
                isLocked: !resident.isPremium,
              ),
              _buildFeatureRow(
                context,
                icon: '👀',
                title: 'Enhanced Peephole',
                description: 'See more details about people knocking on your door.',
                isLocked: !resident.isPremium,
              ),
              _buildFeatureRow(
                context,
                icon: '✨',
                title: 'Golden Ring',
                description: 'A prestigious golden ring around your avatar.',
                isLocked: !resident.isPremium,
              ),
              const SizedBox(height: AppTheme.contentBottomPadding),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildPremiumCard(BuildContext context, WidgetRef ref, bool isPremium) {
    if (isPremium) {
      return DuoCard(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
          child: Column(
            children: [
              const Text(
                '🌟 YOU ARE PREMIUM',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Thank you for supporting Talktive! All extra features are unlocked.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      );
    }

    return DuoCard(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
        child: Column(
          children: [
            const Text(
              'Unlock Talktive Plus',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Get exclusive features and support the community for just \$2.99/month.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            DuoButton(
              text: 'Upgrade Now',
              onPressed: () async {
                HapticFeedback.mediumImpact();
                try {
                  await client.resident.purchasePremium();
                  ref.invalidate(currentResidentProvider);
                  DuoSnackBarHelper.showSuccess(context, 'Welcome to Talktive Plus! 🌟');
                } catch (e) {
                  DuoSnackBarHelper.showError(context, 'Purchase failed');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(
    BuildContext context, {
    required String icon,
    required String title,
    required String description,
    required bool isLocked,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isLocked ? Colors.grey[200] : AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                icon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isLocked ? Colors.grey[600] : Colors.black,
                      ),
                    ),
                    if (isLocked) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.lock_outline, size: 14, color: Colors.grey),
                    ],
                  ],
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
