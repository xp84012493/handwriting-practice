import 'dart:ui' show Canvas, Offset, Paint, PaintingStyle, Path, Rect, Size;

import 'package:flutter/widgets.dart';
import 'package:path_drawing/path_drawing.dart';

/// 标准「米字格」：外框实线，内部十字与对角线为虚线。
///
/// [padding] 为外框向内缩进，便于与父级边框叠加时留出像素对齐余量。
class MiziGridPainter extends CustomPainter {
  MiziGridPainter({
    this.borderColor = const Color(0xFF2C2C2C),
    this.guideColor = const Color(0xFF9E9E9E),
    this.strokeWidth = 1.2,
    this.dashPattern = const [6.0, 4.0],
    this.padding = 0.5,
  });

  final Color borderColor;
  final Color guideColor;
  final double strokeWidth;
  final List<double> dashPattern;
  final double padding;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      padding,
      padding,
      size.width - padding * 2,
      size.height - padding * 2,
    );
    if (rect.isEmpty) return;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..isAntiAlias = true;

    final guidePaint = Paint()
      ..color = guideColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.85
      ..isAntiAlias = true;

    canvas.drawRect(rect, borderPaint);

    final cx = rect.center.dx;
    final cy = rect.center.dy;

    _dashLine(canvas, Offset(rect.left, cy), Offset(rect.right, cy), guidePaint);
    _dashLine(canvas, Offset(cx, rect.top), Offset(cx, rect.bottom), guidePaint);
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
    return oldDelegate.borderColor != borderColor ||
        oldDelegate.guideColor != guideColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.padding != padding ||
        oldDelegate.dashPattern.length != dashPattern.length;
  }
}
