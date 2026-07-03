import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_practice_sheet.dart';

/// Persists recently generated practice sheets on device (characters + timestamp).
class RecentSheetsService extends ChangeNotifier {
  RecentSheetsService._();

  static final RecentSheetsService instance = RecentSheetsService._();

  static const _prefKey = 'recent_practice_sheets_v1';
  static const maxItems = 20;

  List<SavedPracticeSheet> _items = const [];
  bool _loaded = false;

  bool get isLoaded => _loaded;

  List<SavedPracticeSheet> get items => List.unmodifiable(_items);

  bool get isEmpty => _items.isEmpty;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == null || raw.isEmpty) {
      _items = const [];
    } else {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        _items = list
            .map((e) => SavedPracticeSheet.fromJson(e as Map<String, dynamic>))
            .where((s) => s.characters.isNotEmpty)
            .toList(growable: false);
      } catch (e, st) {
        debugPrint('RecentSheetsService.load failed: $e\n$st');
        _items = const [];
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> add(String characters) async {
    if (characters.isEmpty) return;
    await _ensureLoaded();
    _items = [
      SavedPracticeSheet.create(characters),
      ..._items.where((s) => s.characters != characters),
    ];
    if (_items.length > maxItems) {
      _items = _items.sublist(0, maxItems);
    }
    await _persist();
    notifyListeners();
  }

  Future<void> remove(String id) async {
    await _ensureLoaded();
    final next = _items.where((s) => s.id != id).toList(growable: false);
    if (next.length == _items.length) return;
    _items = next;
    await _persist();
    notifyListeners();
  }

  Future<void> removeMany(Iterable<String> ids) async {
    await _ensureLoaded();
    final idSet = ids.toSet();
    if (idSet.isEmpty) return;
    final next = _items.where((s) => !idSet.contains(s.id)).toList(growable: false);
    if (next.length == _items.length) return;
    _items = next;
    await _persist();
    notifyListeners();
  }

  Future<void> clear() async {
    await _ensureLoaded();
    if (_items.isEmpty) return;
    _items = const [];
    await _persist();
    notifyListeners();
  }

  Future<void> _ensureLoaded() async {
    if (!_loaded) await load();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_items.map((s) => s.toJson()).toList());
    await prefs.setString(_prefKey, encoded);
  }
}
