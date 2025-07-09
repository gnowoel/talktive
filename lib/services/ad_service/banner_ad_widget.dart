import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'ad_service.dart';

/// Adaptive banner ad widget for chat interface
/// Displays banner ads at the bottom of screens with proper spacing
class BannerAdWidget extends StatefulWidget {
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final bool showCloseButton;
  final VoidCallback? onClose;

  const BannerAdWidget({
    super.key,
    this.margin,
    this.backgroundColor,
    this.showCloseButton = false,
    this.onClose,
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isLoading = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _loadAd() async {
    if (_isLoading || _isDisposed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final adService = context.read<AdService>();
      if (!adService.isInitialized) {
        await adService.initialize();
      }

      if (!mounted) return;

      // Get adaptive banner size
      final AnchoredAdaptiveBannerAdSize? size =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
        MediaQuery.of(context).size.width.truncate(),
      );

      if (size == null) {
        debugPrint('Unable to get adaptive banner size');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      _bannerAd = BannerAd(
        adUnitId: adService.getAdUnitId('banner'),
        size: size,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            debugPrint('Banner ad loaded successfully');
            if (mounted && !_isDisposed) {
              setState(() {
                _isLoaded = true;
                _isLoading = false;
              });
            }
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('Banner ad failed to load: $error');
            if (mounted && !_isDisposed) {
              setState(() {
                _isLoaded = false;
                _isLoading = false;
              });
            }
            ad.dispose();
          },
          onAdOpened: (ad) {
            debugPrint('Banner ad opened');
          },
          onAdClosed: (ad) {
            debugPrint('Banner ad closed');
          },
          onAdClicked: (ad) {
            debugPrint('Banner ad clicked');
          },
        ),
      );

      await _bannerAd!.load();
    } catch (e) {
      debugPrint('Error loading banner ad: $e');
      if (mounted && !_isDisposed) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _retry() {
    _bannerAd?.dispose();
    _bannerAd = null;
    setState(() {
      _isLoaded = false;
      _isLoading = false;
    });
    _loadAd();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 60,
        margin: widget.margin ?? const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (!_isLoaded || _bannerAd == null) {
      // Show retry option for failed ads
      return Container(
        height: 60,
        margin: widget.margin ?? const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: InkWell(
          onTap: _retry,
          borderRadius: BorderRadius.circular(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.refresh,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                'Tap to load ad',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: widget.margin ?? const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
          ),
          if (widget.showCloseButton)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: widget.onClose,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Simplified banner ad widget for bottom placement
class BottomBannerAd extends StatelessWidget {
  final EdgeInsets? padding;
  final Color? backgroundColor;

  const BottomBannerAd({
    super.key,
    this.padding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: padding ?? const EdgeInsets.only(bottom: 8.0),
        child: BannerAdWidget(
          backgroundColor: backgroundColor,
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
        ),
      ),
    );
  }
}

/// Banner ad for chat list view
class ChatListBannerAd extends StatelessWidget {
  final int itemIndex;
  final int totalItems;

  const ChatListBannerAd({
    super.key,
    required this.itemIndex,
    required this.totalItems,
  });

  @override
  Widget build(BuildContext context) {
    // Only show banner ad every 5th item and not at the very top
    if (itemIndex % 5 != 0 || itemIndex == 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: BannerAdWidget(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
      ),
    );
  }
}
