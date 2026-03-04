import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../services/settings.dart';

class DuoInfoBanner extends StatefulWidget {
  final String bannerId;
  final String text;
  final IconData icon;

  const DuoInfoBanner({
    super.key,
    required this.bannerId,
    required this.text,
    this.icon = Icons.info_outline,
  });

  @override
  State<DuoInfoBanner> createState() => _DuoInfoBannerState();
}

class _DuoInfoBannerState extends State<DuoInfoBanner> {
  bool _isDismissed = true; // Assume dismissed until loaded to prevent flash
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkDismissedState();
  }

  Future<void> _checkDismissedState() async {
    final dismissed = await Prefs.getBool('banner_dismissed_${widget.bannerId}');
    if (mounted) {
      setState(() {
        _isDismissed = dismissed;
        _isLoading = false;
      });
    }
  }

  Future<void> _dismiss() async {
    setState(() => _isDismissed = true);
    await Prefs.setBool('banner_dismissed_${widget.bannerId}', true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _isDismissed) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.duoSpacingLarge,
        vertical: AppTheme.duoSpacingSmall,
      ),
      padding: const EdgeInsets.only(
        left: AppTheme.duoSpacingMedium,
        right: AppTheme.duoSpacingSmall,
        top: AppTheme.duoSpacingSmall,
        bottom: AppTheme.duoSpacingSmall,
      ),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.duoRadiusMedium),
        border: Border.all(
          color: AppTheme.accentColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(widget.icon, color: AppTheme.accentColor, size: 20),
          const SizedBox(width: AppTheme.duoSpacingSmall),
          Expanded(
            child: Text(
              widget.text,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.accentColor,
                fontFamily: 'Rubik',
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: AppTheme.accentColor),
            onPressed: _dismiss,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 20,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.1, end: 0);
  }
}
