import 'package:flutter/material.dart';

import '../engine/prepared_hanzi_strokes.dart';
import '../engine/stroke_path_cache.dart';
import '../models/hanzi_character.dart';
import 'hanzi_practice_cell.dart';

/// 输入一个 [HanziCharacter]，生成「一笔一格」递进米字格列表。
///
/// 性能要点：
/// - [PreparedHanziStrokes] 在 [initState] 中只构建一次，避免滚动时重复解析 SVG。
/// - 每格 [RepaintBoundary]（见 [HanziPracticeCell]）。
/// - [ListView.builder] / [SliverChildBuilderDelegate] 懒构建可见区域。
class ProgressiveHanziPractice extends StatefulWidget {
  const ProgressiveHanziPractice({
    super.key,
    required this.character,
    this.cache,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.cellSpacing = 16,
    this.strokeWidth = 3,
    this.physics = const BouncingScrollPhysics(),
  });

  final HanziCharacter character;

  /// 可注入共享缓存（例如多个字共用同一 [StrokePathCache]）。
  final StrokePathCache? cache;

  final EdgeInsets padding;
  final double cellSpacing;
  final double strokeWidth;
  final ScrollPhysics physics;

  @override
  State<ProgressiveHanziPractice> createState() =>
      _ProgressiveHanziPracticeState();
}

class _ProgressiveHanziPracticeState extends State<ProgressiveHanziPractice> {
  StrokePathCache? _ownedCache;
  late PreparedHanziStrokes _prepared;

  StrokePathCache get _cache => widget.cache ?? (_ownedCache ??= StrokePathCache());

  @override
  void initState() {
    super.initState();
    _prepared = PreparedHanziStrokes.prepare(
      model: widget.character,
      cache: _cache,
    );
  }

  @override
  void didUpdateWidget(covariant ProgressiveHanziPractice oldWidget) {
    super.didUpdateWidget(oldWidget);
    final characterChanged = oldWidget.character != widget.character;
    final cacheChanged = oldWidget.cache != widget.cache;
    if (characterChanged || cacheChanged) {
      if (characterChanged && widget.cache == null) {
        _ownedCache?.clear();
      }
      _prepared = PreparedHanziStrokes.prepare(
        model: widget.character,
        cache: _cache,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = _prepared.strokeCount;

    return ListView.separated(
      physics: widget.physics,
      padding: widget.padding,
      itemCount: n,
      separatorBuilder: (_, __) => SizedBox(height: widget.cellSpacing),
      itemBuilder: (context, index) {
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: HanziPracticeCell(
              prepared: _prepared,
              stepIndex: index,
              strokeWidth: widget.strokeWidth.toDouble(),
            ),
          ),
        );
      },
    );
  }
}
