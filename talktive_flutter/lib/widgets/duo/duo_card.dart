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
        border: borderWidth != null
            ? Border.all(
                color: borderColor ?? Colors.grey[200]!,
                width: borderWidth!,
              )
            : null,
        boxShadow: AppTheme.duoCardShadow,
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
