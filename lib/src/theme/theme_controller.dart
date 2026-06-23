import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 用户选择的主题模式（含跟随系统）。
enum AppThemePreference {
  system,
  light,
  dark,
}

/// 主题模式：浅色、深色或跟随系统。
class ThemeController extends ChangeNotifier {
  ThemeController();

  static const _prefKey = 'app_theme_mode';

  AppThemePreference _preference = AppThemePreference.system;
  bool _loaded = false;

  bool get isLoaded => _loaded;
  AppThemePreference get preference => _preference;

  ThemeMode get themeMode => switch (_preference) {
        AppThemePreference.light => ThemeMode.light,
        AppThemePreference.dark => ThemeMode.dark,
        AppThemePreference.system => ThemeMode.system,
      };

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _preference = preferenceFromStorage(prefs.getString(_prefKey));
    _loaded = true;
    notifyListeners();
  }

  Future<void> setPreference(AppThemePreference value) async {
    if (_preference == value) return;
    _preference = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, preferenceToStorage(value));
  }

  static String preferenceToStorage(AppThemePreference value) {
    return switch (value) {
      AppThemePreference.system => 'system',
      AppThemePreference.light => 'light',
      AppThemePreference.dark => 'dark',
    };
  }

  static AppThemePreference preferenceFromStorage(String? raw) {
    return switch (raw) {
      'light' => AppThemePreference.light,
      'dark' => AppThemePreference.dark,
      _ => AppThemePreference.system,
    };
  }
}
