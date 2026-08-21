import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';
import '../locale/locale_controller.dart';
import '../locale/practice_sheet_messages.dart';
import '../models/practice_sheet_entry.dart';
import '../models/preset_sheet_list.dart';
import '../models/saved_practice_sheet.dart';
import '../print/practice_sheet_export.dart';
import '../print/practice_sheet_pdf_service.dart';
import '../services/preset_list_service.dart';
import '../services/recent_sheets_service.dart';
import '../services/usage_quota_service.dart';
import '../theme/theme_controller.dart';
import 'a4_practice_sheet_preview.dart';
import 'practice_sheet_controller.dart';
import 'preset_list_sheet.dart';
import 'recent_sheets_page.dart';
import 'settings_page.dart';
import 'sheet_config_sheet.dart';
import 'upgrade_page.dart';

enum _PdfExportAction { systemPrint, saveFile, share }

enum _AppTab { practice, recent, settings }

/// 应用主壳：底部导航在字帖、最近字帖与设置之间切换。
class AppShellPage extends StatefulWidget {
  const AppShellPage({
    super.key,
    required this.localeController,
    required this.themeController,
  });

  final LocaleController localeController;
  final ThemeController themeController;

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage> {
  late final PracticeSheetController _controller = PracticeSheetController();
  final _quota = UsageQuotaService.instance;
  final _recentSheets = RecentSheetsService.instance;
  final _presets = PresetListService.instance;
  bool _printInFlight = false;

  _AppTab _tab = _AppTab.practice;

  @override
  void initState() {
    super.initState();
    _quota.addListener(_onQuotaChanged);
    _controller.load();
    _presets.load();
  }

  @override
  void dispose() {
    _quota.removeListener(_onQuotaChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onQuotaChanged() {
    if (mounted) setState(() {});
  }

  void _selectTab(_AppTab tab) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _tab = tab);
  }

  Future<bool> _openUpgradePage() async {
    final unlocked = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => const UpgradePage(asPaywall: true),
      ),
    );
    return unlocked == true || _quota.isUnlocked;
  }

  Future<void> _applyPreset(PresetSheetList preset) async {
    await _presets.recordUse(preset.id);
    _controller.textController.text = preset.text;
    await _onGenerate();
  }

  Future<void> _openPresetSheet({String? initialCategoryId}) async {
    final catalog = _presets.catalog;
    if (catalog == null) {
      if (_presets.isLoading) return;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.presetLoadFailed)),
      );
      return;
    }
    if (!mounted) return;
    await showPresetListSheet(
      context,
      catalog: catalog,
      recentPresets: _presets.recentPresets,
      initialCategoryId: initialCategoryId,
      onSelected: _applyPreset,
    );
  }

  Future<void> _onGenerate() async {
    FocusScope.of(context).unfocus();
    if (!_quota.canGenerate) {
      await _openUpgradePage();
      if (!_quota.canGenerate) return;
    }

    final countBefore = _quota.generationCount;
    await _controller.generate();
    if (!mounted) return;

    if (_controller.hasSheet &&
        !_quota.isUnlocked &&
        _quota.generationCount == countBefore) {
      await _quota.recordSuccessfulGeneration();
    }

    if (_controller.hasSheet) {
      await _recentSheets.add(_controller.generatedCharacters);
    }

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
    if (_printInFlight) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.printBusy)),
      );
      return;
    }
    _printInFlight = true;
    try {
      final bytes = await _buildSheetPdfBytes();
      if (!mounted) return;
      await PracticeSheetPdfService.layoutPrint(
        rows: _controller.sheetRows,
        traceSlots: _controller.traceSlots,
        blankSlots: _controller.blankSlots,
        name: _sheetPdfBaseName(),
        bytes: bytes,
      );
    } catch (e, st) {
      debugPrint('Print failed: $e\n$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.printFailed('$e'))),
      );
    } finally {
      _printInFlight = false;
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

  Future<void> _restoreSavedSheet(SavedPracticeSheet saved) async {
    await _controller.restoreFromCharacters(saved.characters);
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

  Future<void> _onRecentSheetSelected(SavedPracticeSheet sheet) async {
    _selectTab(_AppTab.practice);
    await _restoreSavedSheet(sheet);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: MediaQuery.removeViewInsets(
        context: context,
        removeBottom: true,
        child: IndexedStack(
          index: _tab.index,
          children: [
            _PracticeTab(
              controller: _controller,
              quota: _quota,
              presets: _presets,
              onGenerate: _onGenerate,
              onPdfExportMenu: _onPdfExportMenu,
              onPresetSelected: _applyPreset,
              onOpenPresetSheet: _openPresetSheet,
            ),
            RecentSheetsPage(onSheetSelected: _onRecentSheetSelected),
            SettingsPage(
              localeController: widget.localeController,
              themeController: widget.themeController,
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab.index,
        onDestinationSelected: (index) => _selectTab(_AppTab.values[index]),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.edit_note_outlined),
            selectedIcon: const Icon(Icons.edit_note),
            label: l10n.navTabPractice,
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_outlined),
            selectedIcon: const Icon(Icons.history),
            label: l10n.recentSheetsTitle,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l10n.settingsTitle,
          ),
        ],
      ),
    );
  }
}

