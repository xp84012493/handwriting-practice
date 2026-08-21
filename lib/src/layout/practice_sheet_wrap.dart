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
  final List<PracticeRowSlice> physicalRows;
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
