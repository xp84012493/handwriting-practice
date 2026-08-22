import 'dart:math' as math;
import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4;

import '../locale/hanzi_pinyin.dart';
import '../layout/a4_sheet_layout.dart';
import '../layout/practice_sheet_wrap.dart';
import '../models/practice_sheet_entry.dart';
import '../style/practice_sheet_font.dart';
import '../style/practice_grid_style.dart';
import '../style/practice_stroke_colors.dart';
import '../models/stroke_path_convention.dart';

/// 将当前字帖布局导出为 **矢量 PDF**（笔画使用 [PdfGraphics.drawShape]）。
///
/// 系统打印见 [layoutPrint]；另存为文件与分享见 `practice_sheet_export.dart`。
///
/// 页面格式为 A4 横向或竖向（由 [SheetPageOrientation] 决定）；布局算法与 [A4PracticeSheetPreview] 对齐。
class PracticeSheetPdfService {
  PracticeSheetPdfService._();

  static const _iosPrintChannel = MethodChannel(
    'com.leoxp.handwritingpractice/print',
  );

  /// 默认 A4 横向格式（兼容旧调用）。
  static final PdfPageFormat pageFormat = PdfPageFormat.a4.landscape;

  /// 按方向返回 PDF 页面格式。
  static PdfPageFormat pageFormatFor(SheetPageOrientation orientation) =>
      A4SheetLayout.pageFormatFor(orientation);

  /// 生成 PDF 字节（矢量路径，非位图）。
  static Future<Uint8List> buildPdfBytes({
    required List<PracticeSheetEntry> rows,
    required int traceSlots,
    required int blankSlots,
    bool showStrokeOrder = true,
    bool showStrokeExamples = false,
    bool showStrokePinyin = false,
    PracticeSheetFont sheetFont = PracticeSheetFont.appDefault,
    PracticeGridStyle gridStyle = PracticeGridStyle.mizi,
    SheetPageOrientation pageOrientation = A4SheetLayout.defaultOrientation,
    double cellSizeMm = A4SheetLayout.practiceCellSizeMm,
    double rowGap = 4,
    double pagePadding = 18,
    PdfPageFormat? pageFormat,
  }) async {
    final fmt = pageFormat ?? pageFormatFor(pageOrientation);
    final doc = pw.Document();
    pw.Font? glyphFont;
    pw.Font? pinyinFont;
    final fontAsset = sheetFont.assetPath;
    if (!showStrokeOrder && fontAsset != null) {
      final fontData = await rootBundle.load(fontAsset);
      glyphFont = pw.Font.ttf(fontData);
      pinyinFont = glyphFont;
    } else if (showStrokeExamples && showStrokePinyin) {
      final fontData =
          await rootBundle.load('assets/fonts/LXGWWenKaiGB-Regular.ttf');
      pinyinFont = pw.Font.ttf(fontData);
    }
    final pages = A4SheetLayout.paginateEntries(
      entries: rows,
      traceSlots: traceSlots,
      blankSlots: blankSlots,
      rowGap: rowGap,
      targetCellSize: A4SheetLayout.cellSizePtFromMm(cellSizeMm),
      showStrokeOrder: showStrokeOrder,
      showStrokeExamples: showStrokeExamples,
      showStrokePinyin: showStrokePinyin,
      orientation: pageOrientation,
    );
    final pageRows = pages.isEmpty ? const <List<PracticeSheetEntry>>[[]] : pages;

    for (final pageEntries in pageRows) {
      doc.addPage(
        pw.Page(
          pageFormat: fmt,
          margin: pw.EdgeInsets.zero,
          build: (context) {
            return pw.Container(
              width: fmt.width,
              height: fmt.height,
              color: PdfColors.white,
              child: pw.Padding(
                padding: pw.EdgeInsets.all(pagePadding),
                child: pw.CustomPaint(
                  size: PdfPoint(
                    fmt.width - 2 * pagePadding,
                    fmt.height - 2 * pagePadding,
                  ),
                  painter: (PdfGraphics canvas, PdfPoint innerSize) {
                    _PracticeSheetPdfPainter(
                      rows: pageEntries,
                      traceSlots: traceSlots,
                      blankSlots: blankSlots,
                      showStrokeOrder: showStrokeOrder,
                      showStrokeExamples: showStrokeExamples,
                      showStrokePinyin: showStrokePinyin,
                      cellSizeMm: cellSizeMm,
                      rowGap: rowGap,
                      gridStyle: gridStyle,
                      glyphFont: glyphFont?.getFont(context),
                      pinyinFont: pinyinFont?.getFont(context),
                      contentHeight: innerSize.y,
                    ).paint(canvas, innerSize);
                  },
                ),
              ),
            );
          },
        ),
      );
    }

    return doc.save();
  }

