import 'package:flutter/widgets.dart';

/// 多语言展示文案（与 App 的 zh / en / zh_Hant 对应）。
class LocalizedLabel {
  const LocalizedLabel({
    required this.zh,
    this.en,
    this.zhHant,
  });

  final String zh;
  final String? en;
  final String? zhHant;

  /// 按 [Locale] 选取文案；缺省回退到 [zh]。
  String resolve(Locale locale) {
    if (locale.languageCode == 'en') {
      return en ?? zh;
    }
    if (locale.languageCode == 'zh') {
      if (locale.scriptCode == 'Hant') {
        return zhHant ?? zh;
      }
      return zh;
    }
    return en ?? zh;
  }

  factory LocalizedLabel.fromJson(Map<String, dynamic> json) {
    final zh = json['zh'];
    if (zh is! String || zh.trim().isEmpty) {
      throw FormatException('LocalizedLabel 缺少有效的 zh 字段');
    }
    return LocalizedLabel(
      zh: zh.trim(),
      en: _optionalString(json['en']),
      zhHant: _optionalString(json['zh_Hant']),
    );
  }

  Map<String, dynamic> toJson() => {
        'zh': zh,
        if (en != null) 'en': en,
        if (zhHant != null) 'zh_Hant': zhHant,
      };

  static String? _optionalString(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
