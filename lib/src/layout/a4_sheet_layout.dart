import 'dart:math' as math;

import 'package:pdf/pdf.dart';

import '../models/practice_sheet_entry.dart';
import 'practice_sheet_wrap.dart';

/// A4 字帖版式：横向放置，练字行沿 297mm 长边排列。
abstract final class A4SheetLayout {
  /// 宽:高 = 297:210（A4 横向）。
  static const double aspectRatio = 297 / 210;

  /// 练字米字格推荐边长（mm）。国内小学字帖常见 1.8–2.2cm，默认取 2.0cm。
  static const double practiceCellSizeMm = 20;

  static const double defaultRowGap = 4;
  static const double defaultPagePaddingPt = 18;

  /// 打印/PDF 下的目标格边长（pt）。
  static double get practiceCellSizePt => practiceCellSizeMm * PdfPageFormat.mm;

  static double get pdfInnerWidthPt =>
      PdfPageFormat.a4.landscape.width - 2 * defaultPagePaddingPt;

  static double get pdfInnerHeightPt =>
      PdfPageFormat.a4.landscape.height - 2 * defaultPagePaddingPt;

  /// 屏幕预览：按可打印区域宽度等比缩放目标格大小。
  static double targetCellSizeForPreview(double previewInnerW) {
    return practiceCellSizePt * (previewInnerW / pdfInnerWidthPt);
  }

  /// 单字模式：同一字重复的行数。
  static const int singleModeRows = 7;

  /// 固定 [cellSize] 时，一行最多容纳多少列。
  static int columnsPerLine(double innerW, double cellSize) {
    if (cellSize <= 0) return 1;
    return math.max(1, (innerW / cellSize).floor());
  }

  /// 逻辑行拆成若干物理行（每行最多 [colsPerLine] 列）。
  static List<PracticeRowSlice> sliceLogicalRow(
    PracticeSheetEntry entry, {
    required int traceSlots,
    required int blankSlots,
    required int colsPerLine,
  }) {
    final total = entry.columnsCount(
      traceSlots: traceSlots,
      blankSlots: blankSlots,
    );
    final slices = <PracticeRowSlice>[];
    for (var start = 0; start < total; start += colsPerLine) {
      slices.add(
        PracticeRowSlice(
          entry: entry,
          startCol: start,
          endCol: math.min(start + colsPerLine, total),
        ),
      );
    }
    return slices;
  }

  /// 单条逻辑行占用的物理行数。
  static int physicalLineCountForEntry(
    PracticeSheetEntry entry, {
    required int traceSlots,
    required int blankSlots,
    required int colsPerLine,
  }) {
    final total = entry.columnsCount(
      traceSlots: traceSlots,
      blankSlots: blankSlots,
    );
    return (total + colsPerLine - 1) ~/ colsPerLine;
  }

  /// A4 一页最多容纳多少物理行（固定 2cm 格）。
  static int maxPhysicalRowsOnSheet({
    double rowGap = defaultRowGap,
    double? targetCellSize,
  }) {
    final cell = targetCellSize ?? practiceCellSizePt;
    final innerH = pdfInnerHeightPt;
    if (cell <= 0) return 1;
    return math.max(
      1,
      ((innerH + rowGap) / (cell + rowGap)).floor(),
    );
  }

  /// 多字模式：在不超过一页物理行数的前提下，最多容纳多少字。
  static int maxCharactersOnSheet({
    required int traceSlots,
    required int blankSlots,
    int? maxStrokeCountHint,
    double rowGap = defaultRowGap,
    double? targetCellSize,
  }) {
    final cell = targetCellSize ?? practiceCellSizePt;
    final colsPerLine = columnsPerLine(pdfInnerWidthPt, cell);
    final maxPhysical = maxPhysicalRowsOnSheet(
      rowGap: rowGap,
      targetCellSize: cell,
    );

    if (maxStrokeCountHint != null) {
      final colsPerChar =
          maxStrokeCountHint + traceSlots + blankSlots;
      final linesPerChar =
          (colsPerChar + colsPerLine - 1) ~/ colsPerLine;
      return math.max(1, maxPhysical ~/ math.max(1, linesPerChar));
    }

    return maxPhysical;
  }

  static double strokeWidthForCell(double cell) {
    return (2.2 * (cell / 72.0)).clamp(1.4, 4.2).toDouble();
  }

  /// 固定格宽，逻辑行超宽时自动换行。
  static WrappedSheetLayout planWrappedSheet({
    required double innerW,
    required double innerH,
    required List<PracticeSheetEntry> logicalRows,
    required int traceSlots,
    required int blankSlots,
    double rowGap = defaultRowGap,
    double? targetCellSize,
  }) {
    final cell = targetCellSize ?? practiceCellSizePt;
    final colsPerLine = columnsPerLine(innerW, cell);
    final physicalRows = <PracticeRowSlice>[];

    for (final entry in logicalRows) {
      physicalRows.addAll(
        sliceLogicalRow(
          entry,
          traceSlots: traceSlots,
          blankSlots: blankSlots,
          colsPerLine: colsPerLine,
        ),
      );
    }

    final gapTotal = rowGap * math.max(0, physicalRows.length - 1);
    final totalH = cell * physicalRows.length + gapTotal;
    const top = 0.0;

    return WrappedSheetLayout(
      cellSize: cell,
      strokeWidth: strokeWidthForCell(cell),
      top: top,
      contentWidth: colsPerLine * cell,
      totalHeight: totalH,
      colsPerLine: colsPerLine,
      physicalRows: physicalRows,
    );
  }
}
