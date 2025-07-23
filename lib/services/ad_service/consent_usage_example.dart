import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'consent_service.dart';
import 'ad_request_helper.dart';

/// Example usage of the improved ConsentService and AdRequestHelper
///
/// This example shows how to properly implement GDPR-compliant ads
/// that maximize revenue while respecting user consent.
class ConsentUsageExample extends StatefulWidget {
  const ConsentUsageExample({Key? key}) : super(key: key);

  @override
  State<ConsentUsageExample> createState() => _ConsentUsageExampleState();
}

class _ConsentUsageExampleState extends State<ConsentUsageExample> {
  final ConsentService _consentService = ConsentService.instance;
  final AdRequestHelper _adHelper = AdRequestHelper.instance;

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  bool _isInitialized = false;
  String _statusMessage = 'Initializing...';
  Map<String, dynamic>? _debugInfo;

  @override
  void initState() {
    super.initState();
    _initializeAdsWithConsent();
  }

  /// Proper initialization flow for ads with consent handling
  Future<void> _initializeAdsWithConsent() async {
    try {
      setState(() {
        _statusMessage = 'Initializing consent and ads...';
      });

      // Step 1: Handle consent and initialize ads
      final canShowAds = await _adHelper.handleConsentAndInitialize();

      setState(() {
        _isInitialized = true;
        _statusMessage = canShowAds
            ? 'Ready to show ads'
            : 'Ads blocked due to consent restrictions';
      });

      // Step 2: Load ads if allowed
      if (canShowAds) {
        await _loadAllAds();
      }

      // Step 3: Get debug information
      await _updateDebugInfo();

    } catch (e) {
      setState(() {
        _statusMessage = 'Initialization failed: $e';
        _isInitialized = true; // Still mark as initialized to show UI
      });
    }
  }

  /// Load all ad types with proper consent handling
  Future<void> _loadAllAds() async {
    // Load banner ad
    _loadBannerAd();

    // Preload interstitial ad
    _loadInterstitialAd();

    // Preload rewarded ad
    _loadRewardedAd();
  }

  /// Load banner ad with consent handling
  Future<void> _loadBannerAd() async {
    _bannerAd?.dispose();
    _bannerAd = null;

    try {
      final bannerAd = await _adHelper.loadBannerAd(
        adUnitId: 'ca-app-pub-3940256099942544/6300978111', // Test ad unit
        adSize: AdSize.banner,
        keywords: ['flutter', 'mobile', 'games'],
      );

      if (mounted && bannerAd != null) {
        setState(() {
          _bannerAd = bannerAd;
        });
      }
    } catch (e) {
      debugPrint('Failed to load banner ad: $e');
    }
  }

  /// Load interstitial ad with consent handling
  Future<void> _loadInterstitialAd() async {
    try {
      _interstitialAd?.dispose();
      _interstitialAd = await _adHelper.loadInterstitialAd(
        adUnitId: 'ca-app-pub-3940256099942544/1033173712', // Test ad unit
        keywords: ['flutter', 'mobile', 'games'],
      );
    } catch (e) {
      debugPrint('Failed to load interstitial ad: $e');
    }
  }

  /// Load rewarded ad with consent handling
  Future<void> _loadRewardedAd() async {
    try {
      _rewardedAd?.dispose();
      _rewardedAd = await _adHelper.loadRewardedAd(
        adUnitId: 'ca-app-pub-3940256099942544/5224354917', // Test ad unit
        keywords: ['flutter', 'mobile', 'games'],
      );
    } catch (e) {
      debugPrint('Failed to load rewarded ad: $e');
    }
  }

