import 'dart:math' as math;

import 'package:pdf/pdf.dart';

/// 字帖网格在页面内的几何布局结果。
class PracticeSheetGeometry {
  const PracticeSheetGeometry({
    required this.cellSize,
    required this.strokeWidth,
    required this.left,
    required this.top,
    required this.rowWidth,
    required this.totalGridHeight,
  });

  final double cellSize;
  final double strokeWidth;
  final double left;
  final double top;
  final double rowWidth;
  final double totalGridHeight;
}

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

  /// 计算字帖网格布局。
  ///
  /// 优先使用 [targetCellSize]（默认 [practiceCellSizePt]），仅在格数过多或
  /// 页面高度不足时缩小，不会为铺满纸张而放大。
  static PracticeSheetGeometry computeGeometry({
    required double innerW,
    required double innerH,
    required int cols,
    required int rows,
    double rowGap = defaultRowGap,
    double? targetCellSize,
  }) {
    final target = targetCellSize ?? practiceCellSizePt;
    final gapTotal = rowGap * math.max(0, rows - 1);
    final maxCellW = innerW / cols;
    final maxCellH = (innerH - gapTotal) / math.max(1, rows);
    final maxCell = math.min(maxCellW, maxCellH);
    final cell = math.min(target, maxCell).toDouble();

    final strokeW = (2.2 * (cell / 72.0)).clamp(1.4, 4.2).toDouble();
    final rowWidth = (cell * cols).toDouble();
    const left = 0.0;
    final totalGridH = (cell * rows + gapTotal).toDouble();
    final top = math.max(0.0, (innerH - totalGridH) / 2).toDouble();

    return PracticeSheetGeometry(
      cellSize: cell,
      strokeWidth: strokeW,
      left: left,
      top: top,
      rowWidth: rowWidth,
      totalGridHeight: totalGridH,
    );
  }

  /// 单字模式：同一字重复的行数。
  static const int singleModeRows = 7;

  /// 多字模式：A4 横向可容纳的最大行数（每字一行，按 [practiceCellSizePt] 估算）。
  static int maxCharactersOnSheet({
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

  /// 多字模式：按各行列数计算统一格宽（取最宽行决定缩放）。
  static PracticeSheetGeometry computeMultiRowGeometry({
    required double innerW,
    required double innerH,
    required List<int> colsPerRow,
    double rowGap = defaultRowGap,
    double? targetCellSize,
  }) {
    if (colsPerRow.isEmpty) {
      return const PracticeSheetGeometry(
        cellSize: 0,
        strokeWidth: 0,
        left: 0,
        top: 0,
        rowWidth: 0,
        totalGridHeight: 0,
      );
    }
    final maxCols = colsPerRow.reduce(math.max);
    return computeGeometry(
      innerW: innerW,
      innerH: innerH,
      cols: maxCols,
      rows: colsPerRow.length,
      rowGap: rowGap,
      targetCellSize: targetCellSize,
    );
  }
}
