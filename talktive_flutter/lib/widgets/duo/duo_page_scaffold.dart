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
  final String? emoji;
  final IconData? icon;
  final String title;
  final String? subtitle;
  final Widget body;
  final Widget? trailingHeader;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final List<Color> gradient;
  final bool resizeToAvoidBottomInset;
  final bool hasBackButton;
  final Color? textColor;

  const DuoPageScaffold({
    super.key,
    this.emoji,
    this.icon,
    required this.title,
    required this.body,
    required this.gradient,
    this.subtitle,
    this.trailingHeader,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.resizeToAvoidBottomInset = true,
    this.hasBackButton = false,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    // Determine status bar brightness based on gradient
    // If textColor is dark, status bar should be dark icons
    final isLightHeader =
        textColor != null &&
        (textColor == AppTheme.textPrimary || textColor == Colors.black);
    final SystemUiOverlayStyle overlayStyle = isLightHeader
        ? SystemUiOverlayStyle.dark
        : SystemUiOverlayStyle.light;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        backgroundColor: gradient.first, // Fallback
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
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

            // 1b. Animated Background Decorations (Premium Feel)
            ..._buildBackgroundDecorations(),

            // 2. Layout Column
            Column(
              children: [
                // Header Area
                SafeArea(
                  bottom: false,
                  child: DuoHeader(
                    emoji: emoji,
                    icon: icon,
                    title: title,
                    subtitle: subtitle,
                    trailing: trailingHeader,
                    hasBackButton: hasBackButton,
                    textColor:
                        textColor ??
                        Colors.white, // Invert text color for gradient
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
  List<Widget> _buildBackgroundDecorations() {
    return [
      Positioned(
        top: -20,
        right: -30,
        child: _buildFloatingBubble(80, Colors.white.withValues(alpha: 0.12)),
      ),
      Positioned(
        top: 40,
        left: -40,
        child: _buildFloatingBubble(120, Colors.white.withValues(alpha: 0.08)),
      ),
      Positioned(
        top: 100,
        right: 40,
        child: _buildFloatingBubble(60, Colors.white.withValues(alpha: 0.1)),
      ),
    ];
  }

  Widget _buildFloatingBubble(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .moveY(begin: 0, end: 15, duration: 3.seconds, curve: Curves.easeInOut)
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.1, 1.1),
          duration: 4.seconds,
          curve: Curves.easeInOut,
        );
  }
}
