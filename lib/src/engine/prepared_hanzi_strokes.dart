import 'dart:ui' show Matrix4, Offset, Path, Rect;

import 'package:flutter/foundation.dart';

import '../models/hanzi_character.dart';
import '../models/stroke_path_convention.dart';
import 'stroke_path_cache.dart';

/// 将某个 [HanziCharacter] 的所有笔画预解析为 [Path]，供绘制与矩阵变换复用。
///
/// 所有 [pathsInNormalizedSpace] 已处于 **Y 向下** 的规范化坐标系（宽 [viewBoxWidth]、
/// 高 [viewBoxHeight]），绘制到米字格时只需再乘一次等比适配矩阵即可。
@immutable
class PreparedHanziStrokes {
  PreparedHanziStrokes._({
    required this.character,
    required this.pathsInNormalizedSpace,
    required this.viewBoxWidth,
    required this.viewBoxHeight,
    required this.convention,
  });

  factory PreparedHanziStrokes.prepare({
    required HanziCharacter model,
    required StrokePathCache cache,
  }) {
    final paths = <Path>[];
    for (final d in model.strokePathData) {
      paths.add(cache.getOrParse(convention: model.convention, svgPathData: d));
    }
    return PreparedHanziStrokes._(
      character: model.character,
      pathsInNormalizedSpace: paths,
      viewBoxWidth: model.viewBoxWidth,
      viewBoxHeight: model.viewBoxHeight,
      convention: model.convention,
    );
  }

  final String character;
  final List<Path> pathsInNormalizedSpace;
  final double viewBoxWidth;
  final double viewBoxHeight;
  final StrokePathConvention convention;

  int get strokeCount => pathsInNormalizedSpace.length;

  Matrix4 _fitMatrix(Rect glyphRect) =>
      convention.normalizedViewBoxToRect(
        glyphRect,
        viewBoxWidth,
        viewBoxHeight,
      );

  /// 将第 [index] 笔映射到 [glyphRect]（米字格内实际书写区）。
  Path pathForStrokeInRect(int index, Rect glyphRect) {
    final m = _fitMatrix(glyphRect);
    return Path()
      ..addPath(pathsInNormalizedSpace[index], Offset.zero, matrix4: m.storage);
  }

  /// 合并多笔到同一局部坐标系（再整体变换）。
  Path combinedPathForIndices(Iterable<int> indices, Rect glyphRect) {
    final m = _fitMatrix(glyphRect);
    final out = Path();
    for (final i in indices) {
      out.addPath(pathsInNormalizedSpace[i], Offset.zero, matrix4: m.storage);
    }
    return out;
  }
}
