import 'package:characters/characters.dart';

import 'stroke_path_convention.dart';

/// 单个汉字的笔画路径数据（每笔一条 SVG path `d` 字符串）。
///
/// 兼容：
/// - 本地 JSON：`{ "character": "永", "strokes": ["M...", ...] }`
/// - Make Me a Hanzi `graphics.txt` 每行 JSON：`character` + `strokes`
class HanziCharacter {
  const HanziCharacter({
    required this.character,
    required this.strokePathData,
    this.convention = StrokePathConvention.makemeahanzi1024,
    this.viewBoxWidth = 1024,
    this.viewBoxHeight = 1024,
    this.medians,
  }) : assert(character.characters.length == 1, 'character 应为单个 Unicode 字符'),
       assert(strokePathData.isNotEmpty, '至少应有一笔'),
       assert(viewBoxWidth > 0 && viewBoxHeight > 0);

  /// 单字（一个 grapheme cluster 的简化假设：一个 code unit 常见汉字）。
  final String character;

  /// 按笔顺排列的 SVG path 字符串。
  final List<String> strokePathData;

  /// 路径坐标约定（决定是否需要 Y 翻转等）。
  final StrokePathConvention convention;

  /// 逻辑 viewBox 宽度（用于缩放进米字格）。MMaH 为 1024。
  final double viewBoxWidth;

  /// 逻辑 viewBox 高度。
  final double viewBoxHeight;

  /// 可选：MMaH 的 medians，与 `strokes` 同序；本引擎绘制笔画轮廓时不使用，仅保留字段便于扩展动画。
  final List<List<List<int>>>? medians;

  int get strokeCount => strokePathData.length;

  HanziCharacter copyWith({
    String? character,
    List<String>? strokePathData,
    StrokePathConvention? convention,
    double? viewBoxWidth,
    double? viewBoxHeight,
    List<List<List<int>>>? medians,
  }) {
    return HanziCharacter(
      character: character ?? this.character,
      strokePathData: strokePathData ?? this.strokePathData,
      convention: convention ?? this.convention,
      viewBoxWidth: viewBoxWidth ?? this.viewBoxWidth,
      viewBoxHeight: viewBoxHeight ?? this.viewBoxHeight,
      medians: medians ?? this.medians,
    );
  }
}