  /// 调用系统原生打印预览（可另存为 PDF）。
  ///
  /// [bytes] 若已预生成可直接传入，避免重复构建；否则按当前行数据生成。
  static Future<void> layoutPrint({
    required List<PracticeSheetEntry> rows,
    required int traceSlots,
    required int blankSlots,
    bool showStrokeOrder = true,
    bool showStrokeExamples = false,
    bool showStrokePinyin = false,
    PracticeSheetFont sheetFont = PracticeSheetFont.appDefault,
    PracticeGridStyle gridStyle = PracticeGridStyle.mizi,
    SheetPageOrientation pageOrientation = A4SheetLayout.defaultOrientation,
    double cellSizeMm = A4SheetLayout.practiceCellSizeMm,
    String name = '练字帖',
    Uint8List? bytes,
  }) async {
    final fmt = pageFormatFor(pageOrientation);
    final pdfBytes = bytes ??
        await buildPdfBytes(
          rows: rows,
          traceSlots: traceSlots,
          blankSlots: blankSlots,
          showStrokeOrder: showStrokeOrder,
          showStrokeExamples: showStrokeExamples,
          showStrokePinyin: showStrokePinyin,
          sheetFont: sheetFont,
          gridStyle: gridStyle,
          pageOrientation: pageOrientation,
          cellSizeMm: cellSizeMm,
          pageFormat: fmt,
        );

    // iOS：绕过 `printing` 插件的 FFI setDocument（SPM 静态链接 + App Store strip
    // 后符号丢失，layoutPdf 收不到 PDF，表现为点击无反应）。改用 Runner 内
    // UIPrintInteractionController.printingItem。
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      await _iosPrintChannel.invokeMethod<void>('printPdf', <String, Object?>{
        'bytes': pdfBytes,
        'name': name,
        'landscape': pageOrientation.isLandscape,
      });
      return;
    }

    await Printing.layoutPdf(
      name: name,
      format: fmt,
      dynamicLayout: false,
      onLayout: (_) async => pdfBytes,
    );
  }
}

/// 使用 [PdfGraphics] 矢量指令绘制米字格与 SVG path 笔画。
class _PracticeSheetPdfPainter {
  _PracticeSheetPdfPainter({
    required this.rows,
    required this.traceSlots,
    required this.blankSlots,
    required this.showStrokeOrder,
    required this.showStrokeExamples,
    required this.showStrokePinyin,
    required this.cellSizeMm,
    required this.rowGap,
    this.gridStyle = PracticeGridStyle.mizi,
    this.glyphFont,
    this.pinyinFont,
    this.contentHeight = 0,
  });

  final List<PracticeSheetEntry> rows;
  final int traceSlots;
  final int blankSlots;
  final bool showStrokeOrder;
  final bool showStrokeExamples;
  final bool showStrokePinyin;
  final double cellSizeMm;
  final double rowGap;
  final PracticeGridStyle gridStyle;
  final PdfFont? glyphFont;
  final PdfFont? pinyinFont;
  final double contentHeight;

