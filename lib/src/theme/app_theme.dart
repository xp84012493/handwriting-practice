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
      navigationBarTheme: _navigationBarTheme,
    );
  }

  static ThemeData dark() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      navigationBarTheme: _navigationBarTheme,
    );
  }

  /// 比 Material 3 默认（80）更紧凑的底部导航。
  static const NavigationBarThemeData _navigationBarTheme =
      NavigationBarThemeData(
    height: 58,
    iconTheme: WidgetStatePropertyAll(IconThemeData(size: 22)),
    labelTextStyle: WidgetStatePropertyAll(
      TextStyle(fontSize: 11, height: 1.1, fontWeight: FontWeight.w500),
    ),
  );
}
