import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';

import '../l10n/l10n_extension.dart';
import '../layout/a4_sheet_layout.dart';
import '../style/practice_grid_style.dart';
import '../style/practice_sheet_font.dart';
import 'practice_sheet_controller.dart';

/// 字帖描红 / 空白格数 / 字体大小 / 有无笔画配置（全屏页，iOS/macOS 支持右滑缘返回）。
Future<void> showSheetConfigSheet(
  BuildContext context,
  PracticeSheetController controller,
) {
  final page = _SheetConfigSheet(controller: controller);
  final navigator = Navigator.of(context);
  if (defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    return navigator.push<void>(
      CupertinoPageRoute<void>(builder: (_) => page),
    );
  }
  return navigator.push<void>(
    MaterialPageRoute<void>(builder: (_) => page),
  );
}

class _SheetConfigSheet extends StatefulWidget {
  const _SheetConfigSheet({required this.controller});

  final PracticeSheetController controller;

  @override
  State<_SheetConfigSheet> createState() => _SheetConfigSheetState();
}

class _SheetConfigSheetState extends State<_SheetConfigSheet> {
  late final ScrollController _scrollController = ScrollController();

  late int _traceSlots = widget.controller.traceSlots;
  late int _blankSlots = widget.controller.blankSlots;
  late int _cellSizeMm = widget.controller.cellSizeMm.round();
  late bool _showStrokeOrder = widget.controller.showStrokeOrder;
  late SheetPageOrientation _pageOrientation =
      widget.controller.pageOrientation;
  late PracticeSheetFont _sheetFont = widget.controller.sheetFont;
  late PracticeGridStyle _gridStyle = widget.controller.gridStyle;
  late bool _showStrokeExamples = widget.controller.showStrokeExamples;
  late bool _showStrokePinyin = widget.controller.showStrokePinyin;
  late final TextEditingController _headerController = TextEditingController(
    text: widget.controller.sheetHeader,
  );

  int get _slotMax => PracticeSheetController.maxSlotsFor(
        showStrokeOrder: _showStrokeOrder,
        cellSizeMm: _cellSizeMm.toDouble(),
        orientation: _pageOrientation,
      );

  Future<void> _apply() async {
    await widget.controller.applyLayout(
      traceSlots: _traceSlots,
      blankSlots: _blankSlots,
      cellSizeMm: _cellSizeMm.toDouble(),
      showStrokeOrder: _showStrokeOrder,
      pageOrientation: _pageOrientation,
      sheetFont: _sheetFont,
      gridStyle: _gridStyle,
      showStrokeExamples: _showStrokeExamples,
      showStrokePinyin: _showStrokePinyin,
      sheetHeader: _headerController.text,
    );
    if (mounted) Navigator.of(context).pop();
  }

  /// 无笔画：调整描红格，使示范+描红+空白刚好占满一行（尽量保留空白格数）。
  void _fitTraceToPageWidth() {
    final practice = PracticeSheetController.practiceSlotsToFillLine(
      _cellSizeMm.toDouble(),
      orientation: _pageOrientation,
    );
    final maxS = _slotMax;
    HapticFeedback.selectionClick();
    setState(() {
      final blank = _blankSlots.clamp(0, practice);
      var trace = practice - blank;
      if (trace > maxS) {
        trace = maxS;
      }
      _traceSlots = trace;
      _blankSlots = practice - trace;
    });
  }

  /// 无笔画：调整空白格，使示范+描红+空白刚好占满一行（尽量保留描红格数）。
  void _fitBlankToPageWidth() {
    final practice = PracticeSheetController.practiceSlotsToFillLine(
      _cellSizeMm.toDouble(),
      orientation: _pageOrientation,
    );
    final maxS = _slotMax;
    HapticFeedback.selectionClick();
    setState(() {
      final trace = _traceSlots.clamp(0, practice);
      var blank = practice - trace;
      if (blank > maxS) {
        blank = maxS;
      }
      _blankSlots = blank;
      _traceSlots = practice - blank;
    });
  }

  void _resetDefaults() {
    HapticFeedback.selectionClick();
    setState(() {
      _showStrokeOrder = PracticeSheetController.defaultShowStrokeOrder;
      _pageOrientation = PracticeSheetController.defaultPageOrientation;
      _cellSizeMm = PracticeSheetController.defaultCellSizeMm.round();
      _traceSlots = PracticeSheetController.defaultTraceSlots;
      _blankSlots = PracticeSheetController.defaultBlankSlots;
      _sheetFont = PracticeSheetController.defaultSheetFont;
      _gridStyle = PracticeSheetController.defaultGridStyle;
      _showStrokeExamples = PracticeSheetController.defaultShowStrokeExamples;
      _showStrokePinyin = PracticeSheetController.defaultShowStrokePinyin;
      _headerController.text = PracticeSheetController.defaultSheetHeader;
    });
  }

