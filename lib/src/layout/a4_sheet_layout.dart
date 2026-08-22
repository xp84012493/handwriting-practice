import 'dart:math' as math;

import 'package:pdf/pdf.dart';

import '../models/practice_sheet_entry.dart';
import 'practice_sheet_wrap.dart';

/// A4 纸张方向：横向（297×210）或竖向（210×297）。
enum SheetPageOrientation {
  /// 横向：练字行沿长边排列。
  landscape,

  /// 竖向：练字行沿短边排列。
  portrait;

  bool get isLandscape => this == SheetPageOrientation.landscape;

  /// SharedPreferences 存储值。
  String get prefsValue => name;

  static SheetPageOrientation fromPrefs(String? value) {
    if (value == SheetPageOrientation.portrait.name) {
      return SheetPageOrientation.portrait;
    }
    return SheetPageOrientation.landscape;
  }
}

/// A4 字帖版式：支持横向 / 竖向，练字行沿纸张宽度方向排列。
abstract final class A4SheetLayout {
  /// 默认方向（横向）。
  static const SheetPageOrientation defaultOrientation =
      SheetPageOrientation.landscape;

  /// 宽:高 = 297:210（A4 横向，兼容旧调用）。
  static const double aspectRatio = 297 / 210;

  /// 指定方向的宽高比（宽 / 高）。
  static double aspectRatioFor(SheetPageOrientation orientation) {
    return orientation.isLandscape ? 297 / 210 : 210 / 297;
  }

  /// 练字米字格边长（mm）默认值。
  static const double practiceCellSizeMm = 13;

  /// 可配置格边长范围（mm）。
  static const double minPracticeCellSizeMm = 10;
  static const double maxPracticeCellSizeMm = 18;

  static const double defaultRowGap = 4;
  static const double defaultPagePaddingPt = 18;

  /// 无笔画笔画示例行高度 = 格边长 × 该系数。
  static const double strokeExampleRowHeightFraction = 0.5;

  /// 笔画示例格宽 = 练字格宽 × 该系数（两笔示例对应下一行一字宽）。
  static const double strokeExampleWidthFraction = 0.5;

  static double strokeExampleCellWidth(double cellSize) =>
      cellSize * strokeExampleWidthFraction;

  static int strokeExampleColsPerLine(int practiceColsPerLine) =>
      math.max(1, practiceColsPerLine * 2);

  /// 拼音前缀占用的半宽格位数（等于一个练字格宽）。
  static const int strokeExamplePinyinSlotCount = 2;

  /// 将毫米格边长转为 PDF 点。
  static double cellSizePtFromMm(double cellSizeMm) =>
      cellSizeMm.clamp(minPracticeCellSizeMm, maxPracticeCellSizeMm) *
      PdfPageFormat.mm;

  /// 打印/PDF 下的默认格边长（pt）。
  static double get practiceCellSizePt => cellSizePtFromMm(practiceCellSizeMm);

  /// PDF 页面格式。
  static PdfPageFormat pageFormatFor(SheetPageOrientation orientation) {
    return orientation.isLandscape
        ? PdfPageFormat.a4.landscape
        : PdfPageFormat.a4;
  }

  /// 可打印区域内宽（pt）。默认横向，兼容旧调用。
  static double get pdfInnerWidthPt =>
      pdfInnerWidthPtFor(defaultOrientation);

  /// 可打印区域内高（pt）。默认横向，兼容旧调用。
  static double get pdfInnerHeightPt =>
      pdfInnerHeightPtFor(defaultOrientation);

  static double pdfInnerWidthPtFor(SheetPageOrientation orientation) =>
      pageFormatFor(orientation).width - 2 * defaultPagePaddingPt;

  static double pdfInnerHeightPtFor(SheetPageOrientation orientation) =>
      pageFormatFor(orientation).height - 2 * defaultPagePaddingPt;

