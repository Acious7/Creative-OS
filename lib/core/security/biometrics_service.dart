import 'package:local_auth/local_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final biometricsServiceProvider = Provider<BiometricsService>((ref) {
  return BiometricsService();
});

class BiometricsService {
  final LocalAuthentication _auth;

  BiometricsService({LocalAuthentication? auth}) : _auth = auth ?? LocalAuthentication();

  Future<bool> isDeviceSupported() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      return isSupported && canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate({String reason = 'Authenticate to access Etole'}) async {
    try {
      final supported = await isDeviceSupported();
      if (!supported) return false;

      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
