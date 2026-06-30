import 'package:flutter/material.dart';

/// Anchor rect for the system share sheet (required on iPad / macOS).
Rect sharePositionOriginFor(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  if (box != null && box.hasSize) {
    final origin = box.localToGlobal(Offset.zero) & box.size;
    if (origin.width > 0 && origin.height > 0) {
      return origin;
    }
  }
  final size = MediaQuery.sizeOf(context);
  return Rect.fromCenter(
    center: Offset(size.width / 2, size.height / 2),
    width: 2,
    height: 2,
  );
}
