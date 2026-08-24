import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';
import '../models/localized_label.dart';
import '../models/preset_sheet_list.dart';
import '../services/preset_list_service.dart';
import 'preset_category_icon.dart';

/// 底部弹层：分类 Tab + 关键字搜索 + 预设列表。
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
  late final TextEditingController _searchController;
  String _query = '';

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
    _searchController = TextEditingController();
    _searchController.addListener(() {
      final next = _searchController.text;
      if (next != _query) {
        setState(() => _query = next);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _pick(PresetSheetList preset) {
    Navigator.of(context).pop();
    widget.onSelected(preset);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _query = '');
  }

  bool get _isSearching => _query.trim().isNotEmpty;

  List<PresetSheetList> get _searchResults =>
      widget.catalog.search(_query);

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
            const SizedBox(height: 12),
            SearchBar(
              controller: _searchController,
              hintText: l10n.presetSearchHint,
              leading: const Icon(Icons.search),
              trailing: _isSearching
                  ? [
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                        tooltip: l10n.presetSearchClear,
                      ),
                    ]
                  : null,
              elevation: WidgetStateProperty.all(0),
              backgroundColor: WidgetStateProperty.all(
                theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              ),
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
            if (!_isSearching && widget.recentPresets.isNotEmpty) ...[
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
            if (_isSearching) ...[
              Text(
                l10n.presetSearchResultCount(_searchResults.length),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _searchResults.isEmpty
                    ? Center(
                        child: Text(
                          l10n.presetSearchEmpty,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(top: 4, bottom: 8),
                        itemCount: _searchResults.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final preset = _searchResults[index];
                          final category =
                              widget.catalog.categoryForPreset(preset);
                          return _PresetListTile(
                            preset: preset,
                            locale: locale,
                            categoryLabel: category?.title.resolve(locale),
                            onTap: () => _pick(preset),
                          );
                        },
                      ),
              ),
            ] else ...[
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
                    return _PresetCategoryListView(
                      lists: category.lists,
                      locale: locale,
                      onPick: _pick,
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PresetCategoryListView extends StatelessWidget {
  const _PresetCategoryListView({
    required this.lists,
    required this.locale,
    required this.onPick,
  });

  final List<PresetSheetList> lists;
  final Locale locale;
  final ValueChanged<PresetSheetList> onPick;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      itemCount: _rowCount(lists),
      itemBuilder: (context, index) {
        final row = _rowAt(lists, index);
        if (row.section != null) {
          return Padding(
            padding: EdgeInsets.only(
              top: index == 0 ? 0 : 12,
              bottom: 6,
            ),
            child: Text(
              row.section!.resolve(locale),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          );
        }
        final preset = row.preset!;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _PresetListTile(
            preset: preset,
            locale: locale,
            onTap: () => onPick(preset),
          ),
        );
      },
    );
  }

  static int _rowCount(List<PresetSheetList> lists) {
    var count = 0;
    String? lastSection;
    for (final list in lists) {
      final key = list.section?.zh;
      if (key != null && key != lastSection) {
        count += 1;
        lastSection = key;
      }
      count += 1;
    }
    return count;
  }

  static ({LocalizedLabel? section, PresetSheetList? preset}) _rowAt(
    List<PresetSheetList> lists,
    int index,
  ) {
    var i = 0;
    String? lastSection;
    for (final list in lists) {
      final key = list.section?.zh;
      if (key != null && key != lastSection) {
        if (i == index) return (section: list.section, preset: null);
        i += 1;
        lastSection = key;
      }
      if (i == index) return (section: null, preset: list);
      i += 1;
    }
    throw RangeError.index(index, lists, 'index');
  }
}

class _PresetListTile extends StatelessWidget {
  const _PresetListTile({
    required this.preset,
    required this.locale,
    required this.onTap,
    this.categoryLabel,
  });

  final PresetSheetList preset;
  final Locale locale;
  final VoidCallback onTap;
  final String? categoryLabel;

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
              if (categoryLabel != null) ...[
                const SizedBox(height: 4),
                Text(
                  categoryLabel!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                preset.text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 4,
                  height: 1.3,
                  fontSize: (theme.textTheme.headlineSmall?.fontSize ?? 24) *
                      (preset.characterCount > 28 ? 0.72 : 1.0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
