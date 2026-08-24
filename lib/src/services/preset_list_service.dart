import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/preset_sheet_list.dart';
import '../parsers/preset_list_catalog_loader.dart';

/// 预设字帖目录加载与「最近使用」记录。
class PresetListService extends ChangeNotifier {
  PresetListService._();

  static final PresetListService instance = PresetListService._();

  /// 输入框下方快捷 chip 对应的预设 ID。
  static const List<String> featuredPresetIds = [
    'textbook_g1_1',
    'life_season_spring',
    'practice_strokes',
  ];

  static const String _keyRecentIds = 'preset_recent_ids';
  static const int maxRecentPresets = 5;

  final PresetListCatalogLoader _loader = const PresetListCatalogLoader();

  PresetListCatalog? _catalog;
  bool _loading = false;
  Object? _error;
  List<String> _recentIds = [];

  PresetListCatalog? get catalog => _catalog;
  bool get isLoaded => _catalog != null;
  bool get isLoading => _loading;
  Object? get error => _error;

  List<PresetSheetList> get featuredPresets {
    final cat = _catalog;
    if (cat == null) return const [];
    return featuredPresetIds
        .map(cat.findById)
        .whereType<PresetSheetList>()
        .toList(growable: false);
  }

  List<PresetSheetList> get recentPresets {
    final cat = _catalog;
    if (cat == null) return const [];
    return _recentIds
        .map(cat.findById)
        .whereType<PresetSheetList>()
        .toList(growable: false);
  }

  Future<void> load() async {
    if (_catalog != null) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _catalog = await _loader.loadFromAsset();
      final prefs = await SharedPreferences.getInstance();
      _recentIds = prefs.getStringList(_keyRecentIds) ?? [];
    } catch (e, st) {
      debugPrint('PresetListService.load failed: $e\n$st');
      _error = e;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> recordUse(String presetId) async {
    final next = [
      presetId,
      ..._recentIds.where((id) => id != presetId),
    ].take(maxRecentPresets).toList(growable: false);
    if (listEquals(next, _recentIds)) return;
    _recentIds = next;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyRecentIds, _recentIds);
  }

  int initialCategoryIndex({String? categoryId}) {
    final cat = _catalog;
    if (cat == null || cat.categories.isEmpty) return 0;
    if (categoryId == null) return 0;
    final index = cat.categories.indexWhere((c) => c.id == categoryId);
    return index >= 0 ? index : 0;
  }
}
