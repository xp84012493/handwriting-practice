// 将 Make Me a Hanzi graphics.txt 批量转为项目字库 JSON 格式。
//
// 用法：
//   dart run tool/convert_mmah_to_dictionary.dart -i graphics.txt -o assets/hanzi_dictionary.json --chars 一,二,永
//   dart run tool/convert_mmah_to_dictionary.dart -i graphics.txt -o out.json --all
//   dart run tool/convert_mmah_to_dictionary.dart -i graphics.txt -o assets/hanzi_dictionary.json --chars 永 --merge
//
// 下载 graphics.txt（请自行确认许可）：
//   https://github.com/skishore/makemeahanzi/blob/master/graphics.txt

import 'dart:convert';
import 'dart:io';

import 'package:characters/characters.dart';

const _defaultConvention = 'makemeahanzi1024';
const _defaultViewBox = 1024;

void main(List<String> args) {
  try {
    final options = _parseArgs(args);
    _run(options);
  } on _UsageError catch (e) {
    stderr.writeln(e.message);
    stderr.writeln();
    _printHelp();
    exitCode = 64;
  } on Object catch (e) {
    stderr.writeln('错误：$e');
    exitCode = 1;
  }
}

class _Options {
  _Options({
    required this.input,
    required this.output,
    required this.charFilter,
    required this.merge,
    required this.includeMedians,
    required this.indent,
    required this.progressEvery,
  });

  final File input;
  final File output;
  final Set<String>? charFilter;
  final bool merge;
  final bool includeMedians;
  final int? indent;
  final int progressEvery;
}

class _UsageError implements Exception {
  _UsageError(this.message);
  final String message;
}

_Options _parseArgs(List<String> args) {
  String? inputPath;
  String outputPath = 'assets/hanzi_dictionary.json';
  String? charsArg;
  String? charsFilePath;
  var convertAll = false;
  var merge = false;
  var includeMedians = false;
  int? indent;
  var progressEvery = 500;

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    switch (arg) {
      case '-h':
      case '--help':
        _printHelp();
        exit(0);
      case '-i':
      case '--input':
        inputPath = _requireValue(args, ++i, arg);
      case '-o':
      case '--output':
        outputPath = _requireValue(args, ++i, arg);
      case '--chars':
        charsArg = _requireValue(args, ++i, arg);
      case '--chars-file':
        charsFilePath = _requireValue(args, ++i, arg);
      case '--all':
        convertAll = true;
      case '--merge':
        merge = true;
      case '--include-medians':
        includeMedians = true;
      case '--indent':
        indent = int.parse(_requireValue(args, ++i, arg));
      case '--progress-every':
        progressEvery = int.parse(_requireValue(args, ++i, arg));
      default:
        throw _UsageError('未知参数：$arg');
    }
  }

  if (inputPath == null) {
    throw _UsageError('缺少必填参数 --input');
  }

  final filterModes = [
    if (charsArg != null) 'chars',
    if (charsFilePath != null) 'chars-file',
    if (convertAll) 'all',
  ];
  if (filterModes.isEmpty) {
    throw _UsageError('请指定 --chars、--chars-file 或 --all 之一');
  }
  if (filterModes.length > 1) {
    throw _UsageError('--chars、--chars-file、--all 只能选一个');
  }

  Set<String>? charFilter;
  if (charsArg != null) {
    charFilter = charsArg
        .split(',')
        .expand((part) => part.characters)
        .where((c) => c.trim().isNotEmpty)
        .toSet();
    if (charFilter.isEmpty) {
      throw _UsageError('--chars 未包含有效汉字');
    }
  } else if (charsFilePath != null) {
    final lines = File(charsFilePath).readAsStringSync(encoding: utf8);
    charFilter = lines
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map((line) => line.characters.first)
        .toSet();
    if (charFilter.isEmpty) {
      throw _UsageError('--chars-file 为空：$charsFilePath');
    }
  }

  return _Options(
    input: File(inputPath),
    output: File(outputPath),
    charFilter: charFilter,
    merge: merge,
    includeMedians: includeMedians,
    indent: indent,
    progressEvery: progressEvery,
  );
}