  static final PdfColor _borderColor = PdfColor.fromInt(0xFF2C2C2C);
  static final PdfColor _guideColor = PdfColor.fromInt(0xFF9E9E9E);
  static final PdfColor _highlight = PracticeStrokeColors.pdfHighlight;
  static final PdfColor _completed = PracticeStrokeColors.pdfCompleted;
  static final PdfColor _trace = PracticeStrokeColors.pdfTrace;

  void paint(PdfGraphics g, PdfPoint innerSize) {
    final innerW = innerSize.x;
    final innerH = innerSize.y;
    if (rows.isEmpty) return;

    g.saveContext();
    g.setTransform(
      Matrix4.identity()
        ..translateByDouble(0.0, innerH, 0, 1)
        ..scaleByDouble(1.0, -1.0, 1, 1),
    );

    final targetCell = A4SheetLayout.cellSizePtFromMm(cellSizeMm);
    final layout = A4SheetLayout.planWrappedSheet(
      innerW: innerW,
      innerH: innerH,
      logicalRows: rows,
      traceSlots: traceSlots,
      blankSlots: blankSlots,
      rowGap: rowGap,
      targetCellSize: targetCell,
      showStrokeOrder: showStrokeOrder,
      showStrokeExamples: showStrokeExamples,
      showStrokePinyin: showStrokePinyin,
    );
    final cell = layout.cellSize;
    final strokeW = layout.strokeWidth;
    final top = layout.top;
    final exampleFraction = A4SheetLayout.strokeExampleRowHeightFraction;
    var y = top;

    for (var i = 0; i < layout.physicalRows.length; i++) {
      final row = layout.physicalRows[i];
      const left = 0.0;
      final rowH = row.rowHeight(cell, exampleFraction);
      final next = i + 1 < layout.physicalRows.length
          ? layout.physicalRows[i + 1]
          : null;

      switch (row) {
        case StrokeExamplePhysicalRow():
          final slice = row.slice;
          final strokeCellW = A4SheetLayout.strokeExampleCellWidth(cell);
          final pinyinOffset =
              slice.showPinyinPrefix ? cell : 0.0;
          if (slice.showPinyinPrefix) {
            final pinyin =
                HanziPinyin.forCharacter(slice.entry.character.character);
            _paintPinyinLabel(
              g,
              pinyin,
              left,
              y,
              cell,
              rowH,
            );
          }
          for (var stroke = slice.startStroke; stroke < slice.endStroke; stroke++) {
            final local = stroke - slice.startStroke;
            final x0 = left + pinyinOffset + local * strokeCellW;
            _paintStrokeExampleForCell(
              g,
              slice.entry,
              x0,
              y,
              strokeCellW,
              rowH,
              strokeW,
              strokeIndex: stroke,
            );
          }
        case PracticePhysicalRow():
          final slice = row.slice;
          final strokeCount = slice.entry.prepared.strokeCount;
          final colCount = slice.endCol - slice.startCol;
          _paintRowGrid(g, left, y, cell, colCount);

          for (var col = slice.startCol; col < slice.endCol; col++) {
            final local = col - slice.startCol;
            final x0 = left + local * cell;
            _paintPracticeGridGuides(g, x0, y, cell);

            final kind = _cellKind(col, strokeCount);
            if (kind == _CellKind.blank) continue;

            final useFont = !showStrokeOrder &&
                glyphFont != null &&
                (kind == _CellKind.model || kind == _CellKind.trace);
            if (useFont) {
              _paintFontGlyph(
                g,
                slice.entry.character.character,
                x0,
                y,
                cell,
                kind: kind,
              );
              continue;
            }

            final step = kind == _CellKind.progressive ? col - 1 : null;
            _paintStrokesForCell(
              g,
              slice.entry,
              x0,
              y,
              cell,
              strokeW,
              kind: kind,
              progressiveStep: step,
            );
          }
      }

      y += rowH;
      if (next != null &&
          A4SheetLayout.gapBetweenPhysicalRows(row, next)) {
        y += rowGap;
      }
    }

    g.restoreContext();
  }

