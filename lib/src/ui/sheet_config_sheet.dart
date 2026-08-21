import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n_extension.dart';
import '../layout/a4_sheet_layout.dart';
import 'practice_sheet_controller.dart';

/// 字帖描红 / 空白格数 / 字体大小 / 有无笔画配置（底部弹层）。
Future<void> showSheetConfigSheet(
  BuildContext context,
  PracticeSheetController controller,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return _SheetConfigSheet(controller: controller);
    },
  );
}

class _SheetConfigSheet extends StatefulWidget {
  const _SheetConfigSheet({required this.controller});

  final PracticeSheetController controller;

  @override
  State<_SheetConfigSheet> createState() => _SheetConfigSheetState();
}

class _SheetConfigSheetState extends State<_SheetConfigSheet> {
  late int _traceSlots = widget.controller.traceSlots;
  late int _blankSlots = widget.controller.blankSlots;
  late int _cellSizeMm = widget.controller.cellSizeMm.round();
  late bool _showStrokeOrder = widget.controller.showStrokeOrder;

  Future<void> _apply() async {
    await widget.controller.applyLayout(
      traceSlots: _traceSlots,
      blankSlots: _blankSlots,
      cellSizeMm: _cellSizeMm.toDouble(),
      showStrokeOrder: _showStrokeOrder,
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final minMm = A4SheetLayout.minPracticeCellSizeMm.round();
    final maxMm = A4SheetLayout.maxPracticeCellSizeMm.round();

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.sheetConfigTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.sheetConfigSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 20),
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
              setState(() => _showStrokeOrder = next.first);
            },
          ),
          const SizedBox(height: 16),
          _SlotStepper(
            label: l10n.sheetConfigCellSize,
            hint: l10n.sheetConfigCellSizeHint,
            valueLabel: l10n.sheetConfigCellSizeValue(_cellSizeMm),
            value: _cellSizeMm,
            min: minMm,
            max: maxMm,
            onChanged: (v) => setState(() => _cellSizeMm = v),
          ),
          const SizedBox(height: 16),
          _SlotStepper(
            label: l10n.sheetConfigTraceSlots,
            hint: l10n.sheetConfigTraceHint,
            valueLabel: '$_traceSlots',
            value: _traceSlots,
            min: PracticeSheetController.minSlots,
            max: PracticeSheetController.maxSlots,
            onChanged: (v) => setState(() => _traceSlots = v),
          ),
          const SizedBox(height: 16),
          _SlotStepper(
            label: l10n.sheetConfigBlankSlots,
            hint: l10n.sheetConfigBlankHint,
            valueLabel: '$_blankSlots',
            value: _blankSlots,
            min: PracticeSheetController.minSlots,
            max: PracticeSheetController.maxSlots,
            onChanged: (v) => setState(() => _blankSlots = v),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _apply,
            child: Text(l10n.sheetConfigDone),
          ),
        ],
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
  });

  final String label;
  final String hint;
  final String valueLabel;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

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
      ],
    );
  }
}
