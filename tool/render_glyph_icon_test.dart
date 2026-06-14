import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hanzi_practice_engine/hanzi_practice_engine.dart';

const _iconCharacter = '练';
const _iconSize = 1024.0;
const _glyphInsetFraction = 0.14;
const _outputPath = 'assets/branding/app_icon_lian_square.png';

void main() {
  test('render app icon from practice-sheet stroke paths', () async {
    TestWidgetsFlutterBinding.ensureInitialized();

    final repoRoot = Directory.current;
    final dictFile = File('${repoRoot.path}/assets/hanzi_dictionary.json');
    if (!dictFile.existsSync()) {
      fail('Dictionary not found: ${dictFile.path}');
    }

    const parser = HanziGraphicsParser();
    final dictionary = parser.parseJsonArrayString(dictFile.readAsStringSync());
    HanziCharacter? model;
    for (final entry in dictionary) {
      if (entry.character == _iconCharacter) {
        model = entry;
        break;
      }
    }
    if (model == null) {
      fail('Character $_iconCharacter not found in hanzi_dictionary.json');
    }

    final prepared = PreparedHanziStrokes.prepare(
      model: model,
      cache: StrokePathCache(),
    );

    final inset = _iconSize * _glyphInsetFraction;
    final glyphRect = Rect.fromLTRB(
      inset,
      inset,
      _iconSize - inset,
      _iconSize - inset,
    );
    final strokeWidth = 2.2 * (_iconSize / 72.0);

    final painter = HanziStrokesPainter(
      strokes: prepared,
      glyphRect: glyphRect,
      visibleStrokeCount: prepared.strokeCount,
      highlightStrokeIndex: 0,
      modelStyle: true,
      fillStrokes: true,
      completedColor: const Color(0xFFFFFFFF),
      strokePaintWidth: strokeWidth,
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, _iconSize, _iconSize),
      Paint()..color = const Color(0xFF000000),
    );
    painter.paint(canvas, const Size(_iconSize, _iconSize));

    final picture = recorder.endRecording();
    final image = await picture.toImage(_iconSize.toInt(), _iconSize.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) {
      fail('Failed to encode PNG');
    }

    final out = File('${repoRoot.path}/$_outputPath');
    out.parent.createSync(recursive: true);
    await out.writeAsBytes(bytes.buffer.asUint8List());
    expect(out.existsSync(), isTrue);
  });
}