  /// 屏幕预览：按可打印区域宽度等比缩放目标格大小。
  static double targetCellSizeForPreview(
    double previewInnerW, {
    double cellSizeMm = practiceCellSizeMm,
    SheetPageOrientation orientation = defaultOrientation,
  }) {
    final pageInnerW = pdfInnerWidthPtFor(orientation);
    return cellSizePtFromMm(cellSizeMm) * (previewInnerW / pageInnerW);
  }

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
    bool showStrokeOrder = true,
  }) {
    final total = entry.columnsCount(
      traceSlots: traceSlots,
      blankSlots: blankSlots,
      showStrokeOrder: showStrokeOrder,
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

  /// 笔画示例行拆成若干半高物理行（每行最多 [strokeExampleColsPerLine] 笔）。
  static List<StrokeExampleSlice> sliceStrokeExampleRow(
    PracticeSheetEntry entry, {
    required int colsPerLine,
    bool showPinyin = false,
  }) {
    final total = entry.prepared.strokeCount;
    if (total <= 0) return const [];
    final slotsPerRow = strokeExampleColsPerLine(colsPerLine);
    final pinyinSlots =
        showPinyin ? strokeExamplePinyinSlotCount : 0;
    final slices = <StrokeExampleSlice>[];
    var start = 0;
    var isFirstRow = true;

    while (start < total) {
      final reserved = isFirstRow ? pinyinSlots : 0;
      final capacity = math.max(1, slotsPerRow - reserved);
      final end = math.min(start + capacity, total);
      slices.add(
        StrokeExampleSlice(
          entry: entry,
          startStroke: start,
          endStroke: end,
          showPinyinPrefix: isFirstRow && showPinyin,
        ),
      );
      start = end;
      isFirstRow = false;
    }
    return slices;
  }

  /// 示例行与练字行之间、或同字多段示例行之间不加 [rowGap]。
  static bool gapBetweenPhysicalRows(
    SheetPhysicalRow a,
    SheetPhysicalRow b,
  ) {
    if (a is StrokeExamplePhysicalRow) {
      if (b is PracticePhysicalRow && a.slice.entry == b.slice.entry) {
        return false;
      }
      if (b is StrokeExamplePhysicalRow && a.slice.entry == b.slice.entry) {
        return false;
      }
    }
    return true;
  }

  /// 单字在字帖上占用的全部物理行（可选笔画示例 + 练字行）。
  static List<SheetPhysicalRow> buildPhysicalRowsForEntry(
    PracticeSheetEntry entry, {
    required int traceSlots,
    required int blankSlots,
    required int colsPerLine,
    bool showStrokeOrder = true,
    bool showStrokeExamples = false,
    bool showStrokePinyin = false,
  }) {
    final rows = <SheetPhysicalRow>[];
    if (showStrokeExamples && !showStrokeOrder) {
      for (final slice in sliceStrokeExampleRow(
        entry,
        colsPerLine: colsPerLine,
        showPinyin: showStrokePinyin,
      )) {
        rows.add(StrokeExamplePhysicalRow(slice: slice));
      }
    }
    for (final slice in sliceLogicalRow(
      entry,
      traceSlots: traceSlots,
      blankSlots: blankSlots,
      colsPerLine: colsPerLine,
      showStrokeOrder: showStrokeOrder,
    )) {
      rows.add(PracticePhysicalRow(slice: slice));
    }
    return rows;
  }

  static double totalHeightForPhysicalRows(
    List<SheetPhysicalRow> rows, {
    required double cellSize,
    double rowGap = defaultRowGap,
    double exampleHeightFraction = strokeExampleRowHeightFraction,
  }) {
    if (rows.isEmpty) return 0;
    var total = 0.0;
    for (var i = 0; i < rows.length; i++) {
      total += rows[i].rowHeight(cellSize, exampleHeightFraction);
      if (i < rows.length - 1 &&
          gapBetweenPhysicalRows(rows[i], rows[i + 1])) {
        total += rowGap;
      }
    }
    return total;
  }

  static bool entriesFitOnSheet(
    List<PracticeSheetEntry> entries, {
    required int traceSlots,
    required int blankSlots,
    required double innerH,
    double rowGap = defaultRowGap,
    double? targetCellSize,
    bool showStrokeOrder = true,
    bool showStrokeExamples = false,
    bool showStrokePinyin = false,
    SheetPageOrientation orientation = defaultOrientation,
    double exampleHeightFraction = strokeExampleRowHeightFraction,
  }) {
    final cell = targetCellSize ?? practiceCellSizePt;
    final colsPerLine =
        columnsPerLine(pdfInnerWidthPtFor(orientation), cell);
    final rows = <SheetPhysicalRow>[];
    for (final entry in entries) {
      rows.addAll(
        buildPhysicalRowsForEntry(
          entry,
          traceSlots: traceSlots,
          blankSlots: blankSlots,
          colsPerLine: colsPerLine,
          showStrokeOrder: showStrokeOrder,
          showStrokeExamples: showStrokeExamples,
          showStrokePinyin: showStrokePinyin,
        ),
      );
    }
    return totalHeightForPhysicalRows(
      rows,
      cellSize: cell,
      rowGap: rowGap,
      exampleHeightFraction: exampleHeightFraction,
    ) <= innerH;
  }

  /// 单条逻辑行占用的物理行数（仅练字行，不含笔画示例）。
  static int physicalLineCountForEntry(
    PracticeSheetEntry entry, {
    required int traceSlots,
    required int blankSlots,
    required int colsPerLine,
    bool showStrokeOrder = true,
  }) {
    final total = entry.columnsCount(
      traceSlots: traceSlots,
      blankSlots: blankSlots,
      showStrokeOrder: showStrokeOrder,
    );
    return (total + colsPerLine - 1) ~/ colsPerLine;
  }

  /// A4 一页最多容纳多少物理行（固定格宽）。
  static int maxPhysicalRowsOnSheet({
    double rowGap = defaultRowGap,
    double? targetCellSize,
    SheetPageOrientation orientation = defaultOrientation,
  }) {
    final cell = targetCellSize ?? practiceCellSizePt;
    final innerH = pdfInnerHeightPtFor(orientation);
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
    bool showStrokeOrder = true,
    SheetPageOrientation orientation = defaultOrientation,
  }) {
    final cell = targetCellSize ?? practiceCellSizePt;
    final colsPerLine = columnsPerLine(pdfInnerWidthPtFor(orientation), cell);
    final maxPhysical = maxPhysicalRowsOnSheet(
      rowGap: rowGap,
      targetCellSize: cell,
      orientation: orientation,
    );

    if (maxStrokeCountHint != null) {
      final colsPerChar = practiceColumnsCount(
        strokeCount: maxStrokeCountHint,
        traceSlots: traceSlots,
        blankSlots: blankSlots,
        showStrokeOrder: showStrokeOrder,
      );
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
    bool showStrokeOrder = true,
    bool showStrokeExamples = false,
    bool showStrokePinyin = false,
  }) {
    final cell = targetCellSize ?? practiceCellSizePt;
    final colsPerLine = columnsPerLine(innerW, cell);
    final physicalRows = <SheetPhysicalRow>[];

    for (final entry in logicalRows) {
      physicalRows.addAll(
        buildPhysicalRowsForEntry(
          entry,
          traceSlots: traceSlots,
          blankSlots: blankSlots,
          colsPerLine: colsPerLine,
          showStrokeOrder: showStrokeOrder,
          showStrokeExamples: showStrokeExamples,
          showStrokePinyin: showStrokePinyin,
        ),
      );
    }

    final totalH = totalHeightForPhysicalRows(
      physicalRows,
      cellSize: cell,
      rowGap: rowGap,
    );
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

  /// 按「整字不拆页」将逻辑行分页：一页放不下的字进入下一页。
  static List<List<PracticeSheetEntry>> paginateEntries({
    required List<PracticeSheetEntry> entries,
    required int traceSlots,
    required int blankSlots,
    double rowGap = defaultRowGap,
    double? targetCellSize,
    bool showStrokeOrder = true,
    bool showStrokeExamples = false,
    bool showStrokePinyin = false,
    SheetPageOrientation orientation = defaultOrientation,
  }) {
    if (entries.isEmpty) return const [];

    final cell = targetCellSize ?? practiceCellSizePt;
    final innerH = pdfInnerHeightPtFor(orientation);

    final pages = <List<PracticeSheetEntry>>[];
    var current = <PracticeSheetEntry>[];

    for (final entry in entries) {
      final trial = [...current, entry];
      if (trial.length > 1 &&
          !entriesFitOnSheet(
            trial,
            traceSlots: traceSlots,
            blankSlots: blankSlots,
            innerH: innerH,
            rowGap: rowGap,
            targetCellSize: cell,
            showStrokeOrder: showStrokeOrder,
            showStrokeExamples: showStrokeExamples,
            showStrokePinyin: showStrokePinyin,
            orientation: orientation,
          )) {
        pages.add(current);
        current = <PracticeSheetEntry>[entry];
      } else {
        current = trial;
      }
    }
    if (current.isNotEmpty) {
      pages.add(current);
    }
    return pages;
  }
}
