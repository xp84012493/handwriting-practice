import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 应用语言：跟随系统，或固定为简体 / 繁体中文 / 英文。
class LocaleController extends ChangeNotifier {
  LocaleController();

  static const _prefKey = 'app_locale_code';

  /// `null` 表示跟随系统。
  Locale? _locale;
  bool _loaded = false;

  bool get isLoaded => _loaded;

  /// 当前用户选择；`null` 为跟随系统。
  Locale? get locale => _locale;

  static const Locale chineseSimplified = Locale('zh');
  static const Locale chineseTraditional =
      Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant');
  static const Locale english = Locale('en');

  static const List<Locale> supported = [
    chineseSimplified,
    chineseTraditional,
    english,
  ];

  static bool isTraditionalChinese(Locale locale) {
    return locale.languageCode == 'zh' &&
        (locale.scriptCode == 'Hant' ||
            const {'TW', 'HK', 'MO'}.contains(locale.countryCode));
  }

  static String localeToStorageCode(Locale locale) {
    if (locale.languageCode == 'en') return 'en';
    if (isTraditionalChinese(locale)) return 'zh_Hant';
    if (locale.languageCode == 'zh') return 'zh';
    return locale.toLanguageTag();
  }

  static Locale? localeFromStorageCode(String? code) {
    if (code == null || code.isEmpty || code == 'system') return null;
    return switch (code) {
      'en' => english,
      'zh' => chineseSimplified,
      'zh_Hant' => chineseTraditional,
      _ => Locale(code),
    };
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _locale = localeFromStorageCode(prefs.getString(_prefKey));
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
      await prefs.setString(_prefKey, localeToStorageCode(locale));
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
    final normalized = _normalizeDesired(desired);
    for (final supported in supportedLocales) {
      if (_localesMatch(normalized, supported)) return supported;
    }
    for (final supported in supportedLocales) {
      if (supported.languageCode == normalized.languageCode) {
        return supported;
      }
    }
    return supportedLocales.first;
  }

  Locale _normalizeDesired(Locale locale) {
    if (locale.languageCode == 'en') return english;
    if (locale.languageCode == 'zh') {
      return isTraditionalChinese(locale)
          ? chineseTraditional
          : chineseSimplified;
    }
    return locale;
  }

  bool _localesMatch(Locale a, Locale b) {
    if (a.languageCode != b.languageCode) return false;
    if (a.languageCode == 'zh') {
      return isTraditionalChinese(a) == isTraditionalChinese(b);
    }
    return true;
  }
}
