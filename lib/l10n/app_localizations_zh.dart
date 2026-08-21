// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '笔顺练字帖';

  @override
  String get aboutTooltip => '关于';

  @override
  String get settingsTooltip => '设置';

  @override
  String get settingsTitle => '设置';

  @override
  String get exportPdfTooltip => '导出 PDF';

  @override
  String get exportSystemPrint => '打印…';

  @override
  String get exportSaveFile => '保存 PDF 到文件';

  @override
  String get exportShare => '分享 PDF';

  @override
  String get inputHint => '输入汉字（多字）';

  @override
  String get generateButton => '生成字帖';

  @override
  String emptyStateBody(int maxChars) {
    return '在上方输入多个汉字（每字一行字帖，\nA4 单页约限 $maxChars 字，超出部分将忽略）。';
  }

  @override
  String get printPreparing => '正在准备打印…';

  @override
  String get printBusy => '正在打印，请稍候';

  @override
  String get printUnavailable => '此设备不支持打印，请改用「分享 PDF」';

  @override
  String get printFallbackShare => '无法打开打印面板，已改为分享面板，请选择「打印」';

  @override
  String printFailed(String error) {
    return '打印失败：$error';
  }

  @override
  String get pdfSaved => '已保存 PDF';

  @override
  String get pdfSaveCancelled => '已取消保存';

  @override
  String pdfSaveFailed(String error) {
    return '保存失败：$error';
  }

  @override
  String pdfShareFailed(String error) {
    return '分享失败：$error';
  }

  @override
  String get pdfFileNamePrefix => '练字帖';

  @override
  String get aboutTitle => '关于';

  @override
  String versionLabel(String version) {
    return '版本 $version';
  }

  @override
  String get languageTitle => '语言';

  @override
  String get languageFollowSystem => '跟随系统';

  @override
  String get languageChinese => '简体中文';

  @override
  String get languageChineseTraditional => '繁體中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get themeTitle => '主题';

  @override
  String get themeFollowSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get featureOverviewTitle => '功能简介';

  @override
  String get featureOverviewBody =>
      '根据字库生成汉字笔顺练字帖预览，并可通过系统对话框打印或导出 PDF。当前为多字模式：每字一行版式，具体行数受 A4 可打印区域限制。';

  @override
  String get strokeDataTitle => '笔画数据来源';

  @override
  String get strokeDataBody =>
      '笔画矢量数据来自开源项目 Make Me a Hanzi 的 graphics.txt，基于文鼎 Arphic PL 字体衍生，许可证为 Arphic Public License（1999）。完整第三方声明与链接见下方「第三方说明全文」。';

  @override
  String get thirdPartyNoticesButton => '第三方说明全文';

  @override
  String get openSourceLicensesButton => '开放源代码许可（Flutter 与各依赖）';

  @override
  String get notesTitle => '说明';

  @override
  String get notesBody =>
      '「开放源代码许可」页由 Flutter 汇总本应用及各依赖库的许可证文本；其中可能包含与笔画数据无关的条目。笔画数据以「第三方说明全文」为准。';

  @override
  String get thirdPartyNoticesTitle => '第三方说明';

  @override
  String thirdPartyNoticesLoadError(String error) {
    return '无法加载 THIRD_PARTY_NOTICES.md：$error';
  }

  @override
  String get licenseLegalese =>
      '本应用 Dart/Flutter 源代码以 MIT License 发布（见仓库 LICENSE）。\n笔画轮廓数据来自 Make Me a Hanzi（graphics.txt），再分发须遵守 Arphic Public License；详见应用内「第三方说明」全文。';

  @override
  String get hintSeparator => '；';

  @override
  String get listSeparator => '、';

  @override
  String get hintEmptyInput => '请输入汉字';

  @override
  String hintDictionaryLoadFailed(String error) {
    return '加载字库失败：$error';
  }

  @override
  String get hintInvalidInput => '请输入至少一个汉字（基本区 U+4E00–U+9FFF）';

  @override
  String hintNoMatchingChars(String path) {
    return '字库中暂无所选汉字，请检查输入或扩充 $path。';
  }

  @override
  String hintMissingChars(String chars) {
    return '字库中暂无：$chars';
  }

  @override
  String hintSkippedOverflow(int maxRows, int skipped) {
    return '折行后超出 A4 单页（约 $maxRows 行），已忽略后 $skipped 字';
  }

  @override
  String hintPhysicalOverflow(int usedRows, int maxRows) {
    return '折行后共 $usedRows 行，超出 A4 单页约 $maxRows 行，打印时底部可能被裁切';
  }

  @override
  String quotaRemaining(int count) {
    return '剩余 $count 次免费生成';
  }

  @override
  String get quotaUnlocked => '已解锁，无限次使用';

  @override
  String get quotaExceededTitle => '免费次数已用完';

  @override
  String quotaExceededBody(int limit) {
    return '你已使用完 $limit 次免费生成字帖。一次性购买后可无限生成。';
  }

  @override
  String get upgradeTitle => '解锁无限次';

  @override
  String upgradeOptionalBody(int remaining, int limit) {
    return '你还剩余 $remaining/$limit 次免费生成。如需不限次数，可一次性购买解锁。';
  }

  @override
  String upgradeBuyButton(String price) {
    return '购买解锁（$price）';
  }

  @override
  String get upgradeRestoreButton => '恢复购买';

  @override
  String get upgradeStoreUnavailable => '当前设备无法连接应用商店。';

  @override
  String get upgradeProductNotConfigured => '商店尚未配置内购商品，请稍后再试。';

  @override
  String get upgradePurchaseSuccess => '已解锁，感谢支持！';

  @override
  String upgradePurchaseFailed(String error) {
    return '购买失败：$error';
  }

  @override
  String get settingsUpgradeTitle => '字帖生成';

  @override
  String settingsUpgradeSubtitleRemaining(int remaining, int limit) {
    return '免费剩余 $remaining/$limit 次';
  }

  @override
  String get settingsUpgradeSubtitleUnlocked => '已解锁，无限次';

  @override
  String get settingsPurchaseTitle => '购买解锁';

  @override
  String get settingsPurchaseSubtitle => '一次性购买，无限生成字帖';

  @override
  String get settingsShareTitle => '分享得免费次数';

  @override
  String settingsShareSubtitleAvailable(int bonus, int remaining) {
    return '分享给好友：每次 +$bonus 次（还可分享 $remaining 次）';
  }

  @override
  String get settingsShareSubtitleDone => '分享奖励已领完';

  @override
  String shareAppMessage(String appTitle, String url) {
    return '我在用「$appTitle」练笔顺字帖，推荐给你：\n$url';
  }

  @override
  String shareRewardGranted(int bonus) {
    return '感谢分享！已增加 $bonus 次免费生成';
  }

  @override
  String get shareRewardLimitReached => '分享奖励次数已用完';

  @override
  String get shareRewardCancelled => '已取消分享';

  @override
  String get shareRewardUnavailable => '当前设备无法分享';

  @override
  String upgradeShareButton(int bonus, int remaining) {
    return '分享获得 +$bonus 次（剩余 $remaining 次机会）';
  }

  @override
  String get recentSheetsTooltip => '最近字帖';

  @override
  String get recentSheetsTitle => '最近字帖';

  @override
  String get recentSheetsEmpty => '暂无保存的字帖。\n生成字帖后会自动出现在这里。';

  @override
  String get recentSheetsRestore => '恢复字帖';

  @override
  String recentSheetsItemSubtitle(int count, String when) {
    return '$count 字 · $when';
  }

  @override
  String get recentSheetsSettingsEmpty => '暂无保存';

  @override
  String recentSheetsSettingsCount(int count) {
    return '已保存 $count 条';
  }

  @override
  String get recentSheetsClearAll => '全部清除';

  @override
  String get recentSheetsClearAllTitle => '清除全部最近字帖？';

  @override
  String get recentSheetsClearAllBody => '将删除本机保存的全部字帖记录，且无法恢复。';

  @override
  String get recentSheetsClearAllCancel => '取消';

  @override
  String get recentSheetsClearAllConfirm => '清除';

  @override
  String get recentSheetsSelectAll => '全选';

  @override
  String get recentSheetsDelete => '删除';

  @override
  String get recentSheetsDeleteSelected => '删除所选';

  @override
  String get recentSheetsDeleteSelectedTitle => '删除所选字帖？';

  @override
  String recentSheetsDeleteSelectedBody(int count) {
    return '将删除 $count 条记录，且无法恢复。';
  }

  @override
  String get navTabPractice => '字帖';

  @override
  String get sheetConfigTooltip => '字帖配置';

  @override
  String get sheetConfigTitle => '字帖配置';

  @override
  String get sheetConfigSubtitle => '每字一行：递进笔顺 → 描红 → 空白临摹格。';

  @override
  String get sheetConfigTraceSlots => '描红格数';

  @override
  String get sheetConfigTraceHint => '半透明叠字，供描红练习。';

  @override
  String get sheetConfigBlankSlots => '空白格数';

  @override
  String get sheetConfigBlankHint => '仅米字格，供临摹书写。';

  @override
  String get sheetConfigDone => '完成';

  @override
  String get presetSheetTitle => '预设字帖';

  @override
  String get presetSheetSubtitle => '选择一组生字，将自动填入并生成字帖。';

  @override
  String get presetMoreChip => '更多预设';

  @override
  String get presetOpenAll => '打开全部预设';

  @override
  String get presetEmptyHint => '或在上方选择预设字帖';

  @override
  String get presetRecentSection => '最近用过';

  @override
  String presetCharacterCount(int count) {
    return '$count 字';
  }

  @override
  String get presetLoadFailed => '预设字帖加载失败';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get appTitle => '筆順練字帖';

  @override
  String get aboutTooltip => '關於';

  @override
  String get settingsTooltip => '設定';

  @override
  String get settingsTitle => '設定';

  @override
  String get exportPdfTooltip => '匯出 PDF';

  @override
  String get exportSystemPrint => '列印…';

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
  String get printPreparing => '正在準備列印…';

  @override
  String get printBusy => '正在列印，請稍候';

  @override
  String get printUnavailable => '此裝置不支援列印，請改用「分享 PDF」';

  @override
  String get printFallbackShare => '無法開啟列印面板，已改為分享面板，請選擇「列印」';

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
  String get themeTitle => '主題';

  @override
  String get themeFollowSystem => '跟隨系統';

  @override
  String get themeLight => '淺色';

  @override
  String get themeDark => '深色';

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
    return '折行後超出 A4 單頁（約 $maxRows 行），已忽略後 $skipped 字';
  }

  @override
  String hintPhysicalOverflow(int usedRows, int maxRows) {
    return '折行後共 $usedRows 行，超出 A4 單頁約 $maxRows 行，列印時底部可能被裁切';
  }

  @override
  String quotaRemaining(int count) {
    return '剩餘 $count 次免費生成';
  }

  @override
  String get quotaUnlocked => '已解鎖，無限次使用';

  @override
  String get quotaExceededTitle => '免費次數已用完';

  @override
  String quotaExceededBody(int limit) {
    return '你已使用完 $limit 次免費生成字帖。一次性購買後可無限生成。';
  }

  @override
  String get upgradeTitle => '解鎖無限次';

  @override
  String upgradeOptionalBody(int remaining, int limit) {
    return '你還剩餘 $remaining/$limit 次免費生成。如需不限次數，可一次性購買解鎖。';
  }

  @override
  String upgradeBuyButton(String price) {
    return '購買解鎖（$price）';
  }

  @override
  String get upgradeRestoreButton => '恢復購買';

  @override
  String get upgradeStoreUnavailable => '目前裝置無法連線 App Store。';

  @override
  String get upgradeProductNotConfigured => '商店尚未設定 App 內購買項目，請稍後再試。';

  @override
  String get upgradePurchaseSuccess => '已解鎖，感謝支持！';

  @override
  String upgradePurchaseFailed(String error) {
    return '購買失敗：$error';
  }

  @override
  String get settingsUpgradeTitle => '字帖生成';

  @override
  String settingsUpgradeSubtitleRemaining(int remaining, int limit) {
    return '免費剩餘 $remaining/$limit 次';
  }

  @override
  String get settingsUpgradeSubtitleUnlocked => '已解鎖，無限次';

  @override
  String get settingsPurchaseTitle => '購買解鎖';

  @override
  String get settingsPurchaseSubtitle => '一次性購買，無限生成字帖';

  @override
  String get settingsShareTitle => '分享得免費次數';

  @override
  String settingsShareSubtitleAvailable(int bonus, int remaining) {
    return '分享給好友：每次 +$bonus 次（還可分享 $remaining 次）';
  }

  @override
  String get settingsShareSubtitleDone => '分享獎勵已領完';

  @override
  String shareAppMessage(String appTitle, String url) {
    return '我在用「$appTitle」練筆順字帖，推薦給你：\n$url';
  }

  @override
  String shareRewardGranted(int bonus) {
    return '感謝分享！已增加 $bonus 次免費生成';
  }

  @override
  String get shareRewardLimitReached => '分享獎勵次數已用完';

  @override
  String get shareRewardCancelled => '已取消分享';

  @override
  String get shareRewardUnavailable => '目前裝置無法分享';

  @override
  String upgradeShareButton(int bonus, int remaining) {
    return '分享獲得 +$bonus 次（剩餘 $remaining 次機會）';
  }

  @override
  String get recentSheetsTooltip => '最近字帖';

  @override
  String get recentSheetsTitle => '最近字帖';

  @override
  String get recentSheetsEmpty => '暫無儲存的字帖。\n生成字帖後會自動出現在這裡。';

  @override
  String get recentSheetsRestore => '恢復字帖';

  @override
  String recentSheetsItemSubtitle(int count, String when) {
    return '$count 字 · $when';
  }

  @override
  String get recentSheetsSettingsEmpty => '暫無儲存';

  @override
  String recentSheetsSettingsCount(int count) {
    return '已儲存 $count 條';
  }

  @override
  String get recentSheetsClearAll => '全部清除';

  @override
  String get recentSheetsClearAllTitle => '清除全部最近字帖？';

  @override
  String get recentSheetsClearAllBody => '將刪除本機儲存的全部字帖記錄，且無法復原。';

  @override
  String get recentSheetsClearAllCancel => '取消';

  @override
  String get recentSheetsClearAllConfirm => '清除';

  @override
  String get recentSheetsSelectAll => '全選';

  @override
  String get recentSheetsDelete => '刪除';

  @override
  String get recentSheetsDeleteSelected => '刪除所選';

  @override
  String get recentSheetsDeleteSelectedTitle => '刪除所選字帖？';

  @override
  String recentSheetsDeleteSelectedBody(int count) {
    return '將刪除 $count 條記錄，且無法復原。';
  }

  @override
  String get navTabPractice => '字帖';

  @override
  String get sheetConfigTooltip => '字帖設定';

  @override
  String get sheetConfigTitle => '字帖設定';

  @override
  String get sheetConfigSubtitle => '每字一行：遞進筆順 → 描紅 → 空白臨摹格。';

  @override
  String get sheetConfigTraceSlots => '描紅格數';

  @override
  String get sheetConfigTraceHint => '半透明疊字，供描紅練習。';

  @override
  String get sheetConfigBlankSlots => '空白格數';

  @override
  String get sheetConfigBlankHint => '僅米字格，供臨摹書寫。';

  @override
  String get sheetConfigDone => '完成';

  @override
  String get presetSheetTitle => '預設字帖';

  @override
  String get presetSheetSubtitle => '選擇一組生字，將自動填入並生成字帖。';

  @override
  String get presetMoreChip => '更多預設';

  @override
  String get presetOpenAll => '打開全部預設';

  @override
  String get presetEmptyHint => '或在上方選擇預設字帖';

  @override
  String get presetRecentSection => '最近用過';

  @override
  String presetCharacterCount(int count) {
    return '$count 字';
  }

  @override
  String get presetLoadFailed => '預設字帖載入失敗';
}
