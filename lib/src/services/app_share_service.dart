import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

import 'usage_quota_service.dart';

/// 系统分享面板；用户完成分享后增加免费生成次数（有上限）。
class AppShareService {
  AppShareService._();

  static final AppShareService instance = AppShareService._();

  Future<ShareRewardOutcome> shareForBonus({
    required String message,
    Rect? sharePositionOrigin,
  }) async {
    final quota = UsageQuotaService.instance;
    if (!quota.billingEnforced || quota.isUnlocked) {
      return ShareRewardOutcome.notApplicable;
    }
    if (!quota.canClaimShareReward) {
      return ShareRewardOutcome.limitReached;
    }

    try {
      final result = await Share.share(
        message,
        subject: message.split('\n').first,
        sharePositionOrigin: sharePositionOrigin,
      );

      if (result.status == ShareResultStatus.unavailable) {
        return ShareRewardOutcome.unavailable;
      }

      if (result.status == ShareResultStatus.success) {
        final granted = await quota.claimShareReward();
        return granted
            ? ShareRewardOutcome.granted
            : ShareRewardOutcome.limitReached;
      }

      if (result.status == ShareResultStatus.dismissed) {
        return ShareRewardOutcome.cancelled;
      }

      return ShareRewardOutcome.cancelled;
    } catch (e, st) {
      debugPrint('shareForBonus failed: $e\n$st');
      return ShareRewardOutcome.unavailable;
    }
  }
}

enum ShareRewardOutcome {
  granted,
  limitReached,
  cancelled,
  unavailable,
  notApplicable,
}
