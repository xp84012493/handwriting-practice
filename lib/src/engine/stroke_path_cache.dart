import 'dart:ui' show Offset, Path;

import 'package:flutter/foundation.dart';
import 'package:path_drawing/path_drawing.dart';

import '../models/stroke_path_convention.dart';

/// SVG `d` 解析结果缓存：避免在滚动/重建时重复解析复杂 path。
///
/// - 线程：仅在 UI isolate 使用（依赖 Flutter 的 [Path]）。
/// - 淘汰策略：简单 LRU，防止极端情况下内存膨胀。
@immutable
class StrokePathCache {
  StrokePathCache({this.maxEntries = 512});

  final int maxEntries;

  final _map = <_CacheKey, Path>{};
  final _lru = <_CacheKey>[];

  Path getOrParse({
    required StrokePathConvention convention,
    required String svgPathData,
  }) {
    final key = _CacheKey(convention, svgPathData);
    final hit = _map[key];
    if (hit != null) {
      _touch(key);
      return hit;
    }
    final parsed = parseSvgPathData(svgPathData);
    final transformed = Path()
      ..addPath(
        parsed,
        Offset.zero,
        matrix4: convention.dataToNormalizedSpace().storage,
      );
    _evictIfNeeded();
    _map[key] = transformed;
    _touch(key);
    return transformed;
  }

  void _touch(_CacheKey key) {
    _lru.remove(key);
    _lru.add(key);
  }

  void _evictIfNeeded() {
    while (_map.length > maxEntries && _lru.isNotEmpty) {
      final k = _lru.removeAt(0);
      _map.remove(k);
    }
  }

  void clear() {
    _map.clear();
    _lru.clear();
  }
}

@immutable
class _CacheKey {
  const _CacheKey(this.convention, this.svgPathData);

  final StrokePathConvention convention;
  final String svgPathData;

  @override
  bool operator ==(Object other) =>
      other is _CacheKey &&
      other.convention == convention &&
      other.svgPathData == svgPathData;

  @override
  int get hashCode => Object.hash(convention, svgPathData);
}
