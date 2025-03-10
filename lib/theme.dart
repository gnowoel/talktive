import 'package:flutter/material.dart';

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

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      brightness: brightness,
      seedColor: Colors.lightGreen,
    ),
    extensions: [isDark ? CustomColors.dark : CustomColors.light],
  );
}
