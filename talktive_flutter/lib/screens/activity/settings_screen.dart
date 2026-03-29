import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:talktive_client/talktive_client.dart';
import '../../config/theme.dart';
import '../../providers/current_resident_provider.dart';
import '../../widgets/duo/duo_card.dart';
import '../../widgets/duo/duo_button.dart';
import '../../widgets/duo/duo_switch.dart';
import '../../helpers/duo_snackbar_helper.dart';
import '../../helpers/duo_upgrade_helper.dart';
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
          style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: residentAsync.when(
        data: (resident) {
          if (resident == null) {
            return const Center(child: Text('Please log in'));
          }

          return ListView(
            padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
            children: [
              _buildSectionHeader(context, 'Privacy Control'),
              DuoCard(
                child: Column(
                  children: [
                    _buildDuoListTile(
                      context,
                      title: 'Online Status',
                      subtitle: 'Let others see when you are active',
                      emoji: '🟢',
                      value: resident.showOnlineStatus,
                      activeColor: AppTheme.duoGreen,
                      onChanged: (value) async {
                        try {
                          await client.resident.updateOnlineSettings(
                            showOnlineStatus: value,
                          );
                          ref.invalidate(currentResidentProvider);
                          if (!context.mounted) return;
                          DuoSnackBarHelper.showSuccess(
                            context,
                            value
                                ? 'Online status visible! 🟢'
                                : 'Incognito mode active! 👻',
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          DuoSnackBarHelper.showError(
                            context,
                            'Failed to update settings',
                          );
                        }
                      },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _buildDuoListTile(
                      context,
                      title: 'Read Receipts',
                      subtitle: 'Let others see when you read messages',
                      emoji: '👁️',
                      value: resident.showReadReceipts,
                      activeColor: AppTheme.primaryColor,
                      onChanged: (value) => _updatePrivacySettings(
                        context,
                        ref,
                        showReadReceipts: value,
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _buildDuoListTile(
                      context,
                      title: 'Typing Indicator',
                      subtitle: 'Show others when you are typing',
                      emoji: '✍️',
                      value: resident.showTypingIndicator,
                      activeColor: AppTheme.primaryColor,
                      onChanged: (value) => _updatePrivacySettings(
                        context,
                        ref,
                        showTypingIndicator: value,
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _buildDuoListTile(
                      context,
                      title: 'Appear in Discovery',
                      subtitle: 'Allow others to discover your persona',
                      emoji: '🔍',
                      value: resident.allowDiscovery,
                      activeColor: AppTheme.duoPurple,
                      onChanged: (value) => _updatePrivacySettings(
                        context,
                        ref,
                        allowDiscovery: value,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.duoSpacingLarge),
              _buildSectionHeader(context, 'Premium Features'),
              _buildPremiumCard(context, ref, resident),
              const SizedBox(height: AppTheme.duoSpacingMedium),
              _buildFeatureRow(
                context,
                icon: Icons.block,
                title: 'No Ads',
                description: 'A completely ad-free experience (Coming Soon).',
                isLocked: !resident.isPremium,
                value: resident.isPremium,
                onChanged: null,
              ),
              _buildFeatureRow(
                context,
                icon: Icons.account_circle,
                title: 'Custom Avatar',
                description: 'Upload your own image to use as an avatar.',
                isLocked: !resident.isPlus,
                value: resident.showCustomAvatar,
                onChanged: resident.isPlus
                    ? (val) => _updatePrivacySettings(
                        context,
                        ref,
                        showCustomAvatar: val,
                      )
                    : null,
              ),
              _buildFeatureRow(
                context,
                icon: Icons.mic,
                title: 'Voice Messages',
                description: 'Send audio messages in any chat thread.',
                isLocked: !resident.isPlus,
                value: resident.showVoiceMessages,
                onChanged: resident.isPlus
                    ? (val) => _updatePrivacySettings(
                        context,
                        ref,
                        showVoiceMessages: val,
                      )
                    : null,
              ),
              _buildFeatureRow(
                context,
                icon: Icons.person_search,
                title: 'Advanced Search',
                description:
                    'Search neighbors and lounges using terms and filters.',
                isLocked: !resident.isPlus,
                value: resident.showNeighborsDiscovery,
                onChanged: resident.isPlus
                    ? (val) => _updatePrivacySettings(
                        context,
                        ref,
                        showNeighborsDiscovery: val,
                      )
                    : null,
              ),
              _buildFeatureRow(
                context,
                icon: Icons.online_prediction,
                title: 'Online Indicator',
                description: 'See when your friends are active in real-time.',
                isLocked: !resident.isPlus,
                value: resident.showOthersOnlineStatus,
                onChanged: resident.isPlus
                    ? (val) => _updatePrivacySettings(
                        context,
                        ref,
                        showOthersOnlineStatus: val,
                      )
                    : null,
              ),
              _buildFeatureRow(
                context,
                icon: Icons.done_all,
                title: 'Read Receipts',
                description: 'See when others have read your messages.',
                isLocked: !resident.isPlus,
                value: resident.showOthersReadReceipts,
                onChanged: resident.isPlus
                    ? (val) => _updatePrivacySettings(
                        context,
                        ref,
                        showOthersReadReceipts: val,
                      )
                    : null,
              ),
              _buildFeatureRow(
                context,
                icon: Icons.edit,
                title: 'Typing Indicators',
                description: 'See when someone is replying to you.',
                isLocked: !resident.isPlus,
                value: resident.showOthersTypingIndicators,
                onChanged: resident.isPlus
                    ? (val) => _updatePrivacySettings(
                        context,
                        ref,
                        showOthersTypingIndicators: val,
                      )
                    : null,
              ),
              _buildFeatureRow(
                context,
                icon: Icons.history,
                title: 'Keep Private Chats',
                description: 'Prevent your private chats from being deleted.',
                isLocked: !resident.isPlus,
                value: resident.keepPrivateChats,
                onChanged: resident.isPlus
                    ? (val) => _updatePrivacySettings(
                        context,
                        ref,
                        keepPrivateChats: val,
                      )
                    : null,
              ),
              if (resident.isStaff) ...[
                const SizedBox(height: AppTheme.duoSpacingLarge),
                _buildSectionHeader(context, 'Staff Tools'),
                DuoCard(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    context.push('/admin/dashboard');
                  },
                  child: const ListTile(
                    leading: Icon(
                      Icons.admin_panel_settings,
                      size: 28,
                      color: AppTheme.duoPurple,
                    ),
                    title: Text(
                      'Admin Dashboard',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Manage users and community safety'),
                    trailing: Icon(
                      Icons.chevron_right,
                      size: 24,
                      color: AppTheme.textSecondary,
                    ),
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

  Future<void> _updatePrivacySettings(
    BuildContext context,
    WidgetRef ref, {
    bool? showReadReceipts,
    bool? showTypingIndicator,
    bool? showVoiceMessages,
    bool? showNeighborsDiscovery,
    bool? showCustomAvatar,
    bool? showOthersOnlineStatus,
    bool? showOthersReadReceipts,
    bool? showOthersTypingIndicators,
    bool? allowDiscovery,
    bool? keepPrivateChats,
    bool? showImagesInPlaza,
    bool? showImagesInLounges,
    bool? showImagesInPrivateChats,
    bool? showImagesInMoments,
  }) async {
    HapticFeedback.selectionClick();
    final resident = ref.read(currentResidentProvider).value;
    if (resident == null) return;

    try {
      await client.resident.updatePrivacySettings(
        showReadReceipts: showReadReceipts ?? resident.showReadReceipts,
        showTypingIndicator:
            showTypingIndicator ?? resident.showTypingIndicator,
        showVoiceMessages: showVoiceMessages ?? resident.showVoiceMessages,
        showNeighborsDiscovery:
            showNeighborsDiscovery ?? resident.showNeighborsDiscovery,
        showCustomAvatar: showCustomAvatar ?? resident.showCustomAvatar,
        showOthersOnlineStatus:
            showOthersOnlineStatus ?? resident.showOthersOnlineStatus,
        showOthersReadReceipts:
            showOthersReadReceipts ?? resident.showOthersReadReceipts,
        showOthersTypingIndicators:
            showOthersTypingIndicators ?? resident.showOthersTypingIndicators,
        allowDiscovery: allowDiscovery ?? resident.allowDiscovery,
        keepPrivateChats: keepPrivateChats ?? resident.keepPrivateChats,
        showImagesInPlaza: showImagesInPlaza ?? resident.showImagesInPlaza,
        showImagesInLounges:
            showImagesInLounges ?? resident.showImagesInLounges,
        showImagesInPrivateChats:
            showImagesInPrivateChats ?? resident.showImagesInPrivateChats,
        showImagesInMoments:
            showImagesInMoments ?? resident.showImagesInMoments,
      );
      ref.invalidate(currentResidentProvider);
      if (!context.mounted) return;
      DuoSnackBarHelper.showSuccess(context, 'Settings updated! ✨');
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

  Widget _buildPremiumCard(
    BuildContext context,
    WidgetRef ref,
    Resident resident,
  ) {
    if (resident.isPremium) {
      return DuoCard(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
          child: Column(
            children: [
              const Icon(Icons.stars, size: 40, color: AppTheme.primaryColor),
              const SizedBox(height: 12),
              const Text(
                'TALKTIVE PLUS UNLOCKED',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Thank you for supporting the community! Enjoy your premium experience.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              DuoButton(
                text: 'Cancel Plus (Test)',
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  try {
                    await client.resident.cancelPremium();
                    ref.invalidate(currentResidentProvider);
                    if (!context.mounted) return;
                    DuoSnackBarHelper.showSuccess(
                      context,
                      'Subscription cancelled. Features disabled. 🧹',
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    DuoSnackBarHelper.showError(context, 'Cancellation failed');
                  }
                },
                variant: DuoButtonVariant.secondary,
                width: double.infinity,
              ),
            ],
          ),
        ),
      );
    }

    if (resident.isTrialActive) {
      final expires = resident.premiumTrialExpires!;
      final timeLeft = expires.difference(DateTime.now());
      final hoursLeft = timeLeft.inHours;
      final minutesLeft = timeLeft.inMinutes % 60;

      return DuoCard(
        color: AppTheme.duoPurple.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
          child: Column(
            children: [
              const Icon(Icons.timer, size: 40, color: AppTheme.duoPurple),
              const SizedBox(height: 12),
              const Text(
                'TRIAL ACTIVE',
                style: TextStyle(
                  color: AppTheme.duoPurple,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enjoy all premium features for free!\nExpires in: ${hoursLeft}h ${minutesLeft}m',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
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
                    DuoSnackBarHelper.showSuccess(
                      context,
                      'Welcome to Talktive Plus! 🌟',
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    DuoSnackBarHelper.showError(context, 'Purchase failed');
                  }
                },
                width: double.infinity,
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
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              'Get exclusive features and support the community for just \$2.99/month.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DuoButton(
                    text: 'Try Out',
                    variant: DuoButtonVariant.secondary,
                    onPressed: () async {
                      HapticFeedback.mediumImpact();
                      try {
                        await client.resident.startPremiumTrial();
                        ref.invalidate(currentResidentProvider);
                        if (!context.mounted) return;
                        DuoSnackBarHelper.showSuccess(
                          context,
                          'Trial started! Enjoy 24h of Plus. ✨',
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        DuoSnackBarHelper.showError(context, 'Trial failed');
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DuoButton(
                    text: 'Upgrade Now',
                    onPressed: () async {
                      HapticFeedback.mediumImpact();
                      try {
                        await client.resident.purchasePremium();
                        ref.invalidate(currentResidentProvider);
                        if (!context.mounted) return;
                        DuoSnackBarHelper.showSuccess(
                          context,
                          'Welcome to Talktive Plus! 🌟',
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        DuoSnackBarHelper.showError(context, 'Purchase failed');
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDuoListTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
    required String emoji,
    Color? activeColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.duoSpacingMedium,
        vertical: 12,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.lightBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 20, height: 1.0),
              ),
            ),
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
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          DuoSwitch(
            value: value,
            onChanged: onChanged,
            activeColor: activeColor ?? AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required bool isLocked,
    bool? value,
    Function(bool)? onChanged,
  }) {
    return InkWell(
      onTap: isLocked
          ? () {
              HapticFeedback.lightImpact();
              DuoUpgradeHelper.showUpgradePrompt(context, title);
            }
          : null,
      borderRadius: BorderRadius.circular(AppTheme.duoRadiusMedium),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isLocked
                    ? Colors.grey[100]
                    : AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isLocked ? Colors.grey[200]! : AppTheme.primaryColor.withValues(alpha: 0.2),
                ),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 24,
                  color: isLocked ? Colors.grey[400] : AppTheme.primaryColor,
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
                        Icon(Icons.lock, size: 14, color: Colors.grey[400]),
                      ],
                    ],
                  ),
                  Text(
                    description,
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            if (!isLocked && onChanged != null && value != null)
              DuoSwitch(
                value: value,
                onChanged: onChanged,
                activeColor: AppTheme.primaryColor,
              ),
          ],
        ),
      ),
    );
  }
}
