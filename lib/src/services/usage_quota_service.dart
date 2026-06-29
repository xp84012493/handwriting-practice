import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks free sheet generations; after [freeGenerationLimit], requires IAP unlock.
///
/// Persisted in **Keychain / Encrypted storage** so iOS reinstall usually keeps
/// the count. Android clears app data on uninstall (platform limitation).
class UsageQuotaService extends ChangeNotifier {
  UsageQuotaService._();

  static final UsageQuotaService instance = UsageQuotaService._();

  static const int freeGenerationLimit = 30;

  static const _keyCount = 'sheet_generation_count';
  static const _keyUnlocked = 'sheet_generation_unlocked';

  /// Legacy keys from SharedPreferences (migrated once on load).
  static const _legacyKeyCount = 'sheet_generation_count';
  static const _legacyKeyUnlocked = 'sheet_generation_unlocked';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  int _generationCount = 0;
  bool _unlocked = false;
  bool _loaded = false;

  bool get isLoaded => _loaded;

  /// iOS / Android store builds enforce quota; desktop & web are unrestricted.
  bool get billingEnforced =>
      !kIsWeb && (Platform.isIOS || Platform.isAndroid);

  bool get isUnlocked => !billingEnforced || _unlocked;

  int get generationCount => _generationCount;

  int get remainingFree => isUnlocked
      ? 0
      : (freeGenerationLimit - _generationCount).clamp(0, freeGenerationLimit);

  bool get canGenerate =>
      isUnlocked || _generationCount < freeGenerationLimit;

  bool get quotaExceeded => billingEnforced && !isUnlocked && !canGenerate;

  Future<void> load() async {
    final countStr = await _storage.read(key: _keyCount);
    final unlockedStr = await _storage.read(key: _keyUnlocked);

    if (countStr != null) {
      _generationCount = int.tryParse(countStr) ?? 0;
    }
    if (unlockedStr != null) {
      _unlocked = unlockedStr == 'true';
    }

    if (countStr == null && unlockedStr == null) {
      await _migrateFromSharedPreferences();
    }

    _loaded = true;
    notifyListeners();
  }

  Future<void> _migrateFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final legacyCount = prefs.getInt(_legacyKeyCount);
    final legacyUnlocked = prefs.getBool(_legacyKeyUnlocked);
    if (legacyCount == null && legacyUnlocked == null) return;

    if (legacyCount != null) {
      _generationCount = legacyCount;
      await _storage.write(key: _keyCount, value: '$_generationCount');
    }
    if (legacyUnlocked != null) {
      _unlocked = legacyUnlocked;
      await _storage.write(key: _keyUnlocked, value: '$_unlocked');
    }
    await prefs.remove(_legacyKeyCount);
    await prefs.remove(_legacyKeyUnlocked);
  }

  Future<void> recordSuccessfulGeneration() async {
    if (!billingEnforced || isUnlocked) return;
    _generationCount += 1;
    notifyListeners();
    await _storage.write(key: _keyCount, value: '$_generationCount');
  }

  Future<void> setUnlocked(bool value) async {
    if (_unlocked == value) return;
    _unlocked = value;
    notifyListeners();
    await _storage.write(key: _keyUnlocked, value: '$_unlocked');
  }
}
