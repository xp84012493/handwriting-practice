import 'dart:ui' show Canvas, Offset, Paint, PaintingStyle, Path, Rect, Size;

import 'package:flutter/widgets.dart';
import 'package:path_drawing/path_drawing.dart';

import '../style/practice_grid_style.dart';

/// 练字格行外框：按行一次性绘制，避免相邻格拼接处双线加粗。
class PracticeRowGridPainter extends CustomPainter {
  PracticeRowGridPainter({
    required this.colCount,
    required this.cellSize,
    this.borderColor = const Color(0xFF2C2C2C),
    this.strokeWidth = PracticeGridMetrics.borderStrokeWidth,
  });

  final int colCount;
  final double cellSize;
  final Color borderColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (colCount <= 0 || cellSize <= 0) return;

    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true;

    final rowW = colCount * cellSize;
    final rowH = cellSize;

    for (var i = 0; i <= colCount; i++) {
      final x = i * cellSize;
      canvas.drawLine(Offset(x, 0), Offset(x, rowH), paint);
    }
    canvas.drawLine(Offset(0, 0), Offset(rowW, 0), paint);
    canvas.drawLine(Offset(0, rowH), Offset(rowW, rowH), paint);
  }

  @override
  bool shouldRepaint(covariant PracticeRowGridPainter oldDelegate) {
    return oldDelegate.colCount != colCount ||
        oldDelegate.cellSize != cellSize ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// 练字格内部辅助线：十字虚线；米字格另含对角虚线。
///
/// 字帖行内请配合 [PracticeRowGridPainter] 绘制外框，并设 [drawOuterBorder] 为 false。
class MiziGridPainter extends CustomPainter {
  MiziGridPainter({
    this.gridStyle = PracticeGridStyle.mizi,
    this.drawOuterBorder = true,
    this.borderColor = const Color(0xFF2C2C2C),
    this.guideColor = const Color(0xFF9E9E9E),
    this.strokeWidth = PracticeGridMetrics.borderStrokeWidth,
    this.guideStrokeWidth = PracticeGridMetrics.guideStrokeWidth,
    this.dashPattern = PracticeGridMetrics.guideDashPattern,
    this.padding = 0.5,
  });

  final PracticeGridStyle gridStyle;
  final bool drawOuterBorder;
  final Color borderColor;
  final Color guideColor;
  final double strokeWidth;
  final double guideStrokeWidth;
  final List<double> dashPattern;
  final double padding;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = drawOuterBorder ? padding : 0.0;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );
    if (rect.isEmpty) return;

    if (drawOuterBorder) {
      final borderPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..isAntiAlias = true;
      canvas.drawRect(rect, borderPaint);
    }

    final guidePaint = Paint()
      ..color = guideColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = guideStrokeWidth
      ..isAntiAlias = true;

    final cx = rect.center.dx;
    final cy = rect.center.dy;

    _dashLine(canvas, Offset(rect.left, cy), Offset(rect.right, cy), guidePaint);
    _dashLine(canvas, Offset(cx, rect.top), Offset(cx, rect.bottom), guidePaint);
    if (gridStyle.drawDiagonals) {
      _dashLine(
        canvas,
        rect.topLeft,
        rect.bottomRight,
        guidePaint,
      );
      _dashLine(
        canvas,
        rect.topRight,
        rect.bottomLeft,
        guidePaint,
      );
    }
  }

  void _dashLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    final path = Path()..moveTo(a.dx, a.dy)..lineTo(b.dx, b.dy);
    final dashed = dashPath(
      path,
      dashArray: CircularIntervalList<double>(dashPattern),
    );
    canvas.drawPath(dashed, paint);
  }

  @override
  bool shouldRepaint(covariant MiziGridPainter oldDelegate) {
    return oldDelegate.gridStyle != gridStyle ||
        oldDelegate.drawOuterBorder != drawOuterBorder ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.guideColor != guideColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.guideStrokeWidth != guideStrokeWidth ||
        oldDelegate.padding != padding ||
        oldDelegate.dashPattern.length != dashPattern.length;
  }
}
