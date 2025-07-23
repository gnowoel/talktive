import 'package:flutter/material.dart';
import '../services/ad_service/consent_service.dart';
import '../services/ad_service/admob_compliance.dart';
import '../widgets/consent_debug_widget.dart';

/// Privacy Settings Page for managing user consent and ad preferences
///
/// This page allows users to:
/// - View their current consent status
/// - Manage ad personalization preferences
/// - Request or update consent
/// - Access privacy information
class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  bool _isLoading = false;

  String? _statusMessage;
  String? _error;
  bool _canShowPersonalized = false;
  bool _canShowNonPersonalized = false;
  bool _isInConsentRegion = false;
  bool _shouldShowPrivacySettings = false;

  @override
  void initState() {
    super.initState();
    _loadPrivacyInfo();
  }

  Future<void> _loadPrivacyInfo() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final inConsentRegion = await ConsentService.instance.isInConsentRegion();
      final isAdmin = AdMobCompliance.isCurrentUserAdmin;

      // Load privacy info if user is in consent region OR if user is admin
      if (inConsentRegion || isAdmin) {
        final statusMessage = await AdMobCompliance.getConsentStatusMessage();
        final canPersonalized =
            await ConsentService.instance.canShowPersonalizedAds();
        final canNonPersonalized =
            await ConsentService.instance.canShowNonPersonalizedAds();

        setState(() {
          _statusMessage = statusMessage;
          _canShowPersonalized = canPersonalized;
          _canShowNonPersonalized = canNonPersonalized;
          _isInConsentRegion = inConsentRegion;
          _shouldShowPrivacySettings = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _statusMessage = 'Privacy settings are not required in your region';
          _isInConsentRegion = inConsentRegion;
          _shouldShowPrivacySettings = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load privacy information: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _requestConsent() async {
    setState(() => _isLoading = true);

    try {
      await ConsentService.instance.requestConsent();
      await _loadPrivacyInfo();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Privacy preferences updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _error = 'Failed to update preferences: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update preferences: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetConsent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Privacy Preferences'),
        content: const Text(
          'This will reset your privacy preferences and you may be asked to provide consent again. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await ConsentService.instance.resetConsent();
      await _loadPrivacyInfo();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Privacy preferences reset'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() => _error = 'Failed to reset preferences: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reset preferences: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor() {
    if (!_isInConsentRegion) return Colors.blue;
    return _canShowPersonalized ? Colors.green : Colors.orange;
  }

  IconData _getStatusIcon() {
    if (!_isInConsentRegion) return Icons.info;
    return _canShowPersonalized ? Icons.check_circle : Icons.warning;
  }

  String _getStatusTitle() {
    if (!_isInConsentRegion) {
      return 'Privacy Preferences';
    }
    return _canShowPersonalized
        ? 'Personalized Ads Enabled'
        : 'Non-Personalized Ads Only';
  }

  String _getStatusDescription() {
    if (!_isInConsentRegion) {
      return 'Your region does not require explicit consent for ad personalization.';
    }

    if (_canShowPersonalized) {
      return 'You have consented to personalized ads based on your interests and activity.';
    } else {
      return 'You will see non-personalized ads that are not based on your personal data.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AdMobCompliance.isCurrentUserAdmin && !_isInConsentRegion
            ? 'Privacy Settings (Admin)'
            : 'Privacy Settings'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_shouldShowPrivacySettings
              ? _buildNonConsentRegionContent()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Current Status Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _getStatusIcon(),
                                    color: _getStatusColor(),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _getStatusTitle(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _getStatusDescription(),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              if (_statusMessage != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _statusMessage!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Error Display
                      if (_error != null)
                        Card(
                          color: Colors.red.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(Icons.error, color: Colors.red.shade700),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style:
                                        TextStyle(color: Colors.red.shade700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Ad Preferences Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ad Preferences',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 12),

                              // Personalized Ads Status
                              Row(
                                children: [
                                  Icon(
                                    _canShowPersonalized
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: _canShowPersonalized
                                        ? Colors.green
                                        : Colors.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Personalized Ads',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w500),
                                        ),
                                        Text(
                                          _canShowPersonalized
                                              ? 'Ads tailored to your interests'
                                              : 'Generic ads not based on your data',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Non-Personalized Ads Status
                              Row(
                                children: [
                                  Icon(
                                    _canShowNonPersonalized
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: _canShowNonPersonalized
                                        ? Colors.green
                                        : Colors.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Non-Personalized Ads',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w500),
                                        ),
                                        Text(
                                          _canShowNonPersonalized
                                              ? 'Standard ads without personal targeting'
                                              : 'Ad serving currently restricted',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Action Buttons
                      if (_isInConsentRegion) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _requestConsent,
                            icon: const Icon(Icons.settings),
                            label: const Text('Manage Ad Preferences'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _resetConsent,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Reset Preferences'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Information Section
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      color: Colors.blue.shade700),
                                  const SizedBox(width: 8),
                                  Text(
                                    'About Privacy & Ads',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Colors.blue.shade700,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'We respect your privacy and comply with privacy regulations like GDPR. You have control over how your data is used for ad personalization.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '• Personalized ads use your activity to show relevant advertisements\n'
                                '• Non-personalized ads are generic and not based on your personal data\n'
                                '• You can change these preferences at any time\n'
                                '• Your choice is stored securely on your device',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Developer/Debug Info (if admin)
                      if (AdMobCompliance.isCurrentUserAdmin)
                        const ConsentDebugWidget(
                          showDebugInfo: true,
                          isAdminPanel: true,
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildNonConsentRegionContent() {
    final isAdmin = AdMobCompliance.isCurrentUserAdmin;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Admin notice (if admin)
          if (isAdmin)
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.admin_panel_settings,
                          color: Colors.orange.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Admin Testing Mode',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Colors.orange.shade700,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'You are viewing this page as an admin user from a non-EEA region. In production, regular users in this region would not see privacy settings.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'To test EEA behavior, enable "_forceEeaTesting = true" in ConsentService.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ],
                ),
              ),
            ),

          if (isAdmin) const SizedBox(height: 16),

          // Admin testing controls (if admin)
          if (isAdmin)
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.bug_report,
                          color: Colors.blue.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Admin Testing Controls',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Colors.blue.shade700,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Use these controls to test consent flows and privacy settings:',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  setState(() => _isLoading = true);
                                  try {
                                    await ConsentService.instance
                                        .resetConsent();
                                    await ConsentService.instance
                                        .requestConsent();
                                    await _loadPrivacyInfo();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Forced consent request completed'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Test failed: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  } finally {
                                    setState(() => _isLoading = false);
                                  }
                                },
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Test Consent Flow'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  setState(() => _isLoading = true);
                                  try {
                                    await ConsentService.instance
                                        .resetConsent();
                                    await _loadPrivacyInfo();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Consent data cleared'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Reset failed: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  } finally {
                                    setState(() => _isLoading = false);
                                  }
                                },
                          icon: const Icon(Icons.clear),
                          label: const Text('Clear Consent'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final debugInfo = await ConsentService.instance
                                .getConsentDebugInfo();
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Consent Debug Info'),
                                content: SingleChildScrollView(
                                  child: Text(
                                    debugInfo.entries
                                        .map((e) => '${e.key}: ${e.value}')
                                        .join('\n'),
                                    style: const TextStyle(
                                        fontFamily: 'monospace'),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.info_outline),
                          label: const Text('Show Debug Info'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Testing Notes:',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '• Set "_forceEeaTesting = true" in ConsentService to test EEA behavior\n'
                            '• "Test Consent Flow" simulates a full consent request\n'
                            '• "Clear Consent" resets all stored consent data\n'
                            '• Changes only affect this device/session',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (isAdmin) const SizedBox(height: 16),

          // Non-consent region info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info,
                        color: Colors.blue,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isAdmin
                              ? 'Non-EEA Region Detected'
                              : 'Privacy Settings Not Required',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Based on your location, explicit consent for ad personalization is not required by privacy regulations like GDPR.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You will automatically receive personalized ads that are relevant to your interests and activity.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Information about ads
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.ads_click, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'About Our Ads',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.green.shade700,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'We show ads to keep our app free for everyone. In your region, we can show personalized ads based on your interests and app usage.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Ads are selected based on your interests and activity\n'
                    '• This helps us show you more relevant advertisements\n'
                    '• Ad revenue helps us maintain and improve the app\n'
                    '• Your data is handled according to our privacy policy',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Privacy policy link
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.policy, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Privacy Information',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.blue.shade700,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Even though explicit consent is not required in your region, we still respect your privacy and handle your data responsibly.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Navigate to privacy policy page when available
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Privacy policy link coming soon'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('View Privacy Policy'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Developer/Debug Info (if admin)
          if (AdMobCompliance.isCurrentUserAdmin)
            const ConsentDebugWidget(
              showDebugInfo: true,
              isAdminPanel: true,
            ),
        ],
      ),
    );
  }
}
