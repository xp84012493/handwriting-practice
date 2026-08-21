// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

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
  String get emptyStateBody =>
      'Enter Chinese characters above — one practice row per character.\nExtra content continues on following pages.';

  @override
  String get printPreparing => 'Preparing to print…';

  @override
  String get printBusy => 'Print in progress, please wait';

  @override
  String get printUnavailable =>
      'Printing is not available on this device. Try Share PDF instead.';

  @override
  String get printFallbackShare =>
      'Could not open the print panel. Opening the share sheet — choose Print there.';

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
  String get languageChinese => 'Chinese (Simplified)';

  @override
  String get languageChineseTraditional => 'Chinese (Traditional)';

  @override
  String get languageEnglish => 'English';

  @override
  String get themeTitle => 'Appearance';

  @override
  String get themeFollowSystem => 'System default';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get featureOverviewTitle => 'Overview';

  @override
  String get featureOverviewBody =>
      'Generate stroke-order practice sheets from the built-in dictionary, preview them in the app, and print or export PDF via the system. Multi-page sheets are supported when content exceeds one A4 page.';

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

  @override
  String hintMultiPage(int pageCount) {
    return '$pageCount pages — preview with page controls; print and export include all pages';
  }

  @override
  String sheetPageIndicator(int current, int total) {
    return '$current / $total';
  }

  @override
  String get sheetPagePrevTooltip => 'Previous page';

  @override
  String get sheetPageNextTooltip => 'Next page';

  @override
  String quotaRemaining(int count) {
    return '$count free generations left';
  }

  @override
  String get quotaUnlocked => 'Unlimited access';

  @override
  String get quotaExceededTitle => 'Free limit reached';

  @override
  String quotaExceededBody(int limit) {
    return 'You have used all $limit free sheet generations. Purchase once to unlock unlimited use.';
  }

  @override
  String get upgradeTitle => 'Unlock unlimited';

  @override
  String upgradeOptionalBody(int remaining, int limit) {
    return 'You still have $remaining of $limit free uses. Purchase once for unlimited sheet generation.';
  }

  @override
  String upgradeBuyButton(String price) {
    return 'Unlock for $price';
  }

  @override
  String get upgradeRestoreButton => 'Restore purchase';

  @override
  String get upgradeStoreUnavailable =>
      'The app store is not available on this device.';

  @override
  String get upgradeProductNotConfigured =>
      'In-app purchase is not configured in the store yet.';

  @override
  String get upgradePurchaseSuccess => 'Unlocked. Thank you!';

  @override
  String upgradePurchaseFailed(String error) {
    return 'Purchase failed: $error';
  }

  @override
  String get settingsUpgradeTitle => 'Sheet generation';

  @override
  String settingsUpgradeSubtitleRemaining(int remaining, int limit) {
    return '$remaining of $limit free uses left';
  }

  @override
  String get settingsUpgradeSubtitleUnlocked => 'Unlimited access';

  @override
  String get settingsPurchaseTitle => 'Purchase unlock';

  @override
  String get settingsPurchaseSubtitle =>
      'One-time purchase for unlimited sheets';

  @override
  String get settingsShareTitle => 'Share for free uses';

  @override
  String settingsShareSubtitleAvailable(int bonus, int remaining) {
    return 'Share the app: +$bonus uses each time ($remaining shares left)';
  }

  @override
  String get settingsShareSubtitleDone => 'Share rewards used up';

  @override
  String shareAppMessage(String appTitle, String url) {
    return 'I\'m using $appTitle for Hanzi stroke-order practice sheets — try it:\n$url';
  }

  @override
  String shareRewardGranted(int bonus) {
    return 'Thanks for sharing! +$bonus free generations added.';
  }

  @override
  String get shareRewardLimitReached => 'You\'ve used all share rewards.';

  @override
  String get shareRewardCancelled => 'Share cancelled.';

  @override
  String get shareRewardUnavailable =>
      'Sharing is not available on this device.';

  @override
  String upgradeShareButton(int bonus, int remaining) {
    return 'Share for +$bonus free uses ($remaining left)';
  }

  @override
  String get recentSheetsTooltip => 'Recent sheets';

  @override
  String get recentSheetsTitle => 'Recent sheets';

  @override
  String get recentSheetsEmpty =>
      'No saved sheets yet.\nGenerate a sheet and it will appear here.';

  @override
  String get recentSheetsRestore => 'Restore sheet';

  @override
  String recentSheetsItemSubtitle(int count, String when) {
    return '$count characters · $when';
  }

  @override
  String get recentSheetsSettingsEmpty => 'No saved sheets';

  @override
  String recentSheetsSettingsCount(int count) {
    return '$count saved';
  }

  @override
  String get recentSheetsClearAll => 'Clear all';

  @override
  String get recentSheetsClearAllTitle => 'Clear all recent sheets?';

  @override
  String get recentSheetsClearAllBody =>
      'This removes all saved sheets from this device. It cannot be undone.';

  @override
  String get recentSheetsClearAllCancel => 'Cancel';

  @override
  String get recentSheetsClearAllConfirm => 'Clear';

  @override
  String get recentSheetsSelectAll => 'Select all';

  @override
  String get recentSheetsDelete => 'Delete';

  @override
  String get recentSheetsDeleteSelected => 'Delete selected';

  @override
  String get recentSheetsDeleteSelectedTitle => 'Delete selected sheets?';

  @override
  String recentSheetsDeleteSelectedBody(int count) {
    return 'Delete $count saved sheet(s)? This cannot be undone.';
  }

  @override
  String get navTabPractice => 'Practice';

  @override
  String get sheetConfigTooltip => 'Sheet layout';

  @override
  String get sheetConfigTitle => 'Sheet layout';

  @override
  String get sheetConfigSubtitle =>
      'Each character row: stroke order → trace → blank grids.';

  @override
  String get sheetConfigCellSize => 'Character size';

  @override
  String get sheetConfigCellSizeHint =>
      'Mi-zi grid size. Larger grids mean bigger characters and fewer per page.';

  @override
  String sheetConfigCellSizeValue(int mm) {
    return '$mm mm';
  }

  @override
  String get sheetConfigTraceSlots => 'Trace grids';

  @override
  String get sheetConfigTraceHint =>
      'Semi-transparent character overlays for tracing.';

  @override
  String get sheetConfigBlankSlots => 'Blank grids';

  @override
  String get sheetConfigBlankHint => 'Empty mi zi grids for freehand practice.';

  @override
  String get sheetConfigDone => 'Done';

  @override
  String get presetSheetTitle => 'Preset sheets';

  @override
  String get presetSheetSubtitle =>
      'Pick a character set to fill the input and generate a sheet.';

  @override
  String get presetMoreChip => 'Preset sheets';

  @override
  String get presetOpenAll => 'Browse all presets';

  @override
  String get presetEmptyHint => 'Or choose a preset sheet above';

  @override
  String get presetRecentSection => 'Recently used';

  @override
  String presetCharacterCount(int count) {
    return '$count chars';
  }

  @override
  String get presetLoadFailed => 'Could not load preset sheets';
}
