import 'dart:typed_data';
import 'dart:ui' show Rect;
import 'package:vector_math/vector_math_64.dart' show Matrix4;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../engine/prepared_hanzi_strokes.dart';
import '../models/hanzi_character.dart';
import '../models/stroke_path_convention.dart';

/// 将当前字帖布局导出为 **矢量 PDF**（笔画使用 [PdfGraphics.drawShape]），并唤起系统打印/保存。
///
/// 页面格式固定为 [PdfPageFormat.a4]；布局算法与 [A4PracticeSheetPreview] 对齐。
class PracticeSheetPdfService {
  PracticeSheetPdfService._();

  /// 严格 A4 纵向页面（与 `PdfPageFormat.a4` 一致）。
  static const PdfPageFormat pageFormat = PdfPageFormat.a4;

  /// 生成 PDF 字节（矢量路径，非位图）。
  static Future<Uint8List> buildPdfBytes({
    required HanziCharacter character,
    required PreparedHanziStrokes prepared,
    required int traceSlots,
    required int blankSlots,
    required int rowsOnSheet,
    double rowGap = 4,
    double pagePadding = 18,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.zero,
        build: (context) {
          return pw.Container(
            width: pageFormat.width,
            height: pageFormat.height,
            color: PdfColors.white,
            child: pw.Padding(
              padding: pw.EdgeInsets.all(pagePadding),
              child: pw.CustomPaint(
                size: PdfPoint(
                  pageFormat.width - 2 * pagePadding,
                  pageFormat.height - 2 * pagePadding,
                ),
                painter: (PdfGraphics canvas, PdfPoint innerSize) {
                  _PracticeSheetPdfPainter(
                    character: character,
                    prepared: prepared,
                    traceSlots: traceSlots,
                    blankSlots: blankSlots,
                    rowsOnSheet: rowsOnSheet,
                    rowGap: rowGap,
                  ).paint(canvas, innerSize);
                },
              ),
            ),
          );
        },
      ),
    );

    return doc.save();
  }

  /// 调用系统原生打印预览（可另存为 PDF）。
  static Future<void> layoutPrint({
    required HanziCharacter character,
    required PreparedHanziStrokes prepared,
    required int traceSlots,
    required int blankSlots,
    required int rowsOnSheet,
    String name = '练字帖',
  }) async {
    await Printing.layoutPdf(
      name: name,
      onLayout: (PdfPageFormat _) async {
        // 需求：版式严格 A4；忽略部分平台传入的变体格式，始终输出 A4 矢量页。
        return buildPdfBytes(
          character: character,
          prepared: prepared,
          traceSlots: traceSlots,
          blankSlots: blankSlots,
          rowsOnSheet: rowsOnSheet,
        );
      },
    );
  }
}

/// 使用 [PdfGraphics] 矢量指令绘制米字格与 SVG path 笔画。
class _PracticeSheetPdfPainter {
  _PracticeSheetPdfPainter({
    required this.character,
    required this.prepared,
    required this.traceSlots,
    required this.blankSlots,
    required this.rowsOnSheet,
    required this.rowGap,
  }) : assert(prepared.strokeCount == character.strokePathData.length);

  final HanziCharacter character;
  final PreparedHanziStrokes prepared;
  final int traceSlots;
  final int blankSlots;
  final int rowsOnSheet;
  final double rowGap;

  static final PdfColor _borderColor = PdfColor.fromInt(0xFF2C2C2C);
  static final PdfColor _guideColor = PdfColor.fromInt(0xFF9E9E9E);
  static final PdfColor _highlight = PdfColor.fromInt(0xFFD32F2F);
  static final PdfColor _completed = PdfColor.fromInt(0xFF424242);
  static final PdfColor _trace = PdfColor(0.53, 0.53, 0.53, 0.22);

  void paint(PdfGraphics g, PdfPoint innerSize) {
    final innerW = innerSize.x;
    final innerH = innerSize.y;
    final cols = prepared.strokeCount + traceSlots + blankSlots;
    if (cols <= 0 || rowsOnSheet <= 0) return;

    // Pdf CustomPaint 回调坐标系为左下角原点、Y 向上；与屏幕预览的 Y 向下相反。
    // 先翻转为与 [HanziStrokesPainter] / [A4PracticeSheetPreview] 一致的坐标系。
    g.saveContext();
    g.setTransform(
      Matrix4.identity()
        ..translateByDouble(0.0, innerH, 0, 1)
        ..scaleByDouble(1.0, -1.0, 1, 1),
    );

    final gapTotal = rowGap * (rowsOnSheet > 1 ? rowsOnSheet - 1 : 0);
    final cellW = innerW / cols;
    final cellH = (innerH - gapTotal) / rowsOnSheet;
    final cell = cellW < cellH ? cellW : cellH;
    final strokeW = (2.2 * (cell / 72.0)).clamp(1.4, 4.2).toDouble();

    final rowWidth = cell * cols;
    final left = (innerW - rowWidth) / 2;
    final totalGridH = cell * rowsOnSheet + gapTotal;
    final top = ((innerH - totalGridH) / 2).clamp(0.0, double.infinity);

    for (var row = 0; row < rowsOnSheet; row++) {
      final y0 = top + row * (cell + rowGap);
      for (var col = 0; col < cols; col++) {
        final x0 = left + col * cell;
        _paintMiziGrid(g, x0, y0, cell);

        final kind = _cellKind(col);
        if (kind == _CellKind.blank) continue;

        final step = kind == _CellKind.progressive ? col : null;
        _paintStrokesForCell(
          g,
          x0,
          y0,
          cell,
          strokeW,
          kind: kind,
          progressiveStep: step,
        );
      }
    }

    g.restoreContext();
  }

  _CellKind _cellKind(int col) {
    final n = prepared.strokeCount;
    if (col < n) return _CellKind.progressive;
    if (col < n + traceSlots) return _CellKind.trace;
    return _CellKind.blank;
  }

  void _paintMiziGrid(PdfGraphics g, double x, double y, double size) {
    g.saveContext();
    final pad = 0.5;
    final left = x + pad;
    final top = y + pad;
    final w = size - 2 * pad;
    final h = size - 2 * pad;
    if (w <= 0 || h <= 0) {
      g.restoreContext();
      return;
    }

    g.setLineDashPattern(const []);
    g.setLineWidth(1.1);
    g.setStrokeColor(_borderColor);
    g.drawShape(
      'M $left $top L ${left + w} $top L ${left + w} ${top + h} L $left ${top + h} Z',
    );
    g.strokePath(close: false);

    final cx = left + w / 2;
    final cy = top + h / 2;
    g.setLineWidth(1.0);
    g.setStrokeColor(_guideColor);
    g.setLineDashPattern(const [5, 3]);

    void dashLine(double x1, double y1, double x2, double y2) {
      g.drawShape('M $x1 $y1 L $x2 $y2');
      g.strokePath(close: false);
    }

    dashLine(left, cy, left + w, cy);
    dashLine(cx, top, cx, top + h);
    dashLine(left, top, left + w, top + h);
    dashLine(left + w, top, left, top + h);

    g.setLineDashPattern(const []);
    g.restoreContext();
  }

  void _paintStrokesForCell(
    PdfGraphics g,
    double cellX,
    double cellY,
    double cell,
    double strokeW, {
    required _CellKind kind,
    int? progressiveStep,
  }) {
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

    // progressive
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

enum _CellKind { progressive, trace, blank }