  void _clampSlotsToMax() {
    final maxS = _slotMax;
    _traceSlots = _traceSlots.clamp(0, maxS);
    _blankSlots = _blankSlots.clamp(0, maxS);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _headerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final minMm = A4SheetLayout.minPracticeCellSizeMm.round();
    final maxMm = A4SheetLayout.maxPracticeCellSizeMm.round();
    final slotMax = _slotMax;
    final showFit = !_showStrokeOrder;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(l10n.sheetConfigTitle),
      ),
      body: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.sheetConfigSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.sheetConfigPageOrientation,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              _showStrokeOrder
                  ? l10n.sheetConfigPageOrientationHintStrokeOn
                  : l10n.sheetConfigPageOrientationHintStrokeOff,
              style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<SheetPageOrientation>(
              segments: [
                ButtonSegment<SheetPageOrientation>(
                  value: SheetPageOrientation.landscape,
                  label: Text(l10n.sheetConfigPageOrientationLandscape),
                  icon: const Icon(Icons.stay_current_landscape_outlined),
                ),
                ButtonSegment<SheetPageOrientation>(
                  value: SheetPageOrientation.portrait,
                  label: Text(l10n.sheetConfigPageOrientationPortrait),
                  icon: const Icon(Icons.stay_current_portrait_outlined),
                ),
              ],
              selected: {_pageOrientation},
              onSelectionChanged: (next) {
                HapticFeedback.selectionClick();
                setState(() {
                  _pageOrientation = next.first;
                  _clampSlotsToMax();
                });
              },
            ),
            if (_showStrokeOrder &&
                _pageOrientation == SheetPageOrientation.portrait) ...[
              const SizedBox(height: 8),
              Text(
                l10n.sheetConfigPageOrientationPortraitStrokeWarning,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.tertiary,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              l10n.sheetConfigGridStyle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.sheetConfigGridStyleHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<PracticeGridStyle>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment<PracticeGridStyle>(
                  value: PracticeGridStyle.mizi,
                  label: Text(l10n.sheetConfigGridMizi),
                ),
                ButtonSegment<PracticeGridStyle>(
                  value: PracticeGridStyle.tianzi,
                  label: Text(l10n.sheetConfigGridTianzi),
                ),
              ],
              selected: {_gridStyle},
              onSelectionChanged: (next) {
                HapticFeedback.selectionClick();
                setState(() => _gridStyle = next.first);
              },
            ),
            const SizedBox(height: 16),
            Text(
              l10n.sheetConfigStrokeOrder,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.sheetConfigStrokeOrderHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment<bool>(
                  value: true,
                  label: Text(l10n.sheetConfigStrokeOrderOn),
                ),
                ButtonSegment<bool>(
                  value: false,
                  label: Text(l10n.sheetConfigStrokeOrderOff),
                ),
              ],
              selected: {_showStrokeOrder},
              onSelectionChanged: (next) {
                HapticFeedback.selectionClick();
                setState(() {
                  _showStrokeOrder = next.first;
                  if (_showStrokeOrder) {
                    _showStrokeExamples = false;
                    _showStrokePinyin = false;
                  }
                  _clampSlotsToMax();
                });
              },
            ),
            const SizedBox(height: 16),
            Text(
              l10n.sheetConfigStrokeExamples,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.sheetConfigStrokeExamplesHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            IgnorePointer(
              ignoring: _showStrokeOrder,
              child: Opacity(
                opacity: _showStrokeOrder ? 0.45 : 1,
                child: SegmentedButton<bool>(
                  segments: [
                    ButtonSegment<bool>(
                      value: true,
                      label: Text(l10n.sheetConfigStrokeExamplesOn),
                    ),
                    ButtonSegment<bool>(
                      value: false,
                      label: Text(l10n.sheetConfigStrokeExamplesOff),
                    ),
                  ],
                  selected: {_showStrokeExamples},
                  onSelectionChanged: (next) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _showStrokeExamples = next.first;
                      if (!_showStrokeExamples) {
                        _showStrokePinyin = false;
                      }
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.sheetConfigStrokePinyin,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.sheetConfigStrokePinyinHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            IgnorePointer(
              ignoring: _showStrokeOrder || !_showStrokeExamples,
              child: Opacity(
                opacity: _showStrokeOrder || !_showStrokeExamples ? 0.45 : 1,
                child: SegmentedButton<bool>(
                  segments: [
                    ButtonSegment<bool>(
                      value: true,
                      label: Text(l10n.sheetConfigStrokePinyinOn),
                    ),
                    ButtonSegment<bool>(
                      value: false,
                      label: Text(l10n.sheetConfigStrokePinyinOff),
                    ),
                  ],
                  selected: {_showStrokePinyin},
                  onSelectionChanged: (next) {
                    HapticFeedback.selectionClick();
                    setState(() => _showStrokePinyin = next.first);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.sheetConfigFont,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.sheetConfigFontHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            IgnorePointer(
              ignoring: _showStrokeOrder,
              child: Opacity(
                opacity: _showStrokeOrder ? 0.45 : 1,
                child: SegmentedButton<PracticeSheetFont>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment<PracticeSheetFont>(
                      value: PracticeSheetFont.appDefault,
                      label: Text(l10n.sheetConfigFontDefault),
                    ),
                    ButtonSegment<PracticeSheetFont>(
                      value: PracticeSheetFont.wenKai,
                      label: Text(l10n.sheetConfigFontWenKai),
                    ),
                    ButtonSegment<PracticeSheetFont>(
                      value: PracticeSheetFont.zhenKai,
                      label: Text(l10n.sheetConfigFontZhenKai),
                    ),
                  ],
                  selected: {_sheetFont},
                  onSelectionChanged: (next) {
                    HapticFeedback.selectionClick();
                    setState(() => _sheetFont = next.first);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            _SlotStepper(
              label: l10n.sheetConfigCellSize,
              hint: l10n.sheetConfigCellSizeHint,
              valueLabel: l10n.sheetConfigCellSizeValue(_cellSizeMm),
              value: _cellSizeMm,
              min: minMm,
              max: maxMm,
              onChanged: (v) => setState(() {
                _cellSizeMm = v;
                _clampSlotsToMax();
              }),
            ),
            const SizedBox(height: 16),
            _SlotStepper(
              label: l10n.sheetConfigTraceSlots,
              hint: l10n.sheetConfigTraceHint,
              valueLabel: '$_traceSlots',
              value: _traceSlots,
              min: PracticeSheetController.minSlots,
              max: slotMax,
              onChanged: (v) => setState(() => _traceSlots = v),
              fitPageWidthLabel: showFit ? l10n.sheetConfigFitPageWidth : null,
              fitPageWidthTooltip:
                  showFit ? l10n.sheetConfigFitPageWidthHint : null,
              onFitPageWidth: showFit ? _fitTraceToPageWidth : null,
            ),
            const SizedBox(height: 16),
            _SlotStepper(
              label: l10n.sheetConfigBlankSlots,
              hint: l10n.sheetConfigBlankHint,
              valueLabel: '$_blankSlots',
              value: _blankSlots,
              min: PracticeSheetController.minSlots,
              max: slotMax,
              onChanged: (v) => setState(() => _blankSlots = v),
              fitPageWidthLabel: showFit ? l10n.sheetConfigFitPageWidth : null,
              fitPageWidthTooltip:
                  showFit ? l10n.sheetConfigFitPageWidthHint : null,
              onFitPageWidth: showFit ? _fitBlankToPageWidth : null,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.sheetConfigHeader,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.sheetConfigHeaderHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _headerController,
              maxLength: PracticeSheetController.maxSheetHeaderLength,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: l10n.sheetConfigHeaderPlaceholder,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        ),
      ),
      bottomNavigationBar: Material(
        elevation: 3,
        shadowColor: theme.shadowColor.withValues(alpha: 0.12),
        color: theme.colorScheme.surface,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetDefaults,
                    child: Text(l10n.sheetConfigResetDefaults),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _apply,
                    child: Text(l10n.sheetConfigDone),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SlotStepper extends StatelessWidget {
  const _SlotStepper({
    required this.label,
    required this.hint,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.fitPageWidthLabel,
    this.fitPageWidthTooltip,
    this.onFitPageWidth,
  });

  final String label;
  final String hint;
  final String valueLabel;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final String? fitPageWidthLabel;
  final String? fitPageWidthTooltip;
  final VoidCallback? onFitPageWidth;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          hint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton.filledTonal(
              tooltip: '-1',
              onPressed: value <= min
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      onChanged(value - 1);
                    },
              icon: const Icon(Icons.remove),
            ),
            Expanded(
              child: Text(
                valueLabel,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            IconButton.filledTonal(
              tooltip: '+1',
              onPressed: value >= max
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      onChanged(value + 1);
                    },
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        if (fitPageWidthLabel != null && onFitPageWidth != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Tooltip(
              message: fitPageWidthTooltip ?? fitPageWidthLabel!,
              child: TextButton.icon(
                onPressed: onFitPageWidth,
                icon: const Icon(Icons.view_week_outlined, size: 18),
                label: Text(fitPageWidthLabel!),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
