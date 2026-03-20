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
              _buildSectionHeader(context, 'Privacy Settings'),
              DuoCard(
                child: Column(
                  children: [
                    _buildToggle(
                      context,
                      ref,
                      icon: '🟢',
                      title: 'Show Online Status',
                      description: 'Let others see if you are online',
                      value: resident.showOnlineStatus,
                      onChanged: (val) => _updateOnlineStatus(context, ref, val),
                    ),
                    const Divider(height: 1),
                    _buildToggle(
                      context,
                      ref,
                      icon: '✔️',
                      title: 'Show Read Receipts',
                      description: 'Let others see if you read messages',
                      value: resident.showReadReceipts,
                      onChanged: (val) => _updatePrivacy(context, ref, showReadReceipts: val),
                    ),
                    const Divider(height: 1),
                    _buildToggle(
                      context,
                      ref,
                      icon: '💬',
                      title: 'Show Typing Indicators',
                      description: 'Show others when you are typing',
                      value: resident.showTypingIndicator,
                      onChanged: (val) => _updatePrivacy(context, ref, showTypingIndicator: val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.duoSpacingLarge),
              _buildPremiumStatusCard(context, ref, resident.isPremium),
              const SizedBox(height: AppTheme.duoSpacingLarge),
              _buildSectionHeader(context, 'Premium Features ✨'),
              DuoCard(
                child: Column(
                  children: [
                    _buildBenefitRow(
                      context,
                      ref,
                      icon: '🟢',
                      title: 'Online Indicator',
                      description: 'See when your friends are active in real-time.',
                      value: resident.showOnlineStatus, // Wait, toggle this field? Or just a benefit?
                      isPremium: resident.isPremium,
                      onChanged: (val) => _updateOnlineStatus(context, ref, val),
                    ),
                    const Divider(height: 1),
                    _buildBenefitRow(
                      context,
                      ref,
                      icon: '👀',
                      title: 'Enhanced Peephole',
                      description: 'See more details about people knocking on your door.',
                      value: resident.showEnhancedPeephole,
                      isPremium: resident.isPremium,
                      onChanged: (val) => _updatePrivacy(context, ref, showEnhancedPeephole: val),
                    ),
                    const Divider(height: 1),
                    _buildBenefitRow(
                      context,
                      ref,
                      icon: '✨',
                      title: 'Golden Ring',
                      description: 'A prestigious golden ring around your avatar.',
                      value: resident.showGoldenRing,
                      isPremium: resident.isPremium,
                      onChanged: (val) => _updatePrivacy(context, ref, showGoldenRing: val),
                    ),
                    const Divider(height: 1),
                    _buildBenefitRow(
                      context,
                      ref,
                      icon: '🖼️',
                      title: 'Custom Avatar',
                      description: 'Upload your own image to use as an avatar.',
                      value: resident.showCustomAvatar,
                      isPremium: resident.isPremium,
                      onChanged: (val) => _updatePrivacy(context, ref, showCustomAvatar: val),
                    ),
                    const Divider(height: 1),
                    _buildBenefitRow(
                      context,
                      ref,
                      icon: '🎙️',
                      title: 'Voice Messages',
                      description: 'Send audio messages in any chat thread.',
                      value: resident.showVoiceMessages,
                      isPremium: resident.isPremium,
                      onChanged: (val) => _updatePrivacy(context, ref, showVoiceMessages: val),
                    ),
                    const Divider(height: 1),
                    _buildBenefitRow(
                      context,
                      ref,
                      icon: '✔️',
                      title: 'Read Receipts',
                      description: 'See when others have read your messages.',
                      value: resident.showReadReceipts,
                      isPremium: resident.isPremium,
                      onChanged: (val) => _updatePrivacy(context, ref, showReadReceipts: val),
                    ),
                    const Divider(height: 1),
                    _buildBenefitRow(
                      context,
                      ref,
                      icon: '✍️',
                      title: 'Typing Indicators',
                      description: 'See when someone is replying to you.',
                      value: resident.showTypingIndicator,
                      isPremium: resident.isPremium,
                      onChanged: (val) => _updatePrivacy(context, ref, showTypingIndicator: val),
                    ),
                    const Divider(height: 1),
                    _buildBenefitRow(
                      context,
                      ref,
                      icon: '🔍',
                      title: 'Neighbors Discovery',
                      description: 'Search for any resident in the building.',
                      value: resident.showNeighborsDiscovery,
                      isPremium: resident.isPremium,
                      onChanged: (val) => _updatePrivacy(context, ref, showNeighborsDiscovery: val),
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

  Widget _buildToggle(
    BuildContext context,
    WidgetRef ref, {
    required String icon,
    required String title,
    required String description,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
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
        ],
      ),
      subtitle: Text(description),
      value: value,
      activeThumbColor: AppTheme.primaryColor,
      onChanged: (val) {
        HapticFeedback.selectionClick();
        onChanged(val);
      },
    );
  }

  Widget _buildBenefitRow(
    BuildContext context,
    WidgetRef ref, {
    required String icon,
    required String title,
    required String description,
    required bool value,
    required bool isPremium,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.duoSpacingMedium,
        vertical: AppTheme.duoSpacingSmall,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (isPremium)
            Switch(
              value: value,
              activeThumbColor: AppTheme.primaryColor,
              onChanged: (val) {
                HapticFeedback.selectionClick();
                onChanged(val);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPremiumStatusCard(BuildContext context, WidgetRef ref, bool isPremium) {
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

  Future<void> _updateOnlineStatus(BuildContext context, WidgetRef ref, bool value) async {
    try {
      await client.resident.updateOnlineSettings(showOnlineStatus: value);
      ref.invalidate(currentResidentProvider);
      if (!context.mounted) return;
      DuoSnackBarHelper.showSuccess(context, 'Online status updated');
    } catch (e) {
      if (!context.mounted) return;
      DuoSnackBarHelper.showError(context, 'Failed to update online status');
    }
  }

  Future<void> _updatePrivacy(
    BuildContext context,
    WidgetRef ref, {
    bool? showReadReceipts,
    bool? showTypingIndicator,
    bool? showVoiceMessages,
    bool? showNeighborsDiscovery,
    bool? showEnhancedPeephole,
    bool? showGoldenRing,
    bool? showCustomAvatar,
  }) async {
    final resident = ref.read(currentResidentProvider).value;
    if (resident == null) return;

    try {
      await client.resident.updatePrivacySettings(
        showReadReceipts: showReadReceipts ?? resident.showReadReceipts,
        showTypingIndicator: showTypingIndicator ?? resident.showTypingIndicator,
        showVoiceMessages: showVoiceMessages ?? resident.showVoiceMessages,
        showNeighborsDiscovery: showNeighborsDiscovery ?? resident.showNeighborsDiscovery,
        showEnhancedPeephole: showEnhancedPeephole ?? resident.showEnhancedPeephole,
        showGoldenRing: showGoldenRing ?? resident.showGoldenRing,
        showCustomAvatar: showCustomAvatar ?? resident.showCustomAvatar,
      );
      ref.invalidate(currentResidentProvider);
      if (!context.mounted) return;
      DuoSnackBarHelper.showSuccess(context, 'Settings updated! ✨');
    } catch (e) {
      if (!context.mounted) return;
      DuoSnackBarHelper.showError(context, 'Failed to update settings');
    }
  }
}
