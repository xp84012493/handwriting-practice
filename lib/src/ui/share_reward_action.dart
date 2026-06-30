import 'package:flutter/material.dart';

import '../config/app_share_config.dart';
import '../l10n/l10n_extension.dart';
import '../services/app_share_service.dart';
import '../services/usage_quota_service.dart';
import 'share_position_origin.dart';

/// 调起系统分享并在成功后发放免费次数奖励。
Future<void> runShareForBonus(BuildContext context) async {
  final l10n = context.l10n;
  final message = l10n.shareAppMessage(
    l10n.appTitle,
    AppShareConfig.appStoreUrl,
  );
  final outcome = await AppShareService.instance.shareForBonus(
    message: message,
    sharePositionOrigin: sharePositionOriginFor(context),
  );
  if (!context.mounted) return;

  final text = switch (outcome) {
    ShareRewardOutcome.granted => l10n.shareRewardGranted(
        UsageQuotaService.bonusGenerationsPerShare,
      ),
    ShareRewardOutcome.limitReached => l10n.shareRewardLimitReached,
    ShareRewardOutcome.cancelled => l10n.shareRewardCancelled,
    ShareRewardOutcome.unavailable => l10n.shareRewardUnavailable,
    ShareRewardOutcome.notApplicable => null,
  };
  if (text != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }
}
