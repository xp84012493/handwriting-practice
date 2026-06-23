import 'package:flutter_test/flutter_test.dart';

import 'package:hanzi_practice_engine/l10n/app_localizations.dart';
import 'package:hanzi_practice_engine/main.dart';
import 'package:hanzi_practice_engine/src/locale/locale_controller.dart';

Future<void> _pumpApp(WidgetTester tester, {Locale? locale}) async {
  final localeController = LocaleController();
  await localeController.load();
  if (locale != null) {
    await localeController.setLocale(locale);
  }
  await tester.pumpWidget(
    HanziPracticeApp(localeController: localeController),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('home screen smoke (Chinese)', (WidgetTester tester) async {
    await _pumpApp(tester, locale: const Locale('zh'));

    expect(find.text('汉字笔顺字帖'), findsOneWidget);
    expect(find.text('生成字帖'), findsOneWidget);
  });

  testWidgets('home screen smoke (English)', (WidgetTester tester) async {
    await _pumpApp(tester, locale: const Locale('en'));

    expect(find.text('Hanzi Stroke Practice'), findsOneWidget);
    expect(find.text('Generate sheet'), findsOneWidget);
  });

  testWidgets('about opens from app bar', (WidgetTester tester) async {
    await _pumpApp(tester, locale: const Locale('zh'));

    await tester.tap(find.byTooltip('关于'));
    await tester.pumpAndSettle();

    expect(find.text('关于'), findsOneWidget);
    expect(find.textContaining('Make Me a Hanzi'), findsOneWidget);
    expect(find.text('语言'), findsOneWidget);
  });
}
