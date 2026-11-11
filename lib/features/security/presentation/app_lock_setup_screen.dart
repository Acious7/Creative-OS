import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/security/biometrics_service.dart';
import '../../../../core/security/secure_storage_service.dart';

class AppLockSetupScreen extends ConsumerStatefulWidget {
  const AppLockSetupScreen({super.key});

  @override
  ConsumerState<AppLockSetupScreen> createState() => _AppLockSetupScreenState();
}

class _AppLockSetupScreenState extends ConsumerState<AppLockSetupScreen> {
  bool _isLockEnabled = false;
  bool _isBiometricEnabled = false;
  bool _hasPin = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSecurityStatus();
  }

  Future<void> _loadSecurityStatus() async {
    final storage = ref.read(secureStorageServiceProvider);
    final enabled = await storage.isAppLockEnabled();
    final bio = await storage.isBiometricsEnabled();
    final pin = await storage.getAppPin();

    setState(() {
      _isLockEnabled = enabled;
      _isBiometricEnabled = bio;
      _hasPin = pin != null && pin.isNotEmpty;
      _isLoading = false;
    });
  }

  Future<void> _setupPinDialog() async {
    final storage = ref.read(secureStorageServiceProvider);
    final pinController = TextEditingController();
    final confirmController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set 4-Digit Security PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pinController,
              decoration: const InputDecoration(labelText: 'Enter 4-Digit PIN'),
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(labelText: 'Confirm 4-Digit PIN'),
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final pin = pinController.text.trim();
              final confirm = confirmController.text.trim();

              if (pin.length != 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN must be 4 digits'), backgroundColor: AppColors.error),
                );
                return;
              }

              if (pin != confirm) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PINs do not match'), backgroundColor: AppColors.error),
                );
                return;
              }

              await storage.setAppPin(pin);
              await storage.setAppLockEnabled(true);
              if (ctx.mounted) Navigator.pop(ctx);
              _loadSecurityStatus();
            },
            child: const Text('Save PIN'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final storage = ref.watch(secureStorageServiceProvider);
    final biometrics = ref.watch(biometricsServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('App Lock & Biometrics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Protect your financial quotes, agreements, and client invoices with PIN or fingerprint authentication.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Enable App Lock'),
            subtitle: Text(_hasPin ? 'PIN is configured' : 'Requires setting a 4-digit PIN'),
            value: _isLockEnabled,
            onChanged: (val) async {
              if (val && !_hasPin) {
                await _setupPinDialog();
              } else {
                await storage.setAppLockEnabled(val);
                _loadSecurityStatus();
              }
            },
          ),
          if (_hasPin) ...[
            ListTile(
              leading: const Icon(Icons.pin_outlined),
              title: const Text('Change 4-Digit PIN'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _setupPinDialog,
            ),
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint_rounded),
              title: const Text('Biometric Unlock'),
              subtitle: const Text('Unlock with fingerprint or face biometric'),
              value: _isBiometricEnabled,
              onChanged: _isLockEnabled
                  ? (val) async {
                      final supported = await biometrics.isDeviceSupported();
                      if (!supported) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Biometrics not available on this device')),
                          );
                        }
                        return;
                      }
                      await storage.setBiometricsEnabled(val);
                      _loadSecurityStatus();
                    }
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}
