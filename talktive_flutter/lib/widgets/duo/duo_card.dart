import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Duolingo-style card with white background and subtle shadow
class DuoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final double? borderRadius;
  final double? borderWidth;
  final Color? borderColor;

  const DuoCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.color,
    this.borderRadius,
    this.borderWidth,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(AppTheme.duoSpacingMedium),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(
          borderRadius ?? AppTheme.duoRadiusLarge,
        ),
        border: Border.all(
          color: borderColor ?? const Color(0xFFE5E5E5),
          width: borderWidth ?? 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (color ?? Colors.white).computeLuminance() > 0.5
                ? const Color(0xFFE5E5E5)
                : (color ?? Colors.white).withValues(alpha: 0.8),
            offset: const Offset(0, 2),
            spreadRadius: 0,
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            borderRadius ?? AppTheme.duoRadiusLarge,
          ),
          child: card,
        ),
      );
    }

    return card;
  }
}
