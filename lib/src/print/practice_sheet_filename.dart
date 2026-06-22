/// 将字帖导出用的 [baseName]（如 `练字帖_一二`）整理为安全、无扩展名的文件名主干。
String practiceSheetPdfStem(String baseName) {
  var s = baseName.trim();
  if (s.isEmpty) s = '练字帖';
  s = s.replaceAll(RegExp(r'[/\\?%*:|"<>]'), '_');
  if (s.toLowerCase().endsWith('.pdf')) {
    s = s.substring(0, s.length - 4);
  }
  return s;
}
