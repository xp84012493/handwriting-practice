import '../engine/prepared_hanzi_strokes.dart';
import '../layout/practice_sheet_wrap.dart';
import 'hanzi_character.dart';

/// 字帖中的一行所对应的单字数据。
class PracticeSheetEntry {
  const PracticeSheetEntry({
    required this.character,
    required this.prepared,
  });

  final HanziCharacter character;
  final PreparedHanziStrokes prepared;

  int columnsCount({
    required int traceSlots,
    required int blankSlots,
    bool showStrokeOrder = true,
  }) {
    return practiceColumnsCount(
      strokeCount: prepared.strokeCount,
      traceSlots: traceSlots,
      blankSlots: blankSlots,
      showStrokeOrder: showStrokeOrder,
    );
  }
}
