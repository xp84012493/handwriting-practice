import 'dart:ui' show Canvas, Color, Paint, PaintingStyle, Rect, Size, StrokeCap, StrokeJoin;

import 'package:flutter/widgets.dart';

import '../engine/prepared_hanzi_strokes.dart';
import '../style/practice_stroke_colors.dart';
import '../models/stroke_path_convention.dart';

/// 在 [glyphRect] 内绘制笔画。
///
/// - **示范**：[modelStyle] 为 true 时，全部笔画 [completedColor]。
/// - **递进**：[traceStyle] 与 [modelStyle] 均为 false 时，最后一笔 [highlightColor]，其余 [completedColor]。
/// - **描红**：[traceStyle] 为 true 时，所有可见笔画使用 [traceColor]（建议带透明度）。
///
/// 使用 [Canvas.transform] 将规范化 path 映射到米字格，避免每帧 [Path.addPath] 拷贝。
@immutable
class HanziStrokesPainter extends CustomPainter {
  HanziStrokesPainter({
    required this.strokes,
    required this.glyphRect,
    required this.visibleStrokeCount,
    required this.highlightStrokeIndex,
    this.traceStyle = false,
    this.modelStyle = false,
    this.fillStrokes = false,
    this.traceColor = PracticeStrokeColors.trace,
    this.highlightColor = PracticeStrokeColors.highlight,
    this.completedColor = PracticeStrokeColors.completed,
    this.strokePaintWidth = 3.0,
    this.onlyStrokeIndex,
  }) : assert(
         onlyStrokeIndex == null ||
             (visibleStrokeCount >= 1 &&
                 highlightStrokeIndex >= 0 &&
                 highlightStrokeIndex < visibleStrokeCount),
       );

  final PreparedHanziStrokes strokes;
  final Rect glyphRect;

  /// 当前格显示前多少笔（描红/递进时通常为全字或递增笔数）。
  final int visibleStrokeCount;

  /// 递进模式下高亮「新笔」的索引；描红模式下可忽略。
  final int highlightStrokeIndex;

  /// 为 true 时进入描红样式（淡色叠字）。
  final bool traceStyle;

  /// 为 true 时行首完整示范（全笔深灰，无高亮）。
  final bool modelStyle;

  /// 为 true 时用 [PaintingStyle.fill] 实心填充笔画（如图标），避免描边镂空。
  final bool fillStrokes;

  /// 描红颜色（通常含 alpha）。
  final Color traceColor;

  final Color highlightColor;
  final Color completedColor;
  final double strokePaintWidth;

  /// 仅绘制该索引的单笔（笔画示例格）。
  final int? onlyStrokeIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (glyphRect.isEmpty) return;

    final m = strokes.convention.normalizedViewBoxToRect(
      glyphRect,
      strokes.viewBoxWidth,
      strokes.viewBoxHeight,
    );

    canvas.save();
    canvas.transform(m.storage);

    Paint paintFor(Color color) {
      final p = Paint()
        ..color = color
        ..isAntiAlias = true;
      if (fillStrokes) {
        p.style = PaintingStyle.fill;
      } else {
        p
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokePaintWidth
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round;
      }
      return p;
    }

    if (onlyStrokeIndex != null) {
      final i = onlyStrokeIndex!.clamp(0, strokes.strokeCount - 1);
      final p = paintFor(highlightColor);
      canvas.drawPath(strokes.pathsInNormalizedSpace[i], p);
      canvas.restore();
      return;
    }

    if (traceStyle) {
      final p = paintFor(traceColor);
      for (var i = 0; i < visibleStrokeCount; i++) {
        canvas.drawPath(strokes.pathsInNormalizedSpace[i], p);
      }
    } else if (modelStyle) {
      final p = paintFor(completedColor);
      for (var i = 0; i < visibleStrokeCount; i++) {
        canvas.drawPath(strokes.pathsInNormalizedSpace[i], p);
      }
    } else {
      final highlightPaint = paintFor(highlightColor);
      final completedPaint = paintFor(completedColor);

      for (var i = 0; i < visibleStrokeCount; i++) {
        final paint = i == highlightStrokeIndex ? highlightPaint : completedPaint;
        canvas.drawPath(strokes.pathsInNormalizedSpace[i], paint);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant HanziStrokesPainter oldDelegate) {
    return oldDelegate.strokes != strokes ||
        oldDelegate.glyphRect != glyphRect ||
        oldDelegate.visibleStrokeCount != visibleStrokeCount ||
        oldDelegate.highlightStrokeIndex != highlightStrokeIndex ||
        oldDelegate.traceStyle != traceStyle ||
        oldDelegate.modelStyle != modelStyle ||
        oldDelegate.fillStrokes != fillStrokes ||
        oldDelegate.traceColor != traceColor ||
        oldDelegate.highlightColor != highlightColor ||
        oldDelegate.completedColor != completedColor ||
        oldDelegate.strokePaintWidth != strokePaintWidth ||
        oldDelegate.onlyStrokeIndex != onlyStrokeIndex;
  }
}