  _CellKind _cellKind(int col, int strokeCount) {
    if (col == 0) return _CellKind.model;
    final progressive = showStrokeOrder ? strokeCount : 0;
    if (col <= progressive) return _CellKind.progressive;
    if (col <= progressive + traceSlots) return _CellKind.trace;
    return _CellKind.blank;
  }

  void _paintRowGrid(
    PdfGraphics g,
    double x,
    double y,
    double cellSize,
    int colCount, {
    double? rowH,
  }) {
    if (colCount <= 0 || cellSize <= 0) return;

    g.saveContext();
    g.setLineDashPattern(const []);
    g.setLineWidth(PracticeGridMetrics.borderStrokeWidth);
    g.setStrokeColor(_borderColor);

    final rowW = colCount * cellSize;
    final rowHeight = rowH ?? cellSize;

    void line(double x1, double y1, double x2, double y2) {
      g.drawShape('M $x1 $y1 L $x2 $y2');
      g.strokePath(close: false);
    }

    for (var i = 0; i <= colCount; i++) {
      final xi = x + i * cellSize;
      line(xi, y, xi, y + rowHeight);
    }
    line(x, y, x + rowW, y);
    line(x, y + rowHeight, x + rowW, y + rowHeight);

    g.restoreContext();
  }

  void _paintPracticeGridGuides(
    PdfGraphics g,
    double x,
    double y,
    double cellW, [
    double? cellH,
  ]) {
    g.saveContext();
    final left = x;
    final top = y;
    final w = cellW;
    final h = cellH ?? cellW;
    if (w <= 0 || h <= 0) {
      g.restoreContext();
      return;
    }

    g.setLineDashPattern(const []);
    final cx = left + w / 2;
    final cy = top + h / 2;
    g.setLineWidth(PracticeGridMetrics.guideStrokeWidth);
    g.setStrokeColor(_guideColor);
    g.setLineDashPattern(const [5, 3.5]);

    void dashLine(double x1, double y1, double x2, double y2) {
      g.drawShape('M $x1 $y1 L $x2 $y2');
      g.strokePath(close: false);
    }

    dashLine(left, cy, left + w, cy);
    dashLine(cx, top, cx, top + h);
    if (gridStyle.drawDiagonals) {
      dashLine(left, top, left + w, top + h);
      dashLine(left + w, top, left, top + h);
    }

    g.setLineDashPattern(const []);
    g.restoreContext();
  }

  void _paintStrokeExampleForCell(
    PdfGraphics g,
    PracticeSheetEntry entry,
    double cellX,
    double cellY,
    double cellW,
    double cellH,
    double strokeW, {
    required int strokeIndex,
  }) {
    final character = entry.character;
    final inset = math.min(cellW, cellH) * 0.14;
    final glyph = Rect.fromLTRB(
      cellX + inset,
      cellY + inset,
      cellX + cellW - inset,
      cellY + cellH - inset,
    );

    final fit = character.convention.normalizedViewBoxToRect(
      glyph,
      character.viewBoxWidth,
      character.viewBoxHeight,
    );
    final data = character.convention.dataToNormalizedSpace();
    final ctm = Matrix4.copy(fit)..multiply(data);
    final n = character.strokePathData.length;
    if (n == 0) return;
    final step = strokeIndex.clamp(0, n - 1);
    final visible = step + 1;

    g.saveContext();
    g.setTransform(ctm);
    for (var i = 0; i < visible; i++) {
      g.setFillColor(i == step ? _highlight : _completed);
      g.drawShape(character.strokePathData[i]);
      g.fillPath(evenOdd: true);
    }
    g.restoreContext();
  }

