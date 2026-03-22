import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';

/// Duolingo-style stat card with icon, number, and label
class DuoStatCard extends StatefulWidget {
  final IconData? icon;
  final String? emoji;
  final String value;
  final String label;
  final List<Color> gradientColors;
  final VoidCallback? onTap;

  const DuoStatCard({
    super.key,
    this.icon,
    this.emoji,
    required this.value,
    required this.label,
    required this.gradientColors,
    this.onTap,
  });

  @override
  State<DuoStatCard> createState() => _DuoStatCardState();
}

class _DuoStatCardState extends State<DuoStatCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap == null
          ? null
          : (_) {
              setState(() => _isPressed = true);
              HapticFeedback.selectionClick();
            },
      onTapUp: widget.onTap == null
          ? null
          : (_) {
              setState(() => _isPressed = false);
            },
      onTapCancel: widget.onTap == null
          ? null
          : () {
              setState(() => _isPressed = false);
            },
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: AppTheme.duoAnimationQuick,
        child: Container(
          padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.duoRadiusMedium),
            boxShadow: AppTheme.duoCardShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with gradient background
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: widget.icon != null 
                    ? Icon(widget.icon, color: Colors.white, size: 24)
                    : Text(
                        widget.emoji ?? '', 
                        style: const TextStyle(fontSize: 24, height: 1.0),
                      ),
                ),
              ),
              const SizedBox(height: AppTheme.duoSpacingSmall),
              // Value
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  widget.value,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              // Label
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontFamily: 'Rubik',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
