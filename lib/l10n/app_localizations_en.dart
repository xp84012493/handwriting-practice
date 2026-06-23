// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn() : super('en');

  @override
  String get appTitle => 'Hanzi Stroke Practice';

  @override
  String get aboutTooltip => 'About';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get exportPdfTooltip => 'Export PDF';

  @override
  String get exportSystemPrint => 'Print…';

  @override
  String get exportSaveFile => 'Save PDF to file';

  @override
  String get exportShare => 'Share PDF';

  @override
  String get inputHint => 'Enter Chinese characters';

  @override
  String get generateButton => 'Generate sheet';

  @override
  String emptyStateBody(int maxChars) {
    return 'Enter multiple characters above (one row per character on the sheet).\nAbout $maxChars characters fit on one A4 page; extra characters are ignored.';
  }

  @override
  String sheetRowSummary(String character, int strokeCount) {
    return '「$character」$strokeCount strokes';
  }

  @override
  String printFailed(String error) {
    return 'Print failed: $error';
  }

  @override
  String get pdfSaved => 'PDF saved';

  @override
  String get pdfSaveCancelled => 'Save cancelled';

  @override
  String pdfSaveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String pdfShareFailed(String error) {
    return 'Share failed: $error';
  }

  @override
  String get pdfFileNamePrefix => 'PracticeSheet';

  @override
  String get aboutTitle => 'About';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get languageTitle => 'Language';

  @override
  String get languageFollowSystem => 'System default';

  @override
  String get languageChinese => '中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get featureOverviewTitle => 'Overview';

  @override
  String get featureOverviewBody =>
      'Generate stroke-order practice sheets from the built-in dictionary, preview them in the app, and print or export PDF via the system.';

  @override
  String get strokeDataTitle => 'Stroke data';

  @override
  String get strokeDataBody =>
      'Stroke outlines come from Make Me a Hanzi graphics.txt, derived from Arphic PL fonts under the Arphic Public License (1999). See Third-party notices below for the full statement.';

  @override
  String get thirdPartyNoticesButton => 'Third-party notices';

  @override
  String get openSourceLicensesButton => 'Open-source licenses';

  @override
  String get notesTitle => 'Note';

  @override
  String get notesBody =>
      'The open-source licenses screen lists this app and its dependencies. Stroke data is governed by the third-party notices above.';

  @override
  String get thirdPartyNoticesTitle => 'Third-party notices';

  @override
  String thirdPartyNoticesLoadError(String error) {
    return 'Could not load THIRD_PARTY_NOTICES.md: $error';
  }

  @override
  String get licenseLegalese =>
      'Application source code is under the MIT License (see repository LICENSE).\nStroke outline data is from Make Me a Hanzi (graphics.txt) and must comply with the Arphic Public License; see Third-party notices in the app.';

  @override
  String get hintSeparator => '; ';

  @override
  String get listSeparator => ', ';

  @override
  String get hintEmptyInput => 'Please enter Chinese characters';

  @override
  String hintDictionaryLoadFailed(String error) {
    return 'Failed to load dictionary: $error';
  }

  @override
  String get hintInvalidInput =>
      'Enter at least one Chinese character (Basic Multilingual Plane U+4E00–U+9FFF)';

  @override
  String hintNoMatchingChars(String path) {
    return 'No selected characters are in the dictionary. Check your input or add entries to $path.';
  }

  @override
  String hintMissingChars(String chars) {
    return 'Not in dictionary: $chars';
  }

  @override
  String hintSkippedOverflow(int maxRows, int skipped) {
    return 'Wrapped layout exceeds one A4 page (~$maxRows rows); ignored the last $skipped character(s)';
  }

  @override
  String hintPhysicalOverflow(int usedRows, int maxRows) {
    return 'Wrapped layout uses $usedRows rows, exceeding one A4 page (~$maxRows rows); the bottom may be clipped when printing';
  }
}
