import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
          );

  static const String _keyAppPin = 'etole_app_pin';
  static const String _keyBiometricsEnabled = 'etole_biometrics_enabled';
  static const String _keyAppLockEnabled = 'etole_app_lock_enabled';
  static const String _keySmtpPasswordPrefix = 'etole_smtp_pass_';

  Future<void> setAppPin(String pin) async {
    try {
      await _storage.write(key: _keyAppPin, value: pin);
    } catch (_) {}
  }

  Future<String?> getAppPin() async {
    try {
      return await _storage.read(key: _keyAppPin);
    } catch (_) {
      return null;
    }
  }

  Future<void> removeAppPin() async {
    try {
      await _storage.delete(key: _keyAppPin);
    } catch (_) {}
  }

  Future<void> setAppLockEnabled(bool enabled) async {
    try {
      await _storage.write(key: _keyAppLockEnabled, value: enabled.toString());
    } catch (_) {}
  }

  Future<bool> isAppLockEnabled() async {
    try {
      final val = await _storage.read(key: _keyAppLockEnabled);
      return val == 'true';
    } catch (_) {
      return false;
    }
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    try {
      await _storage.write(
        key: _keyBiometricsEnabled,
        value: enabled.toString(),
      );
    } catch (_) {}
  }

  Future<bool> isBiometricsEnabled() async {
    try {
      final val = await _storage.read(key: _keyBiometricsEnabled);
      return val == 'true';
    } catch (_) {
      return false;
    }
  }

  Future<void> saveSmtpPassword(int brandId, String password) async {
    try {
      await _storage.write(
        key: '$_keySmtpPasswordPrefix$brandId',
        value: password,
      );
    } catch (_) {}
  }

  Future<String?> getSmtpPassword(int brandId) async {
    try {
      return await _storage.read(key: '$_keySmtpPasswordPrefix$brandId');
    } catch (_) {
      return null;
    }
  }

  static const String _keyGeminiApiKey = 'etole_gemini_api_key';

  Future<void> saveGeminiApiKey(String key) async {
    try {
      await _storage.write(key: _keyGeminiApiKey, value: key);
    } catch (_) {}
  }

  Future<String?> getGeminiApiKey() async {
    try {
      return await _storage.read(key: _keyGeminiApiKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteGeminiApiKey() async {
    try {
      await _storage.delete(key: _keyGeminiApiKey);
    } catch (_) {}
  }
}