  /// Show interstitial ad
  Future<void> _showInterstitialAd() async {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          ad.dispose();
          _loadInterstitialAd(); // Preload next ad
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          ad.dispose();
          _loadInterstitialAd(); // Preload next ad
        },
      );

      await _interstitialAd!.show();
      _interstitialAd = null;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Interstitial ad not ready')),
      );
    }
  }

  /// Show rewarded ad
  Future<void> _showRewardedAd() async {
    if (_rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (RewardedAd ad) {
          ad.dispose();
          _loadRewardedAd(); // Preload next ad
        },
        onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
          ad.dispose();
          _loadRewardedAd(); // Preload next ad
        },
      );

      await _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem rewardItem) {
          // Handle reward
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Earned ${rewardItem.amount} ${rewardItem.type}'),
            ),
          );
        },
      );
      _rewardedAd = null;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rewarded ad not ready')),
      );
    }
  }

  /// Request consent manually
  Future<void> _requestConsent() async {
    try {
      setState(() {
        _statusMessage = 'Requesting consent...';
      });

      final status = await _consentService.requestConsent();

      setState(() {
        _statusMessage = 'Consent status: ${await _consentService.getConsentStatusMessage()}';
      });

      // Reload ads after consent change
      final validation = await _adHelper.validateAdRequest();
      if (validation.canRequestAds) {
        await _loadAllAds();
      }

      await _updateDebugInfo();

    } catch (e) {
      setState(() {
        _statusMessage = 'Consent request failed: $e';
      });
    }
  }

  /// Show privacy options
  Future<void> _showPrivacyOptions() async {
    try {
      final isRequired = await _consentService.isPrivacyOptionsRequired();

      if (!isRequired) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Privacy options not available in your region')),
        );
        return;
      }

      await _consentService.showPrivacyOptionsForm();

      // Update ads after privacy options change
      final validation = await _adHelper.validateAdRequest();
      if (validation.canRequestAds) {
        await _loadAllAds();
      }

      await _updateDebugInfo();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to show privacy options: $e')),
      );
    }
  }

  /// Reset consent (for testing)
  Future<void> _resetConsent() async {
    try {
      await _consentService.resetConsent();

      // Dispose current ads
      _bannerAd?.dispose();
      _interstitialAd?.dispose();
      _rewardedAd?.dispose();

      setState(() {
        _bannerAd = null;
        _interstitialAd = null;
        _rewardedAd = null;
        _statusMessage = 'Consent reset';
      });

      // Reinitialize
      await _initializeAdsWithConsent();

    } catch (e) {
      setState(() {
        _statusMessage = 'Reset failed: $e';
      });
    }
  }

  /// Update debug information
  Future<void> _updateDebugInfo() async {
    try {
      final debugInfo = await _adHelper.getDebugInfo();
      setState(() {
        _debugInfo = debugInfo;
      });
    } catch (e) {
      debugPrint('Failed to get debug info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consent & Ads Example'),
      ),
      body: Column(
        children: [
          // Banner ad
          if (_bannerAd != null)
            Container(
              alignment: Alignment.center,
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),

          // Status and controls
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(_statusMessage),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Control buttons
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: _isInitialized ? _requestConsent : null,
                        child: const Text('Request Consent'),
                      ),
                      ElevatedButton(
                        onPressed: _isInitialized ? _showPrivacyOptions : null,
                        child: const Text('Privacy Options'),
                      ),
                      ElevatedButton(
                        onPressed: _isInitialized ? _resetConsent : null,
                        child: const Text('Reset Consent'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Ad test buttons
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton(
                        onPressed: _interstitialAd != null ? _showInterstitialAd : null,
                        child: const Text('Show Interstitial'),
                      ),
                      ElevatedButton(
                        onPressed: _rewardedAd != null ? _showRewardedAd : null,
                        child: const Text('Show Rewarded'),
                      ),
                      ElevatedButton(
                        onPressed: _loadAllAds,
                        child: const Text('Reload Ads'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Debug info
                  if (_debugInfo != null)
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Debug Info',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  IconButton(
                                    onPressed: _updateDebugInfo,
                                    icon: const Icon(Icons.refresh),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Text(
                                    _formatDebugInfo(_debugInfo!),
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDebugInfo(Map<String, dynamic> info) {
    final buffer = StringBuffer();

    void writeMap(Map<String, dynamic> map, [int indent = 0]) {
      final indentStr = '  ' * indent;
      map.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          buffer.writeln('$indentStr$key:');
          writeMap(value, indent + 1);
        } else {
          buffer.writeln('$indentStr$key: $value');
        }
      });
    }

    writeMap(info);
    return buffer.toString();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }
}

/// Example of how to integrate consent service in your app initialization
class AppWithConsentExample extends StatelessWidget {
  const AppWithConsentExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Consent Example',
      home: FutureBuilder<bool>(
        // Initialize ads with consent handling
        future: AdRequestHelper.instance.handleConsentAndInitialize(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Initializing ads and consent...'),
                  ],
                ),
              ),
            );
          }

          // Show main app regardless of ads status
          return const ConsentUsageExample();
        },
      ),
    );
  }
}

/// Best practices for using the consent service:
///
/// 1. **Initialize Early**: Call handleConsentAndInitialize() at app startup
/// 2. **Don't Block UI**: The consent service won't block the app if consent fails
/// 3. **Handle All Scenarios**: The service handles EEA/non-EEA regions automatically
/// 4. **Use AdRequestHelper**: Always use AdRequestHelper for loading ads
/// 5. **Test Different Regions**: Use the _forceEeaTesting flag for testing
/// 6. **Monitor Performance**: Use debug info to monitor consent and ad performance
/// 7. **Respect User Choice**: Provide privacy options where required
/// 8. **Fallback Gracefully**: Non-personalized ads are shown when personalized aren't allowed
///
/// Example integration in main.dart:
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///
///   // Initialize ads with consent
///   await AdRequestHelper.instance.handleConsentAndInitialize();
///
///   runApp(MyApp());
/// }
/// ```
