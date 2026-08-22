import 'package:flutter/material.dart';

import '../engine/prepared_hanzi_strokes.dart';
import '../painters/hanzi_strokes_painter.dart';
import '../painters/mizi_grid_painter.dart';
import '../style/practice_grid_style.dart';
import '../style/practice_stroke_colors.dart';

/// 练字格展示类型。
enum HanziPracticeCellKind {
  /// 行首完整汉字示范（全笔深灰）。
  model,

  /// 递进笔顺：第 [stepIndex] 笔高亮。
  progressive,

  /// 完整叠字（淡色），供描红。
  trace,

  /// 仅米字格，供临摹自写。
  blank,
}

/// 单个练字格：米字格 + 笔画绘制（递进 / 描红 / 空白）。
///
/// 无笔画模式下可传入 [glyphCharacter] + [fontFamily]，用字体字形代替笔画路径。
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
    this.traceColor = PracticeStrokeColors.trace,
    this.glyphCharacter,
    this.fontFamily,
    this.gridStyle = PracticeGridStyle.mizi,
  }) : assert(stepIndex >= 0);

  final PreparedHanziStrokes prepared;
  final HanziPracticeCellKind kind;

  /// 仅 [HanziPracticeCellKind.progressive] 使用：从 0 起为第 1 笔递进。
  final int stepIndex;

  final double glyphInsetFraction;
  final double strokeWidth;
  final Color traceColor;

  /// 无笔画 + 字体模式下绘制的汉字（单字）。
  final String? glyphCharacter;

  /// 无笔画模式下的字体 family；为 null 时仍用笔画路径。
  final String? fontFamily;

  /// 练字格线样式（米字格 / 田字格）。
  final PracticeGridStyle gridStyle;

  bool get _useFontGlyph =>
      fontFamily != null &&
      glyphCharacter != null &&
      glyphCharacter!.isNotEmpty &&
      (kind == HanziPracticeCellKind.model ||
          kind == HanziPracticeCellKind.trace);

  @override
  Widget build(BuildContext context) {
    final n = prepared.strokeCount;
    final safeStep = n == 0 ? 0 : stepIndex.clamp(0, n - 1);
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
                  painter: MiziGridPainter(gridStyle: gridStyle),
                  size: Size(side, side),
                ),
                if (kind != HanziPracticeCellKind.blank)
                  if (_useFontGlyph)
                    Positioned.fromRect(
                      rect: glyphRect,
                      child: Center(
                        child: Text(
                          glyphCharacter!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: glyphRect.width * 0.88,
                            height: 1,
                            color: kind == HanziPracticeCellKind.trace
                                ? traceColor
                                : PracticeStrokeColors.completed,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    )
                  else
                    CustomPaint(
                      painter: switch (kind) {
                        HanziPracticeCellKind.model => HanziStrokesPainter(
                            strokes: prepared,
                            glyphRect: glyphRect,
                            visibleStrokeCount: n,
                            highlightStrokeIndex: 0,
                            modelStyle: true,
                            fillStrokes: true,
                            strokePaintWidth: strokeWidth,
                          ),
                        HanziPracticeCellKind.trace => HanziStrokesPainter(
                            strokes: prepared,
                            glyphRect: glyphRect,
                            visibleStrokeCount: n,
                            highlightStrokeIndex: 0,
                            traceStyle: true,
                            traceColor: traceColor,
                            strokePaintWidth: strokeWidth,
                          ),
                        HanziPracticeCellKind.progressive =>
                          HanziStrokesPainter(
                            strokes: prepared,
                            glyphRect: glyphRect,
                            visibleStrokeCount: progressiveVisible,
                            highlightStrokeIndex: safeStep,
                            strokePaintWidth: strokeWidth,
                          ),
                        HanziPracticeCellKind.blank => throw StateError(
                            'blank cell has no stroke painter',
                          ),
                      },
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
