import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hanzi_practice_engine/src/models/saved_practice_sheet.dart';
import 'package:hanzi_practice_engine/src/services/recent_sheets_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await RecentSheetsService.instance.load();
  });

  test('add moves duplicate to top and caps list length', () async {
    final service = RecentSheetsService.instance;
    await service.clear();

    await service.add('一二三');
    await service.add('四五六');
    await service.add('一二三');

    expect(service.items.length, 2);
    expect(service.items.first.characters, '一二三');
    expect(service.items.last.characters, '四五六');
  });

  test('remove and clear', () async {
    final service = RecentSheetsService.instance;
    await service.clear();
    await service.add('永');

    final id = service.items.single.id;
    await service.remove(id);
    expect(service.isEmpty, isTrue);

    await service.add('永');
    await service.clear();
    expect(service.isEmpty, isTrue);
  });

  test('removeMany deletes only selected ids', () async {
    final service = RecentSheetsService.instance;
    await service.clear();
    await service.add('一');
    await service.add('二');
    await service.add('三');

    final ids = service.items.map((s) => s.id).toList();
    await service.removeMany([ids[0], ids[2]]);

    expect(service.items.length, 1);
    expect(service.items.single.characters, '二');
  });

  test('SavedPracticeSheet json roundtrip', () {
    final sheet = SavedPracticeSheet.create('测试');
    final restored = SavedPracticeSheet.fromJson(sheet.toJson());
    expect(restored.characters, '测试');
    expect(restored.createdAtMs, sheet.createdAtMs);
  });
}
