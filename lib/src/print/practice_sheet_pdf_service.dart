import 'dart:typed_data';
import 'dart:ui' show Rect;
import 'package:vector_math/vector_math_64.dart' show Matrix4;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../layout/a4_sheet_layout.dart';
import '../models/practice_sheet_entry.dart';
import '../style/practice_stroke_colors.dart';
import '../models/stroke_path_convention.dart';

/// 将当前字帖布局导出为 **矢量 PDF**（笔画使用 [PdfGraphics.drawShape]）。
///
/// 系统打印见 [layoutPrint]；另存为文件与分享见 `practice_sheet_export.dart`。
///
/// 页面格式固定为 A4 横向（[PdfPageFormat.a4.landscape]）；布局算法与 [A4PracticeSheetPreview] 对齐。
class PracticeSheetPdfService {
  PracticeSheetPdfService._();

  /// A4 横向：练字行沿 297mm 长边排列。
  static final PdfPageFormat pageFormat = PdfPageFormat.a4.landscape;

  /// 生成 PDF 字节（矢量路径，非位图）。
  ///
  /// [pageFormat] 默认 [PracticeSheetPdfService.pageFormat]；打印使用固定横向 A4，
  /// 保存/分享同此格式。
  static Future<Uint8List> buildPdfBytes({
    required List<PracticeSheetEntry> rows,
    required int traceSlots,
    required int blankSlots,
    double rowGap = 4,
    double pagePadding = 18,
    PdfPageFormat? pageFormat,
  }) async {
    final fmt = pageFormat ?? PracticeSheetPdfService.pageFormat;
    final doc = pw.Document();

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
    // 先生成固定 A4 横向 PDF，再打开系统打印。
    //
    // 不要用 `dynamicLayout: true`：iOS 会在主线程 `numberOfPages` 里 semaphore 等待
    // onLayout；字帖矢量路径较多时预览会一直转圈，且 UIPrintInteractionController.shared
    // 处于未完成状态，导致再次点击打印无反应。
    //
    // `dynamicLayout: false` + 预生成：面板打开时文档已就绪。
    // `forceCustomPrintPaper: true`：iOS 按传入的横向 A4 选纸，避免插件在 setDocument
    // 重建 UIPrintInfo 后丢失横屏尺寸。
    final bytes = await buildPdfBytes(
      rows: rows,
      traceSlots: traceSlots,
      blankSlots: blankSlots,
      pageFormat: pageFormat,
    );
    await Printing.layoutPdf(
      name: name,
      format: pageFormat,
      dynamicLayout: false,
      forceCustomPrintPaper: true,
      onLayout: (_) async => bytes,
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

    final targetCell = A4SheetLayout.practiceCellSizePt;
    final layout = A4SheetLayout.planWrappedSheet(
      innerW: innerW,
      innerH: innerH,
      logicalRows: rows,
      traceSlots: traceSlots,
      blankSlots: blankSlots,
      rowGap: rowGap,
      targetCellSize: targetCell,
    );
    final cell = layout.cellSize;
    final strokeW = layout.strokeWidth;
    final top = layout.top;

    for (var i = 0; i < layout.physicalRows.length; i++) {
      final slice = layout.physicalRows[i];
      const left = 0.0;
      final y0 = top + i * (cell + rowGap);
      final strokeCount = slice.entry.prepared.strokeCount;

      for (var col = slice.startCol; col < slice.endCol; col++) {
        final local = col - slice.startCol;
        final x0 = left + local * cell;
        _paintMiziGrid(g, x0, y0, cell);

        final kind = _cellKind(col, strokeCount);
        if (kind == _CellKind.blank) continue;

        final step = kind == _CellKind.progressive ? col - 1 : null;
        _paintStrokesForCell(
          g,
          slice.entry,
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
    if (col == 0) return _CellKind.model;
    if (col <= strokeCount) return _CellKind.progressive;
    if (col <= strokeCount + traceSlots) return _CellKind.trace;
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
