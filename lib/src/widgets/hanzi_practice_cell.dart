import 'package:flutter/material.dart';

import '../engine/prepared_hanzi_strokes.dart';
import '../painters/hanzi_strokes_painter.dart';
import '../painters/mizi_grid_painter.dart';

/// 练字格展示类型。
enum HanziPracticeCellKind {
  /// 递进笔顺：第 [stepIndex] 笔高亮。
  progressive,

  /// 完整叠字（淡色），供描红。
  trace,

  /// 仅米字格，供临摹自写。
  blank,
}

/// 单个练字格：米字格 + 笔画绘制（递进 / 描红 / 空白）。
///
/// 使用 [RepaintBoundary] 将重绘隔离在格内。
class HanziPracticeCell extends StatelessWidget {
  const HanziPracticeCell({
    super.key,
    required this.prepared,
    this.kind = HanziPracticeCellKind.progressive,
    this.stepIndex = 0,
    this.glyphInsetFraction = 0.14,
    this.strokeWidth = 3.0,
    this.traceColor = const Color(0x66888888),
  }) : assert(stepIndex >= 0);

  final PreparedHanziStrokes prepared;
  final HanziPracticeCellKind kind;

  /// 仅 [HanziPracticeCellKind.progressive] 使用：从 0 起为第 1 笔递进。
  final int stepIndex;

  final double glyphInsetFraction;
  final double strokeWidth;
  final Color traceColor;

  @override
  Widget build(BuildContext context) {
    final n = prepared.strokeCount;
    final safeStep = stepIndex.clamp(0, n - 1);
    final progressiveVisible = safeStep + 1;

    return AspectRatio(
      aspectRatio: 1,
      child: RepaintBoundary(
        child: LayoutBuilder(
          builder: (context, c) {
            final side = c.maxWidth;
            final inset = side * glyphInsetFraction;
            final glyphRect = Rect.fromLTRB(
              inset,
              inset,
              side - inset,
              side - inset,
            );

            return Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: MiziGridPainter(),
                  size: Size(side, side),
                ),
                if (kind != HanziPracticeCellKind.blank)
                  CustomPaint(
                    painter: kind == HanziPracticeCellKind.trace
                        ? HanziStrokesPainter(
                            strokes: prepared,
                            glyphRect: glyphRect,
                            visibleStrokeCount: n,
                            highlightStrokeIndex: 0,
                            traceStyle: true,
                            traceColor: traceColor,
                            strokePaintWidth: strokeWidth,
                          )
                        : HanziStrokesPainter(
                            strokes: prepared,
                            glyphRect: glyphRect,
                            visibleStrokeCount: progressiveVisible,
                            highlightStrokeIndex: safeStep,
                            strokePaintWidth: strokeWidth,
                          ),
                    size: Size(side, side),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
