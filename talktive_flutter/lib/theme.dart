import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomColors extends ThemeExtension<CustomColors> {
  final Color friendIndicator;

  const CustomColors({required this.friendIndicator});

  @override
  ThemeExtension<CustomColors> copyWith({Color? friendIndicator}) {
    return CustomColors(
      friendIndicator: friendIndicator ?? this.friendIndicator,
    );
  }

  @override
  ThemeExtension<CustomColors> lerp(
    ThemeExtension<CustomColors>? other,
    double t,
  ) {
    if (other is! CustomColors) {
      return this;
    }
    return CustomColors(
      friendIndicator: Color.lerp(friendIndicator, other.friendIndicator, t)!,
    );
  }

  static const light = CustomColors(
    friendIndicator: Color(0xFFFFB74D), // Orange 300
  );

  static const dark = CustomColors(
    friendIndicator: Color(0xFFFFD180), // Orange A100
  );
}

ThemeData getTheme(BuildContext context) {
  final brightness = MediaQuery.platformBrightnessOf(context);
  final isDark = brightness == Brightness.dark;

  final colorScheme = ColorScheme.fromSeed(
    brightness: brightness,
    seedColor: Colors.lightGreen,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    extensions: [isDark ? CustomColors.dark : CustomColors.light],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
      iconTheme: IconThemeData(
        color: colorScheme.onSurface,
      ),
      titleTextStyle: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
    ),
    scaffoldBackgroundColor: colorScheme.surface,
    // Ensure proper edge-to-edge support
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: colorScheme.surface,
      elevation: 0,
    ),
  );
}
