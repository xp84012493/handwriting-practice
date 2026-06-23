import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_build_info.dart';
import '../l10n/l10n_extension.dart';

/// 关于：简介、版本、第三方数据说明、系统许可页。
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  void _openLicensePage(BuildContext context) {
    final l10n = context.l10n;
    showLicensePage(
      context: context,
      applicationName: l10n.appTitle,
      applicationVersion: kAppVersion,
      applicationLegalese: l10n.licenseLegalese,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(
            l10n.appTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.versionLabel(kAppVersion),
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          Text(l10n.featureOverviewTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            l10n.featureOverviewBody,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 20),
          Text(l10n.strokeDataTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            l10n.strokeDataBody,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const _ThirdPartyNoticesViewPage(),
                ),
              );
            },
            icon: const Icon(Icons.article_outlined),
            label: Text(l10n.thirdPartyNoticesButton),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _openLicensePage(context),
            icon: const Icon(Icons.gavel_outlined),
            label: Text(l10n.openSourceLicensesButton),
          ),
          const SizedBox(height: 24),
          Text(l10n.notesTitle, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Text(
            l10n.notesBody,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThirdPartyNoticesViewPage extends StatefulWidget {
  const _ThirdPartyNoticesViewPage();

  @override
  State<_ThirdPartyNoticesViewPage> createState() =>
      _ThirdPartyNoticesViewPageState();
}

class _ThirdPartyNoticesViewPageState extends State<_ThirdPartyNoticesViewPage> {
  late final Future<String> _load = rootBundle.loadString(
    'THIRD_PARTY_NOTICES.md',
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.thirdPartyNoticesTitle)),
      body: FutureBuilder<String>(
        future: _load,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.thirdPartyNoticesLoadError('${snapshot.error}'),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final text = snapshot.data ?? '';
          return SelectionArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.45,
                    ),
              ),
            ),
          );
        },
      ),
    );
  }
}
