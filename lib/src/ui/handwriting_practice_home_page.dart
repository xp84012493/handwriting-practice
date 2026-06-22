import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/practice_sheet_entry.dart';
import '../print/practice_sheet_export.dart';
import '../print/practice_sheet_pdf_service.dart';
import 'about_page.dart';
import 'a4_practice_sheet_preview.dart';
import 'practice_sheet_controller.dart';

enum _PdfExportAction { systemPrint, saveFile, share }

/// 练字帖主界面：顶部输入 + 生成，下方 A4 横向比例字帖预览。
class HandwritingPracticeHomePage extends StatefulWidget {
  const HandwritingPracticeHomePage({super.key});

  @override
  State<HandwritingPracticeHomePage> createState() =>
      _HandwritingPracticeHomePageState();
}

class _HandwritingPracticeHomePageState
    extends State<HandwritingPracticeHomePage> {
  late final PracticeSheetController _controller = PracticeSheetController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onGenerate() async {
    // 先收键盘再生成：避免「字帖已出、下一帧才关键盘」导致 viewInsets 突变、面板抖动。
    FocusManager.instance.primaryFocus?.unfocus();
    await _controller.generate();
    if (!mounted) return;
    final hint = _controller.hint;
    if (hint != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(hint)),
      );
    }
  }

  String _sheetPdfBaseName() {
    final rows = _controller.sheetRows;
    return '练字帖_${rows.map((e) => e.character.character).join()}';
  }

  Future<Uint8List> _buildSheetPdfBytes() {
    return PracticeSheetPdfService.buildPdfBytes(
      rows: _controller.sheetRows,
      traceSlots: _controller.traceSlots,
      blankSlots: _controller.blankSlots,
    );
  }

  Future<void> _onSystemPrint() async {
    if (!_controller.hasSheet) return;
    try {
      await PracticeSheetPdfService.layoutPrint(
        rows: _controller.sheetRows,
        traceSlots: _controller.traceSlots,
        blankSlots: _controller.blankSlots,
        name: _sheetPdfBaseName(),
      );
    } catch (e, st) {
      debugPrint('Print failed: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('打印失败：$e')),
      );
    }
  }

  Future<void> _savePdfToFile() async {
    if (!_controller.hasSheet) return;
    try {
      final bytes = await _buildSheetPdfBytes();
      final ok = await PracticeSheetExport.savePdfToFile(
        bytes: bytes,
        baseName: _sheetPdfBaseName(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? '已保存 PDF' : '已取消保存')),
      );
    } catch (e, st) {
      debugPrint('Save PDF failed: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败：$e')),
      );
    }
  }

  Future<void> _sharePdf() async {
    if (!_controller.hasSheet) return;
    try {
      final bytes = await _buildSheetPdfBytes();
      await PracticeSheetExport.sharePdf(
        bytes: bytes,
        baseName: _sheetPdfBaseName(),
        context: context,
      );
    } catch (e, st) {
      debugPrint('Share PDF failed: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('分享失败：$e')),
      );
    }
  }

  Future<void> _onPdfExportMenu(_PdfExportAction action) async {
    switch (action) {
      case _PdfExportAction.systemPrint:
        await _onSystemPrint();
        break;
      case _PdfExportAction.saveFile:
        await _savePdfToFile();
        break;
      case _PdfExportAction.share:
        await _sharePdf();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          // 键盘不挤压 body：与 Android adjustNothing 一致，避免 viewInsets 动画导致字帖区域高度抖动。
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            title: const Text('汉字笔顺字帖'),
            centerTitle: true,
            actions: [
              IconButton(
                tooltip: '关于',
                icon: const Icon(Icons.info_outline),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => const AboutPage(),
                    ),
                  );
                },
              ),
              PopupMenuButton<_PdfExportAction>(
                tooltip: '导出 PDF',
                enabled: _controller.hasSheet && !_controller.loading,
                icon: const Icon(Icons.upload_file_outlined),
                onSelected: _onPdfExportMenu,
                itemBuilder: (menuContext) {
                  final t = Theme.of(menuContext);
                  final onSurface = t.colorScheme.onSurface;
                  return [
                    PopupMenuItem(
                      value: _PdfExportAction.systemPrint,
                      child: Row(
                        children: [
                          Icon(Icons.print_outlined, size: 22, color: onSurface),
                          const SizedBox(width: 12),
                          const Expanded(child: Text('系统打印…')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: _PdfExportAction.saveFile,
                      child: Row(
                        children: [
                          Icon(Icons.save_alt_outlined, size: 22, color: onSurface),
                          const SizedBox(width: 12),
                          const Expanded(child: Text('保存 PDF 到文件')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: _PdfExportAction.share,
                      child: Row(
                        children: [
                          Icon(Icons.share_outlined, size: 22, color: onSurface),
                          const SizedBox(width: 12),
                          const Expanded(child: Text('分享 PDF')),
                        ],
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ControlBar(
                  controller: _controller,
                  onGenerate: _onGenerate,
                  theme: theme,
                ),
                // 固定高度占位，避免生成时进度条插入导致 Column 高度跳变、字帖区域抖动。
                SizedBox(
                  height: 3,
                  width: double.infinity,
                  child: _controller.loading
                      ? const LinearProgressIndicator(minHeight: 3)
                      : const SizedBox.shrink(),
                ),
                Expanded(
                  child: _PreviewBody(controller: _controller, theme: theme),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ControlBar extends StatelessWidget {
  const _ControlBar({
    required this.controller,
    required this.onGenerate,
    required this.theme,
  });

  final PracticeSheetController controller;
  final VoidCallback onGenerate;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final isNarrow = mq.size.width < 420;

    final field = TextField(
      controller: controller.textController,
      textAlign: TextAlign.center,
      maxLines: 1,
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 2,
      ),
      decoration: InputDecoration(
        hintText: '输入汉字（多字）',
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.done,
      autocorrect: false,
      enableSuggestions: true,
      smartDashesType: SmartDashesType.disabled,
      smartQuotesType: SmartQuotesType.disabled,
      inputFormatters: [
        HanziOnlyTextInputFormatter(
          maxCharacters: controller.maxMultiCharacters,
        ),
      ],
      onSubmitted: (_) => onGenerate(),
    );

    final button = FilledButton.icon(
      onPressed: controller.loading ? null : onGenerate,
      icon: const Icon(Icons.auto_fix_high_outlined),
      label: const Text('生成字帖'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    return Material(
      elevation: 0.5,
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: isNarrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  field,
                  const SizedBox(height: 10),
                  button,
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: field),
                  const SizedBox(width: 12),
                  button,
                ],
              ),
      ),
    );
  }
}

class _PreviewBody extends StatelessWidget {
  const _PreviewBody({
    required this.controller,
    required this.theme,
  });

  final PracticeSheetController controller;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    // 空状态与有字帖时共用「顶对齐 + 同宽滚动」外壳，避免首次生成从 Center 垂直居中
    // 切到字帖顶对齐时的整段位移抖动。生成中仍用顶栏细进度条，不在此切全屏转圈。
    final rows = controller.hasSheet ? controller.sheetRows : const <PracticeSheetEntry>[];
    final subtitle = !controller.hasSheet
        ? null
        : rows
            .map(
              (e) => '「${e.character.character}」${e.prepared.strokeCount}笔',
            )
            .join(' · ');

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: math.min(constraints.maxWidth, 620),
              ),
              child: controller.hasSheet
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          subtitle!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        A4PracticeSheetPreview(
                          rows: rows,
                          traceSlots: controller.traceSlots,
                          blankSlots: controller.blankSlots,
                        ),
                      ],
                    )
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(12, 32, 12, 24),
                      child: Text(
                        '在上方输入多个汉字（每字一行字帖，\nA4 单页约限 ${controller.maxMultiCharacters} 字，超出部分将忽略）。',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}
