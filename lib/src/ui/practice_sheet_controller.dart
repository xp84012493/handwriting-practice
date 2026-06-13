import 'package:characters/characters.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../engine/prepared_hanzi_strokes.dart';
import '../engine/stroke_path_cache.dart';
import '../models/hanzi_character.dart';
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

/// 字帖生成状态：输入、查库、预处理笔画路径。
class PracticeSheetController extends ChangeNotifier {
  PracticeSheetController({
    this.dictionaryAssetPath = 'assets/hanzi_dictionary.json',
    this.traceSlots = 3,
    this.blankSlots = 3,
    this.rowsOnSheet = 7,
  });

  /// 笔画字典（JSON 数组），见 [HanziGraphicsParser.loadDictionaryFromAsset]。
  final String dictionaryAssetPath;

  /// 每行末尾「描红」完整叠字的格数。
  final int traceSlots;

  /// 每行末尾仅米字格（临摹）的格数。
  final int blankSlots;

  /// A4 横向预览内重复多少行相同模板（行沿短边堆叠）。
  final int rowsOnSheet;

  final TextEditingController textController = TextEditingController();
  final StrokePathCache pathCache = StrokePathCache();
  static const HanziGraphicsParser _parser = HanziGraphicsParser();

  Map<String, HanziCharacter>? _dictionary;
  HanziCharacter? _character;
  PreparedHanziStrokes? _prepared;
  String? _hint;
  bool _loading = false;

  HanziCharacter? get character => _character;
  PreparedHanziStrokes? get prepared => _prepared;
  String? get hint => _hint;
  bool get loading => _loading;
  bool get hasSheet => _prepared != null;

  int get columnsPerRow {
    final p = _prepared;
    if (p == null) return 0;
    return p.strokeCount + traceSlots + blankSlots;
  }

  Future<void> generate() async {
    final raw = textController.text.trim();
    if (raw.isEmpty) {
      _hint = '请输入一个汉字';
      notifyListeners();
      return;
    }

    final ch = raw.characters.first;
    if (!RegExp(r'^[\u4e00-\u9fff]$').hasMatch(ch)) {
      _hint = '请输入单个汉字（基本区 U+4E00–U+9FFF）';
      notifyListeners();
      return;
    }

    _loading = true;
    _hint = null;
    notifyListeners();

    try {
      await _ensureDictionaryLoaded();
      final model = _dictionary![ch];
      if (model == null) {
        _character = null;
        _prepared = null;
        _hint = '字库中暂无「$ch」。可将该字数据加入 $dictionaryAssetPath。';
        return;
      }
      _character = model;
      _prepared = PreparedHanziStrokes.prepare(
        model: model,
        cache: pathCache,
      );
    } catch (e, st) {
      debugPrint('PracticeSheetController.generate failed: $e\n$st');
      _character = null;
      _prepared = null;
      _hint = '加载字库失败：$e';
    } finally {
      _loading = false;
      notifyListeners();
    }
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
