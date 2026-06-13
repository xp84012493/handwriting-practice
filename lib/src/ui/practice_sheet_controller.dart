import 'package:characters/characters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../engine/prepared_hanzi_strokes.dart';
import '../engine/stroke_path_cache.dart';
import '../layout/a4_sheet_layout.dart';
import '../models/hanzi_character.dart';
import '../models/practice_sheet_entry.dart';
import '../parsers/hanzi_graphics_parser.dart';

/// 仅保留「第一个 grapheme cluster」，用于单字输入。
class SingleGraphemeTextInputFormatter extends TextInputFormatter {
  const SingleGraphemeTextInputFormatter();
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final t = newValue.text;
    if (t.isEmpty) return newValue;
    final chars = t.characters;
    final first = chars.first;
    if (chars.length > 1) {
      return TextEditingValue(
        text: first,
        selection: TextSelection.collapsed(offset: first.length),
      );
    }
    return newValue;
  }
}

/// 多字模式：仅保留基本汉字区字符。
class HanziOnlyTextInputFormatter extends TextInputFormatter {
  const HanziOnlyTextInputFormatter({this.maxCharacters});

  final int? maxCharacters;

  static final RegExp _hanzi = RegExp(r'[\u4e00-\u9fff]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
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

/// 字帖生成状态：输入、查库、预处理笔画路径。
class PracticeSheetController extends ChangeNotifier {
  PracticeSheetController({
    this.dictionaryAssetPath = 'assets/hanzi_dictionary.json',
    this.traceSlots = 3,
    this.blankSlots = 3,
  });

  /// 笔画字典（JSON 数组），见 [HanziGraphicsParser.loadDictionaryFromAsset]。
  final String dictionaryAssetPath;

  /// 每行末尾「描红」完整叠字的格数。
  final int traceSlots;

  /// 每行末尾仅米字格（临摹）的格数。
  final int blankSlots;

  final TextEditingController textController = TextEditingController();
  final StrokePathCache pathCache = StrokePathCache();
  static const HanziGraphicsParser _parser = HanziGraphicsParser();
  static final RegExp _hanzi = RegExp(r'^[\u4e00-\u9fff]$');

  PracticeSheetMode _mode = PracticeSheetMode.single;
  Map<String, HanziCharacter>? _dictionary;
  List<PracticeSheetEntry> _entries = const [];
  String? _hint;
  bool _loading = false;

  PracticeSheetMode get mode => _mode;
  List<PracticeSheetEntry> get entries => _entries;
  String? get hint => _hint;
  bool get loading => _loading;
  bool get hasSheet => _entries.isNotEmpty;

  /// 多字模式 A4 一页最多字数。
  int get maxMultiCharacters => A4SheetLayout.maxCharactersOnSheet();

  /// 兼容旧接口：单字模式下的首字。
  HanziCharacter? get character =>
      _entries.isEmpty ? null : _entries.first.character;

  /// 兼容旧接口：单字模式下的首字笔画。
  PreparedHanziStrokes? get prepared =>
      _entries.isEmpty ? null : _entries.first.prepared;

  /// 渲染用行列表：单字模式重复 7 行，多字模式每字一行。
  List<PracticeSheetEntry> get sheetRows {
    if (_entries.isEmpty) return const [];
    if (_mode == PracticeSheetMode.single) {
      return List<PracticeSheetEntry>.filled(
        A4SheetLayout.singleModeRows,
        _entries.first,
      );
    }
    return _entries;
  }

  int get rowsOnSheet => sheetRows.length;

  void setMode(PracticeSheetMode value) {
    if (_mode == value) return;
    _mode = value;
    textController.clear();
    _entries = const [];
    _hint = null;
    notifyListeners();
  }

  Future<void> generate() async {
    final raw = textController.text.trim();
    if (raw.isEmpty) {
      _hint = _mode == PracticeSheetMode.single ? '请输入一个汉字' : '请输入汉字';
      notifyListeners();
      return;
    }

    _loading = true;
    _hint = null;
    notifyListeners();

    try {
      await _ensureDictionaryLoaded();
      if (_mode == PracticeSheetMode.single) {
        await _generateSingle(raw);
      } else {
        await _generateMulti(raw);
      }
    } catch (e, st) {
      debugPrint('PracticeSheetController.generate failed: $e\n$st');
      _entries = const [];
      _hint = '加载字库失败：$e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _generateSingle(String raw) async {
    final ch = raw.characters.first;
    if (!_hanzi.hasMatch(ch)) {
      _entries = const [];
      _hint = '请输入单个汉字（基本区 U+4E00–U+9FFF）';
      return;
    }

    final model = _dictionary![ch];
    if (model == null) {
      _entries = const [];
      _hint = '字库中暂无「$ch」。可将该字数据加入 $dictionaryAssetPath。';
      return;
    }

    _entries = [
      PracticeSheetEntry(
        character: model,
        prepared: PreparedHanziStrokes.prepare(model: model, cache: pathCache),
      ),
    ];
  }

  Future<void> _generateMulti(String raw) async {
    final chars = raw.characters
        .where((ch) => _hanzi.hasMatch(ch))
        .toList(growable: false);
    if (chars.isEmpty) {
      _entries = const [];
      _hint = '请输入至少一个汉字（基本区 U+4E00–U+9FFF）';
      return;
    }

    final maxChars = maxMultiCharacters;
    final selected = chars.take(maxChars).toList(growable: false);
    final overflow = chars.length - selected.length;

    final built = <PracticeSheetEntry>[];
    final missing = <String>[];

    for (final ch in selected) {
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
      _hint = '字库中暂无所选汉字，请检查输入或扩充 $dictionaryAssetPath。';
      return;
    }

    _entries = built;

    final hints = <String>[];
    if (missing.isNotEmpty) {
      hints.add('字库中暂无：${missing.join('、')}');
    }
    if (overflow > 0) {
      hints.add('A4 一页最多 $maxChars 字，已忽略后 $overflow 字');
    }
    _hint = hints.isEmpty ? null : hints.join('；');
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
