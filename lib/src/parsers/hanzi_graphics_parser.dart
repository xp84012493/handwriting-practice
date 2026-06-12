import 'dart:convert';

import 'package:characters/characters.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/hanzi_character.dart';
import '../models/stroke_path_convention.dart';

/// 从 JSON 解析 [HanziCharacter]。
///
/// 支持对象格式：
/// ```json
/// {
///   "character": "永",
///   "strokes": ["M ...", "M ..."],
///   "convention": "makemeahanzi1024"
/// }
/// ```
///
/// `convention` 可省略，默认 [StrokePathConvention.makemeahanzi1024]。
/// 若你的数据已是常规 SVG（Y 向下），传 `"svgTopLeftYDown"`。
class HanziGraphicsParser {
  const HanziGraphicsParser();

  HanziCharacter parseObject(Map<String, dynamic> json) {
    final rawChar = json['character'];
    if (rawChar is! String || rawChar.isEmpty) {
      throw FormatException('缺少有效的 character 字段');
    }
    final ch = rawChar.characters.first;

    final strokes = json['strokes'];
    if (strokes is! List || strokes.isEmpty) {
      throw FormatException('strokes 必须为非空数组');
    }
    final paths = strokes.map((e) {
      if (e is! String || e.trim().isEmpty) {
        throw FormatException('每笔 strokes 元素应为非空字符串');
      }
      return e.trim();
    }).toList(growable: false);

    final convention = _parseConvention(json['convention']);
    final vw = (json['viewBoxWidth'] as num?)?.toDouble() ?? 1024;
    final vh = (json['viewBoxHeight'] as num?)?.toDouble() ?? 1024;

    List<List<List<int>>>? medians;
    final m = json['medians'];
    if (m is List) {
      medians = m.map((stroke) {
        if (stroke is! List) {
          throw FormatException('medians 格式错误');
        }
        return stroke.map((pt) {
          if (pt is! List || pt.length < 2) {
            throw FormatException('median 点格式错误');
          }
          return [(pt[0] as num).toInt(), (pt[1] as num).toInt()];
        }).toList(growable: false);
      }).toList(growable: false);
    }

    return HanziCharacter(
      character: ch,
      strokePathData: paths,
      convention: convention,
      viewBoxWidth: vw,
      viewBoxHeight: vh,
      medians: medians,
    );
  }

  HanziCharacter parseJsonString(String source) {
    final decoded = json.decode(source);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('根节点必须是 JSON 对象');
    }
    return parseObject(decoded);
  }

  Future<HanziCharacter> loadFromAsset(String assetPath) async {
    final s = await rootBundle.loadString(assetPath);
    return parseJsonString(s);
  }

  List<HanziCharacter> parseJsonArrayString(String source) {
    final decoded = json.decode(source);
    if (decoded is! List) {
      throw FormatException('根节点必须是 JSON 数组');
    }
    return decoded.map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      return parseObject(map);
    }).toList(growable: false);
  }

  Future<List<HanziCharacter>> loadDictionaryFromAsset(String assetPath) async {
    final s = await rootBundle.loadString(assetPath);
    return parseJsonArrayString(s);
  }

  StrokePathConvention _parseConvention(Object? raw) {
    if (raw == null) return StrokePathConvention.makemeahanzi1024;
    if (raw is String) {
      switch (raw) {
        case 'svgTopLeftYDown':
          return StrokePathConvention.svgTopLeftYDown;
        case 'makemeahanzi1024':
          return StrokePathConvention.makemeahanzi1024;
        default:
          throw FormatException('未知 convention: $raw');
      }
    }
    throw FormatException('convention 必须是字符串或省略');
  }

  /// 解析 Make Me a Hanzi 的 `graphics.txt`：每行一个 JSON 对象。
  ///
  /// 会跳过空行与 `#` 开头的注释行。
  List<HanziCharacter> parseGraphicsTxt(String contents) {
    final out = <HanziCharacter>[];
    for (final raw in const LineSplitter().convert(contents)) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      out.add(parseJsonString(line));
    }
    return out;
  }
}