  void _paintPinyinLabel(
    PdfGraphics g,
    String pinyin,
    double cellX,
    double cellY,
    double cellW,
    double cellH,
  ) {
    if (pinyin.isEmpty) return;
    final font = pinyinFont ?? glyphFont;
    if (font == null) return;

    final fontSize = math.min(cellW, cellH * 2) * 0.32;
    final metrics = font.stringMetrics(pinyin) * fontSize;
    final textW = metrics.width;
    final cx = cellX + cellW / 2;
    final cy = cellY + cellH / 2;

    g.saveContext();
    g.setTransform(
      Matrix4.identity()
        ..translateByDouble(0.0, contentHeight, 0, 1)
        ..scaleByDouble(1.0, -1.0, 1, 1)
        ..translateByDouble(cx, cy, 0, 1)
        ..scaleByDouble(1.0, -1.0, 1, 1),
    );
    g.setFillColor(_completed);
    g.drawString(
      font,
      fontSize,
      pinyin,
      -textW / 2,
      fontSize * 0.35,
    );
    g.restoreContext();
  }

  
  void _paintFontGlyph(
    PdfGraphics g,
    String character,
    double cellX,
    double cellY,
    double cell, {
    required _CellKind kind,
  }) {
    final font = glyphFont;
    if (font == null || character.isEmpty) return;

    final inset = cell * 0.14;
    final fontSize = (cell - 2 * inset) * 0.88;
    final color = kind == _CellKind.trace ? _trace : _completed;
    final metrics = font.stringMetrics(character) * fontSize;
    final textW = metrics.width;
    final cx = cellX + cell / 2;
    final cy = cellY + cell / 2;

    g.saveContext();
    // Parent CTM flips Y; counter-flip so glyphs stay upright.
    g.setTransform(
      Matrix4.identity()
        ..translateByDouble(0.0, contentHeight, 0, 1)
        ..scaleByDouble(1.0, -1.0, 1, 1)
        ..translateByDouble(cx, cy, 0, 1)
        ..scaleByDouble(1.0, -1.0, 1, 1),
    );
    g.setFillColor(color);
    g.drawString(
      font,
      fontSize,
      character,
      -textW / 2,
      fontSize * 0.35,
    );
    g.restoreContext();
  }
void _paintStrokesForCell(
    PdfGraphics g,
    PracticeSheetEntry entry,
    double cellX,
    double cellY,
    double cell,
    double strokeW, {
    required _CellKind kind,
    int? progressiveStep,
  }) {
    final character = entry.character;
    final inset = cell * 0.14;
    final glyph = Rect.fromLTRB(
      cellX + inset,
      cellY + inset,
      cellX + cell - inset,
      cellY + cell - inset,
    );

    final fit = character.convention.normalizedViewBoxToRect(
      glyph,
      character.viewBoxWidth,
      character.viewBoxHeight,
    );
    final data = character.convention.dataToNormalizedSpace();
    final ctm = Matrix4.copy(fit)..multiply(data);

    final n = character.strokePathData.length;

    if (kind == _CellKind.trace) {
      g.saveContext();
      g.setLineJoin(PdfLineJoin.round);
      g.setLineCap(PdfLineCap.round);
      g.setLineWidth(strokeW);
      g.setStrokeColor(_trace);
      g.setTransform(ctm);
      for (var i = 0; i < n; i++) {
        g.drawShape(character.strokePathData[i]);
        g.strokePath(close: false);
      }
      g.restoreContext();
      return;
    }

    if (kind == _CellKind.model) {
      g.saveContext();
      g.setTransform(ctm);
      g.setFillColor(_completed);
      for (var i = 0; i < n; i++) {
        g.drawShape(character.strokePathData[i]);
        // 与屏上示范格一致：实心填充笔画轮廓（含带孔部件用 even-odd）
        g.fillPath(evenOdd: true);
      }
      g.restoreContext();
      return;
    }

    final step = (progressiveStep ?? 0).clamp(0, n - 1);
    final visible = step + 1;
    for (var i = 0; i < visible; i++) {
      g.saveContext();
      g.setLineJoin(PdfLineJoin.round);
      g.setLineCap(PdfLineCap.round);
      g.setLineWidth(strokeW);
      g.setStrokeColor(i == step ? _highlight : _completed);
      g.setTransform(ctm);
      g.drawShape(character.strokePathData[i]);
      g.strokePath(close: false);
      g.restoreContext();
    }
  }
}

enum _CellKind { model, progressive, trace, blank }
