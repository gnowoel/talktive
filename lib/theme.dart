import 'package:flutter/material.dart';

ThemeData getTheme(BuildContext context) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      brightness: MediaQuery.platformBrightnessOf(context),
      seedColor: Colors.lightGreen.shade400,
    ),
  );
}
