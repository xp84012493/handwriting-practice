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
enum PracticeCellKind { progressive, trace, blank }

PracticeCellKind practiceCellKindAt({
  required int col,
  required int strokeCount,
  required int traceSlots,
}) {
  if (col < strokeCount) return PracticeCellKind.progressive;
  if (col < strokeCount + traceSlots) return PracticeCellKind.trace;
  return PracticeCellKind.blank;
}
