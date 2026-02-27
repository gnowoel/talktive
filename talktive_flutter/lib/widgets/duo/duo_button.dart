import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';

/// Duolingo-style button with gradient, haptic feedback, and animations
class DuoButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;
  final IconData? icon;
  final Color? color;
  final double? width;

  const DuoButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.icon,
    this.color,
    this.width,
  });

  @override
  State<DuoButton> createState() => _DuoButtonState();
}

class _DuoButtonState extends State<DuoButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;
    final buttonColor = widget.color ?? AppTheme.primaryColor;

    return GestureDetector(
      onTapDown: isDisabled
          ? null
          : (_) {
              setState(() => _isPressed = true);
              HapticFeedback.lightImpact();
            },
      onTapUp: isDisabled
          ? null
          : (_) {
              setState(() => _isPressed = false);
            },
      onTapCancel: isDisabled
          ? null
          : () {
              setState(() => _isPressed = false);
            },
      onTap: isDisabled ? null : widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: AppTheme.duoAnimationQuick,
        curve: Curves.easeOut,
        child: Container(
          width: widget.width,
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.duoSpacingLarge,
            vertical: AppTheme.duoSpacingMedium,
          ),
          decoration: BoxDecoration(
            gradient: widget.isSecondary
                ? null
                : LinearGradient(
                    colors: isDisabled
                        ? [Colors.grey.shade300, Colors.grey.shade400]
                        : [buttonColor, _lightenColor(buttonColor, 0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            color: widget.isSecondary
                ? (isDisabled ? Colors.grey.shade200 : Colors.white)
                : null,
            borderRadius: BorderRadius.circular(AppTheme.duoRadiusMedium),
            border: widget.isSecondary
                ? Border.all(
                    color: isDisabled ? Colors.grey.shade300 : buttonColor,
                    width: 2,
                  )
                : null,
            boxShadow: isDisabled ? null : AppTheme.duoButtonShadow,
          ),
          child: widget.isLoading
              ? const Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        color: widget.isSecondary
                            ? (isDisabled ? Colors.grey : buttonColor)
                            : Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: AppTheme.duoSpacingSmall),
                    ],
                    Text(
                      widget.text,
                      style: TextStyle(
                        color: widget.isSecondary
                            ? (isDisabled ? Colors.grey : buttonColor)
                            : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Color _lightenColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }
}
