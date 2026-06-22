import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import 'practice_sheet_filename.dart';
import 'practice_sheet_save_io.dart'
    if (dart.library.html) 'practice_sheet_save_web.dart' as platform_save;

/// 字帖 PDF 的保存与分享（不经过系统打印面板）。
///
/// - **保存**：移动端 / 桌面端使用 [file_saver] 的另存为；Web 为浏览器下载。
/// - **分享**：使用 [Printing.sharePdf]（与现有 `printing` 依赖一致，支持多平台）。
abstract final class PracticeSheetExport {
  /// 保存到用户选择的位置（或 Web 下载）。取消保存时返回 `false`。
  static Future<bool> savePdfToFile({
    required Uint8List bytes,
    required String baseName,
  }) {
    final stem = practiceSheetPdfStem(baseName);
    return platform_save.savePracticeSheetPdf(bytes: bytes, stem: stem);
  }

  /// 唤起系统分享面板。
  static Future<void> sharePdf({
    required Uint8List bytes,
    required String baseName,
    required BuildContext context,
  }) async {
    final name = '${practiceSheetPdfStem(baseName)}.pdf';
    await Printing.sharePdf(
      bytes: bytes,
      filename: name,
      bounds: _shareBounds(context),
    );
  }

  static Rect? _shareBounds(BuildContext context) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    final topLeft = box.localToGlobal(Offset.zero);
    return topLeft & box.size;
  }
}
