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
import '../style/practice_sheet_font.dart';
import '../style/practice_grid_style.dart';
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
    bool showStrokeOrder = defaultShowStrokeOrder,
    SheetPageOrientation pageOrientation = defaultPageOrientation,
    PracticeSheetFont sheetFont = defaultSheetFont,
    PracticeGridStyle gridStyle = defaultGridStyle,
    bool showStrokeExamples = defaultShowStrokeExamples,
    bool showStrokePinyin = defaultShowStrokePinyin,
  })  : _traceSlots = traceSlots.clamp(minSlots, maxSlots),
        _blankSlots = blankSlots.clamp(minSlots, maxSlots),
        _cellSizeMm = cellSizeMm
            .clamp(
              A4SheetLayout.minPracticeCellSizeMm,
              A4SheetLayout.maxPracticeCellSizeMm,
            )
            .toDouble(),
        _showStrokeOrder = showStrokeOrder,
        _pageOrientation = pageOrientation,
        _sheetFont = sheetFont,
        _gridStyle = gridStyle,
        _showStrokeExamples = showStrokeExamples,
        _showStrokePinyin = showStrokePinyin;

  static const int defaultTraceSlots = 3;
  static const int defaultBlankSlots = 3;
  static const int minSlots = 0;
  static const int maxSlots = 10;

  /// 无笔画填满页宽时允许的格数上限（约 10mm 格下一行可排列数）。
  static const int maxSlotsNoStrokeOrder = 40;
  static const double defaultCellSizeMm = A4SheetLayout.practiceCellSizeMm;
  static const bool defaultShowStrokeOrder = true;
  static const PracticeSheetFont defaultSheetFont =
      PracticeSheetFont.appDefault;
  static const PracticeGridStyle defaultGridStyle = PracticeGridStyle.mizi;
  static const bool defaultShowStrokeExamples = false;
  static const bool defaultShowStrokePinyin = false;
  static const String defaultSheetHeader = '';
  static const int maxSheetHeaderLength = 30;

  /// 描红/空白格可调上限：有笔画用 [maxSlots]；无笔画可提到填满一行所需。
  static int maxSlotsFor({
    required bool showStrokeOrder,
    required double cellSizeMm,
    SheetPageOrientation orientation = A4SheetLayout.defaultOrientation,
  }) {
    if (showStrokeOrder) return maxSlots;
    final cols = A4SheetLayout.columnsPerLine(
      A4SheetLayout.pdfInnerWidthPtFor(orientation),
      A4SheetLayout.cellSizePtFromMm(cellSizeMm),
    );
    return math.max(maxSlots, cols - 1).clamp(maxSlots, maxSlotsNoStrokeOrder);
  }

  /// 无笔画模式下，使「示范 + 描红 + 空白」刚好占满一行所需的练习格总数。
  static int practiceSlotsToFillLine(
    double cellSizeMm, {
    SheetPageOrientation orientation = A4SheetLayout.defaultOrientation,
  }) {
    final cols = A4SheetLayout.columnsPerLine(
      A4SheetLayout.pdfInnerWidthPtFor(orientation),
      A4SheetLayout.cellSizePtFromMm(cellSizeMm),
    );
    return math.max(0, cols - 1);
  }

  static const _prefTraceSlots = 'sheet_trace_slots';
  static const _prefBlankSlots = 'sheet_blank_slots';
  static const _prefCellSizeMm = 'sheet_cell_size_mm';
  static const _prefShowStrokeOrder = 'sheet_show_stroke_order';
  static const _prefPageOrientation = 'sheet_page_orientation';
  static const _prefSheetFont = 'sheet_font';
  static const _prefGridStyle = 'sheet_grid_style';
  static const _prefShowStrokeExamples = 'sheet_show_stroke_examples';
  static const _prefShowStrokePinyin = 'sheet_show_stroke_pinyin';
  static const _prefSheetHeader = 'sheet_header';
  static const SheetPageOrientation defaultPageOrientation =
      A4SheetLayout.defaultOrientation;

  /// 笔画字典（JSON 数组），见 [HanziGraphicsParser.loadDictionaryFromAsset]。
  final String dictionaryAssetPath;

  int _traceSlots;
  int _blankSlots;
  double _cellSizeMm;
  bool _showStrokeOrder;
  SheetPageOrientation _pageOrientation;
  PracticeSheetFont _sheetFont;
  PracticeGridStyle _gridStyle;
  bool _showStrokeExamples;
  bool _showStrokePinyin;
  String _sheetHeader = defaultSheetHeader;

  /// 每行末尾「描红」完整叠字的格数。
  int get traceSlots => _traceSlots;

  /// 每行末尾仅米字格（临摹）的格数。
  int get blankSlots => _blankSlots;

  /// 米字格边长（mm），影响预览与打印字体大小。
  double get cellSizeMm => _cellSizeMm;

  /// 是否包含递进笔顺格（有笔画 / 无笔画）。
  bool get showStrokeOrder => _showStrokeOrder;

  /// A4 纸张方向（横向 / 竖向）。
  SheetPageOrientation get pageOrientation => _pageOrientation;

  /// 无笔画模式下的示范/描红字体（有笔画时忽略）。
  PracticeSheetFont get sheetFont => _sheetFont;

  /// 练字格线样式（米字格 / 田字格）。
  PracticeGridStyle get gridStyle => _gridStyle;

  /// 无笔画模式下是否在每行上方展示半高笔画示例行。
  bool get showStrokeExamples => _showStrokeExamples && !_showStrokeOrder;

  /// 笔画示例行最前显示拼音（需同时启用笔画示例）。
  bool get showStrokePinyin =>
      _showStrokePinyin && showStrokeExamples;

  /// 自定义字帖抬头；空字符串表示不显示。
  String get sheetHeader => _sheetHeader;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final trace = prefs.getInt(_prefTraceSlots);
    final blank = prefs.getInt(_prefBlankSlots);
    final cell = prefs.getDouble(_prefCellSizeMm);
    final strokes = prefs.getBool(_prefShowStrokeOrder);
    final orientation = prefs.getString(_prefPageOrientation);
    final font = prefs.getString(_prefSheetFont);
    final grid = prefs.getString(_prefGridStyle);
    final strokeExamples = prefs.getBool(_prefShowStrokeExamples);
    final strokePinyin = prefs.getBool(_prefShowStrokePinyin);
    final header = prefs.getString(_prefSheetHeader);
    if (trace != null) {
      _traceSlots = trace.clamp(minSlots, maxSlotsNoStrokeOrder);
    }
    if (blank != null) {
      _blankSlots = blank.clamp(minSlots, maxSlotsNoStrokeOrder);
    }
    if (cell != null) {
      _cellSizeMm = cell
          .clamp(
            A4SheetLayout.minPracticeCellSizeMm,
            A4SheetLayout.maxPracticeCellSizeMm,
          )
          .toDouble();
    }
    if (strokes != null) {
      _showStrokeOrder = strokes;
    }
    if (orientation != null) {
      _pageOrientation = SheetPageOrientation.fromPrefs(orientation);
    }
    if (font != null) {
      _sheetFont = PracticeSheetFont.fromPrefs(font);
    }
    if (grid != null) {
      _gridStyle = PracticeGridStyle.fromPrefs(grid);
    }
    if (strokeExamples != null) {
      _showStrokeExamples = strokeExamples;
    }
    if (strokePinyin != null) {
      _showStrokePinyin = strokePinyin;
    }
    if (header != null) {
      _sheetHeader = _normalizeSheetHeader(header);
    }
    notifyListeners();
  }

  static String _normalizeSheetHeader(String raw) =>
      raw.characters.take(maxSheetHeaderLength).toString().trim();

  Future<void> applyLayout({
    required int traceSlots,
    required int blankSlots,
    required double cellSizeMm,
    required bool showStrokeOrder,
    required SheetPageOrientation pageOrientation,
    required PracticeSheetFont sheetFont,
    required PracticeGridStyle gridStyle,
    bool showStrokeExamples = defaultShowStrokeExamples,
    bool showStrokePinyin = defaultShowStrokePinyin,
    String sheetHeader = defaultSheetHeader,
  }) async {
    final maxS = maxSlotsFor(
      showStrokeOrder: showStrokeOrder,
      cellSizeMm: cellSizeMm,
      orientation: pageOrientation,
    );
    final nextTrace = traceSlots.clamp(minSlots, maxS);
    final nextBlank = blankSlots.clamp(minSlots, maxS);
    final nextCell = cellSizeMm
        .clamp(
          A4SheetLayout.minPracticeCellSizeMm,
          A4SheetLayout.maxPracticeCellSizeMm,
        )
        .toDouble();
    final nextExamples = showStrokeOrder ? false : showStrokeExamples;
    final nextPinyin =
        showStrokeOrder || !nextExamples ? false : showStrokePinyin;
    final nextHeader = _normalizeSheetHeader(sheetHeader);
    if (nextTrace == _traceSlots &&
        nextBlank == _blankSlots &&
        nextCell == _cellSizeMm &&
        showStrokeOrder == _showStrokeOrder &&
        pageOrientation == _pageOrientation &&
        sheetFont == _sheetFont &&
        gridStyle == _gridStyle &&
        nextExamples == _showStrokeExamples &&
        nextPinyin == _showStrokePinyin &&
        nextHeader == _sheetHeader) {
      return;
    }
    _traceSlots = nextTrace;
    _blankSlots = nextBlank;
    _cellSizeMm = nextCell;
    _showStrokeOrder = showStrokeOrder;
    _pageOrientation = pageOrientation;
    _sheetFont = sheetFont;
    _gridStyle = gridStyle;
    _showStrokeExamples = nextExamples;
    _showStrokePinyin = nextPinyin;
    _sheetHeader = nextHeader;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefTraceSlots, _traceSlots);
    await prefs.setInt(_prefBlankSlots, _blankSlots);
    await prefs.setDouble(_prefCellSizeMm, _cellSizeMm);
    await prefs.setBool(_prefShowStrokeOrder, _showStrokeOrder);
    await prefs.setString(_prefPageOrientation, _pageOrientation.prefsValue);
    await prefs.setString(_prefSheetFont, _sheetFont.prefsValue);
    await prefs.setString(_prefGridStyle, _gridStyle.prefsValue);
    await prefs.setBool(_prefShowStrokeExamples, _showStrokeExamples);
    await prefs.setBool(_prefShowStrokePinyin, _showStrokePinyin);
    await prefs.setString(_prefSheetHeader, _sheetHeader);

    final raw = textController.text.trim();
    if (raw.isNotEmpty) {
      await _ensureDictionaryLoaded();
      await _generateMulti(raw);
    } else {
      _rebuildPages();
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
  List<List<PracticeSheetEntry>> _pages = const [];
  List<PracticeSheetMessage> _messages = const [];
  bool _loading = false;
  int _previewPageIndex = 0;

  List<PracticeSheetEntry> get entries => _entries;
  List<PracticeSheetMessage> get messages => _messages;
  bool get loading => _loading;
  bool get hasSheet => _entries.isNotEmpty;

  /// 分页后的页数（至少为 1 当有字帖时）。
  int get pageCount => _pages.length;

  int get previewPageIndex => _previewPageIndex;

  /// 当前预览页的逻辑行。
  List<PracticeSheetEntry> get previewPageRows {
    if (_pages.isEmpty) return const [];
    final i = _previewPageIndex.clamp(0, _pages.length - 1);
    return _pages[i];
  }

  void setPreviewPageIndex(int index) {
    if (_pages.isEmpty) return;
    final next = index.clamp(0, _pages.length - 1);
    if (next == _previewPageIndex) return;
    _previewPageIndex = next;
    notifyListeners();
  }

  void goToPreviousPage() => setPreviewPageIndex(_previewPageIndex - 1);

  void goToNextPage() => setPreviewPageIndex(_previewPageIndex + 1);

  /// 兼容：约一页可排字数（仅作空状态提示参考）。
  int get maxMultiCharacters {
    final colsPerLine = A4SheetLayout.columnsPerLine(
      A4SheetLayout.pdfInnerWidthPtFor(_pageOrientation),
      _cellSizePt,
    );
    final maxPhysical = A4SheetLayout.maxPhysicalRowsOnSheet(
      targetCellSize: _cellSizePt,
      orientation: _pageOrientation,
    );
    final minColsPerChar =
        1 + (_showStrokeOrder ? 1 : 0) + _traceSlots + _blankSlots;
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

  void _rebuildPages() {
    _pages = A4SheetLayout.paginateEntries(
      entries: _entries,
      traceSlots: _traceSlots,
      blankSlots: _blankSlots,
      targetCellSize: _cellSizePt,
      showStrokeOrder: _showStrokeOrder,
      showStrokeExamples: _showStrokeExamples,
      showStrokePinyin: _showStrokePinyin,
      orientation: _pageOrientation,
      sheetHeader: _sheetHeader,
    );
    if (_pages.isEmpty) {
      _previewPageIndex = 0;
    } else {
      _previewPageIndex = _previewPageIndex.clamp(0, _pages.length - 1);
    }
  }

  Future<void> _generateMulti(String raw) async {
    final chars = raw.characters
        .where((ch) => _hanzi.hasMatch(ch))
        .toList(growable: false);
    if (chars.isEmpty) {
      _entries = const [];
      _pages = const [];
      _previewPageIndex = 0;
      _messages = const [HintInvalidInput()];
      return;
    }

    final built = <PracticeSheetEntry>[];
    final missing = <String>[];

    for (final ch in chars) {
      final model = _dictionary![ch];
      if (model == null) {
        missing.add(ch);
        continue;
      }
      built.add(
        PracticeSheetEntry(
          character: model,
          prepared: PreparedHanziStrokes.prepare(
            model: model,
            cache: pathCache,
          ),
        ),
      );
    }

    if (built.isEmpty) {
      _entries = const [];
      _pages = const [];
      _previewPageIndex = 0;
      _messages = [HintNoMatchingChars(dictionaryAssetPath)];
      return;
    }

    _entries = built;
    _rebuildPages();
    _previewPageIndex = 0;

    final hints = <PracticeSheetMessage>[];
    if (missing.isNotEmpty) {
      hints.add(HintMissingChars(missing));
    }
    if (_pages.length > 1) {
      hints.add(HintMultiPage(pageCount: _pages.length));
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
