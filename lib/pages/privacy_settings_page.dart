import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service/consent_manager_facade.dart';
import '../services/ad_service/admob_compliance.dart';

class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  final ConsentManagerFacade _consentManager = ConsentManagerFacade.instance;

  bool _isLoading = true;
  bool _isUpdatingConsent = false;

  // Consent state
  ConsentStatus _consentStatus = ConsentStatus.unknown;
  bool _canRequestAds = false;
  String _statusMessage = '';
  String _actionNeeded = 'none';

  // Debug info
  Map<String, dynamic> _debugInfo = {};
  Map<String, dynamic> _requestStats = {};

  @override
  void initState() {
    super.initState();
    _loadPrivacyInfo();
  }

  Future<void> _loadPrivacyInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current consent validation
      // For improved consent manager, we check directly
      _canRequestAds = _consentManager.canRequestAds;

      // Get consent status
      final consentStatus = _consentManager.consentStatus;

      // Get debug info and stats
      final debugInfo = _consentManager.getDebugInfo();
      // Stats not available in simplified system
      final stats = {'message': 'Using simplified ad system'};

      setState(() {
        _consentStatus = consentStatus;
        _canRequestAds = _canRequestAds;
        _statusMessage = _canRequestAds
            ? 'Ads can be requested'
            : 'Consent required for ads';
        _actionNeeded = _canRequestAds ? 'none' : 'request_consent';
        _debugInfo = debugInfo;
        _requestStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading privacy info: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _showConsentForm() async {
    setState(() {
      _isUpdatingConsent = true;
    });

    try {
      // Request consent
      final result = await _consentManager.requestConsentManually();

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Privacy preferences updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update privacy preferences'),
            backgroundColor: Colors.red,
          ),
        );
      }

      // Reload privacy info
      await _loadPrivacyInfo();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUpdatingConsent = false;
      });
    }
  }

  Future<void> _showPrivacyOptions() async {
    setState(() {
      _isUpdatingConsent = true;
    });

    try {
      final success = await _consentManager.showPrivacyOptions();

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Privacy options updated'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // If privacy options form is not available, show consent form
        await _showConsentForm();
      }

      // Reload privacy info
      await _loadPrivacyInfo();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUpdatingConsent = false;
      });
    }
  }

  Future<void> _resetConsent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Privacy Preferences?'),
        content: const Text(
          'This will reset your privacy preferences and you will need to set them again. '
          'This is mainly useful for testing purposes.',
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

    setState(() {
      _isUpdatingConsent = true;
    });

    try {
      await _consentManager.resetConsent();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Privacy preferences reset'),
          backgroundColor: Colors.orange,
        ),
      );

      // Reload privacy info
      await _loadPrivacyInfo();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error resetting consent: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUpdatingConsent = false;
      });
    }
  }

  String _getConsentStatusText(ConsentStatus status) {
    switch (status) {
      case ConsentStatus.unknown:
        return 'Unknown';
      case ConsentStatus.required:
        return 'Consent Required';
      case ConsentStatus.notRequired:
        return 'Not Required (Outside EEA)';
      case ConsentStatus.obtained:
        return 'Consent Obtained';
    }
  }

  Color _getConsentStatusColor(ConsentStatus status) {
    switch (status) {
      case ConsentStatus.unknown:
        return Colors.grey;
      case ConsentStatus.required:
        return Colors.orange;
      case ConsentStatus.notRequired:
        return Colors.blue;
      case ConsentStatus.obtained:
        return Colors.green;
    }
  }

  Widget _buildStatusCard() {
    final statusColor = _getConsentStatusColor(_consentStatus);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Privacy Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    _getConsentStatusText(_consentStatus),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatusRow('Can Show Ads', _canRequestAds),
            const SizedBox(height: 8),
            if (_statusMessage.isNotEmpty) ...[
              const Divider(),
              const SizedBox(height: 8),
              Text(
                _statusMessage,
                style: TextStyle(
                  color: _canRequestAds ? Colors.green : Colors.orange,
                ),
              ),
            ],
            if (_actionNeeded != 'none' && !_canRequestAds) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isUpdatingConsent ? null : _showConsentForm,
                  icon: const Icon(Icons.privacy_tip),
                  label: const Text('Update Privacy Preferences'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Change Privacy Preferences'),
              subtitle: const Text('Update your ad personalization settings'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _isUpdatingConsent ? null : _showPrivacyOptions,
            ),
            if (AdMobCompliance.isCurrentUserAdmin) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Reset Consent (Admin)'),
                subtitle: const Text('For testing purposes only'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _isUpdatingConsent ? null : _resetConsent,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    if (!AdMobCompliance.isCurrentUserAdmin) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ad Request Statistics (Admin)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow('Total Requests',
                _requestStats['totalRequests']?.toString() ?? '0'),
            _buildStatRow('Blocked Requests',
                _requestStats['blockedRequests']?.toString() ?? '0'),
            _buildStatRow('Successful Loads',
                _requestStats['successfulLoads']?.toString() ?? '0'),
            _buildStatRow('Failed Loads',
                _requestStats['failedLoads']?.toString() ?? '0'),
            const Divider(),
            _buildStatRow(
                'Fill Rate', _requestStats['fillRate']?.toString() ?? '0%'),
            _buildStatRow(
                'Block Rate', _requestStats['blockRate']?.toString() ?? '0%'),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugCard() {
    if (!AdMobCompliance.isCurrentUserAdmin) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Debug Information (Admin)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._debugInfo.entries.map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 150,
                        child: Text(
                          '${entry.key}:',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.value.toString(),
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, bool value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Icon(
          value ? Icons.check_circle : Icons.cancel,
          color: value ? Colors.green : Colors.red,
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed:
                _isLoading || _isUpdatingConsent ? null : _loadPrivacyInfo,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPrivacyInfo,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildStatusCard(),
                    const SizedBox(height: 16),
                    _buildOptionsCard(),
                    const SizedBox(height: 16),
                    _buildStatisticsCard(),
                    const SizedBox(height: 16),
                    _buildDebugCard(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}
