import 'dart:math' as math;

import 'package:characters/characters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/prepared_hanzi_strokes.dart';
import '../engine/stroke_path_cache.dart';
import '../layout/a4_sheet_layout.dart';
import '../locale/practice_sheet_messages.dart';
import '../models/hanzi_character.dart';
import '../models/practice_sheet_entry.dart';
import '../parsers/hanzi_graphics_parser.dart';

/// 多字输入：仅保留基本汉字区字符。
class HanziOnlyTextInputFormatter extends TextInputFormatter {
  const HanziOnlyTextInputFormatter({this.maxCharacters});

  final int? maxCharacters;

  static final RegExp _hanzi = RegExp(r'[\u4e00-\u9fff]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.composing.isValid && !newValue.composing.isCollapsed) {
      return newValue;
    }
    final kept = newValue.text.characters
        .where((ch) => _hanzi.hasMatch(ch))
        .take(maxCharacters ?? 1 << 20);
    final text = kept.join();
    if (text == newValue.text) return newValue;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// 字帖生成状态：输入、查库、预处理笔画路径（多字：每字一行）。
class PracticeSheetController extends ChangeNotifier {
  PracticeSheetController({
    this.dictionaryAssetPath = 'assets/hanzi_dictionary.json',
    int traceSlots = defaultTraceSlots,
    int blankSlots = defaultBlankSlots,
    double cellSizeMm = defaultCellSizeMm,
  })  : _traceSlots = traceSlots.clamp(minSlots, maxSlots),
        _blankSlots = blankSlots.clamp(minSlots, maxSlots),
        _cellSizeMm = cellSizeMm
            .clamp(
              A4SheetLayout.minPracticeCellSizeMm,
              A4SheetLayout.maxPracticeCellSizeMm,
            )
            .toDouble();

  static const int defaultTraceSlots = 3;
  static const int defaultBlankSlots = 3;
  static const int minSlots = 0;
  static const int maxSlots = 10;
  static const double defaultCellSizeMm = A4SheetLayout.practiceCellSizeMm;

  static const _prefTraceSlots = 'sheet_trace_slots';
  static const _prefBlankSlots = 'sheet_blank_slots';
  static const _prefCellSizeMm = 'sheet_cell_size_mm';

  /// 笔画字典（JSON 数组），见 [HanziGraphicsParser.loadDictionaryFromAsset]。
  final String dictionaryAssetPath;

  int _traceSlots;
  int _blankSlots;
  double _cellSizeMm;

  /// 每行末尾「描红」完整叠字的格数。
  int get traceSlots => _traceSlots;

  /// 每行末尾仅米字格（临摹）的格数。
  int get blankSlots => _blankSlots;

  /// 米字格边长（mm），影响预览与打印字体大小。
  double get cellSizeMm => _cellSizeMm;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final trace = prefs.getInt(_prefTraceSlots);
    final blank = prefs.getInt(_prefBlankSlots);
    final cell = prefs.getDouble(_prefCellSizeMm);
    if (trace != null) {
      _traceSlots = trace.clamp(minSlots, maxSlots);
    }
    if (blank != null) {
      _blankSlots = blank.clamp(minSlots, maxSlots);
    }
    if (cell != null) {
      _cellSizeMm = cell
          .clamp(
            A4SheetLayout.minPracticeCellSizeMm,
            A4SheetLayout.maxPracticeCellSizeMm,
          )
          .toDouble();
    }
    notifyListeners();
  }

  Future<void> applyLayout({
    required int traceSlots,
    required int blankSlots,
    required double cellSizeMm,
  }) async {
    final nextTrace = traceSlots.clamp(minSlots, maxSlots);
    final nextBlank = blankSlots.clamp(minSlots, maxSlots);
    final nextCell = cellSizeMm
        .clamp(
          A4SheetLayout.minPracticeCellSizeMm,
          A4SheetLayout.maxPracticeCellSizeMm,
        )
        .toDouble();
    if (nextTrace == _traceSlots &&
        nextBlank == _blankSlots &&
        nextCell == _cellSizeMm) {
      return;
    }
    _traceSlots = nextTrace;
    _blankSlots = nextBlank;
    _cellSizeMm = nextCell;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefTraceSlots, _traceSlots);
    await prefs.setInt(_prefBlankSlots, _blankSlots);
    await prefs.setDouble(_prefCellSizeMm, _cellSizeMm);

