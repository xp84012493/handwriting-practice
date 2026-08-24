import 'package:flutter_test/flutter_test.dart';
import 'package:hanzi_practice_engine/src/models/localized_label.dart';
import 'package:hanzi_practice_engine/src/models/preset_sheet_list.dart';
import 'package:hanzi_practice_engine/src/parsers/preset_list_catalog_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PresetListCatalogLoader', () {
    late PresetListCatalogLoader loader;

    setUp(() {
      loader = const PresetListCatalogLoader();
    });

    test('loads asset and validates hanzi text', () async {
      final catalog = await loader.loadFromAsset();

      expect(catalog.schemaVersion, 1);
      expect(catalog.categories.isNotEmpty, isTrue);
      expect(catalog.allLists.isNotEmpty, isTrue);

      final ids = catalog.allLists.map((l) => l.id).toList();
      expect(ids.toSet().length, ids.length, reason: 'list id 应全局唯一');

      for (final list in catalog.allLists) {
        expect(
          PresetListCatalogLoader.sanitizeHanziText(list.text),
          list.text,
        );
      }
    });

    test('findById returns preset', () async {
      final catalog = await loader.loadFromAsset();
      final preset = catalog.findById('grade1_unit1');
      expect(preset, isNotNull);
      expect(preset!.text, contains('天'));
    });

    test('includes tang300 category with poems', () async {
      final catalog = await loader.loadFromAsset();
      final tang = catalog.categories.where((c) => c.id == 'tang300').toList();
      expect(tang, hasLength(1));
      expect(tang.first.lists.length, greaterThanOrEqualTo(300));

      final jingyesi = catalog.findById('tang300_233');
      expect(jingyesi, isNotNull);
      expect(jingyesi!.text, contains('床前明月光'));
      expect(jingyesi.tags, contains('李白'));
    });

    test('search finds poems by title author and content', () async {
      final catalog = await loader.loadFromAsset();

      expect(catalog.search('静夜思'), isNotEmpty);
      expect(catalog.search('夜思'), isNotEmpty);
      expect(catalog.search('李白').length, greaterThan(5));
      expect(catalog.search('明月').length, greaterThan(3));
      expect(catalog.search('五言绝句').length, greaterThan(10));
      expect(catalog.search('xyznotfound'), isEmpty);
    });
  });

  group('PresetSheetList.matchesSearch', () {
    const preset = PresetSheetList(
      id: 'test',
      title: LocalizedLabel(zh: '春晓'),
      description: LocalizedLabel(zh: '孟浩然 · 五言绝句'),
      text: '春眠不觉晓处处闻啼鸟',
      tags: ['tang300', '孟浩然'],
    );

    test('matches title author and text', () {
      expect(preset.matchesSearch('春晓'), isTrue);
      expect(preset.matchesSearch('孟浩然'), isTrue);
      expect(preset.matchesSearch('啼鸟'), isTrue);
      expect(preset.matchesSearch('律诗'), isFalse);
    });
  });
}