String _requireValue(List<String> args, int index, String flag) {
  if (index >= args.length) {
    throw _UsageError('$flag 需要参数值');
  }
  return args[index];
}

void _printHelp() {
  stdout.writeln('''
将 Make Me a Hanzi graphics.txt 转为 hanzi_dictionary.json

用法：
  dart run tool/convert_mmah_to_dictionary.dart -i <graphics.txt> [选项]

必填：
  -i, --input <path>          graphics.txt 路径

输出：
  -o, --output <path>         输出 JSON（默认 assets/hanzi_dictionary.json）

筛选（三选一）：
  --chars <一,二,永>          仅转换指定汉字
  --chars-file <path>         每行一个汉字的文本文件
  --all                       转换全部汉字（体积较大）

其他：
  --merge                     与已有输出合并，同字覆盖
  --include-medians           保留 medians 字段
  --indent <N>                美化 JSON 缩进；默认紧凑输出
  --progress-every <N>        进度间隔行数（默认 500，0 关闭）
  -h, --help                  显示帮助
''');
}

void _run(_Options options) {
  if (!options.input.existsSync()) {
    throw StateError('输入文件不存在：${options.input.path}');
  }

  stderr.writeln('读取：${options.input.path}');
  if (options.charFilter == null) {
    stderr.writeln('模式：转换全部汉字');
  } else {
    stderr.writeln('模式：仅转换 ${options.charFilter!.length} 个指定汉字');
  }

  final result = _readGraphicsTxt(
    options.input,
    charFilter: options.charFilter,
    includeMedians: options.includeMedians,
    progressEvery: options.progressEvery,
  );

  if (options.charFilter != null) {
    final missing =
        options.charFilter!.difference(result.found.keys.toSet()).toList()
      ..sort((a, b) => a.codeUnitAt(0).compareTo(b.codeUnitAt(0)));
    if (missing.isNotEmpty) {
      final preview = missing.take(20).join('、');
      final suffix = missing.length > 20 ? ' 等共 ${missing.length} 字' : '';
      stderr.writeln('警告：graphics.txt 中未找到：$preview$suffix');
    }
  }

  final merged = <String, Map<String, dynamic>>{};
  if (options.merge && options.output.existsSync()) {
    final existing = _loadExistingDictionary(options.output);
    merged.addAll(existing);
    merged.addAll(result.found);
    stderr.writeln(
      '合并：原有 ${existing.length} 字，本次写入 ${result.found.length} 字',
    );
  } else {
    merged.addAll(result.found);
  }

  final entries = merged.values.toList()
    ..sort((a, b) {
      final ac = a['character'] as String;
      final bc = b['character'] as String;
      return ac.codeUnitAt(0).compareTo(bc.codeUnitAt(0));
    });

  options.output.parent.createSync(recursive: true);
  final payload = options.indent == null
      ? jsonEncode(entries)
      : JsonEncoder.withIndent(' ' * options.indent!).convert(entries);
  options.output.writeAsStringSync('$payload\n', encoding: utf8);

  final sizeKb = options.output.lengthSync() / 1024;
  stderr.writeln();
  stderr.writeln('完成');
  stderr.writeln(
    '  输出：${options.output.path}（${sizeKb.toStringAsFixed(1)} KB，${entries.length} 字）',
  );
  stderr.writeln('  扫描行数：${result.stats.linesRead}');
  if (result.stats.linesSkippedFilter > 0) {
    stderr.writeln('  过滤跳过：${result.stats.linesSkippedFilter}');
  }
  if (result.stats.linesInvalid > 0) {
    stderr.writeln('  无效行：${result.stats.linesInvalid}');
  }
  if (result.stats.duplicates > 0) {
    stderr.writeln('  重复字（后者覆盖）：${result.stats.duplicates}');
  }
}

class _Stats {
  _Stats({
    required this.linesRead,
    required this.linesSkippedEmpty,
    required this.linesSkippedFilter,
    required this.linesInvalid,
    required this.duplicates,
  });

  int linesRead;
  int linesSkippedEmpty;
  int linesSkippedFilter;
  int linesInvalid;
  int duplicates;
}

class _ReadResult {
  _ReadResult({required this.found, required this.stats});

