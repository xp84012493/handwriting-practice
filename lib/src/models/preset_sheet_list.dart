import 'localized_label.dart';

/// 单条预设字帖：一组汉字（可多字、可词组），生成时每字一行。
class PresetSheetList {
  const PresetSheetList({
    required this.id,
    required this.title,
    required this.text,
    this.sortOrder = 0,
    this.description,
    this.tags = const [],
    this.source,
  });

  /// 稳定 ID，用于去重与埋点（如 `grade1_unit1`）。
  final String id;

  /// 列表项标题（如「第一单元」「春天常用字」）。
  final LocalizedLabel title;

  /// 仅含基本汉字（U+4E00–U+9FFF），无空格与标点；与输入框一致。
  final String text;

  /// 分类内排序，越小越靠前。
  final int sortOrder;

  /// 可选副标题（如「约 10 字 · 人教版上册」）。
  final LocalizedLabel? description;

  /// 自由标签，便于筛选（`grade1`、`season`、`festival`）。
  final List<String> tags;

  /// 可选出处说明（展示用，如教材版本）。
  final LocalizedLabel? source;

  /// 去重后的汉字个数（按 Unicode 字符计）。
  int get characterCount => text.runes.length;

  factory PresetSheetList.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String || id.trim().isEmpty) {
      throw FormatException('PresetSheetList 缺少有效的 id');
    }
    final title = json['title'];
    if (title is! Map<String, dynamic>) {
      throw FormatException('PresetSheetList.$id 缺少 title');
    }
    final text = json['text'];
    if (text is! String || text.trim().isEmpty) {
      throw FormatException('PresetSheetList.$id 缺少有效的 text');
    }

    LocalizedLabel? description;
    final descJson = json['description'];
    if (descJson is Map<String, dynamic>) {
      description = LocalizedLabel.fromJson(descJson);
    }

    LocalizedLabel? source;
    final sourceJson = json['source'];
    if (sourceJson is Map<String, dynamic>) {
      source = LocalizedLabel.fromJson(sourceJson);
    }

    final tagsRaw = json['tags'];
    final tags = tagsRaw is List
        ? tagsRaw
            .whereType<String>()
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList(growable: false)
        : const <String>[];

    return PresetSheetList(
      id: id.trim(),
      title: LocalizedLabel.fromJson(title),
      text: text.trim(),
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      description: description,
      tags: tags,
      source: source,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title.toJson(),
        'text': text,
        if (sortOrder != 0) 'sortOrder': sortOrder,
        if (description != null) 'description': description!.toJson(),
        if (tags.isNotEmpty) 'tags': tags,
        if (source != null) 'source': source!.toJson(),
      };
}

/// 预设分类（如「一年级生字」「节日主题」）。
class PresetListCategory {
  const PresetListCategory({
    required this.id,
    required this.title,
    required this.lists,
    this.sortOrder = 0,
    this.icon,
  });

  final String id;
  final LocalizedLabel title;
  final List<PresetSheetList> lists;
  final int sortOrder;

  /// 可选 Material Icons 名（如 `school`、`eco`），UI 层映射。
  final String? icon;

  factory PresetListCategory.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String || id.trim().isEmpty) {
      throw FormatException('PresetListCategory 缺少有效的 id');
    }
    final title = json['title'];
    if (title is! Map<String, dynamic>) {
      throw FormatException('PresetListCategory.$id 缺少 title');
    }
    final listsRaw = json['lists'];
    if (listsRaw is! List || listsRaw.isEmpty) {
      throw FormatException('PresetListCategory.$id 缺少非空 lists');
    }

    final lists = listsRaw
        .map((e) {
          if (e is! Map<String, dynamic>) {
            throw FormatException('PresetListCategory.$id lists 元素格式错误');
          }
          return PresetSheetList.fromJson(e);
        })
        .toList(growable: false);

    PresetListCatalog._assertUniqueIds(
      lists.map((l) => l.id),
      'PresetListCategory.$id',
    );

    return PresetListCategory(
      id: id.trim(),
      title: LocalizedLabel.fromJson(title),
      lists: PresetListCatalog._sortedLists(lists),
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      icon: _optionalString(json['icon']),
    );
  }

  static String? _optionalString(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title.toJson(),
        'lists': lists.map((l) => l.toJson()).toList(),
        if (sortOrder != 0) 'sortOrder': sortOrder,
        if (icon != null) 'icon': icon,
      };
}

/// 根目录：`assets/preset_lists.json` 解析结果。
class PresetListCatalog {
  const PresetListCatalog({
    required this.schemaVersion,
    required this.categories,
  });

  static const String assetPath = 'assets/preset_lists.json';

  final int schemaVersion;
  final List<PresetListCategory> categories;

  /// 扁平化所有预设，按分类顺序 + 列表 sortOrder。
  List<PresetSheetList> get allLists {
    return categories
        .expand((c) => c.lists)
        .toList(growable: false);
  }

  PresetSheetList? findById(String id) {
    for (final category in categories) {
      for (final list in category.lists) {
        if (list.id == id) return list;
      }
    }
    return null;
  }

  factory PresetListCatalog.fromJson(Map<String, dynamic> json) {
    final version = json['schemaVersion'];
    if (version is! num) {
      throw FormatException('preset_lists 缺少 schemaVersion');
    }
    final categoriesRaw = json['categories'];
    if (categoriesRaw is! List || categoriesRaw.isEmpty) {
      throw FormatException('preset_lists 缺少非空 categories');
    }

    final categories = categoriesRaw
        .map((e) {
          if (e is! Map<String, dynamic>) {
            throw FormatException('categories 元素格式错误');
          }
          return PresetListCategory.fromJson(e);
        })
        .toList(growable: false);

    _assertUniqueIds(categories.map((c) => c.id), 'categories');
    _assertUniqueIds(
      categories.expand((c) => c.lists.map((l) => l.id)),
      'all lists',
    );

    return PresetListCatalog(
      schemaVersion: version.toInt(),
      categories: _sortedCategories(categories),
    );
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'categories': categories.map((c) => c.toJson()).toList(),
      };

  static List<PresetListCategory> _sortedCategories(
    List<PresetListCategory> items,
  ) {
    final copy = List<PresetListCategory>.from(items);
    copy.sort((a, b) {
      final byOrder = a.sortOrder.compareTo(b.sortOrder);
      if (byOrder != 0) return byOrder;
      return a.id.compareTo(b.id);
    });
    return copy;
  }

  static List<PresetSheetList> _sortedLists(List<PresetSheetList> items) {
    final copy = List<PresetSheetList>.from(items);
    copy.sort((a, b) {
      final byOrder = a.sortOrder.compareTo(b.sortOrder);
      if (byOrder != 0) return byOrder;
      return a.id.compareTo(b.id);
    });
    return copy;
  }

  static void _assertUniqueIds(Iterable<String> ids, String scope) {
    final seen = <String>{};
    for (final id in ids) {
      if (seen.contains(id)) {
        throw FormatException('preset_lists 中 $scope 存在重复 id: $id');
      }
      seen.add(id);
    }
  }
}
