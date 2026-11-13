import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/design_system/etole_colors.dart';
import '../../../core/design_system/etole_components.dart';
import '../../../core/security/biometrics_service.dart';
import '../../../core/security/secure_storage_service.dart';
import '../../../core/theme/brand_theme_provider.dart';
import '../../digital_cards/presentation/screens/card_presentation_screen.dart';

class AppLockScreen extends ConsumerStatefulWidget {
  final VoidCallback onAuthenticated;

  const AppLockScreen({super.key, required this.onAuthenticated});

  @override
  ConsumerState<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends ConsumerState<AppLockScreen> {
  String _enteredPin = '';
  String? _savedPin;
  bool _biometricsAvailable = false;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkSecurityState();
  }

  Future<void> _checkSecurityState() async {
    try {
      final storage = ref.read(secureStorageServiceProvider);
      final biometrics = ref.read(biometricsServiceProvider);

      final isLockEnabled = await storage.isAppLockEnabled();
      if (!isLockEnabled) {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onAuthenticated();
          });
        }
        return;
      }

      _savedPin = await storage.getAppPin();
      final bioEnabled = await storage.isBiometricsEnabled();
      _biometricsAvailable = bioEnabled && await biometrics.isDeviceSupported();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      if (_biometricsAvailable) {
        _triggerBiometricAuth();
      }
    } catch (_) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onAuthenticated();
        });
      }
    }
  }

  Future<void> _triggerBiometricAuth() async {
    final biometrics = ref.read(biometricsServiceProvider);
    final authenticated = await biometrics.authenticate(
      reason: 'Scan fingerprint to unlock Etole',
    );
    if (authenticated && mounted) {
      widget.onAuthenticated();
    }
  }

  void _onDigitPressed(String digit) {
    if (_enteredPin.length >= 4) return;
    setState(() {
      _errorMessage = null;
      _enteredPin += digit;
    });

    if (_enteredPin.length == 4) {
      _verifyPin();
    }
  }

  void _onDeletePressed() {
    if (_enteredPin.isEmpty) return;
    setState(() {
      _errorMessage = null;
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
    });
  }

  void _verifyPin() {
    if (_savedPin != null && _enteredPin == _savedPin) {
      widget.onAuthenticated();
    } else {
      setState(() {
        _errorMessage = 'Incorrect PIN. Try again.';
        _enteredPin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = EtoleColors.cyan;

    return Scaffold(
      backgroundColor: isDark ? EtoleColors.obsidian : EtoleColors.warmWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? EtoleColors.darkSurfaceElevated
                      : Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  border: Border.all(
                    color: isDark
                        ? EtoleColors.darkHairline
                        : EtoleColors.lightBorder,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.4 : 0.06,
                      ),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    EtoleBrandLogo(size: 24, showSubtitle: true),
                    SizedBox(width: 18),
                    EtoleBauhausCluster(size: 40),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Studio Protected',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                  color: isDark
                      ? EtoleColors.cream
                      : EtoleColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your 4-digit PIN to access documents',
                style: TextStyle(
                  color: isDark
                      ? EtoleColors.muted
                      : EtoleColors.lightTextMuted,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // PIN Indicator Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < _enteredPin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled ? accent : Colors.transparent,
                      border: Border.all(
                        color: isFilled ? accent : AppColors.darkBorder,
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: AppColors.statusOverdue,
                    fontSize: 13,
                  ),
                ),
              ],
              const Spacer(),

              // Custom Keypad
              _buildKeypad(accent),
              const SizedBox(height: 16),

              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CardPresentationScreen(),
                    ),
                  );
                },
                icon: Icon(Icons.qr_code_2_rounded, color: accent, size: 18),
                label: Text(
                  'Show My Business Card (No Unlock Required)',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad(Color accent) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['1', '2', '3'].map((d) => _buildKeypadButton(d)).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['4', '5', '6'].map((d) => _buildKeypadButton(d)).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['7', '8', '9'].map((d) => _buildKeypadButton(d)).toList(),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (_biometricsAvailable)
              IconButton(
                iconSize: 32,
                icon: Icon(Icons.fingerprint_rounded, color: accent),
                onPressed: _triggerBiometricAuth,
              )
            else
              const SizedBox(width: 64, height: 64),
            _buildKeypadButton('0'),
            IconButton(
              iconSize: 28,
              icon: const Icon(
                Icons.backspace_outlined,
                color: AppColors.darkTextSecondary,
              ),
              onPressed: _onDeletePressed,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeypadButton(String digit) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 72,
      height: 72,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
          side: BorderSide(
            color: isDark ? EtoleColors.darkHairline : EtoleColors.lightBorder,
            width: 1.5,
          ),
          backgroundColor: isDark
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.white,
        ),
        onPressed: () => _onDigitPressed(digit),
        child: Text(
          digit,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: isDark ? EtoleColors.cream : EtoleColors.lightTextPrimary,
          ),
        ),
      ),
    );
  }
}
