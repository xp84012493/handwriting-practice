import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_build_info.dart';

/// 关于：简介、版本、第三方数据说明、系统许可页。
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  void _openLicensePage(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: kAppName,
      applicationVersion: kAppVersion,
      applicationLegalese:
          '本应用 Dart/Flutter 源代码以 MIT License 发布（见仓库 LICENSE）。\n'
          '笔画轮廓数据来自 Make Me a Hanzi（graphics.txt），再分发须遵守 Arphic Public License；详见应用内「第三方说明」全文。',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('关于'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(
            kAppName,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text('版本 $kAppVersion', style: theme.textTheme.bodyLarge),
          const SizedBox(height: 20),
          Text(
            '功能简介',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '根据字库生成汉字笔顺练字帖预览，并可通过系统对话框打印或导出 PDF。'
            '当前为多字模式：每字一行版式，具体行数受 A4 可打印区域限制。',
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
          ),
          const SizedBox(height: 20),
          Text(
            '笔画数据来源',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '笔画矢量数据来自开源项目 Make Me a Hanzi 的 graphics.txt，'
            '基于文鼎 Arphic PL 字体衍生，许可证为 Arphic Public License（1999）。'
            '完整第三方声明与链接见下方「第三方说明全文」。',
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
            label: const Text('第三方说明全文'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _openLicensePage(context),
            icon: const Icon(Icons.gavel_outlined),
            label: const Text('开放源代码许可（Flutter 与各依赖）'),
          ),
          const SizedBox(height: 24),
          Text(
            '说明',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '「开放源代码许可」页由 Flutter 汇总本应用及各依赖库的许可证文本；'
            '其中可能包含与笔画数据无关的条目。笔画数据以「第三方说明全文」为准。',
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('第三方说明'),
      ),
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
                  '无法加载 THIRD_PARTY_NOTICES.md：${snapshot.error}',
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
