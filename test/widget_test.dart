import 'package:flutter_test/flutter_test.dart';

import 'package:hanzi_practice_engine/main.dart';

void main() {
  testWidgets('home screen smoke: title and generate button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const HanziPracticeApp());
    await tester.pumpAndSettle();

    expect(find.text('汉字笔顺字帖'), findsOneWidget);
    expect(find.text('生成字帖'), findsOneWidget);
  });

  testWidgets('about opens from app bar', (WidgetTester tester) async {
    await tester.pumpWidget(const HanziPracticeApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('关于'));
    await tester.pumpAndSettle();

    expect(find.text('关于'), findsOneWidget);
    expect(find.textContaining('Make Me a Hanzi'), findsOneWidget);
  });
}
