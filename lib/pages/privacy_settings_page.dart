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
  Map<String, dynamic>? _consentInfo;
  String? _statusMessage;
  String? _error;
  bool _canShowPersonalized = false;
  bool _canShowNonPersonalized = false;
  bool _isInConsentRegion = false;

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
      final consentInfo = await ConsentService.instance.getConsentDebugInfo();
      final statusMessage = await AdMobCompliance.getConsentStatusMessage();
      final canPersonalized = await ConsentService.instance.canShowPersonalizedAds();
      final canNonPersonalized = await ConsentService.instance.canShowNonPersonalizedAds();
      final inConsentRegion = await ConsentService.instance.isInConsentRegion();

      setState(() {
        _consentInfo = consentInfo;
        _statusMessage = statusMessage;
        _canShowPersonalized = canPersonalized;
        _canShowNonPersonalized = canNonPersonalized;
        _isInConsentRegion = inConsentRegion;
        _isLoading = false;
      });
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
        title: const Text('Privacy Settings'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                                  style: Theme.of(context).textTheme.titleLarge,
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
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                                style: TextStyle(color: Colors.red.shade700),
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
                                _canShowPersonalized ? Icons.check_circle : Icons.cancel,
                                color: _canShowPersonalized ? Colors.green : Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Personalized Ads',
                                      style: TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      _canShowPersonalized
                                          ? 'Ads tailored to your interests'
                                          : 'Generic ads not based on your data',
                                      style: Theme.of(context).textTheme.bodySmall,
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
                                _canShowNonPersonalized ? Icons.check_circle : Icons.cancel,
                                color: _canShowNonPersonalized ? Colors.green : Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Non-Personalized Ads',
                                      style: TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      _canShowNonPersonalized
                                          ? 'Standard ads without personal targeting'
                                          : 'Ad serving currently restricted',
                                      style: Theme.of(context).textTheme.bodySmall,
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
                              Icon(Icons.info_outline, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'About Privacy & Ads',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
}
