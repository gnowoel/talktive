import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';

/// A small, Duolingo-style badge that displays a user's floor level.
class DuoFloorBadge extends StatelessWidget {
  final int floor;
  final double fontSize;
  final double padding;

  const DuoFloorBadge({
    super.key,
    required this.floor,
    this.fontSize = 10,
    this.padding = 6,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getFloorColor(floor);
    final isHighFloor = floor >= 10;

    Widget badge = Container(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.apartment, size: 10, color: Colors.white),
          const SizedBox(width: 2),
          Text(
            '$floor',
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );

    if (isHighFloor) {
      badge = badge
          .animate(onPlay: (c) => c.repeat())
          .shimmer(duration: 1500.ms, color: Colors.white.withValues(alpha: 0.4))
          .animate()
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.05, 1.05),
            duration: 800.ms,
            curve: Curves.easeInOut,
          )
          .then()
          .scale(
            begin: const Offset(1.05, 1.05),
            end: const Offset(1, 1),
            duration: 800.ms,
            curve: Curves.easeInOut,
          );
    }

    return badge;
  }

  Color _getFloorColor(int floor) {
    if (floor >= 10) return AppTheme.diamondBadge;
    if (floor >= 7) return AppTheme.goldBadge;
    if (floor >= 4) return AppTheme.silverBadge;
    if (floor >= 2) return AppTheme.bronzeBadge;
    return AppTheme.primaryColor;
  }
}
