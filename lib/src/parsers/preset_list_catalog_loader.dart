import 'dart:convert';

import 'package:characters/characters.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/preset_sheet_list.dart';

/// 从 `assets/preset_lists.json` 加载预设生字词表。
class PresetListCatalogLoader {
  const PresetListCatalogLoader();

  static final RegExp _hanzi = RegExp(r'[\u4e00-\u9fff]');

  Future<PresetListCatalog> loadFromAsset({
    String assetPath = PresetListCatalog.assetPath,
  }) async {
    final raw = await rootBundle.loadString(assetPath);
    final json = jsonDecode(raw);
    if (json is! Map<String, dynamic>) {
      throw FormatException('preset_lists 根节点须为 JSON 对象');
    }
    final catalog = PresetListCatalog.fromJson(json);
    _validateHanziText(catalog);
    return catalog;
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
