import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../l10n/l10n_extension.dart';
import '../locale/locale_controller.dart';

enum _LanguageChoice { system, chineseSimplified, chineseTraditional, english }

/// 设置 → 语言。
class LanguageSettingsPage extends StatelessWidget {
  const LanguageSettingsPage({super.key, required this.localeController});

  final LocaleController localeController;

  _LanguageChoice _currentChoice() {
    final locale = localeController.locale;
    if (locale == null) return _LanguageChoice.system;
    if (locale.languageCode == 'en') return _LanguageChoice.english;
    if (LocaleController.isTraditionalChinese(locale)) {
      return _LanguageChoice.chineseTraditional;
    }
    if (locale.languageCode == 'zh') return _LanguageChoice.chineseSimplified;
    return _LanguageChoice.english;
  }

  Future<void> _setLanguage(_LanguageChoice choice) async {
    switch (choice) {
      case _LanguageChoice.system:
        await localeController.setLocale(null);
      case _LanguageChoice.chineseSimplified:
        await localeController.setLocale(LocaleController.chineseSimplified);
      case _LanguageChoice.chineseTraditional:
        await localeController.setLocale(LocaleController.chineseTraditional);
      case _LanguageChoice.english:
        await localeController.setLocale(LocaleController.english);
    }
  }

  static String currentLanguageLabel(
    AppLocalizations l10n,
    LocaleController controller,
  ) {
    final locale = controller.locale;
    if (locale == null) return l10n.languageFollowSystem;
    if (locale.languageCode == 'en') return l10n.languageEnglish;
    if (LocaleController.isTraditionalChinese(locale)) {
      return l10n.languageChineseTraditional;
    }
    if (locale.languageCode == 'zh') return l10n.languageChinese;
    return l10n.languageEnglish;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: localeController,
      builder: (context, _) {
        final l10n = context.l10n;
        final languageChoice = _currentChoice();
        return Scaffold(
          appBar: AppBar(title: Text(l10n.languageTitle)),
          body: ListView(
            children: [
              RadioListTile<_LanguageChoice>(
                title: Text(l10n.languageFollowSystem),
                value: _LanguageChoice.system,
                groupValue: languageChoice,
                onChanged: (value) {
                  if (value != null) _setLanguage(value);
                },
              ),
              RadioListTile<_LanguageChoice>(
                title: Text(l10n.languageChinese),
                value: _LanguageChoice.chineseSimplified,
                groupValue: languageChoice,
                onChanged: (value) {
                  if (value != null) _setLanguage(value);
                },
              ),
              RadioListTile<_LanguageChoice>(
                title: Text(l10n.languageChineseTraditional),
                value: _LanguageChoice.chineseTraditional,
                groupValue: languageChoice,
                onChanged: (value) {
                  if (value != null) _setLanguage(value);
                },
              ),
              RadioListTile<_LanguageChoice>(
                title: Text(l10n.languageEnglish),
                value: _LanguageChoice.english,
                groupValue: languageChoice,
                onChanged: (value) {
                  if (value != null) _setLanguage(value);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
