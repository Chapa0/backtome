import 'package:flutter/material.dart';

class AppTheme {
  static const Color institutionalColor = Color(0xFF1B396A);
  static const Color appBackgroundColor = Color(0xFFE1EDFF);

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      primaryColor: institutionalColor,
      scaffoldBackgroundColor: appBackgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: institutionalColor,
        primary: institutionalColor,
        surface: appBackgroundColor,
      ),
    );
  }
}
