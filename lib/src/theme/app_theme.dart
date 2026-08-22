import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 应用主题色与浅色 / 深色 [ThemeData]。
abstract final class AppTheme {
  static const Color seedColor = Color(0xFF006A6A);

  /// Web 界面字体（已打包，避免从 gstatic 拉 Noto Sans SC）。
  static const String webUiFontFamily = 'LXGWWenKai';

  static ThemeData light() => _themed(Brightness.light);

  static ThemeData dark() => _themed(Brightness.dark);

  static ThemeData _themed(Brightness brightness) {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: brightness,
      ),
      useMaterial3: true,
    );

    if (!kIsWeb) {
      return base;
    }

    final webBase = ThemeData(
      colorScheme: base.colorScheme,
      useMaterial3: true,
      fontFamily: webUiFontFamily,
    );
    return webBase.copyWith(
      textTheme: webBase.textTheme.apply(fontFamily: webUiFontFamily),
      primaryTextTheme:
          webBase.primaryTextTheme.apply(fontFamily: webUiFontFamily),
    );
  }
}
