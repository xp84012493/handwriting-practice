import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n_extension.dart';
import '../models/saved_practice_sheet.dart';
import '../services/recent_sheets_service.dart';

/// Lists locally saved practice sheets; tap to restore, swipe to reveal delete.
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
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CheckboxListTile(
                      value: _selectAllValue(items),
                      tristate: true,
                      onChanged: (_) => _toggleSelectAll(items),
                      title: Text(l10n.recentSheetsSelectAll),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.only(bottom: 8),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final sheet = items[index];
                          final selected = _selectedIds.contains(sheet.id);
                          return _SwipeRevealDeleteTile(
                            onDelete: () async {
                              await service.remove(sheet.id);
                              if (mounted) {
                                setState(() => _selectedIds.remove(sheet.id));
                              }
                            },
                            deleteLabel: l10n.recentSheetsDelete,
                            child: ListTile(
                              leading: Checkbox(
                                value: selected,
                                onChanged: (_) => _toggleItem(sheet.id),
                              ),
                              title: Text(
                                _previewTitle(sheet.characters),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(letterSpacing: 1.5),
                              ),
                              subtitle: Text(
                                l10n.recentSheetsItemSubtitle(
                                  sheet.characterCount,
                                  _formatWhen(context, sheet.createdAt),
                                ),
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _openSheet(sheet),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

/// 左滑露出删除按钮；点击按钮后才删除（不随滑动手势直接删除）。
class _SwipeRevealDeleteTile extends StatefulWidget {
  const _SwipeRevealDeleteTile({
    required this.child,
    required this.onDelete,
    required this.deleteLabel,
  });

  final Widget child;
  final Future<void> Function() onDelete;
  final String deleteLabel;

  @override
  State<_SwipeRevealDeleteTile> createState() => _SwipeRevealDeleteTileState();
}

class _SwipeRevealDeleteTileState extends State<_SwipeRevealDeleteTile> {
  static const _actionWidth = 80.0;

  double _offset = 0;

  void _close() => setState(() => _offset = 0);

  Future<void> _onDeletePressed() async {
    await widget.onDelete();
    if (mounted) _close();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final offset = _offset.clamp(-_actionWidth, 0.0);

    return ClipRect(
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: _actionWidth,
                child: Material(
                  color: theme.colorScheme.errorContainer,
                  child: InkWell(
                    onTap: _onDeletePressed,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.delete_outline,
                            color: theme.colorScheme.onErrorContainer,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.deleteLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() {
                _offset =
                    (_offset + details.delta.dx).clamp(-_actionWidth, 0.0);
              });
            },
            onHorizontalDragEnd: (details) {
              setState(() {
                final velocity = details.primaryVelocity ?? 0;
                final open = _offset < -_actionWidth / 2 || velocity < -200;
                _offset = open ? -_actionWidth : 0;
              });
            },
            child: ColoredBox(
              color: theme.colorScheme.surface,
              child: Transform.translate(
                offset: Offset(offset, 0),
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
