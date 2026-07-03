import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n_extension.dart';
import '../models/saved_practice_sheet.dart';
import '../services/recent_sheets_service.dart';

/// Lists locally saved practice sheets; tap to restore, swipe to delete.
class RecentSheetsPage extends StatelessWidget {
  const RecentSheetsPage({
    super.key,
    this.onSheetSelected,
  });

  /// When set (bottom tab), restores sheet via callback instead of popping route.
  final ValueChanged<SavedPracticeSheet>? onSheetSelected;

  static String _previewTitle(String characters, {int maxGlyphs = 18}) {
    final runes = characters.runes.toList();
    if (runes.length <= maxGlyphs) return characters;
    return '${String.fromCharCodes(runes.take(maxGlyphs))}…';
  }

  static String _formatWhen(BuildContext context, DateTime when) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).add_Hm().format(when);
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
                  tooltip: l10n.recentSheetsClearAll,
                  icon: const Icon(Icons.delete_sweep_outlined),
                  onPressed: () => _confirmClearAll(context, service),
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
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final sheet = items[index];
                    return _RecentSheetTile(
                      sheet: sheet,
                      title: _previewTitle(sheet.characters),
                      subtitle: l10n.recentSheetsItemSubtitle(
                        sheet.characterCount,
                        _formatWhen(context, sheet.createdAt),
                      ),
                      onTap: () {
                        if (onSheetSelected != null) {
                          onSheetSelected!(sheet);
                        } else {
                          Navigator.of(context)
                              .pop<SavedPracticeSheet>(sheet);
                        }
                      },
                      onDelete: () => service.remove(sheet.id),
                    );
                  },
                ),
        );
      },
    );
  }

  Future<void> _confirmClearAll(
    BuildContext context,
    RecentSheetsService service,
  ) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.recentSheetsClearAllTitle),
        content: Text(l10n.recentSheetsClearAllBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.recentSheetsClearAllCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.recentSheetsClearAllConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await service.clear();
    }
  }
}

class _RecentSheetTile extends StatelessWidget {
  const _RecentSheetTile({
    required this.sheet,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.onDelete,
  });

  final SavedPracticeSheet sheet;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Dismissible(
      key: ValueKey(sheet.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(
          Icons.delete_outline,
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: Tooltip(
        message: sheet.characters.length > title.length
            ? sheet.characters
            : l10n.recentSheetsRestore,
        child: ListTile(
          leading: const Icon(Icons.description_outlined),
          title: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  letterSpacing: 1.5,
                ),
          ),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      ),
    );
  }
}
