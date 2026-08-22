import 'dart:ui' show Color;

import 'package:pdf/pdf.dart';

/// 练字格笔画颜色（递进高亮 / 已完成 / 描红），预览与 PDF 共用。
abstract final class PracticeStrokeColors {
  /// 示范格 / 行首完整字：深灰近黑实心。
  static const Color completed = Color(0xFF1A1A1A);

  /// 笔画示例等场景：深红高亮（实心）。
  static const Color highlight = Color(0xFFB71C1C);

  /// 描红叠字：浅红半透明实心填充（笔画路径与字体字形共用）。
  static const Color trace = Color(0x55EF9A9A);

  /// 递进格已完成笔画：浅灰实心。
  static const Color progressiveCompleted = Color(0xFFB8B8B8);

  static final PdfColor pdfCompleted = PdfColor.fromInt(0xFF1A1A1A);
  static final PdfColor pdfHighlight = PdfColor.fromInt(0xFFB71C1C);
  static final PdfColor pdfTrace = PdfColor.fromInt(0x55EF9A9A);
  static final PdfColor pdfProgressiveCompleted =
      PdfColor.fromInt(0xFFB8B8B8);
}
