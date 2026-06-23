import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'l10n/app_localizations.dart';
import 'src/locale/locale_controller.dart';
import 'src/ui/handwriting_practice_home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(
      <String>['hanzi_practice_engine'],
      await rootBundle.loadString('LICENSE'),
    );
  });
  final localeController = LocaleController();
  await localeController.load();
  runApp(HanziPracticeApp(localeController: localeController));
}

class HanziPracticeApp extends StatelessWidget {
  const HanziPracticeApp({super.key, required this.localeController});

  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: localeController,
      builder: (context, _) {
        return MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF006A6A),
            ),
            useMaterial3: true,
          ),
          locale: localeController.locale,
          localeResolutionCallback: localeController.localeResolutionCallback,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HandwritingPracticeHomePage(
            localeController: localeController,
          ),
        );
      },
    );
  }
}
