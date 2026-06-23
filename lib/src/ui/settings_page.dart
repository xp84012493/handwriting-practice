import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';
import '../locale/locale_controller.dart';
import 'about_page.dart';
import 'language_settings_page.dart';

/// 设置：语言、关于等入口。
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.localeController});

  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: localeController,
      builder: (context, _) {
        final languageSubtitle = LanguageSettingsPage.currentLanguageLabel(
          context.l10n,
          localeController,
        );
        return Scaffold(
          appBar: AppBar(title: Text(l10n.settingsTitle)),
          body: ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.translate_outlined),
                title: Text(l10n.languageTitle),
                subtitle: Text(languageSubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => LanguageSettingsPage(
                        localeController: localeController,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l10n.aboutTitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => const AboutPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
