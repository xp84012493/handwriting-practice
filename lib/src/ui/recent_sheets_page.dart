import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n_extension.dart';
import '../models/saved_practice_sheet.dart';
import '../services/recent_sheets_service.dart';

/// Lists locally saved practice sheets; tap to restore, batch delete via selection.
class RecentSheetsPage extends StatefulWidget {
  const RecentSheetsPage({
    super.key,
    this.onSheetSelected,
  });

  /// When set (bottom tab), restores sheet via callback instead of popping route.
  final ValueChanged<SavedPracticeSheet>? onSheetSelected;

  @override
  State<RecentSheetsPage> createState() => _RecentSheetsPageState();
}

class _RecentSheetsPageState extends State<RecentSheetsPage> {
  final Set<String> _selectedIds = {};

  static const _listTilePadding = EdgeInsets.symmetric(horizontal: 16);
  static const _minLeadingWidth = 40.0;
  static const _horizontalTitleGap = 8.0;

  static String _previewTitle(String characters, {int maxGlyphs = 18}) {
    final runes = characters.runes.toList();
    if (runes.length <= maxGlyphs) return characters;
    return '${String.fromCharCodes(runes.take(maxGlyphs))}…';
  }

  static String _formatWhen(BuildContext context, DateTime when) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).add_Hm().format(when);
  }

  bool? _selectAllValue(List<SavedPracticeSheet> items) {
    if (items.isEmpty || _selectedIds.isEmpty) return false;
    if (_selectedIds.length == items.length) return true;
    return null;
  }

  void _toggleItem(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _toggleSelectAll(List<SavedPracticeSheet> items) {
    setState(() {
      final allSelected =
          items.isNotEmpty && _selectedIds.length == items.length;
      if (allSelected) {
        _selectedIds.clear();
      } else {
        _selectedIds
          ..clear()
          ..addAll(items.map((s) => s.id));
      }
    });
  }

  Future<void> _confirmDeleteSelected(RecentSheetsService service) async {
    if (_selectedIds.isEmpty) return;
    final l10n = context.l10n;
    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.recentSheetsDeleteSelectedTitle),
        content: Text(l10n.recentSheetsDeleteSelectedBody(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.recentSheetsClearAllCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.recentSheetsDelete),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await service.removeMany(_selectedIds);
      setState(_selectedIds.clear);
    }
  }

  void _openSheet(SavedPracticeSheet sheet) {
    if (widget.onSheetSelected != null) {
      widget.onSheetSelected!(sheet);
    } else {
      Navigator.of(context).pop<SavedPracticeSheet>(sheet);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final service = RecentSheetsService.instance;
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final items = service.items;

        return Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            title: Text(l10n.recentSheetsTitle),
            automaticallyImplyLeading: false,
            actions: [
              if (items.isNotEmpty)
                IconButton(
                  tooltip: l10n.recentSheetsDeleteSelected,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _selectedIds.isEmpty
                      ? null
                      : () => _confirmDeleteSelected(service),
                ),
            ],
          ),
          body: items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.recentSheetsEmpty,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: items.length + 1,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return ListTile(
                        contentPadding: _listTilePadding,
                        minLeadingWidth: _minLeadingWidth,
                        horizontalTitleGap: _horizontalTitleGap,
                        leading: _RoundCheckbox(
                          value: _selectAllValue(items),
                          tristate: true,
                          onChanged: (_) => _toggleSelectAll(items),
                        ),
                        title: Text(l10n.recentSheetsSelectAll),
                        onTap: () => _toggleSelectAll(items),
                      );
                    }

                    final sheet = items[index - 1];
                    final selected = _selectedIds.contains(sheet.id);
                    return ListTile(
                      contentPadding: _listTilePadding,
                      minLeadingWidth: _minLeadingWidth,
                      horizontalTitleGap: _horizontalTitleGap,
                      leading: _RoundCheckbox(
                        value: selected,
                        onChanged: (_) => _toggleItem(sheet.id),
                      ),
                      title: Text(
                        _previewTitle(sheet.characters),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              letterSpacing: 1.5,
                            ),
                      ),
                      subtitle: Text(
                        l10n.recentSheetsItemSubtitle(
                          sheet.characterCount,
                          _formatWhen(context, sheet.createdAt),
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _openSheet(sheet),
                    );
                  },
                ),
        );
      },
    );
  }
}

class _RoundCheckbox extends StatelessWidget {
  const _RoundCheckbox({
    required this.value,
    required this.onChanged,
    this.tristate = false,
  });

  final bool? value;
  final bool tristate;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Checkbox(
      value: value,
      tristate: tristate,
      shape: const CircleBorder(),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      onChanged: onChanged,
    );
  }
}
