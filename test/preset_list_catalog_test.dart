import 'package:flutter_test/flutter_test.dart';
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
  });
}
