import 'package:flutter/material.dart';

/// A wrapper widget that handles edge-to-edge display by applying proper
/// system insets padding to avoid content being hidden behind system UI.
class EdgeToEdgeWrapper extends StatelessWidget {
  const EdgeToEdgeWrapper({
    super.key,
    required this.child,
    this.includeTop = true,
    this.includeBottom = true,
    this.includeLeft = true,
    this.includeRight = true,
    this.minimum = EdgeInsets.zero,
  });

  /// The child widget to wrap with edge-to-edge support
  final Widget child;

  /// Whether to include top system inset (status bar)
  final bool includeTop;

  /// Whether to include bottom system inset (navigation bar)
  final bool includeBottom;

  /// Whether to include left system inset (for landscape/notch)
  final bool includeLeft;

  /// Whether to include right system inset (for landscape/notch)
  final bool includeRight;

  /// Minimum padding to apply even when system insets are zero
  final EdgeInsets minimum;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: includeTop,
      bottom: includeBottom,
      left: includeLeft,
      right: includeRight,
      minimum: minimum,
      child: child,
    );
  }
}

/// A more granular wrapper that gives direct access to system insets
/// without automatically applying SafeArea
class SystemInsetsWrapper extends StatelessWidget {
  const SystemInsetsWrapper({super.key, required this.builder});

  /// Builder function that receives system insets and builds the UI
  final Widget Function(BuildContext context, EdgeInsets systemInsets) builder;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final systemInsets = mediaQuery.viewPadding;

    return builder(context, systemInsets);
  }
}

/// A scaffold wrapper that handles edge-to-edge display properly
class EdgeToEdgeScaffold extends StatelessWidget {
  const EdgeToEdgeScaffold({
    super.key,
    this.appBar,
    this.body,
    this.bottomNavigationBar,
    this.drawer,
    this.endDrawer,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.backgroundColor,
    this.resizeToAvoidBottomInset,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
  });

  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final Widget? endDrawer;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Color? backgroundColor;
  final bool? resizeToAvoidBottomInset;
  final bool extendBody;
  final bool extendBodyBehindAppBar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: appBar,
      body: body != null
          ? EdgeToEdgeWrapper(
              includeTop: appBar == null, // Only include top if no AppBar
              child: body!,
            )
          : null,
      bottomNavigationBar: bottomNavigationBar,
      drawer: drawer,
      endDrawer: endDrawer,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      backgroundColor: backgroundColor ?? theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
    );
  }
}

/// Extension to easily apply edge-to-edge padding to any widget
extension EdgeToEdgeExtension on Widget {
  /// Wraps the widget with EdgeToEdgeWrapper
  Widget withEdgeToEdge({
    bool includeTop = true,
    bool includeBottom = true,
    bool includeLeft = true,
    bool includeRight = true,
    EdgeInsets minimum = EdgeInsets.zero,
  }) {
    return EdgeToEdgeWrapper(
      includeTop: includeTop,
      includeBottom: includeBottom,
      includeLeft: includeLeft,
      includeRight: includeRight,
      minimum: minimum,
      child: this,
    );
  }
}
