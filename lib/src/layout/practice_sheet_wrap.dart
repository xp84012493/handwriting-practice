import '../models/practice_sheet_entry.dart';

/// 一行练字格切片（逻辑行超宽时拆成多段物理行）。
class PracticeRowSlice {
  const PracticeRowSlice({
    required this.entry,
    required this.startCol,
    required this.endCol,
  });

  final PracticeSheetEntry entry;
  final int startCol;
  final int endCol;

  int get columnCount => endCol - startCol;
}

/// 笔画示例行切片（按页宽拆成多段半高物理行）。
class StrokeExampleSlice {
  const StrokeExampleSlice({
    required this.entry,
    required this.startStroke,
    required this.endStroke,
  });

  final PracticeSheetEntry entry;
  final int startStroke;
  final int endStroke;

  int get strokeCount => endStroke - startStroke;
}

/// 字帖物理行：半高笔画示例行，或整格练字行。
sealed class SheetPhysicalRow {
  const SheetPhysicalRow();

  double rowHeight(double cellSize, double exampleHeightFraction);
}

/// 半高行：逐笔展示笔画路径示例。
final class StrokeExamplePhysicalRow extends SheetPhysicalRow {
  const StrokeExamplePhysicalRow({required this.slice});

  final StrokeExampleSlice slice;

  @override
  double rowHeight(double cellSize, double exampleHeightFraction) =>
      cellSize * exampleHeightFraction;
}

/// 整格高练字行。
final class PracticePhysicalRow extends SheetPhysicalRow {
  const PracticePhysicalRow({required this.slice});

  final PracticeRowSlice slice;

  @override
  double rowHeight(double cellSize, double exampleHeightFraction) => cellSize;
}

/// 固定格宽 + 自动换行后的字帖布局计划。
class WrappedSheetLayout {
  const WrappedSheetLayout({
    required this.cellSize,
    required this.strokeWidth,
    required this.top,
    required this.contentWidth,
    required this.totalHeight,
    required this.colsPerLine,
    required this.physicalRows,
  });

  final double cellSize;
  final double strokeWidth;
  final double top;
  final double contentWidth;
  final double totalHeight;
  final int colsPerLine;
  final List<SheetPhysicalRow> physicalRows;
}

/// 练字格类型（列索引决定）。
enum PracticeCellKind {
  /// 行首完整汉字示范。
  model,

  /// 递进笔顺。
  progressive,

  /// 描红。
  trace,

  /// 空白临摹。
  blank,
}

/// 每行第一格为完整字，其后可选递进笔顺 → 描红 → 临摹。
int practiceColumnsCount({
  required int strokeCount,
  required int traceSlots,
  required int blankSlots,
  bool showStrokeOrder = true,
}) {
  final progressive = showStrokeOrder ? strokeCount : 0;
  return 1 + progressive + traceSlots + blankSlots;
}

PracticeCellKind practiceCellKindAt({
  required int col,
  required int strokeCount,
  required int traceSlots,
  bool showStrokeOrder = true,
}) {
  if (col == 0) return PracticeCellKind.model;
  final progressive = showStrokeOrder ? strokeCount : 0;
  if (col <= progressive) return PracticeCellKind.progressive;
  if (col <= progressive + traceSlots) return PracticeCellKind.trace;
  return PracticeCellKind.blank;
}

/// 递进格对应的 stepIndex（0 = 仅第 1 笔）。无笔画模式下返回 null。
int? practiceProgressiveStepIndex(int col, {bool showStrokeOrder = true}) {
  if (!showStrokeOrder || col <= 0) return null;
  return col - 1;
}
