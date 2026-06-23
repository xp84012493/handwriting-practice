import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../l10n/l10n_extension.dart';
import '../theme/theme_controller.dart';

/// 设置 → 主题外观。
class ThemeSettingsPage extends StatelessWidget {
  const ThemeSettingsPage({super.key, required this.themeController});

  final ThemeController themeController;

  static String currentThemeLabel(
    AppLocalizations l10n,
    ThemeController controller,
  ) {
    return switch (controller.preference) {
      AppThemePreference.system => l10n.themeFollowSystem,
      AppThemePreference.light => l10n.themeLight,
      AppThemePreference.dark => l10n.themeDark,
    };
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        final l10n = context.l10n;
        final selected = themeController.preference;
        return Scaffold(
          appBar: AppBar(title: Text(l10n.themeTitle)),
          body: ListView(
            children: [
              RadioListTile<AppThemePreference>(
                title: Text(l10n.themeFollowSystem),
                value: AppThemePreference.system,
                groupValue: selected,
                onChanged: (value) {
                  if (value != null) themeController.setPreference(value);
                },
              ),
              RadioListTile<AppThemePreference>(
                title: Text(l10n.themeLight),
                value: AppThemePreference.light,
                groupValue: selected,
                onChanged: (value) {
                  if (value != null) themeController.setPreference(value);
                },
              ),
              RadioListTile<AppThemePreference>(
                title: Text(l10n.themeDark),
                value: AppThemePreference.dark,
                groupValue: selected,
                onChanged: (value) {
                  if (value != null) themeController.setPreference(value);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
