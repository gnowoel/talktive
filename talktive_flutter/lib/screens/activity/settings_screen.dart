import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../providers/current_resident_provider.dart';
import '../../widgets/duo/duo_card.dart';
import '../../widgets/duo/duo_button.dart';
import '../../helpers/duo_snackbar_helper.dart';
import '../../helpers/resident_ext.dart';
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
              _buildSectionHeader(context, 'Premium Features ✨'),
              _buildPremiumCard(context, ref, resident.isPremium),
              const SizedBox(height: AppTheme.duoSpacingMedium),
              DuoCard(
                child: Column(
                  children: [
                    _buildFeatureToggle(
                      context,
                      ref,
                      icon: '🟢',
                      title: 'Online Indicator',
                      description: 'See when neighbors are active',
                      value: resident.showOnlineStatus,
                      isLocked: !resident.isPremium,
                      onChanged: (val) => _updatePremiumSettings(context, ref, showOnlineStatus: val),
                    ),
                    const Divider(height: 1),
                    _buildFeatureToggle(
                      context,
                      ref,
                      icon: '✔️',
                      title: 'Read Receipts',
                      description: 'Let others see if you read messages',
                      value: resident.showReadReceipts,
                      isLocked: !resident.isPremium,
                      onChanged: (val) => _updatePremiumSettings(context, ref, showReadReceipts: val),
                    ),
                    const Divider(height: 1),
                    _buildFeatureToggle(
                      context,
                      ref,
                      icon: '💬',
                      title: 'Typing Indicators',
                      description: 'Show others when you are typing',
                      value: resident.showTypingIndicator,
                      isLocked: !resident.isPremium,
                      onChanged: (val) => _updatePremiumSettings(context, ref, showTypingIndicator: val),
                    ),
                    const Divider(height: 1),
                    _buildFeatureToggle(
                      context,
                      ref,
                      icon: '🎙️',
                      title: 'Voice Messages',
                      description: 'Send audio messages in chats',
                      value: resident.showVoiceMessages,
                      isLocked: !resident.isPremium,
                      onChanged: (val) => _updatePremiumSettings(context, ref, showVoiceMessages: val),
                    ),
                    const Divider(height: 1),
                    _buildFeatureToggle(
                      context,
                      ref,
                      icon: '🔍',
                      title: 'Neighbor Discovery',
                      description: 'Search for any resident',
                      value: resident.showNeighborsDiscovery,
                      isLocked: !resident.isPremium,
                      onChanged: (val) => _updatePremiumSettings(context, ref, showNeighborsDiscovery: val),
                    ),
                    const Divider(height: 1),
                    _buildFeatureToggle(
                      context,
                      ref,
                      icon: '👁️',
                      title: 'Enhanced Peephole',
                      description: 'Get deep insights when checking peepholes',
                      value: resident.showEnhancedPeephole,
                      isLocked: !resident.isPremium,
                      onChanged: (val) => _updatePremiumSettings(context, ref, showEnhancedPeephole: val),
                    ),
                  ],
                ),
              ),
              if (resident.isStaff) ...[
                const SizedBox(height: AppTheme.duoSpacingLarge),
                _buildSectionHeader(context, 'Staff Tools 🛠️'),
                DuoCard(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    context.push('/admin/dashboard');
                  },
                  child: const ListTile(
                    leading: Text('👨‍💼', style: TextStyle(fontSize: 24)),
                    title: Text(
                      'Admin Dashboard',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Manage users and community safety'),
                    trailing: Icon(Icons.chevron_right_rounded),
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.contentBottomPadding),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }



  Future<void> _updatePremiumSettings(
    BuildContext context,
    WidgetRef ref, {
    bool? showOnlineStatus,
    bool? showReadReceipts,
    bool? showTypingIndicator,
    bool? showVoiceMessages,
    bool? showNeighborsDiscovery,
    bool? showEnhancedPeephole,
  }) async {
    HapticFeedback.selectionClick();
    final resident = ref.read(currentResidentProvider).value;
    if (resident == null) return;

    try {
      await client.resident.updatePrivacySettings(
        showReadReceipts: showReadReceipts ?? resident.showReadReceipts,
        showTypingIndicator: showTypingIndicator ?? resident.showTypingIndicator,
        showVoiceMessages: showVoiceMessages ?? resident.showVoiceMessages,
        showNeighborsDiscovery: showNeighborsDiscovery ?? resident.showNeighborsDiscovery,
        showEnhancedPeephole: showEnhancedPeephole ?? resident.showEnhancedPeephole,
      );
      
      // Handle Online status separately if needed or update it here
      if (showOnlineStatus != null) {
        await client.resident.updateOnlineSettings(showOnlineStatus: showOnlineStatus);
      }

      ref.invalidate(currentResidentProvider);
      if (!context.mounted) return;
      DuoSnackBarHelper.showSuccess(context, 'Premium settings updated! ✨');
    } catch (e) {
      if (!context.mounted) return;
      DuoSnackBarHelper.showError(context, 'Failed to update settings');
    }
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
                  if (!context.mounted) return;
                  DuoSnackBarHelper.showSuccess(context, 'Welcome to Talktive Plus! 🌟');
                } catch (e) {
                  if (!context.mounted) return;
                  DuoSnackBarHelper.showError(context, 'Purchase failed');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureToggle(
    BuildContext context,
    WidgetRef ref, {
    required String icon,
    required String title,
    required String description,
    required bool value,
    required bool isLocked,
    required Function(bool) onChanged,
  }) {
    return Opacity(
      opacity: isLocked ? 0.5 : 1.0,
      child: SwitchListTile(
        title: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (isLocked)
              const Icon(Icons.lock_rounded, size: 16, color: Colors.grey),
          ],
        ),
        subtitle: Text(description),
        value: isLocked ? false : value,
        activeThumbColor: AppTheme.primaryColor,
        onChanged: isLocked ? null : (val) {
          HapticFeedback.selectionClick();
          onChanged(val);
        },
      ),
    );
  }
}
