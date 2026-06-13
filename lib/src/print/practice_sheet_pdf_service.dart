import 'dart:typed_data';
import 'dart:ui' show Rect;
import 'package:vector_math/vector_math_64.dart' show Matrix4;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../layout/a4_sheet_layout.dart';
import '../models/practice_sheet_entry.dart';
import '../models/stroke_path_convention.dart';

/// 将当前字帖布局导出为 **矢量 PDF**（笔画使用 [PdfGraphics.drawShape]），并唤起系统打印/保存。
///
/// 页面格式固定为 A4 横向（[PdfPageFormat.a4.landscape]）；布局算法与 [A4PracticeSheetPreview] 对齐。
class PracticeSheetPdfService {
  PracticeSheetPdfService._();

  /// A4 横向：练字行沿 297mm 长边排列。
  static final PdfPageFormat pageFormat = PdfPageFormat.a4.landscape;

  /// 生成 PDF 字节（矢量路径，非位图）。
  static Future<Uint8List> buildPdfBytes({
    required List<PracticeSheetEntry> rows,
    required int traceSlots,
    required int blankSlots,
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
                    rows: rows,
                    traceSlots: traceSlots,
                    blankSlots: blankSlots,
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
    required List<PracticeSheetEntry> rows,
    required int traceSlots,
    required int blankSlots,
    String name = '练字帖',
  }) async {
    await Printing.layoutPdf(
      name: name,
      format: pageFormat,
      dynamicLayout: false,
      onLayout: (PdfPageFormat _) async {
        return buildPdfBytes(
          rows: rows,
          traceSlots: traceSlots,
          blankSlots: blankSlots,
        );
      },
    );
  }
}

/// 使用 [PdfGraphics] 矢量指令绘制米字格与 SVG path 笔画。
class _PracticeSheetPdfPainter {
  _PracticeSheetPdfPainter({
    required this.rows,
    required this.traceSlots,
    required this.blankSlots,
    required this.rowGap,
  });

  final List<PracticeSheetEntry> rows;
  final int traceSlots;
  final int blankSlots;
  final double rowGap;

  static final PdfColor _borderColor = PdfColor.fromInt(0xFF2C2C2C);
  static final PdfColor _guideColor = PdfColor.fromInt(0xFF9E9E9E);
  static final PdfColor _highlight = PdfColor.fromInt(0xFFD32F2F);
  static final PdfColor _completed = PdfColor.fromInt(0xFF424242);
  static final PdfColor _trace = PdfColor(0.53, 0.53, 0.53, 0.22);

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

    final colsPerRow = rows
        .map(
          (e) => e.columnsCount(
            traceSlots: traceSlots,
            blankSlots: blankSlots,
          ),
        )
        .toList(growable: false);
    final geometry = A4SheetLayout.computeMultiRowGeometry(
      innerW: innerW,
      innerH: innerH,
      colsPerRow: colsPerRow,
      rowGap: rowGap,
    );
    final cell = geometry.cellSize;
    final strokeW = geometry.strokeWidth;
    final top = geometry.top;

    for (var row = 0; row < rows.length; row++) {
      final entry = rows[row];
      final rowCols = colsPerRow[row];
      const left = 0.0;
      final y0 = top + row * (cell + rowGap);

      for (var col = 0; col < rowCols; col++) {
        final x0 = left + col * cell;
        _paintMiziGrid(g, x0, y0, cell);

        final kind = _cellKind(col, entry.prepared.strokeCount);
        if (kind == _CellKind.blank) continue;

        final step = kind == _CellKind.progressive ? col : null;
        _paintStrokesForCell(
          g,
          entry,
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

  _CellKind _cellKind(int col, int strokeCount) {
    if (col < strokeCount) return _CellKind.progressive;
    if (col < strokeCount + traceSlots) return _CellKind.trace;
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
