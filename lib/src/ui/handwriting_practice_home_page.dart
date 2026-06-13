import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../layout/a4_sheet_layout.dart';
import '../models/practice_sheet_entry.dart';
import '../print/practice_sheet_pdf_service.dart';
import 'a4_practice_sheet_preview.dart';
import 'practice_sheet_controller.dart';

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
    FocusScope.of(context).unfocus();
    await _controller.generate();
    if (!mounted) return;
    final hint = _controller.hint;
    if (hint != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(hint)),
      );
    }
  }

  Future<void> _onPrintOrExport() async {
    if (!_controller.hasSheet) return;
    try {
      final rows = _controller.sheetRows;
      final name = _controller.mode == PracticeSheetMode.single
          ? '练字帖_${_controller.character!.character}'
          : '练字帖_${rows.map((e) => e.character.character).join()}';
      await PracticeSheetPdfService.layoutPrint(
        rows: rows,
        traceSlots: _controller.traceSlots,
        blankSlots: _controller.blankSlots,
        name: name,
      );
    } catch (e, st) {
      debugPrint('Print/Export failed: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('打印失败：$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('汉字笔顺字帖'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: '打印 / 导出 PDF',
            icon: const Icon(Icons.print_outlined),
            onPressed: _controller.hasSheet && !_controller.loading
                ? _onPrintOrExport
                : null,
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ControlBar(
                  controller: _controller,
                  onGenerate: _onGenerate,
                  theme: theme,
                ),
                if (_controller.loading)
                  const LinearProgressIndicator(minHeight: 2),
                Expanded(
                  child: _PreviewBody(controller: _controller, theme: theme),
                ),
              ],
            );
          },
        ),
      ),
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

    final isSingle = controller.mode == PracticeSheetMode.single;

    final field = TextField(
      controller: controller.textController,
      textAlign: TextAlign.center,
      maxLines: 1,
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: isSingle ? 4 : 2,
      ),
      decoration: InputDecoration(
        hintText: isSingle ? '输入一个汉字' : '输入多个汉字',
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
      inputFormatters: [
        if (isSingle)
          const SingleGraphemeTextInputFormatter()
        else
          HanziOnlyTextInputFormatter(
            maxCharacters: controller.maxMultiCharacters,
          ),
      ],
      onSubmitted: (_) => onGenerate(),
    );

    final modeToggle = SegmentedButton<PracticeSheetMode>(
      segments: const [
        ButtonSegment(
          value: PracticeSheetMode.single,
          label: Text('单字'),
          icon: Icon(Icons.looks_one_outlined),
        ),
        ButtonSegment(
          value: PracticeSheetMode.multi,
          label: Text('多字'),
          icon: Icon(Icons.notes_outlined),
        ),
      ],
      selected: {controller.mode},
      onSelectionChanged: controller.loading
          ? null
          : (selection) => controller.setMode(selection.first),
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
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          mq.viewPadding.bottom > 0 ? 8 : 12,
        ),
        child: isNarrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  modeToggle,
                  const SizedBox(height: 10),
                  field,
                  const SizedBox(height: 10),
                  button,
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  modeToggle,
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: field),
                      const SizedBox(width: 12),
                      button,
                    ],
                  ),
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
    if (controller.loading && !controller.hasSheet) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!controller.hasSheet) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '在上方选择模式并输入汉字，\n单字模式 7 行重复；多字模式每字一行（A4 限 ${controller.maxMultiCharacters} 字）。',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ),
      );
    }

    final rows = controller.sheetRows;
    final subtitle = controller.mode == PracticeSheetMode.single
        ? '「${controller.character!.character}」'
            ' · ${controller.prepared!.strokeCount} 笔递进 + '
            '${controller.traceSlots} 描红 + '
            '${controller.blankSlots} 临摹 × '
            '${A4SheetLayout.singleModeRows} 行'
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    subtitle,
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
              ),
            ),
          ),
        );
      },
    );
  }
}
