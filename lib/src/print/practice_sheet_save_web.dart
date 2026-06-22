import 'dart:html' as html;
import 'dart:typed_data';

/// Web：触发浏览器下载 PDF。
Future<bool> savePracticeSheetPdf({
  required Uint8List bytes,
  required String stem,
}) async {
  final name = '$stem.pdf';
  final blob = html.Blob(<Object>[bytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', name)
    ..click();
  html.Url.revokeObjectUrl(url);
  return true;
}
