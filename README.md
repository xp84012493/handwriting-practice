# hanzi_practice_engine

汉字笔顺练字帖的 **数据解析 + 米字格 + 递进绘制** 核心模块（Flutter / Dart）。

## 功能

- **数据模型**：[HanziCharacter](lib/src/models/hanzi_character.dart) 表示单字、每笔 SVG path、坐标约定（含 [Make Me a Hanzi](https://github.com/skishore/makemeahanzi) 的 Y 轴翻转）。
- **解析器**：[HanziGraphicsParser](lib/src/parsers/hanzi_graphics_parser.dart) 支持本地 JSON、`graphics.txt` 多行 JSON。
- **米字格**：[MiziGridPainter](lib/src/painters/mizi_grid_painter.dart) 外框实线、内部十字与对角线虚线。
- **递进练字格**：[ProgressiveHanziPractice](lib/src/widgets/progressive_hanzi_practice.dart) 第 1 格仅第 1 笔（红），之后每格多一笔：旧笔深灰、新笔红。
- **性能**：SVG 解析结果进入 [StrokePathCache](lib/src/engine/stroke_path_cache.dart)；[PreparedHanziStrokes](lib/src/engine/prepared_hanzi_strokes.dart) 每字只构建一次；每格 [RepaintBoundary](lib/src/widgets/hanzi_practice_cell.dart)；列表懒构建。
- **PDF / 导出**：矢量生成见 [PracticeSheetPdfService](lib/src/print/practice_sheet_pdf_service.dart)（[PdfGraphics.drawShape](https://pub.dev/documentation/pdf/latest/pdf/PdfGraphics/drawShape.html)）；系统打印、另存为、分享见 [PracticeSheetExport](lib/src/print/practice_sheet_export.dart)（`Printing.layoutPdf` / `Printing.sharePdf` + `file_saver`）。

## 运行示例

```bash
flutter pub get
flutter run -t lib/main.dart
```

主界面为 [HandwritingPracticeHomePage](lib/src/ui/handwriting_practice_home_page.dart)：顶部为**多字**输入（基本汉字区）与「生成字帖」按钮；下方为 **A4 纵向比例**（210:297）预览，**每字一行**。每一行格子顺序为：**递进笔顺（1 笔→全字）→ 半透明叠字描红 → 仅米字格临摹**；行数由 [PracticeSheetController.rowsOnSheet](lib/src/ui/practice_sheet_controller.dart) 控制。默认可用字见 `assets/hanzi_dictionary.json`（一、二、三），可自行扩充或接入 Make Me a Hanzi 导出数据。

状态管理使用 [PracticeSheetController](lib/src/ui/practice_sheet_controller.dart)（`ChangeNotifier`）+ 页面内 `AnimatedBuilder` 刷新。

## 多语言（中 / 英）

- 文案定义在 [`lib/l10n/app_en.arb`](lib/l10n/app_en.arb)（模板）与 [`lib/l10n/app_zh.arb`](lib/l10n/app_zh.arb)。
- 生成代码：`flutter gen-l10n`（配置见 [`l10n.yaml`](l10n.yaml)；`pubspec.yaml` 已开启 `generate: true`）。
- **关于 → 语言**：跟随系统 / 中文 / English；选择会写入 `shared_preferences` 并在下次启动恢复。
- 代码中通过 `context.l10n`（[`lib/src/l10n/l10n_extension.dart`](lib/src/l10n/l10n_extension.dart)）取字符串；字帖生成提示使用 [`practice_sheet_messages.dart`](lib/src/locale/practice_sheet_messages.dart) 结构化消息再本地化。

## `pubspec.yaml`：PDF / 导出依赖

在 `dependencies` 下加入（与仓库当前版本一致即可）：

```yaml
  pdf: ^3.11.1
  printing: ^5.13.4
  file_saver: ^0.2.14
  shared_preferences: ^2.3.0
```

笔画在 PDF 中通过 **SVG path 字符串 + `PdfGraphics.drawShape`** 输出为矢量路径；页面格式为 **`PdfPageFormat.a4`**。主界面 AppBar 右侧 **「导出 PDF」** 菜单：`Printing.layoutPdf()` 系统打印、`file_saver` 另存为、`Printing.sharePdf()` 分享。

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

## iOS 云端打包（GitHub Actions）

推送 `main` 或手动触发 **iOS Build** workflow，在 macOS + Xcode 26 runner 上构建 Ad Hoc / App Store 两套 IPA，并可选自动上传 TestFlight。

- Workflow：[`.github/workflows/ios.yml`](.github/workflows/ios.yml)  
- 配置说明：[`docs/IOS_CI_UPLOAD.md`](docs/IOS_CI_UPLOAD.md)  
- Bundle ID：`com.leoxp.handwritingpractice`

签名证书与描述文件通过 GitHub Repository secrets 注入；配置方式与 `pose-angle` 项目相同。

## 上架前核对

商店与合规项见 **[上架前 Checklist](docs/STORE_LAUNCH_CHECKLIST.md)**（产品、测试、版权、App Store / Play / 国内渠道等）。

## 许可

### 本仓库源代码

除下述第三方数据外，本仓库中的 **Dart / Flutter 源代码** 以 [**MIT License**](LICENSE) 发布。

在应用商店 **收费上架、内购或广告** 并不改变你对第三方数据仍需履行的许可义务（保留许可、按上游要求再分发等）。以下说明不构成法律意见。

### 第三方数据（Make Me a Hanzi）

笔画矢量数据来自 [Make Me a Hanzi](https://github.com/skishore/makemeahanzi) 的 **`graphics.txt`**，或由该文件转换生成的资源（例如 `assets/hanzi_dictionary.json`）。上游在 [COPYING](https://github.com/skishore/makemeahanzi/blob/master/COPYING) 中说明：`graphics.txt` 基于文鼎 **Arphic PL** 字体衍生，再分发时需遵守 **Arphic Public License**。

- **详细说明与链接：** [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md)  
- **Arphic 许可全文（英文，与上游一致）：** [`third_party/licenses/ARPHICPL.TXT`](third_party/licenses/ARPHICPL.TXT)

**未使用** MMaH 的 `dictionary.txt`（LGPL）。若你自行加入该文件，须另行遵守 LGPL。
