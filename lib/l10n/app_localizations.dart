import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'Hanzi Stroke Practice'**
  String get appTitle;

  /// No description provided for @aboutTooltip.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTooltip;

  /// No description provided for @settingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @exportPdfTooltip.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdfTooltip;

  /// No description provided for @exportSystemPrint.
  ///
  /// In en, this message translates to:
  /// **'Print…'**
  String get exportSystemPrint;

  /// No description provided for @exportSaveFile.
  ///
  /// In en, this message translates to:
  /// **'Save PDF to file'**
  String get exportSaveFile;

  /// No description provided for @exportShare.
  ///
  /// In en, this message translates to:
  /// **'Share PDF'**
  String get exportShare;

  /// No description provided for @inputHint.
  ///
  /// In en, this message translates to:
  /// **'Enter Chinese characters'**
  String get inputHint;

  /// No description provided for @generateButton.
  ///
  /// In en, this message translates to:
  /// **'Generate sheet'**
  String get generateButton;

  /// No description provided for @emptyStateBody.
  ///
  /// In en, this message translates to:
  /// **'Enter multiple characters above (one row per character on the sheet).\nAbout {maxChars} characters fit on one A4 page; extra characters are ignored.'**
  String emptyStateBody(int maxChars);

  /// No description provided for @sheetRowSummary.
  ///
  /// In en, this message translates to:
  /// **'「{character}」{strokeCount} strokes'**
  String sheetRowSummary(String character, int strokeCount);

  /// No description provided for @printFailed.
  ///
  /// In en, this message translates to:
  /// **'Print failed: {error}'**
  String printFailed(String error);

  /// No description provided for @pdfSaved.
  ///
  /// In en, this message translates to:
  /// **'PDF saved'**
  String get pdfSaved;

  /// No description provided for @pdfSaveCancelled.
  ///
  /// In en, this message translates to:
  /// **'Save cancelled'**
  String get pdfSaveCancelled;

  /// No description provided for @pdfSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String pdfSaveFailed(String error);

  /// No description provided for @pdfShareFailed.
  ///
  /// In en, this message translates to:
  /// **'Share failed: {error}'**
  String pdfShareFailed(String error);

  /// No description provided for @pdfFileNamePrefix.
  ///
  /// In en, this message translates to:
  /// **'PracticeSheet'**
  String get pdfFileNamePrefix;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionLabel(String version);

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageFollowSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageFollowSystem;

  /// No description provided for @languageChinese.
  ///
  /// In en, this message translates to:
  /// **'Chinese (Simplified)'**
  String get languageChinese;

  /// No description provided for @languageChineseTraditional.
  ///
  /// In en, this message translates to:
  /// **'Chinese (Traditional)'**
  String get languageChineseTraditional;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @themeTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get themeTitle;

  /// No description provided for @themeFollowSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get themeFollowSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @featureOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get featureOverviewTitle;

  /// No description provided for @featureOverviewBody.
  ///
  /// In en, this message translates to:
  /// **'Generate stroke-order practice sheets from the built-in dictionary, preview them in the app, and print or export PDF via the system.'**
  String get featureOverviewBody;

  /// No description provided for @strokeDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Stroke data'**
  String get strokeDataTitle;

  /// No description provided for @strokeDataBody.
  ///
  /// In en, this message translates to:
  /// **'Stroke outlines come from Make Me a Hanzi graphics.txt, derived from Arphic PL fonts under the Arphic Public License (1999). See Third-party notices below for the full statement.'**
  String get strokeDataBody;

  /// No description provided for @thirdPartyNoticesButton.
  ///
  /// In en, this message translates to:
  /// **'Third-party notices'**
  String get thirdPartyNoticesButton;

  /// No description provided for @openSourceLicensesButton.
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get openSourceLicensesButton;

  /// No description provided for @notesTitle.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get notesTitle;

  /// No description provided for @notesBody.
  ///
  /// In en, this message translates to:
  /// **'The open-source licenses screen lists this app and its dependencies. Stroke data is governed by the third-party notices above.'**
  String get notesBody;

  /// No description provided for @thirdPartyNoticesTitle.
  ///
  /// In en, this message translates to:
  /// **'Third-party notices'**
  String get thirdPartyNoticesTitle;

  /// No description provided for @thirdPartyNoticesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load THIRD_PARTY_NOTICES.md: {error}'**
  String thirdPartyNoticesLoadError(String error);

  /// No description provided for @licenseLegalese.
  ///
  /// In en, this message translates to:
  /// **'Application source code is under the MIT License (see repository LICENSE).\nStroke outline data is from Make Me a Hanzi (graphics.txt) and must comply with the Arphic Public License; see Third-party notices in the app.'**
  String get licenseLegalese;

  /// No description provided for @hintSeparator.
  ///
  /// In en, this message translates to:
  /// **'; '**
  String get hintSeparator;

  /// No description provided for @listSeparator.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get listSeparator;

  /// No description provided for @hintEmptyInput.
  ///
  /// In en, this message translates to:
  /// **'Please enter Chinese characters'**
  String get hintEmptyInput;

  /// No description provided for @hintDictionaryLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load dictionary: {error}'**
  String hintDictionaryLoadFailed(String error);

  /// No description provided for @hintInvalidInput.
  ///
  /// In en, this message translates to:
  /// **'Enter at least one Chinese character (Basic Multilingual Plane U+4E00–U+9FFF)'**
  String get hintInvalidInput;

  /// No description provided for @hintNoMatchingChars.
  ///
  /// In en, this message translates to:
  /// **'No selected characters are in the dictionary. Check your input or add entries to {path}.'**
  String hintNoMatchingChars(String path);

  /// No description provided for @hintMissingChars.
  ///
  /// In en, this message translates to:
  /// **'Not in dictionary: {chars}'**
  String hintMissingChars(String chars);

  /// No description provided for @hintSkippedOverflow.
  ///
  /// In en, this message translates to:
  /// **'Wrapped layout exceeds one A4 page (~{maxRows} rows); ignored the last {skipped} character(s)'**
  String hintSkippedOverflow(int maxRows, int skipped);

  /// No description provided for @hintPhysicalOverflow.
  ///
  /// In en, this message translates to:
  /// **'Wrapped layout uses {usedRows} rows, exceeding one A4 page (~{maxRows} rows); the bottom may be clipped when printing'**
  String hintPhysicalOverflow(int usedRows, int maxRows);

  /// No description provided for @quotaRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} free generations left'**
  String quotaRemaining(int count);

  /// No description provided for @quotaUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlimited access'**
  String get quotaUnlocked;

  /// No description provided for @quotaExceededTitle.
  ///
  /// In en, this message translates to:
  /// **'Free limit reached'**
  String get quotaExceededTitle;

  /// No description provided for @quotaExceededBody.
  ///
  /// In en, this message translates to:
  /// **'You have used all {limit} free sheet generations. Purchase once to unlock unlimited use.'**
  String quotaExceededBody(int limit);

  /// No description provided for @upgradeTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock unlimited'**
  String get upgradeTitle;

  /// No description provided for @upgradeOptionalBody.
  ///
  /// In en, this message translates to:
  /// **'You still have {remaining} of {limit} free uses. Purchase once for unlimited sheet generation.'**
  String upgradeOptionalBody(int remaining, int limit);

  /// No description provided for @upgradeBuyButton.
  ///
  /// In en, this message translates to:
  /// **'Unlock for {price}'**
  String upgradeBuyButton(String price);

  /// No description provided for @upgradeStoreUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The app store is not available on this device.'**
  String get upgradeStoreUnavailable;

  /// No description provided for @upgradeProductNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'In-app purchase is not configured in the store yet.'**
  String get upgradeProductNotConfigured;

  /// No description provided for @upgradePurchaseSuccess.
  ///
  /// In en, this message translates to:
  /// **'Unlocked. Thank you!'**
  String get upgradePurchaseSuccess;

  /// No description provided for @upgradePurchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchase failed: {error}'**
  String upgradePurchaseFailed(String error);

  /// No description provided for @settingsUpgradeTitle.
  ///
  /// In en, this message translates to:
  /// **'Sheet generation'**
  String get settingsUpgradeTitle;

  /// No description provided for @settingsUpgradeSubtitleRemaining.
  ///
  /// In en, this message translates to:
  /// **'{remaining} of {limit} free uses left'**
  String settingsUpgradeSubtitleRemaining(int remaining, int limit);

  /// No description provided for @settingsUpgradeSubtitleUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlimited access'**
  String get settingsUpgradeSubtitleUnlocked;

  /// No description provided for @settingsPurchaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Purchase unlock'**
  String get settingsPurchaseTitle;

  /// No description provided for @settingsPurchaseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One-time purchase for unlimited sheets'**
  String get settingsPurchaseSubtitle;

  /// No description provided for @settingsShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share for free uses'**
  String get settingsShareTitle;

  /// No description provided for @settingsShareSubtitleAvailable.
  ///
  /// In en, this message translates to:
  /// **'Share the app: +{bonus} uses each time ({remaining} shares left)'**
  String settingsShareSubtitleAvailable(int bonus, int remaining);

  /// No description provided for @settingsShareSubtitleDone.
  ///
  /// In en, this message translates to:
  /// **'Share rewards used up'**
  String get settingsShareSubtitleDone;

  /// No description provided for @shareAppMessage.
  ///
  /// In en, this message translates to:
  /// **'I\'m using {appTitle} for Hanzi stroke-order practice sheets — try it:\n{url}'**
  String shareAppMessage(String appTitle, String url);

  /// No description provided for @shareRewardGranted.
  ///
  /// In en, this message translates to:
  /// **'Thanks for sharing! +{bonus} free generations added.'**
  String shareRewardGranted(int bonus);

  /// No description provided for @shareRewardLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used all share rewards.'**
  String get shareRewardLimitReached;

  /// No description provided for @shareRewardCancelled.
  ///
  /// In en, this message translates to:
  /// **'Share cancelled.'**
  String get shareRewardCancelled;

  /// No description provided for @shareRewardUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Sharing is not available on this device.'**
  String get shareRewardUnavailable;

  /// No description provided for @upgradeShareButton.
  ///
  /// In en, this message translates to:
  /// **'Share for +{bonus} free uses ({remaining} left)'**
  String upgradeShareButton(int bonus, int remaining);

  /// No description provided for @recentSheetsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Recent sheets'**
  String get recentSheetsTooltip;

  /// No description provided for @recentSheetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent sheets'**
  String get recentSheetsTitle;

  /// No description provided for @recentSheetsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved sheets yet.\nGenerate a sheet and it will appear here.'**
  String get recentSheetsEmpty;

  /// No description provided for @recentSheetsRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore sheet'**
  String get recentSheetsRestore;

  /// No description provided for @recentSheetsItemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} characters · {when}'**
  String recentSheetsItemSubtitle(int count, String when);

  /// No description provided for @recentSheetsSettingsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved sheets'**
  String get recentSheetsSettingsEmpty;

  /// No description provided for @recentSheetsSettingsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} saved'**
  String recentSheetsSettingsCount(int count);

  /// No description provided for @recentSheetsClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get recentSheetsClearAll;

  /// No description provided for @recentSheetsClearAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear all recent sheets?'**
  String get recentSheetsClearAllTitle;

  /// No description provided for @recentSheetsClearAllBody.
  ///
  /// In en, this message translates to:
  /// **'This removes all saved sheets from this device. It cannot be undone.'**
  String get recentSheetsClearAllBody;

  /// No description provided for @recentSheetsClearAllCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get recentSheetsClearAllCancel;

  /// No description provided for @recentSheetsClearAllConfirm.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get recentSheetsClearAllConfirm;

  /// No description provided for @recentSheetsSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get recentSheetsSelectAll;

  /// No description provided for @recentSheetsDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get recentSheetsDelete;

  /// No description provided for @recentSheetsDeleteSelected.
  ///
  /// In en, this message translates to:
  /// **'Delete selected'**
  String get recentSheetsDeleteSelected;

  /// No description provided for @recentSheetsDeleteSelectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete selected sheets?'**
  String get recentSheetsDeleteSelectedTitle;

  /// No description provided for @recentSheetsDeleteSelectedBody.
  ///
  /// In en, this message translates to:
  /// **'Delete {count} saved sheet(s)? This cannot be undone.'**
  String recentSheetsDeleteSelectedBody(int count);

  /// No description provided for @navTabPractice.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get navTabPractice;

  /// No description provided for @sheetConfigTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sheet layout'**
  String get sheetConfigTooltip;

  /// No description provided for @sheetConfigTitle.
  ///
  /// In en, this message translates to:
  /// **'Sheet layout'**
  String get sheetConfigTitle;

  /// No description provided for @sheetConfigSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Each character row: stroke order → trace → blank grids.'**
  String get sheetConfigSubtitle;

  /// No description provided for @sheetConfigTraceSlots.
  ///
  /// In en, this message translates to:
  /// **'Trace grids'**
  String get sheetConfigTraceSlots;

  /// No description provided for @sheetConfigTraceHint.
  ///
  /// In en, this message translates to:
  /// **'Semi-transparent character overlays for tracing.'**
  String get sheetConfigTraceHint;

  /// No description provided for @sheetConfigBlankSlots.
  ///
  /// In en, this message translates to:
  /// **'Blank grids'**
  String get sheetConfigBlankSlots;

  /// No description provided for @sheetConfigBlankHint.
  ///
  /// In en, this message translates to:
  /// **'Empty mi zi grids for freehand practice.'**
  String get sheetConfigBlankHint;

  /// No description provided for @sheetConfigDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get sheetConfigDone;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
