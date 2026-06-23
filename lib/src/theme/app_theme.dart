import 'package:flutter/material.dart';

/// 应用主题色与浅色 / 深色 [ThemeData]。
abstract final class AppTheme {
  static const Color seedColor = Color(0xFF006A6A);

  static ThemeData light() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );
  }

  static ThemeData dark() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );
  }
}
