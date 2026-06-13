import 'package:flutter/material.dart';

import '../layout/a4_sheet_layout.dart';
import '../layout/practice_sheet_wrap.dart';
import '../models/practice_sheet_entry.dart';
import '../style/practice_stroke_colors.dart';
import '../widgets/hanzi_practice_cell.dart';

/// A4 横向比例（宽:高 = 297:210）下的字帖预览：固定 2cm 格宽，超宽自动换行。
class A4PracticeSheetPreview extends StatelessWidget {
  const A4PracticeSheetPreview({
    super.key,
    required this.rows,
    required this.traceSlots,
    required this.blankSlots,
    this.rowGap = 4,
    this.pagePadding = 14,
    this.traceColor = PracticeStrokeColors.trace,
  });

  final List<PracticeSheetEntry> rows;
  final int traceSlots;
  final int blankSlots;
  final double rowGap;
  final double pagePadding;
  final Color traceColor;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final pageW = maxW.clamp(200.0, 560.0);

        return SizedBox(
          width: pageW,
          child: AspectRatio(
            aspectRatio: A4SheetLayout.aspectRatio,
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
                    final targetCell =
                        A4SheetLayout.targetCellSizeForPreview(innerW);
                    final layout = A4SheetLayout.planWrappedSheet(
                      innerW: innerW,
                      innerH: innerH,
                      logicalRows: rows,
                      traceSlots: traceSlots,
                      blankSlots: blankSlots,
                      rowGap: rowGap,
                      targetCellSize: targetCell,
                    );

                    return Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _MarginGuidePainter(
                              safeLeft: 0,
                              safeTop: layout.top,
                              rowWidth: layout.contentWidth,
                              totalGridH: layout.totalHeight,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          top: layout.top,
                          width: innerW,
                          height: layout.totalHeight,
                          child: ClipRect(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: List.generate(
                                layout.physicalRows.length,
                                (index) {
                                  final slice = layout.physicalRows[index];
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom: index ==
                                              layout.physicalRows.length - 1
                                          ? 0
                                          : rowGap,
                                    ),
                                    child: SizedBox(
                                      height: layout.cellSize,
                                      child: _PracticeRowSlice(
                                        slice: slice,
                                        traceSlots: traceSlots,
                                        cellSize: layout.cellSize,
                                        strokeWidth: layout.strokeWidth,
                                        traceColor: traceColor,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
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

class _PracticeRowSlice extends StatelessWidget {
  const _PracticeRowSlice({
    required this.slice,
    required this.traceSlots,
    required this.cellSize,
    required this.strokeWidth,
    required this.traceColor,
  });

  final PracticeRowSlice slice;
  final int traceSlots;
  final double cellSize;
  final double strokeWidth;
  final Color traceColor;

  @override
  Widget build(BuildContext context) {
    final prepared = slice.entry.prepared;
    final strokeCount = prepared.strokeCount;
    final children = <Widget>[];

    for (var col = slice.startCol; col < slice.endCol; col++) {
      final kind = practiceCellKindAt(
        col: col,
        strokeCount: strokeCount,
        traceSlots: traceSlots,
      );
      children.add(
        SizedBox(
          width: cellSize,
          height: cellSize,
          child: switch (kind) {
            PracticeCellKind.progressive => HanziPracticeCell(
                prepared: prepared,
                kind: HanziPracticeCellKind.progressive,
                stepIndex: col,
                strokeWidth: strokeWidth,
              ),
            PracticeCellKind.trace => HanziPracticeCell(
                prepared: prepared,
                kind: HanziPracticeCellKind.trace,
                strokeWidth: strokeWidth,
                traceColor: traceColor,
              ),
            PracticeCellKind.blank => HanziPracticeCell(
                prepared: prepared,
                kind: HanziPracticeCellKind.blank,
                strokeWidth: strokeWidth,
              ),
          },
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
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
