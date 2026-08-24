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

    test('has four top-level categories after merge', () async {
      final catalog = await loader.loadFromAsset();
      expect(catalog.categories.length, 4);
      expect(catalog.categories.map((c) => c.id).toList(), [
        'classic_poetry',
        'textbook',
        'life',
        'practice',
      ]);
    });

    test('findById returns textbook preset', () async {
      final catalog = await loader.loadFromAsset();
      final preset = catalog.findById('textbook_g1_1');
      expect(preset, isNotNull);
      expect(preset!.text, contains('天'));
      expect(preset.section?.zh, '一年级');
    });

    test('includes classic poetry with tang300 poems', () async {
      final catalog = await loader.loadFromAsset();
      final poetry = catalog.categories.firstWhere((c) => c.id == 'classic_poetry');
      expect(poetry.lists.length, greaterThanOrEqualTo(300));

      final jingyesi = catalog.findById('tang300_233');
      expect(jingyesi, isNotNull);
      expect(jingyesi!.text, contains('床前明月光'));
      expect(jingyesi.section?.zh, '五言绝句');
    });

    test('textbook grade lists cover multiple chunks per grade', () async {
      final catalog = await loader.loadFromAsset();
      final textbook = catalog.categories.firstWhere((c) => c.id == 'textbook');
      final g1 = textbook.lists.where((l) => l.tags.contains('grade1')).length;
      final g2 = textbook.lists.where((l) => l.tags.contains('grade2')).length;
      final g3 = textbook.lists.where((l) => l.tags.contains('grade3')).length;
      expect(g1, greaterThanOrEqualTo(8));
      expect(g2, greaterThanOrEqualTo(6));
      expect(g3, greaterThanOrEqualTo(6));
    });

    test('search finds poems by title author and content', () async {
      final catalog = await loader.loadFromAsset();

      expect(catalog.search('静夜思'), isNotEmpty);
      expect(catalog.search('夜思'), isNotEmpty);
      expect(catalog.search('李白').length, greaterThan(5));
      expect(catalog.search('明月').length, greaterThan(3));
      expect(catalog.search('五言绝句').length, greaterThan(10));
      expect(catalog.search('一年级').length, greaterThan(5));
      expect(catalog.search('xyznotfound'), isEmpty);
    });
  });

  group('PresetSheetList.matchesSearch', () {
    final preset = PresetSheetList(
      id: 'test',
      title: const LocalizedLabel(zh: '春晓'),
      section: const LocalizedLabel(zh: '一年级'),
      description: const LocalizedLabel(zh: '孟浩然 · 五言绝句'),
      text: '春眠不觉晓处处闻啼鸟',
      tags: ['tang300', '孟浩然'],
    );

    test('matches title author section and text', () {
      expect(preset.matchesSearch('春晓'), isTrue);
      expect(preset.matchesSearch('孟浩然'), isTrue);
      expect(preset.matchesSearch('啼鸟'), isTrue);
      expect(preset.matchesSearch('一年级'), isTrue);
      expect(preset.matchesSearch('律诗'), isFalse);
    });
  });
}
