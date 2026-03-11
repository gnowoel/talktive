import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A button that displays a refresh icon on platforms (Web, macOS, Windows, Linux) 
/// where native pull-to-refresh gestures are typically unavailable.
class DuoRefreshButton extends StatelessWidget {
  final VoidCallback onRefresh;
  final Color? color;

  const DuoRefreshButton({
    super.key,
    required this.onRefresh,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bool showRefresh = kIsWeb || 
      (![TargetPlatform.iOS, TargetPlatform.android].contains(defaultTargetPlatform));

    if (!showRefresh) {
      return const SizedBox.shrink();
    }

    return IconButton(
      icon: const Icon(Icons.refresh),
      color: color ?? Colors.white,
      onPressed: onRefresh,
      tooltip: 'Refresh',
    );
  }
}
