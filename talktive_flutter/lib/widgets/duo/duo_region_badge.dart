import 'package:flutter/material.dart';

/// A reusable badge widget for displaying a region/country for a lounge.
///
/// If [countryCode] is null or 'Global', it displays a 'Global' 🌍 badge.
/// Otherwise, it displays the [countryCode] with a 🚩 icon.
class DuoRegionBadge extends StatelessWidget {
  /// The country code to display.
  final String? countryCode;

  /// Creates a [DuoRegionBadge].
  const DuoRegionBadge({
    super.key,
    this.countryCode,
  });

  @override
  Widget build(BuildContext context) {
    final isGlobal = countryCode == null || countryCode == 'Global';
    final label = isGlobal ? 'Global' : countryCode!;
    final emoji = isGlobal ? '🌍' : '🚩';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
