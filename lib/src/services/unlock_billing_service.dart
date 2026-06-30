import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/iap_products.dart';
import 'usage_quota_service.dart';

/// App Store / Google Play one-time unlock for unlimited sheet generation.
class UnlockBillingService extends ChangeNotifier {
  UnlockBillingService._();

  static final UnlockBillingService instance = UnlockBillingService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  static const _keySilentRestoreAttempted = 'iap_silent_restore_attempted';

  bool _started = false;
  bool _storeAvailable = false;

  bool get storeAvailable => _storeAvailable;
  bool purchaseInFlight = false;
  String? lastPurchaseError;

  List<ProductDetails> products = [];
  List<String> notFoundProductIds = [];

  ProductDetails? get unlockProduct {
    for (final p in products) {
      if (p.id == IapProducts.unlock) return p;
    }
    return null;
  }

  Future<void> start() async {
    if (_started) return;
    _started = true;
    if (!UsageQuotaService.instance.billingEnforced) {
      await UsageQuotaService.instance.setUnlocked(true);
      notifyListeners();
      return;
    }
    try {
      _storeAvailable = await _iap.isAvailable();
      if (!_storeAvailable) {
        lastPurchaseError = 'store_unavailable';
        notifyListeners();
        return;
      }
      _purchaseSub = _iap.purchaseStream.listen(
        (list) => unawaited(_handlePurchases(list)),
        onError: (Object e, StackTrace st) {
          debugPrint('IAP purchaseStream error: $e\n$st');
          if (purchaseInFlight) {
            lastPurchaseError = e.toString();
            purchaseInFlight = false;
            notifyListeners();
          }
        },
      );
      _scheduleSilentRestore();
    } catch (e, st) {
      debugPrint('UnlockBillingService.start failed: $e\n$st');
      _storeAvailable = false;
      lastPurchaseError = e.toString();
    }
    notifyListeners();
  }

  Future<void> loadProducts() async {
    lastPurchaseError = null;
    notFoundProductIds = [];
    products = [];
    if (!_storeAvailable) {
      notifyListeners();
      return;
    }
    try {
      final response = await _iap.queryProductDetails(IapProducts.allIds);
      if (response.error != null) {
        lastPurchaseError = response.error!.message;
        notFoundProductIds = response.notFoundIDs.toList();
        notifyListeners();
        return;
      }
      products = List<ProductDetails>.from(response.productDetails);
      notFoundProductIds = List<String>.from(response.notFoundIDs);
    } catch (e, st) {
      debugPrint('loadProducts: $e\n$st');
      lastPurchaseError = e.toString();
    }
    notifyListeners();
  }

  Future<void> buyUnlock() async {
    final product = unlockProduct;
    if (!_storeAvailable || product == null) return;
    purchaseInFlight = true;
    lastPurchaseError = null;
    notifyListeners();
    try {
      await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
    } catch (e, st) {
      debugPrint('buyUnlock: $e\n$st');
      lastPurchaseError = e.toString();
      purchaseInFlight = false;
      notifyListeners();
    }
  }

  /// Runs once per install (first launch) to recover a prior non-consumable purchase.
  void _scheduleSilentRestore() {
    if (UsageQuotaService.instance.isUnlocked) return;
    unawaited(_silentRestoreOnFirstLaunchIfNeeded());
  }

  Future<void> _silentRestoreOnFirstLaunchIfNeeded() async {
    if (!_storeAvailable) return;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_keySilentRestoreAttempted) == true) return;

    try {
      await _iap.restorePurchases();
    } catch (e, st) {
      debugPrint('silentRestorePurchases: $e\n$st');
    } finally {
      await prefs.setBool(_keySilentRestoreAttempted, true);
    }
  }

  Future<void> _handlePurchases(List<PurchaseDetails> detailsList) async {
    for (final purchase in detailsList) {
      if (purchase.status == PurchaseStatus.pending) {
        if (purchaseInFlight) {
          notifyListeners();
        }
        continue;
      }

      final userInitiated = purchaseInFlight;
      purchaseInFlight = false;

      if (purchase.status == PurchaseStatus.error) {
        if (userInitiated) {
          lastPurchaseError = purchase.error?.message ??
              purchase.error?.code ??
              'purchase_error';
        }
      } else if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        if (IapProducts.unlocksApp(purchase.productID)) {
          await UsageQuotaService.instance.setUnlocked(true);
          lastPurchaseError = null;
        }
      } else if (purchase.status == PurchaseStatus.canceled) {
        if (userInitiated) {
          lastPurchaseError = null;
        }
      }
      if (userInitiated ||
          purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        notifyListeners();
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  @override
  void dispose() {
    _purchaseSub?.cancel();
    super.dispose();
  }
}
