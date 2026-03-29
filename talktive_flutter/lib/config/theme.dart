import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // ─── Core Duolingo-Inspired Colors (defined first – used as aliases below) ──
  static const Color duoGreen = Color(
    0xFF58CC02,
  ); // Signature green   → success, profile
  static const Color duoYellow = Color(
    0xFFFFD93D,
  ); // Cheerful yellow    → streaks, XP
  static const Color duoRed = Color(
    0xFFFF4B4B,
  ); // Friendly red       → danger, unread badges
  static const Color duoOrange = Color(
    0xFFFF9600,
  ); // Vibrant orange     → chats
  static const Color duoBlue = Color(
    0xFF1CB0F6,
  ); // Deep cheerful blue → lounges, links

  // ─── Brand Colors ────────────────────────────────────────────────────────────
  static const Color primaryColor = Color(0xFF6C63FF); // Purple (main brand)
  static const Color duoPurple = primaryColor; // Alias for primaryColor
  static const Color secondaryColor = Color(0xFFFF6584); // Pink (Moments)
  // accentColor is aliased to duoBlue for a consistent, accessible palette.
  // Prefer using duoBlue directly to make semantic intent explicit.
  static const Color accentColor = duoBlue;

  // ─── Gradient Collections ─────────────────────────────────────────────────
  static const List<Color> primaryGradient = [
    Color(0xFF6C63FF),
    Color(0xFF8B80FF),
  ];

  static const List<Color> secondaryGradient = [
    Color(0xFFFF6584),
    Color(0xFFFF8FA3),
  ];

  // accentGradient == duoBlueGradient for palette consistency.
  static const List<Color> accentGradient = duoBlueGradient;

  static const List<Color> duoGreenGradient = [
    Color(0xFF58CC02),
    Color(0xFF78E028),
  ];

  static const List<Color> duoYellowGradient = [
    Color(0xFFFFD93D),
    Color(0xFFFFEA85),
  ];

  static const List<Color> duoOrangeGradient = [
    Color(0xFFFF9600),
    Color(0xFFFFB038),
  ];

  static const List<Color> duoPurpleGradient = [
    Color(0xFF6C63FF),
    Color(0xFF8B80FF),
  ];

  static const List<Color> duoBlueGradient = [
    Color(0xFF1CB0F6),
    Color(0xFF49C0F8),
  ];

  static const List<Color> duoRedGradient = [
    Color(0xFFFF4B4B),
    Color(0xFFFF6B6B),
  ];

  // ─── Semantic Palette ─────────────────────────────────────────────────────
  // Plaza   → primaryGradient   (purple)
  // Moments → secondaryGradient (pink)
  // Chats   → duoOrangeGradient (orange)
  // Lounges → duoBlueGradient   (blue)
  // Profile → duoGreenGradient  (green)

  // Functional Colors
  static const Color successColor = duoGreen;
  static const Color warningColor = duoYellow;
  static const Color errorColor = duoRed;
  static const Color infoColor = duoBlue;

  // Mood Colors (for user moods)
  static const Color happyColor = Color(0xFFFFD93D);
  static const Color sadColor = Color(0xFF6C9BD2);
  static const Color excitedColor = Color(0xFFFF6B6B);
  static const Color calmColor = Color(0xFF95E1D3);
  static const Color loveColor = Color(0xFFF38181);

  // Trust Score Colors
  static const Color highTrustColor = Color(0xFF4CAF50);
  static const Color mediumTrustColor = Color(0xFFFFA726);
  static const Color lowTrustColor = Color(0xFFEF5350);
  static const Color newUserColor = Color(0xFF9E9E9E);

  // Background Colors
  static const Color lightBackground = Color(0xFFF7F9FC);
  static const Color darkBackground = Color(0xFF1A1A2E);
  static const Color backgroundColor =
      lightBackground; // Added for compatibility
  static const Color cardLight = Colors.white;
  static const Color cardDark = Color(0xFF16213E);

  // Text Colors
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(
    0xFF424242,
  ); // Even darker for high contrast (WCAG AA)
  static const Color textLight = Color(
    0xFF616161,
  ); // Improved from #777777 for better hint readability
  static const Color textOnPrimary = Colors.white;
  static const Color duoBorder = Color(0xFFE0E0E0);

  /// Returns a color that contrasts well with the given [background] color.
  /// Primarily used for text on colored backgrounds (e.g. primary buttons).
  static Color getContrastColor(Color background) {
    final double luminance = background.computeLuminance();
    // Standard threshold for choosing black vs white text
    return luminance > 0.4 ? textPrimary : Colors.white;
  }

  /// Returns a brand color optimized for text on a white/light background.
  /// If the color is too light, it returns a darkened version to meet contrast requirements.
  static Color getBrandTextColor(Color color) {
    final double luminance = color.computeLuminance();
    // If contrast with white (L=1.0) is less than 4.5:1, darken the color.
    // Contrast Ratio = (L1 + 0.05) / (L2 + 0.05)
    // 4.5 = (1.05) / (L_brand + 0.05) => L_brand + 0.05 = 1.05 / 4.5 = 0.233 => L_brand = 0.183
    if (luminance > 0.18) {
      final hsl = HSLColor.fromColor(color);
      // Darken until luminance is acceptable
      return hsl
          .withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0))
          .toColor();
    }
    return color;
  }

  // Badge Colors (Gamification)
  static const Color diamondBadge = Color(0xFFB9F2FF);
  static const Color platinumBadge = Color(0xFFE5E4E2);
  static const Color goldBadge = Color(0xFFFFD700);
  static const Color silverBadge = Color(0xFFC0C0C0);
  static const Color bronzeBadge = Color(0xFFCD7F32);

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: lightBackground,

    // Color Scheme
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      surface: cardLight,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimary,
      onError: Colors.white,
    ),

    // App Bar Theme
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      foregroundColor: textPrimary,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
    ),

    // Bottom Navigation Bar
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: cardLight,
      selectedItemColor: primaryColor,
      unselectedItemColor: textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    ),

    // Card Theme
    cardTheme: CardThemeData(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: cardLight,
      shadowColor: Colors.black.withValues(alpha: 0.1),
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: primaryColor,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor, width: 1),
      ),
      labelStyle: const TextStyle(fontFamily: 'Poppins', color: textSecondary),
      hintStyle: const TextStyle(fontFamily: 'Poppins', color: textLight),
    ),

    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: primaryColor.withValues(alpha: 0.1),
      selectedColor: primaryColor,
      labelStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),

    // Dialog Theme
    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 16,
    ),

    // Bottom Sheet Theme
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: cardLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      elevation: 16,
    ),

    // Floating Action Button Theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // Icon Theme
    iconTheme: const IconThemeData(color: textPrimary, size: 24),

    // Text Theme
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      displaySmall: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      titleSmall: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Rubik',
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: textPrimary,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Rubik',
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: textPrimary,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Rubik',
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: textSecondary,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      labelMedium: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      ),
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: darkBackground,

    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      surface: cardDark,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onError: Colors.white,
    ),

    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
  );

  // Spacing Constants
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Border Radius
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusRound = 100.0;

  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Box Shadows
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: primaryColor.withValues(alpha: 0.3),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  // Duolingo-Style Shadows
  static List<BoxShadow> duoCardShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.07),
      blurRadius: 20,
      spreadRadius: 0,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> duoButtonShadow = [
    BoxShadow(
      color: primaryColor.withValues(alpha: 0.28),
      blurRadius: 14,
      spreadRadius: 0,
      offset: const Offset(0, 4),
    ),
  ];

  // Duolingo-Style Border Radius
  static const double duoRadiusSmall = 12.0;
  static const double duoRadiusMedium = 16.0;
  static const double duoRadiusLarge = 20.0;
  static const double duoRadiusPill = 100.0;

  // Alias for common usage
  static const double duoBorderRadius = duoRadiusMedium;

  // Duolingo-Style Spacing
  static const double duoSpacingTiny = 4.0;
  static const double duoSpacingSmall = 8.0;
  static const double duoSpacingMedium = 16.0;
  static const double duoSpacingLarge = 24.0;
  static const double duoSpacingXLarge = 32.0;
  static const double duoSpacingXXLarge = 48.0;

  // Bottom Navigation Bar
  static const double bottomNavHeight = 70.0;
  static const double bottomNavMargin = 0.0;
  static const double bottomNavTotalHeight = bottomNavHeight;

  // Content bottom padding (for screens with bottom nav)
  static const double contentBottomPadding =
      duoSpacingMedium + duoSpacingMedium;

  // Duolingo-Style Animation Durations
  static const Duration duoAnimationQuick = Duration(milliseconds: 150);
  static const Duration duoAnimationNormal = Duration(milliseconds: 300);
  static const Duration duoAnimationSlow = Duration(milliseconds: 500);
  static const Duration duoAnimationCelebration = Duration(milliseconds: 3000);
}
