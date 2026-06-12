import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../engine/prepared_hanzi_strokes.dart';
import '../widgets/hanzi_practice_cell.dart';

/// A4 纵向比例（宽:高 = 210:297）下的字帖预览：多行 × 多列练字格。
class A4PracticeSheetPreview extends StatelessWidget {
  const A4PracticeSheetPreview({
    super.key,
    required this.prepared,
    required this.traceSlots,
    required this.blankSlots,
    required this.rowsOnSheet,
    this.rowGap = 4,
    this.pagePadding = 14,
    this.traceColor = const Color(0x55888888),
  });

  final PreparedHanziStrokes prepared;
  final int traceSlots;
  final int blankSlots;
  final int rowsOnSheet;
  final double rowGap;
  final double pagePadding;
  final Color traceColor;

  @override
  Widget build(BuildContext context) {
    final cols = prepared.strokeCount + traceSlots + blankSlots;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final pageW = maxW.clamp(200.0, 560.0);

        return SizedBox(
          width: pageW,
          child: AspectRatio(
            aspectRatio: 210 / 297,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE0E0E0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(pagePadding),
                child: LayoutBuilder(
                  builder: (context, inner) {
                    final innerW = inner.maxWidth;
                    final innerH = inner.maxHeight;
                    final gapTotal = rowGap * math.max(0, rowsOnSheet - 1);
                    final cellW = innerW / cols;
                    final cellH = (innerH - gapTotal) / math.max(1, rowsOnSheet);
                    final cell = math.min(cellW, cellH);
                    final strokeW =
                        (2.2 * (cell / 72.0)).clamp(1.4, 4.2).toDouble();

                    final rowWidth = cell * cols;
                    final left = (innerW - rowWidth) / 2;
                    final totalGridH = cell * rowsOnSheet + gapTotal;
                    final top = ((innerH - totalGridH) / 2).clamp(0.0, double.infinity);

                    return Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _MarginGuidePainter(
                              safeLeft: left,
                              safeTop: top,
                              rowWidth: rowWidth,
                              totalGridH: totalGridH,
                            ),
                          ),
                        ),
                        Positioned(
                          left: left,
                          top: top,
                          width: rowWidth,
                          height: totalGridH,
                          child: Column(
                            children: List.generate(rowsOnSheet, (row) {
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: row == rowsOnSheet - 1 ? 0 : rowGap,
                                ),
                                child: SizedBox(
                                  height: cell,
                                  child: _PracticeRow(
                                    prepared: prepared,
                                    traceSlots: traceSlots,
                                    blankSlots: blankSlots,
                                    cellSize: cell,
                                    strokeWidth: strokeW,
                                    traceColor: traceColor,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PracticeRow extends StatelessWidget {
  const _PracticeRow({
    required this.prepared,
    required this.traceSlots,
    required this.blankSlots,
    required this.cellSize,
    required this.strokeWidth,
    required this.traceColor,
  });

  final PreparedHanziStrokes prepared;
  final int traceSlots;
  final int blankSlots;
  final double cellSize;
  final double strokeWidth;
  final Color traceColor;

  @override
  Widget build(BuildContext context) {
    final n = prepared.strokeCount;
    final children = <Widget>[];

    for (var s = 0; s < n; s++) {
      children.add(
        SizedBox(
          width: cellSize,
          height: cellSize,
          child: HanziPracticeCell(
            prepared: prepared,
            kind: HanziPracticeCellKind.progressive,
            stepIndex: s,
            strokeWidth: strokeWidth,
          ),
        ),
      );
    }
    for (var t = 0; t < traceSlots; t++) {
      children.add(
        SizedBox(
          width: cellSize,
          height: cellSize,
          child: HanziPracticeCell(
            prepared: prepared,
            kind: HanziPracticeCellKind.trace,
            strokeWidth: strokeWidth,
            traceColor: traceColor,
          ),
        ),
      );
    }
    for (var b = 0; b < blankSlots; b++) {
      children.add(
        SizedBox(
          width: cellSize,
          height: cellSize,
          child: HanziPracticeCell(
            prepared: prepared,
            kind: HanziPracticeCellKind.blank,
            strokeWidth: strokeWidth,
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.max,
      children: children,
    );
  }
}

/// 轻量装饰：淡色书写区提示（可选视觉层次）。
class _MarginGuidePainter extends CustomPainter {
  _MarginGuidePainter({
    required this.safeLeft,
    required this.safeTop,
    required this.rowWidth,
    required this.totalGridH,
  });

  final double safeLeft;
  final double safeTop;
  final double rowWidth;
  final double totalGridH;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(safeLeft, safeTop, rowWidth, totalGridH),
      const Radius.circular(2),
    );
    final paint = Paint()
      ..color = const Color(0x08000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(r, paint);
  }

  @override
  bool shouldRepaint(covariant _MarginGuidePainter oldDelegate) {
    return oldDelegate.safeLeft != safeLeft ||
        oldDelegate.safeTop != safeTop ||
        oldDelegate.rowWidth != rowWidth ||
        oldDelegate.totalGridH != totalGridH;
  }
}
