import 'package:flutter/material.dart';

import '../l10n/l10n_extension.dart';
import '../services/unlock_billing_service.dart';
import '../services/usage_quota_service.dart';
import 'share_reward_action.dart';

/// Paywall: unlimited sheet generation after free quota.
class UpgradePage extends StatefulWidget {
  const UpgradePage({super.key});

  @override
  State<UpgradePage> createState() => _UpgradePageState();
}

class _UpgradePageState extends State<UpgradePage> {
  final _quota = UsageQuotaService.instance;
  final _billing = UnlockBillingService.instance;

  @override
  void initState() {
    super.initState();
    _billing.addListener(_onBillingChanged);
    _quota.addListener(_onQuotaChanged);
    if (_billing.products.isEmpty) {
      _billing.loadProducts();
    }
  }

  @override
  void dispose() {
    _billing.removeListener(_onBillingChanged);
    _quota.removeListener(_onQuotaChanged);
    super.dispose();
  }

  void _onBillingChanged() {
    if (mounted) setState(() {});
    if (_quota.isUnlocked && mounted) {
      Navigator.of(context).maybePop(true);
    }
  }

  void _onQuotaChanged() {
    if (mounted) setState(() {});
    if (_quota.canGenerate && mounted) {
      Navigator.of(context).maybePop(true);
    }
  }

  Future<void> _buy() async {
    await _billing.buyUnlock();
  }

  Future<void> _restore() async {
    await _billing.restorePurchases();
    if (!mounted) return;
    final l10n = context.l10n;
    if (_quota.isUnlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.upgradePurchaseSuccess)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final product = _billing.unlockProduct;
    final limit = _quota.effectiveFreeLimit;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.upgradeTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(
            Icons.lock_open_outlined,
            size: 56,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.quotaExceededTitle,
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.quotaExceededBody(limit),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          if (_billing.purchaseInFlight)
            const Center(child: CircularProgressIndicator())
          else if (!_billing.storeAvailable)
            Text(
              l10n.upgradeStoreUnavailable,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.error),
            )
          else if (product == null)
            Text(
              l10n.upgradeProductNotConfigured,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.error),
            )
          else ...[
            FilledButton(
              onPressed: _buy,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: Text(l10n.upgradeBuyButton(product.price)),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _restore,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
              child: Text(l10n.upgradeRestoreButton),
            ),
          ],
          if (_quota.canClaimShareReward) ...[
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () => runShareForBonus(context),
              icon: const Icon(Icons.share_outlined),
              label: Text(
                l10n.upgradeShareButton(
                  UsageQuotaService.bonusGenerationsPerShare,
                  _quota.shareRewardsRemaining,
                ),
              ),
            ),
          ],
          if (_billing.lastPurchaseError != null) ...[
            const SizedBox(height: 16),
            Text(
              l10n.upgradePurchaseFailed(_billing.lastPurchaseError!),
              style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
