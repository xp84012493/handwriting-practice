import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 应用语言：跟随系统，或固定为中文 / 英文。
class LocaleController extends ChangeNotifier {
  LocaleController();

  static const _prefKey = 'app_locale_code';

  /// `null` 表示跟随系统。
  Locale? _locale;
  bool _loaded = false;

  bool get isLoaded => _loaded;

  /// 当前用户选择；`null` 为跟随系统。
  Locale? get locale => _locale;

  static const Locale chinese = Locale('zh');
  static const Locale english = Locale('en');

  static const List<Locale> supported = [chinese, english];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefKey);
    if (code == null || code.isEmpty) {
      _locale = null;
    } else if (code == 'system') {
      _locale = null;
    } else {
      _locale = Locale(code);
    }
    _loaded = true;
    notifyListeners();
  }

  /// [locale] 为 `null` 时跟随系统。
  Future<void> setLocale(Locale? locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.setString(_prefKey, 'system');
    } else {
      await prefs.setString(_prefKey, locale.languageCode);
    }
  }

  Locale? localeResolutionCallback(
    Locale? systemLocale,
    Iterable<Locale> supportedLocales,
  ) {
    if (_locale != null) {
      return _resolve(_locale!, supportedLocales);
    }
    if (systemLocale != null) {
      return _resolve(systemLocale, supportedLocales);
    }
    return supportedLocales.first;
  }

  Locale _resolve(Locale desired, Iterable<Locale> supportedLocales) {
    for (final supported in supportedLocales) {
      if (supported.languageCode == desired.languageCode) {
        return supported;
      }
    }
    return supportedLocales.first;
  }
}
