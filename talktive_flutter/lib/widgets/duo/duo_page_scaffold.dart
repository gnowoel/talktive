import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/theme.dart';
import 'duo_header.dart';

/// A Scaffold wrapper that provides the Duolingo-style "Immersive Curve" layout.
///
/// Features:
/// - Vibrant gradient background at the top.
/// - White content container with rounded top corners.
/// - Consistent header placement.
class DuoPageScaffold extends StatelessWidget {
  final String emoji;
  final String title;
  final String? subtitle;
  final Widget body;
  final Widget? trailingHeader;
  final Widget? floatingActionButton;
  final List<Color> gradient;
  final bool resizeToAvoidBottomInset;
  final bool hasBackButton;
  final Color? textColor;

  const DuoPageScaffold({
    super.key,
    required this.emoji,
    required this.title,
    required this.body,
    required this.gradient,
    this.subtitle,
    this.trailingHeader,
    this.floatingActionButton,
    this.resizeToAvoidBottomInset = true,
    this.hasBackButton = false,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    // Determine status bar brightness based on gradient
    // If textColor is dark, status bar should be dark icons
    final isLightHeader = textColor != null && (textColor == AppTheme.textPrimary || textColor == Colors.black);
    final SystemUiOverlayStyle overlayStyle = isLightHeader ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        backgroundColor: gradient.first, // Fallback
        floatingActionButton: floatingActionButton,
        body: Stack(
          children: [
            // 1. Full-screen Gradient Background (for bounce effect)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: gradient,
                ),
              ),
            ),

            // 2. Layout Column
            Column(
              children: [
                // Header Area
                SafeArea(
                  bottom: false,
                  child: DuoHeader(
                    emoji: emoji,
                    title: title,
                    subtitle: subtitle,
                    trailing: trailingHeader,
                    hasBackButton: hasBackButton,
                    textColor: textColor ?? Colors.white, // Invert text color for gradient
                  ),
                ),

                // Content Area (White Sheet)
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(AppTheme.duoRadiusLarge * 1.5),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: body,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
