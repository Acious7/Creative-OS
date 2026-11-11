import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../../data/google_auth_service.dart';
import '../../data/gmail_send_service.dart';
import '../../domain/google_email_account.dart';
import '../../domain/email_template.dart';
import '../widgets/email_template_editor_sheet.dart';
import 'smtp_email_settings_screen.dart';

class GoogleEmailSettingsScreen extends StatefulWidget {
  const GoogleEmailSettingsScreen({super.key});

  @override
  State<GoogleEmailSettingsScreen> createState() =>
      _GoogleEmailSettingsScreenState();
}

class _GoogleEmailSettingsScreenState extends State<GoogleEmailSettingsScreen> {
  final GoogleAuthService _authService = GoogleAuthService();
  GoogleEmailAccount? _account;
  GoogleConnectionStatus _connectionStatus =
      GoogleConnectionStatus.notConnected;
  Map<EmailTemplateType, EmailTemplate> _templates = {};
  bool _isLoading = true;
  bool _isSigningIn = false;
  bool _isSendingTest = false;

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  Future<void> _loadAccount() async {
    setState(() => _isLoading = true);
    final account = await _authService.getSavedAccount();
    final status = await _authService.getConnectionStatus();
    final templates = await EmailTemplateRepository.getAllTemplates();
    if (mounted) {
      setState(() {
        _account = account;
        _connectionStatus = status;
        _templates = templates;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSignIn() async {
    setState(() => _isSigningIn = true);
    try {
      final account = await _authService.signIn();
      final status = await _authService.getConnectionStatus();
      if (account != null && mounted) {
        setState(() {
          _account = account;
          _connectionStatus = status;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to Gmail as ${account.email}'),
            backgroundColor: const Color(0xFF1B5E20),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Google Sign-In unavailable. Use Direct SMTP instead!',
            ),
            backgroundColor: const Color(0xFFC62828),
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Open SMTP',
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SmtpEmailSettingsScreen(),
                  ),
                );
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSigningIn = false);
      }
    }
  }

  Future<void> _handleReconnect() async {
    setState(() => _isSigningIn = true);
    try {
      final account = await _authService.signIn();
      final status = await _authService.getConnectionStatus();
      if (account != null && mounted) {
        setState(() {
          _account = account;
          _connectionStatus = status;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reconnected to Gmail as ${account.email}'),
            backgroundColor: const Color(0xFF1B5E20),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reconnect failed: $e'),
            backgroundColor: const Color(0xFFC62828),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSigningIn = false);
      }
    }
  }

  Future<void> _handleSignOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14181B),
        title: Text(
          'Disconnect Gmail?',
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFFF1EDE4),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'You will need to sign in again to send documents directly from Gmail.',
          style: TextStyle(color: Color(0xFFD6D1C7), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _authService.signOut();
      if (mounted) {
        setState(() {
          _account = null;
          _connectionStatus = GoogleConnectionStatus.notConnected;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signed out of Google account')),
        );
      }
    }
  }

  Future<void> _handleSendTest() async {
    setState(() => _isSendingTest = true);
    try {
      await GmailSendService.sendTestEmail();
      final refreshedAccount = await _authService.getSavedAccount();
      final status = await _authService.getConnectionStatus();
      if (mounted) {
        setState(() {
          if (refreshedAccount != null) _account = refreshedAccount;
          _connectionStatus = status;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Test email successfully sent to ${_account?.email}!',
            ),
            backgroundColor: const Color(0xFF1B5E20),
          ),
        );
      }
    } catch (e) {
      final status = await _authService.getConnectionStatus();
      if (mounted) {
        setState(() => _connectionStatus = status);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send test email: $e'),
            backgroundColor: const Color(0xFFC62828),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingTest = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const cream = Color(0xFFF1EDE4);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0E1113)
          : const Color(0xFFF9F7F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? cream : Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '05 · THE WORKSHOP',
              style: EtoleTypography.labelCaps(color: EtoleColors.cyan),
            ),
            Text(
              'Gmail Integration',
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
                color: isDark ? cream : Colors.black87,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: EtoleColors.cyan),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_account == null) ...[
                    _buildSignedOutCard(isDark),
                  ] else ...[
                    _buildSignedInCard(isDark),
                  ],
                  const SizedBox(height: 20),
                  _buildTemplatesSection(isDark),
                  const SizedBox(height: 24),
                  _buildSecurityNote(isDark),
                  const SizedBox(height: 16),
                  _buildTestingModeNotice(isDark),
                ],
              ),
            ),
    );
  }

  Widget _buildSignedOutCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161A1D) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2C3238) : const Color(0xFFE5E0D5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: EtoleColors.cyan.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.mail_lock_rounded,
                color: EtoleColors.cyan,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Send with Gmail',
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
              color: isDark ? const Color(0xFFF1EDE4) : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in with your Google account to send quotations, invoices, and documents directly through Gmail. No passwords stored, no inbox reading.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFFB0A99F) : Colors.black54,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark
                    ? Colors.white
                    : const Color(0xFF14181B),
                foregroundColor: isDark ? Colors.black87 : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: _isSigningIn ? null : _handleSignIn,
              child: _isSigningIn
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: EtoleColors.cyan,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Google "G" representation
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.g_mobiledata_rounded,
                            color: Color(0xFF4285F4),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Sign in with Google',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5FF),
                foregroundColor: const Color(0xFF080B0F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SmtpEmailSettingsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.mark_email_read_rounded, size: 18),
              label: const Text(
                'SET UP DIRECT SMTP (RECOMMENDED)',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignedInCard(bool isDark) {
    final account = _account!;
    final isConnected = _connectionStatus == GoogleConnectionStatus.connected;
    final isReconnectNeeded =
        _connectionStatus == GoogleConnectionStatus.reconnectNeeded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161A1D) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isReconnectNeeded
              ? const Color(0xFFFF9800).withValues(alpha: 0.5)
              : (isDark ? const Color(0xFF2C3238) : const Color(0xFFE5E0D5)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 26,
                backgroundColor: EtoleColors.cyan,
                backgroundImage: account.photoUrl != null
                    ? NetworkImage(account.photoUrl!)
                    : null,
                child: account.photoUrl == null
                    ? Text(
                        account.displayName.isNotEmpty
                            ? account.displayName[0].toUpperCase()
                            : 'B',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.displayName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? const Color(0xFFF1EDE4)
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      account.email,
                      style: const TextStyle(
                        fontSize: 13,
                        color: EtoleColors.cyan,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isConnected)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B5E20).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF2E7D32)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF4CAF50),
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Connected',
                        style: TextStyle(
                          color: Color(0xFF4CAF50),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE65100).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFF9800)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Color(0xFFFFB74D),
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Reconnect needed',
                        style: TextStyle(
                          color: Color(0xFFFFB74D),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (isReconnectNeeded) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE65100).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFFF9800).withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.sync_problem_rounded,
                    color: Color(0xFFFFB74D),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Google session has expired. Tap Reconnect to refresh sending permissions.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFFFFD180)
                            : const Color(0xFFBF360C),
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9800),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _isSigningIn ? null : _handleReconnect,
                    child: _isSigningIn
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'Reconnect',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          const EtoleHairline(),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                isReconnectNeeded
                    ? Icons.lock_clock_outlined
                    : Icons.shield_outlined,
                size: 16,
                color: isReconnectNeeded
                    ? const Color(0xFFFFB74D)
                    : const Color(0xFF4CAF50),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isReconnectNeeded
                      ? 'Permission expired: Reconnect to send emails directly'
                      : 'Permission: Send emails on your behalf only',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF9E9E9E) : Colors.black54,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF5350),
                    side: const BorderSide(color: Color(0xFFEF5350)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Sign Out'),
                  onPressed: _handleSignOut,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: EtoleColors.cyan,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: _isSendingTest
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(
                    _isSendingTest ? 'Sending...' : 'Send Test Email',
                  ),
                  onPressed: _isSendingTest ? null : _handleSendTest,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityNote(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14181B) : const Color(0xFFEFECE6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: EtoleColors.cyan,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HOW SENDING WORKS',
                  style: GoogleFonts.inter(
                    letterSpacing: 1.0,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFF1EDE4) : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'When you send a document from preview, the PDF is attached, your professional email signature is appended at the bottom, and the send activity is logged directly on the document.\n\nIf you are offline, you will be offered the option to open the document with your email app or Gmail so you can always send without interruptions.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF9E9E9E) : Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestingModeNotice(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14181B) : const Color(0xFFEFECE6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lock_clock_outlined,
            color: EtoleColors.cyan,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GOOGLE SIGN-IN & PERMISSION DURATION',
                  style: GoogleFonts.inter(
                    letterSpacing: 1.0,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFF1EDE4) : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your sign-in survives app updates and reinstalls. While the Google Cloud integration is in Testing mode, Google automatically expires permission tokens every 7 days.\n\nWhen this happens, you\'ll see "Reconnect needed" above, or the app will simply reopen Google sign-in when you send so you can keep working without interruption.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF9E9E9E) : Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplatesSection(bool isDark) {
    final templates = _templates;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161A1D) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2C3238) : const Color(0xFFE5E0D5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: EtoleColors.cyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.edit_note_rounded,
                  color: EtoleColors.cyan,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'EMAIL TEMPLATES (EDITABLE)',
                style: GoogleFonts.inter(
                  letterSpacing: 1.0,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFF1EDE4) : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Customizable subjects & messages for all 7 document types. Tap any template to adjust text and placeholders:',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFFB0A99F) : Colors.black54,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ...EmailTemplateType.values.map((type) {
            final tpl = templates[type] ?? EmailTemplate.defaults[type]!;
            final icon = _getTemplateIcon(type);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F1214)
                    : const Color(0xFFF7F5EE),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF2C3238)
                      : const Color(0xFFE2DDD2),
                ),
              ),
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 2,
                ),
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: EtoleColors.cyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(icon, color: EtoleColors.cyan, size: 18),
                  ),
                ),
                title: Text(
                  tpl.label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDark ? const Color(0xFFF1EDE4) : Colors.black87,
                  ),
                ),
                subtitle: Text(
                  tpl.subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF9E9E9E) : Colors.black54,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF8A7E72),
                  size: 18,
                ),
                onTap: () {
                  EmailTemplateEditorSheet.show(
                    context,
                    template: tpl,
                    onSaved: (updated) {
                      setState(() => _templates[updated.type] = updated);
                    },
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  IconData _getTemplateIcon(EmailTemplateType type) {
    switch (type) {
      case EmailTemplateType.quotation:
        return Icons.request_quote_outlined;
      case EmailTemplateType.invoice:
        return Icons.receipt_long_outlined;
      case EmailTemplateType.receipt:
        return Icons.task_alt_outlined;
      case EmailTemplateType.rateCard:
        return Icons.style_outlined;
      case EmailTemplateType.contract:
        return Icons.draw_outlined;
      case EmailTemplateType.intro:
        return Icons.person_add_alt_outlined;
      case EmailTemplateType.test:
        return Icons.mark_email_read_outlined;
    }
  }
}
