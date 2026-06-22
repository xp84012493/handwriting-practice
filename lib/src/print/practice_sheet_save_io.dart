import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';

/// 打开系统「另存为」对话框（支持情况见 file_saver）。用户取消时返回 `false`。
Future<bool> savePracticeSheetPdf({
  required Uint8List bytes,
  required String stem,
}) async {
  final path = await FileSaver.instance.saveAs(
    name: stem,
    bytes: bytes,
    ext: 'pdf',
    mimeType: MimeType.pdf,
  );
  return path != null && path.isNotEmpty;
}
