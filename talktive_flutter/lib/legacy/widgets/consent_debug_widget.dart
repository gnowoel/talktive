import './package:flutter/material.dart';
import '../services/ad_service/improved_consent_manager.dart';
import '../services/ad_service/admob_compliance.dart';

/// Debug widget for consent management and privacy settings
///
/// This widget provides a UI for testing and debugging consent functionality,
/// as well as allowing users to manage their privacy preferences.
class ConsentDebugWidget extends StatefulWidget {
  final bool showDebugInfo;
  final bool isAdminPanel;

  const ConsentDebugWidget({
    super.key,
    this.showDebugInfo = false,
    this.isAdminPanel = false,
  });

  @override
  State<ConsentDebugWidget> createState() => _ConsentDebugWidgetState();
}

class _ConsentDebugWidgetState extends State<ConsentDebugWidget> {
  bool _isLoading = false;
  Map<String, dynamic>? _consentDebugInfo;
  Map<String, dynamic>? _complianceInfo;
  String? _consentStatusMessage;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadConsentInfo();
  }

  Future<void> _loadConsentInfo() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final consentInfo = ImprovedConsentManager.instance.getDebugInfo();
      final complianceInfo = await AdMobCompliance.getDetailedComplianceInfo();
      final statusMessage = await AdMobCompliance.getConsentStatusMessage();

      setState(() {
        _consentDebugInfo = consentInfo;
        _complianceInfo = complianceInfo;
        _consentStatusMessage = statusMessage;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load consent info: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _requestConsent() async {
    setState(() => _isLoading = true);

    try {
      await ImprovedConsentManager.instance.requestConsentManually();
      await _loadConsentInfo();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Consent request completed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _error = 'Failed to request consent: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Consent request failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetConsent() async {
    setState(() => _isLoading = true);

    try {
      await ImprovedConsentManager.instance.resetConsent();
      await _loadConsentInfo();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Consent reset successfully'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() => _error = 'Failed to reset consent: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Consent reset failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'obtained':
        return Colors.green;
      case 'not_required':
        return Colors.blue;
      case 'required':
        return Colors.orange;
      case 'unknown':
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'obtained':
        return Icons.check_circle;
      case 'not_required':
        return Icons.info;
      case 'required':
        return Icons.warning;
      case 'unknown':
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.privacy_tip, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  widget.isAdminPanel
                      ? 'Consent Management (Admin)'
                      : 'Privacy Settings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _isLoading ? null : _loadConsentInfo,
                ),
              ],
            ),
            const Divider(),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              // Consent Status
              if (_consentDebugInfo != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      _consentDebugInfo!['consentStatus'] ?? 'unknown',
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getStatusColor(
                        _consentDebugInfo!['consentStatus'] ?? 'unknown',
                      ).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getStatusIcon(
                          _consentDebugInfo!['consentStatus'] ?? 'unknown',
                        ),
                        color: _getStatusColor(
                          _consentDebugInfo!['consentStatus'] ?? 'unknown',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Consent Status: ${_consentDebugInfo!['consentStatus'] ?? 'Unknown'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_consentStatusMessage != null)
                              Text(
                                _consentStatusMessage!,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Consent Actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _requestConsent,
                        icon: const Icon(Icons.assignment),
                        label: const Text('Request Consent'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (widget.isAdminPanel || widget.showDebugInfo)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _resetConsent,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reset'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Ad Permissions
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ad Permissions',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            _consentDebugInfo!['canShowPersonalizedAds'] == true
                                ? Icons.check_circle
                                : Icons.cancel,
                            color:
                                _consentDebugInfo!['canShowPersonalizedAds'] ==
                                    true
                                ? Colors.green
                                : Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          const Text('Personalized Ads'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            _consentDebugInfo!['canShowNonPersonalizedAds'] ==
                                    true
                                ? Icons.check_circle
                                : Icons.cancel,
                            color:
                                _consentDebugInfo!['canShowNonPersonalizedAds'] ==
                                    true
                                ? Colors.green
                                : Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          const Text('Non-Personalized Ads'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              // Debug Information (Admin/Debug only)
              if ((widget.showDebugInfo || widget.isAdminPanel) &&
                  _consentDebugInfo != null) ...[
                const SizedBox(height: 16),
                ExpansionTile(
                  title: const Text('Debug Information'),
                  leading: const Icon(Icons.bug_report),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Consent Debug Info:',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          ..._consentDebugInfo!.entries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 120,
                                    child: Text(
                                      '${entry.key}:',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      '${entry.value}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_complianceInfo != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AdMob Compliance Info:',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _complianceInfo!['complianceSummary'] ??
                                  'No summary available',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],

              // User-friendly explanation
              if (!widget.isAdminPanel) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'About Privacy & Ads',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We respect your privacy. You can control whether you see personalized ads based on your interests. This setting helps us comply with privacy regulations like GDPR.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Simple consent status indicator for the main UI
class ConsentStatusIndicator extends StatefulWidget {
  const ConsentStatusIndicator({super.key});

  @override
  State<ConsentStatusIndicator> createState() => _ConsentStatusIndicatorState();
}

class _ConsentStatusIndicatorState extends State<ConsentStatusIndicator> {
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final message = await AdMobCompliance.getConsentStatusMessage();
      if (mounted) {
        setState(() => _statusMessage = message);
      }
    } catch (e) {
      // Silently handle errors for this indicator
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_statusMessage == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.privacy_tip, size: 16, color: Colors.blue.shade700),
          const SizedBox(width: 4),
          Text(
            _statusMessage!,
            style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
          ),
        ],
      ),
    );
  }
}
