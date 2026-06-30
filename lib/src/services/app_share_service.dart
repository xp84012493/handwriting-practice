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
      final result = await SharePlus.instance.share(
        ShareParams(
          text: message,
          subject: message.split('\n').first,
          sharePositionOrigin: sharePositionOrigin,
        ),
      );

      if (result.status == ShareResultStatus.unavailable) {
        return ShareRewardOutcome.unavailable;
      }

      // iOS 常返回 dismissed；用户已打开并完成分享流程即发放（总次数有上限）。
      if (result.status == ShareResultStatus.success ||
          result.status == ShareResultStatus.dismissed) {
        final granted = await quota.claimShareReward();
        return granted
            ? ShareRewardOutcome.granted
            : ShareRewardOutcome.limitReached;
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
