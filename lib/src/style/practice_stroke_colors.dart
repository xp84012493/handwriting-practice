import 'dart:ui' show Color;

import 'package:pdf/pdf.dart';

/// 练字格笔画颜色（递进高亮 / 已完成 / 描红），预览与 PDF 共用。
abstract final class PracticeStrokeColors {
  /// 已完成笔画：深灰近黑。
  static const Color completed = Color(0xFF1A1A1A);

  /// 当前新笔：深红。
  static const Color highlight = Color(0xFFB71C1C);

  /// 描红叠字：半透明深灰。
  static const Color trace = Color(0x99404040);

  static final PdfColor pdfCompleted = PdfColor.fromInt(0xFF1A1A1A);
  static final PdfColor pdfHighlight = PdfColor.fromInt(0xFFB71C1C);
  static final PdfColor pdfTrace = PdfColor.fromInt(0x99404040);
}
