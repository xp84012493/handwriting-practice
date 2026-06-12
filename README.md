# hanzi_practice_engine

汉字笔顺练字帖的 **数据解析 + 米字格 + 递进绘制** 核心模块（Flutter / Dart）。

## 功能

- **数据模型**：[HanziCharacter](lib/src/models/hanzi_character.dart) 表示单字、每笔 SVG path、坐标约定（含 [Make Me a Hanzi](https://github.com/skishore/makemeahanzi) 的 Y 轴翻转）。
- **解析器**：[HanziGraphicsParser](lib/src/parsers/hanzi_graphics_parser.dart) 支持本地 JSON、`graphics.txt` 多行 JSON。
- **米字格**：[MiziGridPainter](lib/src/painters/mizi_grid_painter.dart) 外框实线、内部十字与对角线虚线。
- **递进练字格**：[ProgressiveHanziPractice](lib/src/widgets/progressive_hanzi_practice.dart) 第 1 格仅第 1 笔（红），之后每格多一笔：旧笔深灰、新笔红。
- **性能**：SVG 解析结果进入 [StrokePathCache](lib/src/engine/stroke_path_cache.dart)；[PreparedHanziStrokes](lib/src/engine/prepared_hanzi_strokes.dart) 每字只构建一次；每格 [RepaintBoundary](lib/src/widgets/hanzi_practice_cell.dart)；列表懒构建。
- **PDF / 打印**：矢量导出见 [PracticeSheetPdfService](lib/src/print/practice_sheet_pdf_service.dart)（[PdfGraphics.drawShape](https://pub.dev/documentation/pdf/latest/pdf/PdfGraphics/drawShape.html) + `Printing.layoutPdf`）。

## 运行示例

```bash
flutter pub get
flutter run -t lib/main.dart
```

主界面为 [HandwritingPracticeHomePage](lib/src/ui/handwriting_practice_home_page.dart)：顶部限制为**单个 grapheme** 的输入框与「生成字帖」按钮；下方为 **A4 纵向比例**（210:297）预览。每一行格子顺序为：**递进笔顺（1 笔→全字）→ 半透明叠字描红 → 仅米字格临摹**；行数由 [PracticeSheetController.rowsOnSheet](lib/src/ui/practice_sheet_controller.dart) 控制。默认可用字见 `assets/hanzi_dictionary.json`（一、二、三），可自行扩充或接入 Make Me a Hanzi 导出数据。

状态管理使用 [PracticeSheetController](lib/src/ui/practice_sheet_controller.dart)（`ChangeNotifier`）+ 页面内 `AnimatedBuilder` 刷新。

## `pubspec.yaml`：PDF / 打印依赖

在 `dependencies` 下加入（与仓库当前版本一致即可）：

```yaml
  pdf: ^3.11.1
  printing: ^5.13.4
```

笔画在 PDF 中通过 **SVG path 字符串 + `PdfGraphics.drawShape`** 输出为矢量路径；页面格式为 **`PdfPageFormat.a4`**。主界面 AppBar 右侧「打印」按钮调用 `Printing.layoutPdf()` 打开系统打印/另存为 PDF。

## JSON 格式示例

```json
{
  "character": "永",
  "convention": "makemeahanzi1024",
  "viewBoxWidth": 1024,
  "viewBoxHeight": 1024,
  "strokes": ["M ...", "M ..."]
}
```

`convention` 省略时默认为 `makemeahanzi1024`。若路径已是常规 SVG（左上角原点、Y 向下），使用 `svgTopLeftYDown`。

## 接入 Make Me a Hanzi

将 `graphics.txt` 读入字符串后：

```dart
final list = HanziGraphicsParser().parseGraphicsTxt(contents);
```

再按 `character` 字段检索所需单字即可。

## 许可

示例代码与结构可自由使用；若使用 Make Me a Hanzi 数据，请遵循其仓库许可说明。