class _PracticeTab extends StatelessWidget {
  const _PracticeTab({
    required this.controller,
    required this.quota,
    required this.presets,
    required this.onGenerate,
    required this.onPdfExportMenu,
    required this.onPresetSelected,
    required this.onOpenPresetSheet,
  });

  final PracticeSheetController controller;
  final UsageQuotaService quota;
  final PresetListService presets;
  final VoidCallback onGenerate;
  final ValueChanged<_PdfExportAction> onPdfExportMenu;
  final ValueChanged<PresetSheetList> onPresetSelected;
  final Future<void> Function({String? initialCategoryId}) onOpenPresetSheet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return AnimatedBuilder(
      animation: Listenable.merge([controller, quota, presets]),
      builder: (context, _) {
        return Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            title: Text(l10n.appTitle),
            centerTitle: true,
            leading: IconButton(
              tooltip: l10n.sheetConfigTooltip,
              icon: const Icon(Icons.tune_outlined),
              onPressed: () => showSheetConfigSheet(context, controller),
            ),
            actions: [
              PopupMenuButton<_PdfExportAction>(
                tooltip: l10n.exportPdfTooltip,
                enabled: controller.hasSheet && !controller.loading,
                icon: const Icon(Icons.upload_file_outlined),
                onSelected: onPdfExportMenu,
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
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ControlBar(
                controller: controller,
                onGenerate: onGenerate,
                theme: theme,
                quota: quota,
                featuredPresets: presets.featuredPresets,
                onPresetSelected: onPresetSelected,
                onOpenPresetSheet: () => onOpenPresetSheet(),
              ),
              SizedBox(
                height: 3,
                width: double.infinity,
                child: controller.loading
                    ? const LinearProgressIndicator(minHeight: 3)
                    : const SizedBox.shrink(),
              ),
              Expanded(
                child: _PreviewBody(
                  controller: controller,
                  theme: theme,
                  featuredPresets: presets.featuredPresets,
                  onPresetSelected: onPresetSelected,
                  onOpenPresetSheet: () => onOpenPresetSheet(),
                ),
              ),
            ],
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
    required this.quota,
    required this.featuredPresets,
    required this.onPresetSelected,
    required this.onOpenPresetSheet,
  });

  final PracticeSheetController controller;
  final VoidCallback onGenerate;
  final ThemeData theme;
  final UsageQuotaService quota;
  final List<PresetSheetList> featuredPresets;
  final ValueChanged<PresetSheetList> onPresetSelected;
  final VoidCallback onOpenPresetSheet;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (quota.billingEnforced && !quota.isUnlocked)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  l10n.quotaRemaining(quota.remainingFree),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            isNarrow
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
            if (featuredPresets.isNotEmpty) ...[
              const SizedBox(height: 10),
              PresetQuickChips(
                presets: featuredPresets,
                onPresetSelected: onPresetSelected,
                onMore: onOpenPresetSheet,
              ),
            ],
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
    required this.featuredPresets,
    required this.onPresetSelected,
    required this.onOpenPresetSheet,
  });

  final PracticeSheetController controller;
  final ThemeData theme;
  final List<PresetSheetList> featuredPresets;
  final ValueChanged<PresetSheetList> onPresetSelected;
  final VoidCallback onOpenPresetSheet;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rows =
        controller.hasSheet ? controller.sheetRows : const <PracticeSheetEntry>[];

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
                  ? A4PracticeSheetPreview(
                      rows: rows,
                      traceSlots: controller.traceSlots,
                      blankSlots: controller.blankSlots,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.emptyStateBody(controller.maxMultiCharacters),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                        if (featuredPresets.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Text(
                            l10n.presetEmptyHint,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          PresetQuickChips(
                            presets: featuredPresets,
                            onPresetSelected: onPresetSelected,
                            onMore: onOpenPresetSheet,
                            centered: true,
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}
