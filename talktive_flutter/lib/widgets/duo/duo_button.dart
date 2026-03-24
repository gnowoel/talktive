import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';

enum DuoButtonVariant { primary, secondary, ghost, danger }

enum DuoButtonSize { small, medium, large }

/// Duolingo-style button with gradient, haptic feedback, and animations
class DuoButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final DuoButtonVariant variant;
  final DuoButtonSize size;
  final IconData? icon;
  final String? emoji;
  final IconData? secondaryIcon;
  final String? secondaryEmoji;
  final Color? color;
  final double? width;

  const DuoButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    DuoButtonVariant? variant,
    bool isSecondary = false, // Alias
    this.size = DuoButtonSize.medium,
    this.icon,
    this.emoji,
    this.secondaryIcon,
    this.secondaryEmoji,
    this.color,
    this.width,
  }) : variant =
           variant ??
           (isSecondary
               ? DuoButtonVariant.secondary
               : DuoButtonVariant.primary);

  @override
  State<DuoButton> createState() => _DuoButtonState();
}

class _DuoButtonState extends State<DuoButton> {
  bool _isPressed = false;

  Color _lightenColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  Color _darkenColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  Color _getContrastColor(Color color, DuoButtonVariant variant) {
    // For primary/danger buttons, we need contrast for the colored background
    if (variant == DuoButtonVariant.primary || variant == DuoButtonVariant.danger) {
      return AppTheme.getContrastColor(color);
    }
    
    // For secondary/ghost, background is white/transparent,
    // so we need a potentially darkened brand color for text on white.
    return AppTheme.getBrandTextColor(color);
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;
    final buttonColor =
        widget.color ??
        (widget.variant == DuoButtonVariant.danger
            ? AppTheme.duoRed
            : AppTheme.primaryColor);

    final isGhost = widget.variant == DuoButtonVariant.ghost;
    final isSecondary = widget.variant == DuoButtonVariant.secondary;

    final textColor = isDisabled 
        ? Colors.grey.shade500 
        : _getContrastColor(buttonColor, widget.variant);

    // Size settings
    double fontSize;
    double iconSize;
    EdgeInsets padding;
    double borderRadius;

    switch (widget.size) {
      case DuoButtonSize.small:
        fontSize = 13;
        iconSize = 16;
        padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
        borderRadius = AppTheme.duoRadiusSmall;
        break;
      case DuoButtonSize.large:
        fontSize = 18;
        iconSize = 22;
        padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
        borderRadius = AppTheme.duoRadiusMedium;
        break;
      default: // medium
        fontSize = 16;
        iconSize = 20;
        padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
        borderRadius = AppTheme.duoRadiusMedium;
    }

    return GestureDetector(
      onTapDown: isDisabled
          ? null
          : (_) {
              setState(() => _isPressed = true);
              HapticFeedback.lightImpact();
            },
      onTapUp: isDisabled ? null : (_) => setState(() => _isPressed = false),
      onTapCancel: isDisabled ? null : () => setState(() => _isPressed = false),
      onTap: isDisabled ? null : widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: AppTheme.duoAnimationQuick,
        curve: Curves.easeOut,
        child: Container(
          width: widget.width,
          padding: padding,
          decoration: BoxDecoration(
            gradient: (isSecondary || isGhost)
                ? null
                : LinearGradient(
                    colors: isDisabled
                        ? [Colors.grey.shade300, Colors.grey.shade400]
                        : [buttonColor, _darkenColor(buttonColor, 0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            color: isGhost
                ? Colors.transparent
                : isSecondary
                ? (isDisabled ? Colors.grey.shade200 : Colors.white)
                : null,
            borderRadius: BorderRadius.circular(borderRadius),
            border: isGhost
                ? Border.all(
                    color: isDisabled ? Colors.grey.shade300 : buttonColor,
                    width: 2,
                  )
                : isSecondary
                ? Border.all(
                    color: isDisabled ? Colors.grey.shade300 : buttonColor,
                    width: 2,
                  )
                : null,
            boxShadow: (isDisabled || isGhost)
                ? null
                : AppTheme.duoButtonShadow,
          ),
          child: widget.isLoading
              ? Center(
                  child: SizedBox(
                    height: iconSize,
                    width: iconSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(textColor),
                    ),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null || widget.emoji != null) ...[
                      widget.icon != null
                          ? Icon(widget.icon, color: textColor, size: iconSize)
                          : Text(
                              widget.emoji!,
                              style: TextStyle(fontSize: iconSize, height: 1.0),
                            ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.text,
                      style: TextStyle(
                        color: textColor,
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    if (widget.secondaryIcon != null || widget.secondaryEmoji != null) ...[
                      const SizedBox(width: 8),
                      (widget.secondaryIcon != null
                              ? Icon(
                                  widget.secondaryIcon,
                                  color: textColor.withValues(
                                    alpha: (isSecondary || isGhost) ? 1.0 : 0.9,
                                  ),
                                  size: iconSize * 0.9,
                                )
                              : Text(
                                  widget.secondaryEmoji!,
                                  style: TextStyle(fontSize: iconSize * 0.9),
                                ))
                          .animate(
                            onPlay: (controller) =>
                                controller.repeat(reverse: true),
                          )
                          .scale(
                            duration: 1000.ms,
                            begin: const Offset(1, 1),
                            end: const Offset(1.2, 1.2),
                          )
                          .shimmer(duration: 2000.ms),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
