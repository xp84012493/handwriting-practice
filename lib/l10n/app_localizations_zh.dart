// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh() : super('zh');

  @override
  String get appTitle => '汉字笔顺字帖';

  @override
  String get aboutTooltip => '关于';

  @override
  String get settingsTooltip => '设置';

  @override
  String get settingsTitle => '设置';

  @override
  String get exportPdfTooltip => '导出 PDF';

  @override
  String get exportSystemPrint => '系统打印…';

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
  String sheetRowSummary(String character, int strokeCount) {
    return '「$character」$strokeCount笔';
  }

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
}
