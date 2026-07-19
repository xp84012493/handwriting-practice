/// In-app product identifiers. Create matching products in
/// App Store Connect and Google Play Console.
///
/// See `docs/IAP_STORE_SETUP.md`.
abstract final class IapProducts {
  /// One-time non-consumable — unlock unlimited sheet generation.
  static const String unlock = 'unlock_handwriting_practice';

  static const Set<String> allIds = {unlock};

  static bool unlocksApp(String productId) => productId == unlock;
}