  final Map<String, Map<String, dynamic>> found;
  final _Stats stats;
}

_ReadResult _readGraphicsTxt(
  File input, {
  required Set<String>? charFilter,
  required bool includeMedians,
  required int progressEvery,
}) {
  final found = <String, Map<String, dynamic>>{};
  final stats = _Stats(
    linesRead: 0,
    linesSkippedEmpty: 0,
    linesSkippedFilter: 0,
    linesInvalid: 0,
    duplicates: 0,
  );

  final lines = input.readAsLinesSync(encoding: utf8);

  var lineNo = 0;
  for (final line in lines) {
    lineNo++;
    final stripped = line.trim();
    if (stripped.isEmpty || stripped.startsWith('#')) {
      stats.linesSkippedEmpty++;
      continue;
    }

    stats.linesRead++;
    if (progressEvery > 0 && stats.linesRead % progressEvery == 0) {
      stderr.writeln('  已扫描 ${stats.linesRead} 行，已匹配 ${found.length} 字…');
    }

    Map<String, dynamic> raw;
    try {
      final decoded = jsonDecode(stripped);
      if (decoded is! Map) {
        stats.linesInvalid++;
        stderr.writeln('警告：第 $lineNo 行根节点不是对象，已跳过');
        continue;
      }
      raw = Map<String, dynamic>.from(decoded);
    } catch (e) {
      stats.linesInvalid++;
      stderr.writeln('警告：第 $lineNo 行 JSON 无效，已跳过：$e');
      continue;
    }

    final character = raw['character'];
    if (character is! String || character.isEmpty) {
      stats.linesInvalid++;
      stderr.writeln('警告：第 $lineNo 行缺少 character，已跳过');
      continue;
    }
    final ch = character.characters.first;

    if (charFilter != null && !charFilter.contains(ch)) {
      stats.linesSkippedFilter++;
      continue;
    }

    try {
      final entry = _toDictionaryEntry(raw, includeMedians: includeMedians);
      if (found.containsKey(ch)) {
        stats.duplicates++;
      }
      found[ch] = entry;
    } catch (e) {
      stats.linesInvalid++;
      stderr.writeln('警告：第 $lineNo 行「$ch」格式错误，已跳过：$e');
      continue;
    }

    if (charFilter != null && found.length == charFilter.length) {
      break;
    }
  }

  return _ReadResult(found: found, stats: stats);
}

Map<String, dynamic> _toDictionaryEntry(
  Map<String, dynamic> raw, {
  required bool includeMedians,
}) {
  final character = raw['character'];
  if (character is! String || character.isEmpty) {
    throw FormatException('缺少有效的 character 字段');
  }
  final ch = character.characters.first;

  final strokes = raw['strokes'];
  if (strokes is! List || strokes.isEmpty) {
    throw FormatException('strokes 必须为非空数组');
  }
  final pathList = <String>[];
  for (final stroke in strokes) {
    if (stroke is! String || stroke.trim().isEmpty) {
      throw FormatException('strokes 元素应为非空字符串');
    }
    pathList.add(stroke.trim());
  }

  final entry = <String, dynamic>{
    'character': ch,
    'convention': _defaultConvention,
    'viewBoxWidth': (raw['viewBoxWidth'] as num?)?.toInt() ?? _defaultViewBox,
    'viewBoxHeight':
        (raw['viewBoxHeight'] as num?)?.toInt() ?? _defaultViewBox,
    'strokes': pathList,
  };

  if (includeMedians && raw.containsKey('medians')) {
    entry['medians'] = raw['medians'];
  }

  return entry;
}

Map<String, Map<String, dynamic>> _loadExistingDictionary(File path) {
  final decoded = jsonDecode(path.readAsStringSync(encoding: utf8));
  if (decoded is! List) {
    throw FormatException('已有字库根节点必须是数组：${path.path}');
  }
  final out = <String, Map<String, dynamic>>{};
  for (final item in decoded) {
    if (item is! Map) continue;
    final map = Map<String, dynamic>.from(item);
    final ch = map['character'];
    if (ch is String && ch.isNotEmpty) {
      out[ch.characters.first] = map;
    }
  }
  return out;
}
