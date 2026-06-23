import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';
import '../locale/locale_controller.dart';
import '../locale/practice_sheet_messages.dart';
import '../models/practice_sheet_entry.dart';
import '../print/practice_sheet_export.dart';
import '../print/practice_sheet_pdf_service.dart';
import 'a4_practice_sheet_preview.dart';
import 'practice_sheet_controller.dart';
import 'settings_page.dart';

enum _PdfExportAction { systemPrint, saveFile, share }

/// 练字帖主界面：顶部输入 + 生成，下方 A4 横向比例字帖预览。
class HandwritingPracticeHomePage extends StatefulWidget {
  const HandwritingPracticeHomePage({
    super.key,
    required this.localeController,
  });

  final LocaleController localeController;

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
    FocusManager.instance.primaryFocus?.unfocus();
    await _controller.generate();
    if (!mounted) return;
    if (_controller.messages.isNotEmpty) {
      final text = formatPracticeSheetMessages(
        context.l10n,
        _controller.messages,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(text)),
      );
    }
  }

  String _sheetPdfBaseName() {
    final l10n = context.l10n;
    final rows = _controller.sheetRows;
    final chars = rows.map((e) => e.character.character).join();
    return '${l10n.pdfFileNamePrefix}_$chars';
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
    final l10n = context.l10n;
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
        SnackBar(content: Text(l10n.printFailed('$e'))),
      );
    }
  }

  Future<void> _savePdfToFile() async {
    if (!_controller.hasSheet) return;
    final l10n = context.l10n;
    try {
      final bytes = await _buildSheetPdfBytes();
      final ok = await PracticeSheetExport.savePdfToFile(
        bytes: bytes,
        baseName: _sheetPdfBaseName(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? l10n.pdfSaved : l10n.pdfSaveCancelled)),
      );
    } catch (e, st) {
      debugPrint('Save PDF failed: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pdfSaveFailed('$e'))),
      );
    }
  }

  Future<void> _sharePdf() async {
    if (!_controller.hasSheet) return;
    final l10n = context.l10n;
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
        SnackBar(content: Text(l10n.pdfShareFailed('$e'))),
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
    final l10n = context.l10n;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            title: Text(l10n.appTitle),
            centerTitle: true,
            leading: IconButton(
              tooltip: l10n.settingsTooltip,
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => SettingsPage(
                      localeController: widget.localeController,
                    ),
                  ),
                );
              },
            ),
            actions: [
              PopupMenuButton<_PdfExportAction>(
                tooltip: l10n.exportPdfTooltip,
                enabled: _controller.hasSheet && !_controller.loading,
                icon: const Icon(Icons.upload_file_outlined),
                onSelected: _onPdfExportMenu,
                itemBuilder: (menuContext) {
                  final menuL10n = menuContext.l10n;
                  final t = Theme.of(menuContext);
                  final onSurface = t.colorScheme.onSurface;
                  return [
                    PopupMenuItem(
                      value: _PdfExportAction.systemPrint,
                      child: Row(
                        children: [
                          Icon(Icons.print_outlined, size: 22, color: onSurface),
                          const SizedBox(width: 12),
                          Expanded(child: Text(menuL10n.exportSystemPrint)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: _PdfExportAction.saveFile,
                      child: Row(
                        children: [
                          Icon(Icons.save_alt_outlined, size: 22, color: onSurface),
                          const SizedBox(width: 12),
                          Expanded(child: Text(menuL10n.exportSaveFile)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: _PdfExportAction.share,
                      child: Row(
                        children: [
                          Icon(Icons.share_outlined, size: 22, color: onSurface),
                          const SizedBox(width: 12),
                          Expanded(child: Text(menuL10n.exportShare)),
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
    final l10n = context.l10n;
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
        hintText: l10n.inputHint,
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
      label: Text(l10n.generateButton),
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
    final l10n = context.l10n;
    final rows = controller.hasSheet ? controller.sheetRows : const <PracticeSheetEntry>[];
    final subtitle = !controller.hasSheet
        ? null
        : rows
            .map(
              (e) => l10n.sheetRowSummary(
                e.character.character,
                e.prepared.strokeCount,
              ),
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
                        l10n.emptyStateBody(controller.maxMultiCharacters),
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
