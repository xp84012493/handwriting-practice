import 'package:flutter/material.dart';

import '../layout/a4_sheet_layout.dart';
import '../models/practice_sheet_entry.dart';
import '../widgets/hanzi_practice_cell.dart';

/// A4 横向比例（宽:高 = 297:210）下的字帖预览：练字行沿长边排列，多行堆叠。
class A4PracticeSheetPreview extends StatelessWidget {
  const A4PracticeSheetPreview({
    super.key,
    required this.rows,
    required this.traceSlots,
    required this.blankSlots,
    this.rowGap = 4,
    this.pagePadding = 14,
    this.traceColor = const Color(0x55888888),
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
                    final colsPerRow = rows
                        .map(
                          (e) => e.columnsCount(
                            traceSlots: traceSlots,
                            blankSlots: blankSlots,
                          ),
                        )
                        .toList(growable: false);
                    final targetCell =
                        A4SheetLayout.targetCellSizeForPreview(innerW);
                    final geometry = A4SheetLayout.computeMultiRowGeometry(
                      innerW: innerW,
                      innerH: innerH,
                      colsPerRow: colsPerRow,
                      rowGap: rowGap,
                      targetCellSize: targetCell,
                    );
                    final cell = geometry.cellSize;
                    final strokeW = geometry.strokeWidth;
                    final top = geometry.top;
                    final totalGridH = geometry.totalGridHeight;
                    final maxRowWidth = geometry.rowWidth;

                    return Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _MarginGuidePainter(
                              safeLeft: 0,
                              safeTop: top,
                              rowWidth: maxRowWidth,
                              totalGridH: totalGridH,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          top: top,
                          width: innerW,
                          height: totalGridH,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: List.generate(rows.length, (rowIndex) {
                              final entry = rows[rowIndex];
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom:
                                      rowIndex == rows.length - 1 ? 0 : rowGap,
                                ),
                                child: SizedBox(
                                  height: cell,
                                  child: _PracticeRow(
                                    entry: entry,
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
    required this.entry,
    required this.traceSlots,
    required this.blankSlots,
    required this.cellSize,
    required this.strokeWidth,
    required this.traceColor,
  });

  final PracticeSheetEntry entry;
  final int traceSlots;
  final int blankSlots;
  final double cellSize;
  final double strokeWidth;
  final Color traceColor;

  @override
  Widget build(BuildContext context) {
    final prepared = entry.prepared;
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
