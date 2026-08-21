import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';
import '../models/preset_sheet_list.dart';
import '../services/preset_list_service.dart';
import 'preset_category_icon.dart';

/// 底部弹层：分类 Tab + 预设列表。
Future<void> showPresetListSheet(
  BuildContext context, {
  required PresetListCatalog catalog,
  required ValueChanged<PresetSheetList> onSelected,
  List<PresetSheetList> recentPresets = const [],
  String? initialCategoryId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return _PresetListSheet(
        catalog: catalog,
        onSelected: onSelected,
        recentPresets: recentPresets,
        initialCategoryId: initialCategoryId,
      );
    },
  );
}

class _PresetListSheet extends StatefulWidget {
  const _PresetListSheet({
    required this.catalog,
    required this.onSelected,
    required this.recentPresets,
    this.initialCategoryId,
  });

  final PresetListCatalog catalog;
  final ValueChanged<PresetSheetList> onSelected;
  final List<PresetSheetList> recentPresets;
  final String? initialCategoryId;

  @override
  State<_PresetListSheet> createState() => _PresetListSheetState();
}

class _PresetListSheetState extends State<_PresetListSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    final initialIndex = PresetListService.instance.initialCategoryIndex(
      categoryId: widget.initialCategoryId,
    );
    _tabController = TabController(
      length: widget.catalog.categories.length,
      vsync: this,
      initialIndex: initialIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _pick(PresetSheetList preset) {
    Navigator.of(context).pop();
    widget.onSelected(preset);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.75;

    return SizedBox(
      height: sheetHeight,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.presetSheetTitle,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.presetSheetSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (widget.recentPresets.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                l10n.presetRecentSection,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final preset in widget.recentPresets) ...[
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(preset.title.resolve(locale)),
                          onPressed: () => _pick(preset),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: widget.catalog.categories.map((category) {
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        presetCategoryIcon(category.icon),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(category.title.resolve(locale)),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: widget.catalog.categories.map((category) {
                  return ListView.separated(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    itemCount: category.lists.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final preset = category.lists[index];
                      return _PresetListTile(
                        preset: preset,
                        locale: locale,
                        onTap: () => _pick(preset),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetListTile extends StatelessWidget {
  const _PresetListTile({
    required this.preset,
    required this.locale,
    required this.onTap,
  });

  final PresetSheetList preset;
  final Locale locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    final meta = preset.description?.resolve(locale) ??
        l10n.presetCharacterCount(preset.characterCount);

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      preset.title.resolve(locale),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    meta,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                preset.text,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 4,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
