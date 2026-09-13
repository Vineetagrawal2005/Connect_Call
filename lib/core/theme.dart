import 'package:flutter/material.dart';

/// App theme — intentionally simple (polish is out of scope).
class AppTheme {
  static const Color primary = Color(0xFF1A73E8);
  static const Color onlineGreen = Color(0xFF34A853);
  static const Color offlineGrey = Color(0xFF9AA0A6);
  static const Color missedRed = Color(0xFFD93025);

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: primary),
      appBarTheme: const AppBarTheme(centerTitle: false),
    );
  }
}