    final raw = textController.text.trim();
    if (raw.isNotEmpty) {
      await _ensureDictionaryLoaded();
      await _generateMulti(raw);
    } else {
      notifyListeners();
    }
  }

  double get _cellSizePt => A4SheetLayout.cellSizePtFromMm(_cellSizeMm);

  final TextEditingController textController = TextEditingController();
  final StrokePathCache pathCache = StrokePathCache();
  static const HanziGraphicsParser _parser = HanziGraphicsParser();
  static final RegExp _hanzi = RegExp(r'[\u4e00-\u9fff]');

  Map<String, HanziCharacter>? _dictionary;
  List<PracticeSheetEntry> _entries = const [];
  List<PracticeSheetMessage> _messages = const [];
  bool _loading = false;

  List<PracticeSheetEntry> get entries => _entries;
  List<PracticeSheetMessage> get messages => _messages;
  bool get loading => _loading;
  bool get hasSheet => _entries.isNotEmpty;

  /// 输入上限（按每字至少占 1 物理行估算）。
  int get maxMultiCharacters {
    final colsPerLine = A4SheetLayout.columnsPerLine(
      A4SheetLayout.pdfInnerWidthPt,
      _cellSizePt,
    );
    final maxPhysical = A4SheetLayout.maxPhysicalRowsOnSheet(
      targetCellSize: _cellSizePt,
    );
    final minColsPerChar = 1 + 1 + _traceSlots + _blankSlots;
    final minPhysPerChar =
        (minColsPerChar + colsPerLine - 1) ~/ colsPerLine;
    return math.max(1, maxPhysical ~/ minPhysPerChar);
  }

  /// 兼容：首字。
  HanziCharacter? get character =>
      _entries.isEmpty ? null : _entries.first.character;

  /// 兼容：首字笔画。
  PreparedHanziStrokes? get prepared =>
      _entries.isEmpty ? null : _entries.first.prepared;

  /// 渲染用行列表：每字一行。
  List<PracticeSheetEntry> get sheetRows => _entries;

  /// 当前字帖中的汉字（按行顺序拼接）。
  String get generatedCharacters =>
      _entries.map((e) => e.character.character).join();

  int get rowsOnSheet => sheetRows.length;

  /// 从历史记录恢复字帖（不消耗新的生成次数）。
  Future<void> restoreFromCharacters(String characters) async {
    textController.text = characters;
    await generate();
  }

  Future<void> generate() async {
    final raw = textController.text.trim();
    if (raw.isEmpty) {
      _messages = const [HintEmptyInput()];
      notifyListeners();
      return;
    }

    _loading = true;
    _messages = const [];
    notifyListeners();

    try {
      await _ensureDictionaryLoaded();
      await _generateMulti(raw);
    } catch (e, st) {
      debugPrint('PracticeSheetController.generate failed: $e\n$st');
      _entries = const [];
      _messages = [HintDictionaryLoadFailed(e)];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  HintPhysicalOverflow? _pageOverflowMessage(List<PracticeSheetEntry> logicalRows) {
    final colsPerLine = A4SheetLayout.columnsPerLine(
      A4SheetLayout.pdfInnerWidthPt,
      _cellSizePt,
    );
    final maxPhysical = A4SheetLayout.maxPhysicalRowsOnSheet(
      targetCellSize: _cellSizePt,
    );
    var used = 0;
    for (final entry in logicalRows) {
      used += A4SheetLayout.physicalLineCountForEntry(
        entry,
        traceSlots: traceSlots,
        blankSlots: blankSlots,
        colsPerLine: colsPerLine,
      );
    }
    if (used <= maxPhysical) return null;
    return HintPhysicalOverflow(usedRows: used, maxRows: maxPhysical);
  }

  Future<void> _generateMulti(String raw) async {
    final chars = raw.characters
        .where((ch) => _hanzi.hasMatch(ch))
        .toList(growable: false);
    if (chars.isEmpty) {
      _entries = const [];
      _messages = const [HintInvalidInput()];
      return;
    }

    final colsPerLine = A4SheetLayout.columnsPerLine(
      A4SheetLayout.pdfInnerWidthPt,
      _cellSizePt,
    );
    final maxPhysical = A4SheetLayout.maxPhysicalRowsOnSheet(
      targetCellSize: _cellSizePt,
    );

    final built = <PracticeSheetEntry>[];
    final missing = <String>[];
    var physicalUsed = 0;
    var skippedForPage = 0;

    for (final ch in chars) {
      final model = _dictionary![ch];
      if (model == null) {
        missing.add(ch);
        continue;
      }
      final entry = PracticeSheetEntry(
        character: model,
        prepared: PreparedHanziStrokes.prepare(
          model: model,
          cache: pathCache,
        ),
      );
      final lines = A4SheetLayout.physicalLineCountForEntry(
        entry,
        traceSlots: traceSlots,
        blankSlots: blankSlots,
        colsPerLine: colsPerLine,
      );
      if (physicalUsed + lines > maxPhysical) {
        skippedForPage++;
        continue;
      }
      physicalUsed += lines;
      built.add(entry);
    }

    if (built.isEmpty) {
      _entries = const [];
      _messages = [HintNoMatchingChars(dictionaryAssetPath)];
      return;
    }

    _entries = built;

    final hints = <PracticeSheetMessage>[];
    if (missing.isNotEmpty) {
      hints.add(HintMissingChars(missing));
    }
    if (skippedForPage > 0) {
      hints.add(
        HintSkippedOverflow(maxRows: maxPhysical, skipped: skippedForPage),
      );
    }
    final overflow = _pageOverflowMessage(built);
    if (overflow != null) {
      hints.add(overflow);
    }
    _messages = hints;
  }

  Future<void> _ensureDictionaryLoaded() async {
    if (_dictionary != null) return;
    final list = await _parser.loadDictionaryFromAsset(dictionaryAssetPath);
    _dictionary = {for (final h in list) h.character: h};
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }
}
