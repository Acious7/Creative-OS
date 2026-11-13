import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../../data/smtp_email_service.dart';
import '../../domain/smtp_config.dart';

class SmtpEmailSettingsScreen extends StatefulWidget {
  const SmtpEmailSettingsScreen({super.key});

  @override
  State<SmtpEmailSettingsScreen> createState() =>
      _SmtpEmailSettingsScreenState();
}

class _SmtpEmailSettingsScreenState extends State<SmtpEmailSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _hostController;
  late TextEditingController _portController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;

  bool _isSsl = true;
  bool _obscurePassword = true;
  bool _isLoading = true;
  bool _isTesting = false;
  bool _isSaving = false;
  String _selectedPreset = 'gmail';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'Creative Studio');
    _emailController = TextEditingController(text: 'studio@creativeos.app');
    _hostController = TextEditingController(text: 'smtp.gmail.com');
    _portController = TextEditingController(text: '465');
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();

    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final cfg = await SmtpStorage.loadConfig();
    if (cfg != null && mounted) {
      setState(() {
        _nameController.text = cfg.senderName;
        _emailController.text = cfg.senderEmail;
        _hostController.text = cfg.host;
        _portController.text = cfg.port.toString();
        _usernameController.text = cfg.username;
        _passwordController.text = cfg.password;
        _isSsl = cfg.isSsl;
      });
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _applyPreset(String preset) {
    setState(() {
      _selectedPreset = preset;
      switch (preset) {
        case 'gmail':
          _hostController.text = 'smtp.gmail.com';
          _portController.text = '465';
          _isSsl = true;
          break;
        case 'custom':
          _hostController.text = 'mail.yourdomain.com';
          _portController.text = '465';
          _isSsl = true;
          break;
        case 'outlook':
          _hostController.text = 'smtp.office365.com';
          _portController.text = '587';
          _isSsl = false;
          break;
        case 'zoho':
          _hostController.text = 'smtp.zoho.com';
          _portController.text = '465';
          _isSsl = true;
          break;
      }
    });
    EtoleHaptics.selection();
  }

  SmtpConfig _buildConfig() {
    return SmtpConfig(
      senderName: _nameController.text.trim(),
      senderEmail: _emailController.text.trim(),
      host: _hostController.text.trim(),
      port: int.tryParse(_portController.text.trim()) ?? 465,
      username: _usernameController.text.trim().isNotEmpty
          ? _usernameController.text.trim()
          : _emailController.text.trim(),
      password: _passwordController.text.trim(),
      isSsl: _isSsl,
    );
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isTesting = true);
    EtoleHaptics.medium();

    final config = _buildConfig();
    try {
      await SmtpEmailService.testConnection(config);
      if (mounted) {
        EtoleHaptics.success();
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF14171B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFF00E5FF), width: 1.2),
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF00E5FF),
                  size: 22,
                ),
                SizedBox(width: 8),
                Text(
                  'SMTP Verified!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            content: Text(
              'Successfully connected to ${_hostController.text} on port ${_portController.text}. '
              'A test message has been delivered to ${config.senderEmail}. Etole is ready to dispatch official PDF proposals & invoices!',
              style: const TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: const Color(0xFF080B0F),
                ),
                child: const Text('Great'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        EtoleHaptics.warning();
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF14171B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFD32F2F), width: 1.2),
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFEF4444),
                  size: 22,
                ),
                SizedBox(width: 8),
                Text(
                  'Connection Failed',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Error details:\n$e',
                  style: const TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  '💡 For Gmail users:\n'
                  'Standard Google passwords will not work. You must use a 16-character App Password:\n'
                  '1. Go to myaccount.google.com ➔ Security\n'
                  '2. Enable 2-Step Verification\n'
                  '3. Search "App Passwords" and create one for "Etole"\n'
                  '4. Paste that 16-character code into the Password field.',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'OK',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    EtoleHaptics.medium();

    final config = _buildConfig();
    await SmtpStorage.saveConfig(config);

    if (mounted) {
      setState(() => _isSaving = false);
      EtoleHaptics.success();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF14171B),
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF00E5FF),
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'SMTP Email Dispatch settings saved and activated!',
                style: TextStyle(color: Colors.white, fontSize: 12.5),
              ),
            ],
          ),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080B0F),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SMTP EMAIL DISPATCH',
                          style: EtoleTypography.h2.copyWith(
                            color: EtoleColors.cream,
                            letterSpacing: 2.0,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'Direct Proposal & Invoice PDF Delivery (Zero OAuth Friction)',
                          style: TextStyle(
                            color: Color(0xFF00E5FF),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
                ),
              )
            else
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: [
                      // Instructions Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF14171B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF00E5FF)
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00E5FF)
                                    .withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.mail_rounded,
                                color: Color(0xFF00E5FF),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'OFFICIAL CLIENT PDF DISPATCH',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Send official commercial PDFs directly from your own email (Gmail, custom domain, cPanel or Outlook) without OAuth login errors.',
                                    style: TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 11.5,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Presets Row
                      const Text(
                        'CHOOSE EMAIL PROVIDER',
                        style: TextStyle(
                          color: Color(0xFF00E5FF),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildPresetChip(
                            'Gmail',
                            'gmail',
                            Icons.mail_outline_rounded,
                          ),
                          const SizedBox(width: 6),
                          _buildPresetChip(
                            'Custom',
                            'custom',
                            Icons.language_rounded,
                          ),
                          const SizedBox(width: 6),
                          _buildPresetChip(
                            'Outlook',
                            'outlook',
                            Icons.business_rounded,
                          ),
                          const SizedBox(width: 6),
                          _buildPresetChip(
                            'Zoho',
                            'zoho',
                            Icons.cloud_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Step 1: Sender Identity
                      _buildSectionHeader('1. SENDER IDENTITY'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        decoration: _inputDecoration(
                          label: 'Sender Display Name',
                          hint: 'Creative Studio | Commercial Production',
                          icon: Icons.person_outline_rounded,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => v == null || !v.contains('@')
                            ? 'Valid email required'
                            : null,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        decoration: _inputDecoration(
                          label: 'Sender Email Address',
                          hint: 'studio@creativeos.app or user@gmail.com',
                          icon: Icons.alternate_email_rounded,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Step 2: Server Settings
                      _buildSectionHeader('2. SMTP SERVER CONNECTION'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _hostController,
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Required'
                                  : null,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                              decoration: _inputDecoration(
                                label: 'SMTP Host',
                                hint: 'smtp.gmail.com',
                                icon: Icons.dns_rounded,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              controller: _portController,
                              keyboardType: TextInputType.number,
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Required'
                                  : null,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                              decoration: _inputDecoration(
                                label: 'Port',
                                hint: '465',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // SSL Toggle Tile
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF14171B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.lock_outline_rounded,
                                  size: 16,
                                  color: Color(0xFF00E5FF),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Use SSL / TLS Secure Encryption',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: _isSsl,
                              onChanged: (v) => setState(() => _isSsl = v),
                              activeColor: const Color(0xFF00E5FF),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Step 3: Authentication
                      _buildSectionHeader('3. SMTP AUTHENTICATION'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _usernameController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        decoration: _inputDecoration(
                          label:
                              'Username / Account (optional if same as email)',
                          hint: 'Leave empty to use sender email',
                          icon: Icons.account_circle_outlined,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Password or App Password required'
                            : null,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        decoration: _inputDecoration(
                          label: 'SMTP Password or Google App Password',
                          hint: '16-character Google App Password or cPanel password',
                          icon: Icons.key_rounded,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: Colors.white54,
                              size: 18,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Actions: Test & Save
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isTesting ? null : _testConnection,
                              icon: _isTesting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF00E5FF),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.send_rounded,
                                      size: 16,
                                      color: Color(0xFF00E5FF),
                                    ),
                              label: Text(
                                _isTesting ? 'Testing...' : 'Test Connection',
                                style: const TextStyle(
                                  color: Color(0xFF00E5FF),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFF00E5FF),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isSaving ? null : _saveConfig,
                              icon: const Icon(
                                Icons.check_rounded,
                                color: Color(0xFF080B0F),
                                size: 18,
                              ),
                              label: const Text(
                                'Save & Activate',
                                style: TextStyle(
                                  color: Color(0xFF080B0F),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12.5,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00E5FF),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF00E5FF),
        fontWeight: FontWeight.bold,
        fontSize: 11,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildPresetChip(String label, String value, IconData icon) {
    final isSelected = _selectedPreset == value;
    return Expanded(
      child: InkWell(
        onTap: () => _applyPreset(value),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
                : const Color(0xFF14171B),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF00E5FF) : Colors.white12,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? const Color(0xFF00E5FF) : Colors.white60,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    IconData? icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
      prefixIcon: icon != null
          ? Icon(icon, color: Colors.white60, size: 18)
          : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFF14171B),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF00E5FF)),
      ),
    );
  }
}
