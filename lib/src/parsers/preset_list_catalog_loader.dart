import 'dart:convert';

import 'package:characters/characters.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/preset_sheet_list.dart';

/// 从 assets 加载预设生字词表（基础 + 唐诗三百首等扩展包）。
class PresetListCatalogLoader {
  const PresetListCatalogLoader();

  static const String tang300AssetPath = 'assets/preset_tang300.json';

  static final RegExp _hanzi = RegExp(r'[\u4e00-\u9fff]');

  Future<PresetListCatalog> loadFromAsset({
    String assetPath = PresetListCatalog.assetPath,
    bool includeTang300 = true,
  }) async {
    final catalogs = <PresetListCatalog>[
      await _loadSingle(assetPath),
    ];
    if (includeTang300) {
      catalogs.add(await _loadSingle(tang300AssetPath));
    }
    final catalog = PresetListCatalog.merge(catalogs);
    _validateHanziText(catalog);
    return catalog;
  }

  Future<PresetListCatalog> _loadSingle(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    final json = jsonDecode(raw);
    if (json is! Map<String, dynamic>) {
      throw FormatException('$assetPath 根节点须为 JSON 对象');
    }
    return PresetListCatalog.fromJson(json);
  }

  /// 仅保留基本汉字，与 [PracticeSheetController] 输入规则一致。
  static String sanitizeHanziText(String raw) {
    return raw.characters
        .where((ch) => _hanzi.hasMatch(ch))
        .join();
  }

  void _validateHanziText(PresetListCatalog catalog) {
    for (final list in catalog.allLists) {
      final sanitized = sanitizeHanziText(list.text);
      if (sanitized.isEmpty) {
        throw FormatException('PresetSheetList.${list.id} text 无有效汉字');
      }
      if (sanitized != list.text) {
        throw FormatException(
          'PresetSheetList.${list.id} text 含非汉字字符，请仅保留 U+4E00–U+9FFF',
        );
      }
    }
  }
}
