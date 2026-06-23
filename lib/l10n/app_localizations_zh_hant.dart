// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

/// The translations for Chinese Traditional (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizations {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get appTitle => '漢字筆順字帖';

  @override
  String get aboutTooltip => '關於';

  @override
  String get settingsTooltip => '設定';

  @override
  String get settingsTitle => '設定';

  @override
  String get exportPdfTooltip => '匯出 PDF';

  @override
  String get exportSystemPrint => '系統列印…';

  @override
  String get exportSaveFile => '儲存 PDF 到檔案';

  @override
  String get exportShare => '分享 PDF';

  @override
  String get inputHint => '輸入漢字（多字）';

  @override
  String get generateButton => '生成字帖';

  @override
  String emptyStateBody(int maxChars) {
    return '在上方輸入多個漢字（每字一行字帖，\nA4 單頁約限 $maxChars 字，超出部分將忽略）。';
  }

  @override
  String sheetRowSummary(String character, int strokeCount) {
    return '「$character」$strokeCount筆';
  }

  @override
  String printFailed(String error) {
    return '列印失敗：$error';
  }

  @override
  String get pdfSaved => '已儲存 PDF';

  @override
  String get pdfSaveCancelled => '已取消儲存';

  @override
  String pdfSaveFailed(String error) {
    return '儲存失敗：$error';
  }

  @override
  String pdfShareFailed(String error) {
    return '分享失敗：$error';
  }

  @override
  String get pdfFileNamePrefix => '練字帖';

  @override
  String get aboutTitle => '關於';

  @override
  String versionLabel(String version) {
    return '版本 $version';
  }

  @override
  String get languageTitle => '語言';

  @override
  String get languageFollowSystem => '跟隨系統';

  @override
  String get languageChinese => '簡體中文';

  @override
  String get languageChineseTraditional => '繁體中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get featureOverviewTitle => '功能簡介';

  @override
  String get featureOverviewBody =>
      '根據字庫生成漢字筆順練字帖預覽，並可透過系統對話方塊列印或匯出 PDF。目前為多字模式：每字一行版式，具體行數受 A4 可列印區域限制。';

  @override
  String get strokeDataTitle => '筆畫資料來源';

  @override
  String get strokeDataBody =>
      '筆畫向量資料來自開源專案 Make Me a Hanzi 的 graphics.txt，基於文鼎 Arphic PL 字體衍生，授權條款為 Arphic Public License（1999）。完整第三方聲明與連結見下方「第三方說明全文」。';

  @override
  String get thirdPartyNoticesButton => '第三方說明全文';

  @override
  String get openSourceLicensesButton => '開放原始碼授權（Flutter 與各依賴）';

  @override
  String get notesTitle => '說明';

  @override
  String get notesBody =>
      '「開放原始碼授權」頁由 Flutter 彙總本應用及各依賴庫的授權條款文本；其中可能包含與筆畫資料無關的條目。筆畫資料以「第三方說明全文」為準。';

  @override
  String get thirdPartyNoticesTitle => '第三方說明';

  @override
  String thirdPartyNoticesLoadError(String error) {
    return '無法載入 THIRD_PARTY_NOTICES.md：$error';
  }

  @override
  String get licenseLegalese =>
      '本應用 Dart/Flutter 原始碼以 MIT License 發布（見倉庫 LICENSE）。\n筆畫輪廓資料來自 Make Me a Hanzi（graphics.txt），再分發須遵守 Arphic Public License；詳見應用內「第三方說明」全文。';

  @override
  String get hintSeparator => '；';

  @override
  String get listSeparator => '、';

  @override
  String get hintEmptyInput => '請輸入漢字';

  @override
  String hintDictionaryLoadFailed(String error) {
    return '載入字庫失敗：$error';
  }

  @override
  String get hintInvalidInput => '請輸入至少一個漢字（基本區 U+4E00–U+9FFF）';

  @override
  String hintNoMatchingChars(String path) {
    return '字庫中暫無所選漢字，請檢查輸入或擴充 $path。';
  }

  @override
  String hintMissingChars(String chars) {
    return '字庫中暫無：$chars';
  }

  @override
  String hintSkippedOverflow(int maxRows, int skipped) {
    return '折行後超出 A4 單頁（約 $maxRows} 行），已忽略後 $skipped 字';
  }

  @override
  String hintPhysicalOverflow(int usedRows, int maxRows) {
    return '折行後共 $usedRows 行，超出 A4 單頁約 $maxRows 行，列印時底部可能被裁切';
  }
}
