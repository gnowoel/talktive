import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A utility class that manages edge-to-edge display and system UI overlays
/// for Android 15+ compatibility and consistent cross-platform behavior.
class EdgeToEdgeManager {
  static EdgeToEdgeManager? _instance;

  EdgeToEdgeManager._();

  /// Get the singleton instance of EdgeToEdgeManager
  static EdgeToEdgeManager get instance {
    _instance ??= EdgeToEdgeManager._();
    return _instance!;
  }

  /// Initialize edge-to-edge display with default settings
  static Future<void> initialize() async {
    await instance._configure();
  }

  /// Configure system UI overlays for edge-to-edge display
  Future<void> _configure() async {
    // Set preferred orientations for better edge-to-edge experience
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Enable edge-to-edge by setting system UI mode
    // For Android 15+, we don't set colors as they're deprecated
    _configureSystemUIMode();
  }

  /// Configure system UI mode without setting deprecated color properties
  void _configureSystemUIMode() {
    // For Android 15+, we only set the brightness properties
    // The system handles transparency automatically with edge-to-edge
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  /// Update system UI overlay style based on theme brightness
  void updateForTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    // Only set brightness properties for Android 15+ compatibility
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
    );
  }

  /// Update system UI overlay style for a specific context
  void updateForContext(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    updateForTheme(brightness);
  }

  /// Configure system UI for splash screen or launch
  void configureLaunchStyle() {
    // Only set brightness properties for Android 15+ compatibility
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  /// Hide system UI for immersive experience (like fullscreen media)
  Future<void> hideSystemUI() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersive,
    );
  }

  /// Show system UI after hiding it
  Future<void> showSystemUI() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );
  }

  /// Configure system UI for modal or dialog
  void configureModalStyle(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    // Only set brightness properties for Android 15+ compatibility
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
    );
  }

  /// Reset to default edge-to-edge configuration
  Future<void> resetToDefault() async {
    _configureSystemUIMode();
    await showSystemUI();
  }

  /// Get safe area insets for the current context
  EdgeInsets getSafeAreaInsets(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.viewPadding;
  }

  /// Check if the device supports edge-to-edge display
  bool get supportsEdgeToEdge {
    // For Flutter, we assume edge-to-edge is supported on all platforms
    // In a real implementation, you might check platform versions
    return true;
  }

  /// Get the recommended padding for content to avoid system UI
  EdgeInsets getContentPadding(BuildContext context) {
    final safeArea = getSafeAreaInsets(context);
    return EdgeInsets.only(
      top: safeArea.top,
      bottom: safeArea.bottom,
    );
  }

  /// Apply edge-to-edge styling to an AppBar
  AppBar styleAppBar({
    required AppBar appBar,
    required BuildContext context,
    Color? backgroundColor,
    bool forceTransparent = false,
  }) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;

    return AppBar(
      title: appBar.title,
      leading: appBar.leading,
      actions: appBar.actions,
      backgroundColor: forceTransparent
          ? Colors.transparent
          : backgroundColor ?? theme.appBarTheme.backgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
      iconTheme: appBar.iconTheme ??
          IconThemeData(
            color: theme.colorScheme.onSurface,
          ),
      titleTextStyle: appBar.titleTextStyle ??
          TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
    );
  }

  /// Create a system UI overlay style for the given context
  SystemUiOverlayStyle createOverlayStyle(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    // Only return brightness properties for Android 15+ compatibility
    return SystemUiOverlayStyle(
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    );
  }
}

/// Extension methods for easier edge-to-edge integration
extension EdgeToEdgeContext on BuildContext {
  /// Get the EdgeToEdgeManager instance
  EdgeToEdgeManager get edgeToEdge => EdgeToEdgeManager.instance;

  /// Update system UI for this context
  void updateSystemUI() {
    EdgeToEdgeManager.instance.updateForContext(this);
  }

  /// Get safe area insets for this context
  EdgeInsets get safeAreaInsets =>
      EdgeToEdgeManager.instance.getSafeAreaInsets(this);

  /// Get content padding for this context
  EdgeInsets get contentPadding =>
      EdgeToEdgeManager.instance.getContentPadding(this);
}
