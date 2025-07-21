import 'package:flutter/material.dart';
import 'services/ad_service/ad_service_adapter.dart';

import 'services/ad_service/optimized_ad_config.dart';

/// Debug widget to test session initialization and ad service functionality
class DebugSessionTest extends StatefulWidget {
  const DebugSessionTest({super.key});

  @override
  State<DebugSessionTest> createState() => _DebugSessionTestState();
}

class _DebugSessionTestState extends State<DebugSessionTest> {
  String _testResults = 'Ready to test...';
  bool _isTesting = false;
  Map<String, dynamic>? _sessionStats;
  String? _statusMessage;
  bool? _sessionActive;

  @override
  void initState() {
    super.initState();
    _runInitialTest();
  }

  Future<void> _runInitialTest() async {
    setState(() {
      _isTesting = true;
      _testResults = 'Running initial session test...';
    });

    try {
      // Test session initialization
      final adapter = AdServiceAdapter.instance;
      adapter.initialize();

      // Get session status
      final stats = await adapter.getSessionStats();
      final statusMessage = await adapter.getStatusMessage();

      setState(() {
        _sessionStats = stats;
        _statusMessage = statusMessage;
        _sessionActive = stats['sessionDurationMinutes'] != null;
        _testResults = _sessionActive == true
            ? '✅ Session is ACTIVE! No "No active session" error.'
            : '❌ Session is NOT active - issue still exists.';
        _isTesting = false;
      });
    } catch (e) {
      setState(() {
        _testResults = '❌ Error during test: $e';
        _isTesting = false;
      });
    }
  }

  Future<void> _testRoomTransition() async {
    setState(() {
      _isTesting = true;
      _testResults = 'Testing room transition...';
    });

    try {
      final adapter = AdServiceAdapter.instance;
      final beforeTransitions = adapter.roomTransitions;

      adapter.trackRoomTransition();

      final afterTransitions = adapter.roomTransitions;
      final stats = await adapter.getSessionStats();

      setState(() {
        _sessionStats = stats;
        _testResults = '✅ Room transition tracked! '
            'Before: $beforeTransitions, After: $afterTransitions';
        _isTesting = false;
      });
    } catch (e) {
      setState(() {
        _testResults = '❌ Room transition test failed: $e';
        _isTesting = false;
      });
    }
  }

  Future<void> _testAdDecision() async {
    setState(() {
      _isTesting = true;
      _testResults = 'Testing ad decision logic...';
    });

    try {
      final adapter = AdServiceAdapter.instance;
      final shouldShow = await adapter.shouldShowAdNow();
      final stats = await adapter.getSessionStats();
      final statusMessage = await adapter.getStatusMessage();

      setState(() {
        _sessionStats = stats;
        _statusMessage = statusMessage;
        _testResults = shouldShow
            ? '✅ Ad SHOULD show (all conditions met)'
            : '⚠️ Ad should NOT show: $statusMessage';
        _isTesting = false;
      });
    } catch (e) {
      setState(() {
        _testResults = '❌ Ad decision test failed: $e';
        _isTesting = false;
      });
    }
  }

  Future<void> _resetSession() async {
    setState(() {
      _isTesting = true;
      _testResults = 'Resetting session...';
    });

    try {
      final adapter = AdServiceAdapter.instance;
      adapter.resetSession();

      final stats = await adapter.getSessionStats();

      setState(() {
        _sessionStats = stats;
        _testResults = '✅ Session reset successfully!';
        _isTesting = false;
      });
    } catch (e) {
      setState(() {
        _testResults = '❌ Session reset failed: $e';
        _isTesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Session Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Test Results
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Results',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _testResults.contains('✅')
                            ? Colors.green.withOpacity(0.1)
                            : _testResults.contains('❌')
                                ? Colors.red.withOpacity(0.1)
                                : Colors.orange.withOpacity(0.1),
                        border: Border.all(
                          color: _testResults.contains('✅')
                              ? Colors.green
                              : _testResults.contains('❌')
                                  ? Colors.red
                                  : Colors.orange,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _testResults,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _testResults.contains('✅')
                              ? Colors.green[800]
                              : _testResults.contains('❌')
                                  ? Colors.red[800]
                                  : Colors.orange[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Actions',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isTesting ? null : _runInitialTest,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Re-test Session'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isTesting ? null : _testRoomTransition,
                          icon: const Icon(Icons.navigation),
                          label: const Text('Test Transition'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isTesting ? null : _testAdDecision,
                          icon: const Icon(Icons.ads_click),
                          label: const Text('Test Ad Decision'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isTesting ? null : _resetSession,
                          icon: const Icon(Icons.restart_alt),
                          label: const Text('Reset Session'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Session Status
            if (_sessionStats != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Session Status',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      _buildStatusRow('Session Active', _sessionActive == true),
                      _buildStatusRow(
                          'Ad Ready', _sessionStats!['isAdReady'] ?? false),
                      _buildStatusRow('Can Show Ad',
                          _sessionStats!['canShowAdNow'] ?? false),
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                          'Session Duration: ${_sessionStats!['sessionDurationMinutes'] ?? 0} minutes'),
                      Text(
                          'Room Transitions: ${_sessionStats!['roomTransitions'] ?? 0}'),
                      Text(
                          'Ads Shown: ${_sessionStats!['adsShownThisSession'] ?? 0}/${_sessionStats!['maxAdsPerSession'] ?? "unlimited"}'),
                      Text(
                          'Engagement Level: ${_sessionStats!['userEngagementLevel'] ?? "unknown"}'),
                      if (_statusMessage != null) ...[
                        const SizedBox(height: 8),
                        Text('Status: $_statusMessage'),
                      ],
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Configuration Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configuration',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                        'System: ${AdServiceAdapter.instance.currentSystemName}'),
                    Text('Config: ${OptimizedAdConfig.getConfigDescription()}'),
                    const Text('Compliance: Check logs for status'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        final config = OptimizedAdConfig.getConfigSummary();
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Full Configuration'),
                            content: SingleChildScrollView(
                              child: Text(config.toString()),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Text('Show Full Config'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Loading Indicator
            if (_isTesting)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, bool status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            status ? Icons.check_circle : Icons.cancel,
            color: status ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
