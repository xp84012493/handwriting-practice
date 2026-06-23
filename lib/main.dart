import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'l10n/app_localizations.dart';
import 'src/locale/locale_controller.dart';
import 'src/theme/app_theme.dart';
import 'src/theme/theme_controller.dart';
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
  final themeController = ThemeController();
  await Future.wait([
    localeController.load(),
    themeController.load(),
  ]);
  runApp(
    HanziPracticeApp(
      localeController: localeController,
      themeController: themeController,
    ),
  );
}

class HanziPracticeApp extends StatelessWidget {
  const HanziPracticeApp({
    super.key,
    required this.localeController,
    required this.themeController,
  });

  final LocaleController localeController;
  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([localeController, themeController]),
      builder: (context, _) {
        return MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeController.themeMode,
          locale: localeController.locale,
          localeResolutionCallback: localeController.localeResolutionCallback,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HandwritingPracticeHomePage(
            localeController: localeController,
            themeController: themeController,
          ),
        );
      },
    );
  }
}
