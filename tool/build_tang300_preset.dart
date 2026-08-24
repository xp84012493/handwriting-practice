// ignore_for_file: avoid_print
//
// Converts tool/tang300_source.json (from github.com/xuchunyang/300) into
// assets/preset_tang300.json for the preset sheet catalog.
//
// Run: dart run tool/build_tang300_preset.dart

import 'dart:convert';
import 'dart:io';

String sanitizeHanzi(String raw) {
  return raw.replaceAll(RegExp(r'[^\u4e00-\u9fff]'), '');
}

String typeEn(String type) => switch (type) {
      '五言古诗' => 'Five-character ancient verse',
      '七言古诗' => 'Seven-character ancient verse',
      '五言绝句' => 'Five-character quatrain',
      '七言绝句' => 'Seven-character quatrain',
      '五言律诗' => 'Five-character regulated verse',
      '七言律诗' => 'Seven-character regulated verse',
      '乐府' => 'Yuefu',
      _ => type,
    };

/// 常见别称 / 检索词（数据源标题与通行名不一致时）。
const _titleAliases = <String, List<String>>{
  '夜思': ['静夜思'],
  '鹿柴': ['鹿砦'],
  '江南曲': ['江南'],
};

void main() {
  const sourcePath = 'tool/tang300_source.json';
  const outPath = 'assets/preset_tang300.json';

  final raw = File(sourcePath).readAsStringSync();
  final poems = jsonDecode(raw) as List<dynamic>;

  final lists = <Map<String, dynamic>>[];
  for (final item in poems) {
    if (item is! Map<String, dynamic>) continue;
    final idNum = item['id'];
    final title = item['title'] as String? ?? '';
    final author = item['author'] as String? ?? '';
    final type = item['type'] as String? ?? '';
    final contents = item['contents'] as String? ?? '';
    final text = sanitizeHanzi(contents);
    if (text.isEmpty || title.isEmpty) continue;

    final presetId = 'tang300_${(idNum as num).toInt().toString().padLeft(3, '0')}';
    final tags = <String>['tang300', 'classic_poetry', author, type, ...?_titleAliases[title]];
    lists.add({
      'id': presetId,
      'sortOrder': (idNum as num).toInt(),
      'section': {
        'zh': type,
        'en': typeEn(type),
        'zh_Hant': type,
      },
      'title': {'zh': title, 'en': title},
      'description': {
        'zh': '$author · $type',
        'en': '$author · ${typeEn(type)}',
        'zh_Hant': '$author · $type',
      },
      'text': text,
      'tags': tags,
    });
  }

  final category = {
    'id': 'classic_poetry',
    'sortOrder': 1,
    'icon': 'auto_stories',
    'title': {
      'zh': '经典诗词',
      'en': 'Classic poetry',
      'zh_Hant': '經典詩詞',
    },
    'lists': lists,
  };

  final output = {
    'schemaVersion': 1,
    'categories': [category],
  };

  final encoder = const JsonEncoder.withIndent('  ');
  File(outPath).writeAsStringSync('${encoder.convert(output)}\n');
  print('Wrote ${lists.length} poems to $outPath (${File(outPath).lengthSync()} bytes)');
}
