import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';
import 'app_localizations_zh_hant.dart';

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  String get appTitle;
  String get aboutTooltip;
  String get settingsTooltip;
  String get settingsTitle;
  String get exportPdfTooltip;
  String get exportSystemPrint;
  String get exportSaveFile;
  String get exportShare;
  String get inputHint;
  String get generateButton;
  String emptyStateBody(int maxChars);
  String sheetRowSummary(String character, int strokeCount);
  String printFailed(String error);
  String get pdfSaved;
  String get pdfSaveCancelled;
  String pdfSaveFailed(String error);
  String pdfShareFailed(String error);
  String get pdfFileNamePrefix;
  String get aboutTitle;
  String versionLabel(String version);
  String get languageTitle;
  String get languageFollowSystem;
  String get languageChinese;
  String get languageChineseTraditional;
  String get languageEnglish;
  String get featureOverviewTitle;
  String get featureOverviewBody;
  String get strokeDataTitle;
  String get strokeDataBody;
  String get thirdPartyNoticesButton;
  String get openSourceLicensesButton;
  String get notesTitle;
  String get notesBody;
  String get thirdPartyNoticesTitle;
  String thirdPartyNoticesLoadError(String error);
  String get licenseLegalese;
  String get hintSeparator;
  String get listSeparator;
  String get hintEmptyInput;
  String hintDictionaryLoadFailed(String error);
  String get hintInvalidInput;
  String hintNoMatchingChars(String path);
  String hintMissingChars(String chars);
  String hintSkippedOverflow(int maxRows, int skipped);
  String hintPhysicalOverflow(int usedRows, int maxRows);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) {
    if (locale.languageCode == 'en') return true;
    if (locale.languageCode == 'zh') return true;
    return false;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

bool _isTraditionalChineseLocale(Locale locale) {
  return locale.languageCode == 'zh' &&
      (locale.scriptCode == 'Hant' ||
          const {'TW', 'HK', 'MO'}.contains(locale.countryCode));
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  if (locale.languageCode == 'en') {
    return AppLocalizationsEn();
  }
  if (locale.languageCode == 'zh') {
    if (_isTraditionalChineseLocale(locale)) {
      return AppLocalizationsZhHant();
    }
    return AppLocalizationsZh();
  }
  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale".',
  );
}
