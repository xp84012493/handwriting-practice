import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';
import '../models/saved_practice_sheet.dart';
import '../locale/locale_controller.dart';
import '../theme/theme_controller.dart';
import '../services/recent_sheets_service.dart';
import '../services/usage_quota_service.dart';
import 'about_page.dart';
import 'language_settings_page.dart';
import 'recent_sheets_page.dart';
import 'share_reward_action.dart';
import 'theme_settings_page.dart';
import 'upgrade_page.dart';

/// 设置：语言、主题、关于等入口。
class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.localeController,
    required this.themeController,
  });

  final LocaleController localeController;
  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final quota = UsageQuotaService.instance;
    final recentSheets = RecentSheetsService.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([
        localeController,
        themeController,
        quota,
        recentSheets,
      ]),
      builder: (context, _) {
        final languageSubtitle = LanguageSettingsPage.currentLanguageLabel(
          context.l10n,
          localeController,
        );
        final themeSubtitle = ThemeSettingsPage.currentThemeLabel(
          context.l10n,
          themeController,
        );
        final upgradeSubtitle = quota.isUnlocked
            ? l10n.settingsUpgradeSubtitleUnlocked
            : l10n.settingsUpgradeSubtitleRemaining(
                quota.remainingFree,
                quota.effectiveFreeLimit,
              );
        final shareSubtitle = quota.canClaimShareReward
            ? l10n.settingsShareSubtitleAvailable(
                UsageQuotaService.bonusGenerationsPerShare,
                quota.shareRewardsRemaining,
              )
            : l10n.settingsShareSubtitleDone;
        final recentSubtitle = recentSheets.isEmpty
            ? l10n.recentSheetsSettingsEmpty
            : l10n.recentSheetsSettingsCount(recentSheets.items.length);
        return Scaffold(
          appBar: AppBar(title: Text(l10n.settingsTitle)),
          body: ListView(
            children: [
              if (quota.billingEnforced)
                ListTile(
                  leading: const Icon(Icons.auto_fix_high_outlined),
                  title: Text(l10n.settingsUpgradeTitle),
                  subtitle: Text(upgradeSubtitle),
                  trailing: quota.isUnlocked
                      ? Icon(
                          Icons.check_circle_outline,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                ),
              if (quota.billingEnforced && !quota.isUnlocked)
                ListTile(
                  leading: const Icon(Icons.lock_open_outlined),
                  title: Text(l10n.settingsPurchaseTitle),
                  subtitle: Text(l10n.settingsPurchaseSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => const UpgradePage(),
                      ),
                    );
                  },
                ),
              if (quota.billingEnforced && !quota.isUnlocked)
                Builder(
                  builder: (shareContext) {
                    return ListTile(
                      leading: const Icon(Icons.share_outlined),
                      title: Text(l10n.settingsShareTitle),
                      subtitle: Text(shareSubtitle),
                      enabled: quota.canClaimShareReward,
                      onTap: quota.canClaimShareReward
                          ? () => runShareForBonus(shareContext)
                          : null,
                    );
                  },
                ),
              ListTile(
                leading: const Icon(Icons.history_outlined),
                title: Text(l10n.recentSheetsTitle),
                subtitle: Text(recentSubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final saved =
                      await Navigator.of(context).push<SavedPracticeSheet>(
                    MaterialPageRoute<SavedPracticeSheet>(
                      builder: (context) => const RecentSheetsPage(),
                    ),
                  );
                  if (saved != null && context.mounted) {
                    Navigator.of(context).pop(saved);
                  }
                },
              ),
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
                leading: const Icon(Icons.palette_outlined),
                title: Text(l10n.themeTitle),
                subtitle: Text(themeSubtitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => ThemeSettingsPage(
                        themeController: themeController,
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
