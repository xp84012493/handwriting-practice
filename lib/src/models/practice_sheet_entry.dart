import '../engine/prepared_hanzi_strokes.dart';
import 'hanzi_character.dart';

/// 字帖模式。
enum PracticeSheetMode {
  /// 单字：同一字重复 7 行。
  single,

  /// 多字：每字一行，行数受 A4 可打印高度限制。
  multi,
}

/// 字帖中的一行所对应的单字数据。
class PracticeSheetEntry {
  const PracticeSheetEntry({
    required this.character,
    required this.prepared,
  });

  final HanziCharacter character;
  final PreparedHanziStrokes prepared;

  int columnsCount({required int traceSlots, required int blankSlots}) {
    return prepared.strokeCount + traceSlots + blankSlots;
  }
}
