import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ad_service/simplified_room_ads.dart';
import '../services/ad_service/go_router_room_helper.dart';
import '../services/ad_service/admob_compliance.dart';

class AdTestPage extends StatefulWidget {
  const AdTestPage({super.key});

  @override
  State<AdTestPage> createState() => _AdTestPageState();
}

class _AdTestPageState extends State<AdTestPage> {
  final SimplifiedRoomAds _adManager = SimplifiedRoomAds.instance;
  String _lastActionResult = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ad System Test'),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Action Result Display
            if (_lastActionResult.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: _lastActionResult.contains('SUCCESS') ||
                          _lastActionResult.contains('✅')
                      ? Colors.green.withOpacity(0.2)
                      : Colors.orange.withOpacity(0.2),
                  border: Border.all(
                    color: _lastActionResult.contains('SUCCESS') ||
                            _lastActionResult.contains('✅')
                        ? Colors.green
                        : Colors.orange,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _lastActionResult,
                  style: TextStyle(
                    color: _lastActionResult.contains('SUCCESS') ||
                            _lastActionResult.contains('✅')
                        ? Colors.green[800]
                        : Colors.orange[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            // Quick Actions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _forceShowAd,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Force Show Ad'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _forceLoadAd,
                          icon: const Icon(Icons.download),
                          label: const Text('Force Load Ad'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed:
                              _isLoading ? null : _simulateRoomTransition,
                          icon: const Icon(Icons.navigation),
                          label: const Text('Simulate Room Transition'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _resetSession,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reset Session'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Current Status
            Consumer<SimplifiedRoomAds>(
              builder: (context, adManager, child) {
                final stats = adManager.getSessionStats();
                final shouldShow = adManager.shouldShowAdNow();

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Status',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 12),

                        // Ad Ready Status
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: shouldShow
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: shouldShow ? Colors.green : Colors.red,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                shouldShow ? Icons.check_circle : Icons.cancel,
                                color: shouldShow ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  shouldShow
                                      ? 'AD READY TO SHOW'
                                      : 'AD NOT READY',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: shouldShow
                                        ? Colors.green[800]
                                        : Colors.red[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Status Details
                        _buildStatusRow('Ad Loaded', adManager.isAdReady),
                        _buildStatusRow('Session Started',
                            stats['sessionDurationMinutes'] > 0),
                        _buildStatusRow(
                            'Enough Transitions', _hasEnoughTransitions(stats)),
                        _buildStatusRow('Time Requirements Met',
                            _timeRequirementsMet(stats)),
                        _buildStatusRow('Good User State',
                            stats['isUserInGoodStateForAds'] ?? false),
                        _buildStatusRow('Optimal Moment',
                            stats['isOptimalAdMoment'] ?? false),
                        _buildStatusRow('Compliance OK',
                            GoRouterRoomHelper.validateCompliance()),

                        const SizedBox(height: 12),

                        // Key Metrics
                        Text('Key Metrics:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Room Transitions: ${stats['roomTransitions']}'),
                        Text(
                            'Ads Shown: ${stats['adsShownThisSession']}/${stats['maxAdsPerSession']}'),
                        Text(
                            'Session Duration: ${stats['sessionDurationMinutes']} minutes'),
                        Text(
                            'Engagement: ${stats['engagementLevel']} (${stats['sessionEngagementScore']}/100)'),
                        Text('Next Opportunity: ${stats['nextAdOpportunity']}'),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Compliance Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AdMob Compliance',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text('Admin User: ${AdMobCompliance.isCurrentUserAdmin}'),
                    Text('Test Ads: ${AdMobCompliance.shouldUseTestAds}'),
                    Text('Debug Mode: ${AdMobCompliance.shouldLogVerbose}'),
                    if (AdMobCompliance.getComplianceBadge() != null)
                      Chip(
                        label: Text(AdMobCompliance.getComplianceBadge()!),
                        backgroundColor: Colors.orange.withOpacity(0.2),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      AdMobCompliance.getUserFriendlyMessage(),
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Debug Widget
            const RoomAdDebugInfo(),

            const SizedBox(height: 16),

            // Test Room Transitions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Room Transitions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text('Simulate navigation to rooms to test ad timing:'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: () => _simulateNavigation('Chat Room 1'),
                          child: const Text('Go to Chat 1'),
                        ),
                        OutlinedButton(
                          onPressed: () => _simulateNavigation('Chat Room 2'),
                          child: const Text('Go to Chat 2'),
                        ),
                        OutlinedButton(
                          onPressed: () => _simulateNavigation('Topic Room 1'),
                          child: const Text('Go to Topic 1'),
                        ),
                        OutlinedButton(
                          onPressed: () => _simulateNavigation('Topic Room 2'),
                          child: const Text('Go to Topic 2'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Detailed Debug Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detailed Debug Info',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<Map<String, dynamic>>(
                      future: _getDetailedInfo(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final info = snapshot.data!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: info.entries.map((entry) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  '${entry.key}: ${entry.value}',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        }
                        return const CircularProgressIndicator();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, bool status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            status ? Icons.check_circle : Icons.cancel,
            color: status ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  bool _hasEnoughTransitions(Map<String, dynamic> stats) {
    final transitions = stats['roomTransitions'] as int? ?? 0;
    final adsShown = stats['adsShownThisSession'] as int? ?? 0;

    if (adsShown == 0) {
      return transitions >= 2; // First ad needs 2 transitions
    } else {
      return transitions >=
          (adsShown + 1) * 2; // Subsequent ads need 2 transitions each
    }
  }

  bool _timeRequirementsMet(Map<String, dynamic> stats) {
    final sessionMinutes = stats['sessionDurationMinutes'] as int? ?? 0;
    final timeUntilNext = stats['timeUntilNextAdEligible'] as int?;

    return sessionMinutes >= 1 && (timeUntilNext == null || timeUntilNext <= 0);
  }

  Future<void> _forceShowAd() async {
    setState(() {
      _isLoading = true;
      _lastActionResult = 'Attempting to force show ad...';
    });

    try {
      final success = await _adManager.forceShowAd();
      setState(() {
        _lastActionResult = success
            ? '✅ SUCCESS: Ad shown successfully!'
            : '❌ FAILED: Could not show ad. Check logs for details.';
      });
    } catch (e) {
      setState(() {
        _lastActionResult = '❌ ERROR: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _forceLoadAd() async {
    setState(() {
      _isLoading = true;
      _lastActionResult = 'Loading ad...';
    });

    try {
      await _adManager.forceLoadAd();
      setState(() {
        _lastActionResult = '✅ SUCCESS: Ad load initiated. Check status above.';
      });
    } catch (e) {
      setState(() {
        _lastActionResult = '❌ ERROR loading ad: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _simulateRoomTransition() async {
    setState(() {
      _lastActionResult = 'Simulating room transition...';
    });

    _adManager.trackRoomTransition();

    setState(() {
      _lastActionResult =
          '✅ Room transition tracked. Check status for changes.';
    });
  }

  Future<void> _resetSession() async {
    setState(() {
      _lastActionResult = 'Resetting session...';
    });

    _adManager.resetSession();

    setState(() {
      _lastActionResult =
          '✅ Session reset. All counters and timers have been reset.';
    });
  }

  Future<void> _simulateNavigation(String destination) async {
    setState(() {
      _lastActionResult = 'Navigating to $destination...';
    });

    // Track the transition
    _adManager.trackRoomTransition();

    // Check if ad should show
    final shouldShow = _adManager.shouldShowAdNow();

    if (shouldShow) {
      final adShown = await _adManager.showAdIfAppropriate();
      setState(() {
        _lastActionResult = adShown
            ? '✅ Navigated to $destination and showed ad!'
            : '⚠️ Navigated to $destination, ad was eligible but failed to show.';
      });
    } else {
      setState(() {
        _lastActionResult =
            'Navigated to $destination. No ad shown (conditions not met).';
      });
    }
  }

  Future<Map<String, dynamic>> _getDetailedInfo() async {
    return GoRouterRoomHelper.getDetailedTimingInfo();
  }
}
