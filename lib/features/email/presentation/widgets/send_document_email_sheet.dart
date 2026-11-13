import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:drift/drift.dart' as drift;

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/constants/document_constants.dart';
import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../brands/domain/brand_social_links.dart';
import '../../../documents/data/document_repository.dart';
import '../../../pdf_export/domain/pdf_builder.dart';
import '../../data/gmail_send_service.dart';
import '../../data/google_auth_service.dart';
import '../../data/smtp_email_service.dart';
import '../../domain/branded_email_builder.dart';
import '../../domain/email_template.dart';
import '../../domain/google_email_account.dart';
import '../../domain/smtp_config.dart';
import '../screens/smtp_email_settings_screen.dart';

class SendDocumentEmailSheet extends ConsumerStatefulWidget {
  final CompleteDocument completeDoc;

  const SendDocumentEmailSheet({super.key, required this.completeDoc});

  @override
  ConsumerState<SendDocumentEmailSheet> createState() =>
      _SendDocumentEmailSheetState();
}

class _SendDocumentEmailSheetState
    extends ConsumerState<SendDocumentEmailSheet> {
  final _toController = TextEditingController();
  final _ccController = TextEditingController();
  final _bccController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();

  final GoogleAuthService _authService = GoogleAuthService();
  GoogleEmailAccount? _connectedAccount;
  SmtpConfig? _smtpConfig;

  bool _isLoadingAccount = true;
  bool _isSending = false;
  bool _attachPdf = true;
  bool _showMore = false;
  bool _isPreviewMode = false;

  late EmailTemplateType _selectedTemplateType;
  Client? _selectedClient;

  @override
  void initState() {
    super.initState();
    _selectedClient = widget.completeDoc.client;
    _selectedTemplateType = _mapDocTypeToTemplate(
      widget.completeDoc.document.docType,
    );
    _toController.text = _selectedClient?.email ?? '';
    _loadConnectedAccount();
    _applyTemplate(_selectedTemplateType);
  }

  @override
  void dispose() {
    _toController.dispose();
    _ccController.dispose();
    _bccController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  EmailTemplateType _mapDocTypeToTemplate(String docType) {
    switch (docType.toLowerCase()) {
      case 'quotation':
        return EmailTemplateType.quotation;
      case 'invoice':
        return EmailTemplateType.invoice;
      case 'receipt':
        return EmailTemplateType.receipt;
      case 'ratecard':
      case 'rate_card':
        return EmailTemplateType.rateCard;
      case 'contract':
        return EmailTemplateType.contract;
      default:
        return EmailTemplateType.quotation;
    }
  }

  Future<void> _loadConnectedAccount() async {
    final account = await _authService.getSavedAccount();
    final smtp = await SmtpStorage.loadConfig();
    if (mounted) {
      setState(() {
        _connectedAccount = account;
        _smtpConfig = smtp;
        _isLoadingAccount = false;
      });
    }
  }

  Map<String, String> _buildPlaceholderValues() {
    final doc = widget.completeDoc.document;
    final client = _selectedClient;

    String firstName = 'Client';
    if (client != null && client.name.trim().isNotEmpty) {
      firstName = client.name.trim().split(' ').first;
    } else if (_toController.text.contains('@')) {
      final prefix = _toController.text.split('@').first.trim();
      if (prefix.isNotEmpty) {
        firstName = prefix[0].toUpperCase() + prefix.substring(1);
      }
    }

    final clientName = client?.name.trim().isNotEmpty == true
        ? client!.name.trim()
        : firstName;
    final amountStr = CurrencyFormatter.format(
      doc.totalAmount,
      currencyCode: doc.currencyCode,
    );
    final dueDateStr = doc.dueOrValidityDate != null
        ? DateFormatter.format(doc.dueOrValidityDate!)
        : DateFormatter.format(doc.issueDate.add(const Duration(days: 14)));
    final projectStr =
        (doc.titleOverride != null && doc.titleOverride!.trim().isNotEmpty)
        ? doc.titleOverride!.trim()
        : (client?.organization ?? doc.docNumber);

    final paymentProfile = widget.completeDoc.paymentProfile;
    final paymentBuffer = StringBuffer();
    if (paymentProfile != null) {
      if (paymentProfile.mpesaTillNumber?.trim().isNotEmpty == true) {
        paymentBuffer.writeln(
          '• M-Pesa Buy Goods: ${paymentProfile.mpesaTillNumber!.trim()}',
        );
      }
      if (paymentProfile.mpesaPaybillNumber?.trim().isNotEmpty == true) {
        paymentBuffer.writeln(
          '• M-Pesa Paybill: ${paymentProfile.mpesaPaybillNumber!.trim()} (Acc: ${paymentProfile.mpesaPaybillAccount ?? doc.docNumber})',
        );
      }
      if (paymentProfile.bankName?.trim().isNotEmpty == true) {
        paymentBuffer.writeln(
          '• Bank: ${paymentProfile.bankName!.trim()} | Acc: ${paymentProfile.accountNumber ?? ""} (${paymentProfile.accountName ?? ""})',
        );
      }
    }
    if (paymentBuffer.isEmpty) {
      paymentBuffer.writeln('• Payment details available on invoice');
    }

    return {
      'first_name': firstName,
      'client_name': clientName,
      'document_number': doc.docNumber,
      'amount': amountStr,
      'due_date': dueDateStr,
      'project': projectStr,
      'payment_channels': paymentBuffer.toString().trim(),
      'showreel_url': 'https://brianetole.com/films',
      'rate_card_url': 'https://brianetole.com',
    };
  }

  Future<void> _applyTemplate(EmailTemplateType type) async {
    final tpl = await EmailTemplateRepository.getTemplate(type);
    final placeholders = _buildPlaceholderValues();
    if (mounted) {
      setState(() {
        _selectedTemplateType = type;
        _subjectController.text = tpl.renderSubject(placeholders);
        _bodyController.text = tpl.renderBody(placeholders);
      });
    }
  }

  void _insertPlaceholder(String placeholder) {
    final text = _bodyController.text;
    final selection = _bodyController.selection;
    if (selection.start >= 0) {
      final newText = text.replaceRange(
        selection.start,
        selection.end,
        placeholder,
      );
      _bodyController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.start + placeholder.length,
        ),
      );
    } else {
      _bodyController.text = '$text $placeholder';
    }
  }

  Future<void> _openContactPicker() async {
    final db = ref.read(databaseProvider);
    final clients = await (db.select(
      db.clients,
    )..where((c) => c.isDeleted.equals(false))).get();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = clients.where((c) {
              final q = query.toLowerCase();
              return c.name.toLowerCase().contains(q) ||
                  (c.email?.toLowerCase().contains(q) ?? false) ||
                  (c.organization?.toLowerCase().contains(q) ?? false);
            }).toList();

            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF14181B) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'CHOOSE RECIPIENT',
                    style: EtoleTypography.labelCaps(color: EtoleColors.cyan),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    autofocus: false,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search contacts...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF0F1214)
                          : const Color(0xFFF7F5EE),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (val) => setModalState(() => query = val),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text(
                              'No contacts found',
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, idx) {
                              final c = filtered[idx];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: EtoleColors.cyan.withValues(
                                    alpha: 0.15,
                                  ),
                                  child: Text(
                                    c.name.isNotEmpty
                                        ? c.name[0].toUpperCase()
                                        : 'C',
                                    style: const TextStyle(
                                      color: EtoleColors.cyan,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  c.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDark
                                        ? const Color(0xFFF1EDE4)
                                        : Colors.black87,
                                  ),
                                ),
                                subtitle: Text(
                                  c.email ?? c.organization ?? 'No email saved',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? const Color(0xFF9E9E9E)
                                        : Colors.black54,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  setState(() {
                                    _selectedClient = c;
                                    if (c.email != null &&
                                        c.email!.isNotEmpty) {
                                      final current = _toController.text.trim();
                                      if (current.isEmpty) {
                                        _toController.text = c.email!;
                                      } else if (!current.contains(c.email!)) {
                                        _toController.text =
                                            '$current, ${c.email!}';
                                      }
                                    }
                                  });
                                  _applyTemplate(_selectedTemplateType);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _previewPdf() async {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF14181B),
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                '${widget.completeDoc.document.docNumber}.pdf',
                style: const TextStyle(fontSize: 14),
              ),
              leading: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            Expanded(
              child: PdfPreview(
                build: (_) => PdfBuilder.buildDocumentPdf(
                  completeDoc: widget.completeDoc,
                ),
                canChangeOrientation: false,
                canChangePageFormat: false,
                canDebug: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _parseEmails(String input) {
    return input
        .split(RegExp(r'[,;\s]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty && e.contains('@'))
        .toList();
  }

  Future<void> _sendEmail() async {
    final toList = _parseEmails(_toController.text);
    if (toList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter at least one valid recipient email address.',
          ),
          backgroundColor: Color(0xFFC62828),
        ),
      );
      return;
    }

    if (_smtpConfig == null && _connectedAccount == null) {
      final configured = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SmtpEmailSettingsScreen()),
      );
      final refreshed = await SmtpStorage.loadConfig();
      if (refreshed != null) {
        setState(() => _smtpConfig = refreshed);
      } else {
        return;
      }
    }

    setState(() => _isSending = true);

    Uint8List? fileBytes;
    final doc = widget.completeDoc.document;
    final filename = '${doc.docNumber}.pdf';

    try {
      if (_attachPdf) {
        fileBytes = await PdfBuilder.buildDocumentPdf(
          completeDoc: widget.completeDoc,
        );
      }

      final ccList = _parseEmails(_ccController.text);
      final bccList = _parseEmails(_bccController.text);

      final docType = DocTypeExtension.fromCode(doc.docType);
      final paymentMap = _buildPaymentMap();

      final logoPath = widget.completeDoc.brand.logoPath;
      final hasCustomLogo =
          logoPath != null &&
          logoPath.isNotEmpty &&
          (logoPath.startsWith('assets/') || File(logoPath).existsSync());
      final socialLinks = await BrandSocialLinksRepository.getSocialLinks();

      final branded = BrandedEmailBuilder.buildEmail(
        theme: EmailTheme.editorialGallery,
        recipientName: _selectedClient?.name ?? toList.first,
        recipientEmail: toList.first,
        heading: _subjectController.text.trim(),
        messageHtml: BrandedEmailBuilder.plainTextToHtmlParagraphs(
          _bodyController.text.trim(),
        ),
        messagePlainText: _bodyController.text.trim(),
        clientName: _selectedClient?.name,
        docDate: DateFormatter.format(doc.issueDate),
        docType: docType.displayName.toUpperCase(),
        docNumber: doc.docNumber,
        docAmount: CurrencyFormatter.format(
          doc.totalAmount,
          currencyCode: doc.currencyCode,
        ),
        docDueDate: doc.dueOrValidityDate != null
            ? DateFormatter.format(doc.dueOrValidityDate!)
            : null,
        statusLabel: (doc.status.toLowerCase() == 'paid')
            ? 'PAID'
            : (doc.dueOrValidityDate != null
                  ? 'Due ${DateFormatter.format(doc.dueOrValidityDate!)}'
                  : null),
        paymentDetails: paymentMap,
        hasPdfAttachment: _attachPdf,
        hasCustomLogo: hasCustomLogo,
        socialLinks: socialLinks,
      );

      Uint8List? customLogoBytes;
      if (hasCustomLogo) {
        if (logoPath.startsWith('assets/')) {
          customLogoBytes = (await rootBundle.load(logoPath)).buffer
              .asUint8List();
        } else {
          customLogoBytes = await File(logoPath).readAsBytes();
        }
      }

      if (_smtpConfig != null && _smtpConfig!.password.isNotEmpty) {
        // Send via direct SMTP
        await SmtpEmailService.sendDocumentEmail(
          config: _smtpConfig!,
          recipientEmail: toList.first,
          subject: _subjectController.text.trim(),
          bodyText: branded.plainText,
          attachmentBytes: fileBytes ?? Uint8List(0),
          attachmentFilename: _attachPdf ? filename : '${doc.docNumber}.pdf',
          recipientName: _selectedClient?.name,
        );
      } else {
        // Fall back to Gmail OAuth
        await GmailSendService.sendEmail(
          recipientEmail: toList.first,
          additionalToEmails: toList.skip(1).toList(),
          recipientName: _selectedClient?.name,
          ccEmails: ccList,
          bccEmails: bccList,
          subject: _subjectController.text.trim(),
          bodyText: branded.plainText,
          htmlBody: branded.html,
          attachmentBytes: fileBytes,
          attachmentFilename: _attachPdf ? filename : null,
          customLogoBytes: customLogoBytes,
        );
      }

      await _logSuccessAndMarkSent(toList);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Document ${doc.docNumber} successfully sent to ${toList.join(", ")}!',
            ),
            backgroundColor: const Color(0xFF1B5E20),
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showFailureDialog(e.toString(), fileBytes, filename, toList.first);
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Map<String, String>? _buildPaymentMap() {
    final profile = widget.completeDoc.paymentProfile;
    if (profile == null) return null;
    final map = <String, String>{};
    if (profile.mpesaTillNumber?.trim().isNotEmpty == true) {
      map['M-Pesa Buy Goods'] = profile.mpesaTillNumber!.trim();
    }
    if (profile.mpesaPaybillNumber?.trim().isNotEmpty == true) {
      map['M-Pesa Paybill'] =
          '${profile.mpesaPaybillNumber!.trim()} (Acc: ${profile.mpesaPaybillAccount ?? widget.completeDoc.document.docNumber})';
    }
    if (profile.bankName?.trim().isNotEmpty == true) {
      map['Bank Transfer'] =
          '${profile.bankName!.trim()} — Acc: ${profile.accountNumber ?? ""} (${profile.accountName ?? ""})';
    }
    return map.isNotEmpty ? map : null;
  }

  Future<void> _logSuccessAndMarkSent(List<String> toList) async {
    try {
      final docId = widget.completeDoc.document.id;
      final docRepo = ref.read(documentRepositoryProvider);
      final db = ref.read(databaseProvider);
      final doc = widget.completeDoc.document;
      final docType = DocTypeExtension.fromCode(doc.docType);
      final recipientStr = toList.join(', ');

      // 1. Log in document activity logs
      await docRepo.logActivity(
        docId,
        'SENT',
        'Sent via Gmail (${_connectedAccount?.email ?? "hello@brianetole.com"}) to $recipientStr',
      );

      // 2. Mark document as sent and update lastSentAt
      await (db.update(db.documents)..where((t) => t.id.equals(docId))).write(
        DocumentsCompanion(
          status: const drift.Value('sent'),
          lastSentAt: drift.Value(DateTime.now()),
        ),
      );

      // 3. Log on Contact record
      if (_selectedClient != null) {
        final existingNotes = _selectedClient!.notes ?? '';
        final entry =
            '[Email Sent ${DateFormatter.format(DateTime.now())}] Sent ${docType.displayName} ${doc.docNumber} (${CurrencyFormatter.format(doc.totalAmount, currencyCode: doc.currencyCode)}) via Gmail to $recipientStr';
        final updatedNotes = existingNotes.isEmpty
            ? entry
            : '$existingNotes\n$entry';

        await (db.update(db.clients)
              ..where((c) => c.id.equals(_selectedClient!.id)))
            .write(ClientsCompanion(notes: drift.Value(updatedNotes)));
      }
    } catch (_) {}
  }

  void _showFailureDialog(
    String error,
    Uint8List? fileBytes,
    String filename,
    String recipient,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161A1D),
        title: Text(
          'Could Not Send Email',
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xFFF1EDE4),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Error sending via Gmail API:\n$error\n\nWould you like to try again or open in your email app instead?',
          style: const TextStyle(color: Color(0xFFD6D1C7), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              GmailSendService.openInExternalEmailApp(
                recipientEmail: recipient,
                subject: _subjectController.text.trim(),
                bodyText: _bodyController.text.trim(),
                attachmentBytes: fileBytes ?? Uint8List(0),
                attachmentFilename: filename,
              );
            },
            child: const Text(
              'Open in Gmail instead',
              style: TextStyle(color: EtoleColors.cyan),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: EtoleColors.cyan),
            onPressed: () {
              Navigator.pop(ctx);
              _sendEmail();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final doc = widget.completeDoc.document;

    if (_isLoadingAccount) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: CircularProgressIndicator(color: EtoleColors.cyan),
        ),
      );
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14181B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header with Preview Switcher
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SEND DOCUMENT',
                        style: EtoleTypography.labelCaps(
                          color: EtoleColors.cyan,
                        ),
                      ),
                      Text(
                        '${doc.docNumber} · GMAIL',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xFFF1EDE4)
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                // Toggle Preview button
                ActionChip(
                  avatar: Icon(
                    _isPreviewMode
                        ? Icons.edit_note_rounded
                        : Icons.visibility_outlined,
                    size: 16,
                    color: EtoleColors.cyan,
                  ),
                  label: Text(_isPreviewMode ? 'Compose' : 'Preview Branded'),
                  backgroundColor: isDark
                      ? const Color(0xFF1E2429)
                      : const Color(0xFFF0EBE1),
                  side: BorderSide(
                    color: isDark
                        ? const Color(0xFF2C3238)
                        : const Color(0xFFDDD7CB),
                  ),
                  onPressed: () =>
                      setState(() => _isPreviewMode = !_isPreviewMode),
                ),
              ],
            ),
          ),

          const EtoleHairline(),

          // Body Content (Compose or Preview)
          Expanded(
            child: _isPreviewMode
                ? _buildBrandedPreview(isDark)
                : _buildComposeForm(isDark),
          ),

          const EtoleHairline(),

          // Bottom Bar with Send Button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Row(
              children: [
                IconButton.outlined(
                  icon: const Icon(Icons.open_in_new_rounded),
                  tooltip: 'Open in Gmail App',
                  onPressed: _isSending
                      ? null
                      : () async {
                          final bytes = await PdfBuilder.buildDocumentPdf(
                            completeDoc: widget.completeDoc,
                          );
                          GmailSendService.openInExternalEmailApp(
                            recipientEmail: _toController.text.trim(),
                            subject: _subjectController.text.trim(),
                            bodyText: _bodyController.text.trim(),
                            attachmentBytes: bytes,
                            attachmentFilename: '${doc.docNumber}.pdf',
                          );
                        },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: EtoleColors.cyan,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      _isSending ? 'Sending via Gmail...' : 'SEND WITH GMAIL',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: _isSending ? null : _sendEmail,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposeForm(bool isDark) {
    final doc = widget.completeDoc.document;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sender Identity Card (SMTP or Google)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2429) : const Color(0xFFF3EFE6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _smtpConfig != null
                    ? const Color(0xFF00E5FF).withValues(alpha: 0.4)
                    : Colors.white12,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _smtpConfig != null
                      ? Icons.dns_rounded
                      : Icons.account_circle_rounded,
                  size: 16,
                  color: const Color(0xFF00E5FF),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _smtpConfig != null
                        ? 'From: ${_smtpConfig!.senderName} <${_smtpConfig!.senderEmail}> (SMTP)'
                        : (_connectedAccount != null
                              ? 'From: ${_connectedAccount!.email} (Gmail OAuth)'
                              : 'No dispatch email configured'),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                InkWell(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SmtpEmailSettingsScreen(),
                      ),
                    );
                    final refSmtp = await SmtpStorage.loadConfig();
                    if (mounted) setState(() => _smtpConfig = refSmtp);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _smtpConfig != null ? 'Change' : 'Set Up SMTP',
                      style: const TextStyle(
                        color: Color(0xFF00E5FF),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Choose Template Row
          Text(
            'CHOOSE TEMPLATE',
            style: EtoleTypography.labelCaps(
              color: isDark ? const Color(0xFFB0A99F) : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: EmailTemplateType.values.map((type) {
                final isSelected = _selectedTemplateType == type;
                final tpl = EmailTemplate.defaults[type]!;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(tpl.label),
                    selected: isSelected,
                    selectedColor: EtoleColors.cyan,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? const Color(0xFFD6D1C7) : Colors.black87),
                    ),
                    onSelected: (val) {
                      if (val) _applyTemplate(type);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // To Field + Contact Picker
          Row(
            children: [
              Expanded(
                child: Text(
                  'TO (RECIPIENTS)',
                  style: EtoleTypography.labelCaps(
                    color: isDark ? const Color(0xFFB0A99F) : Colors.black54,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _openContactPicker,
                child: const Row(
                  children: [
                    Icon(
                      Icons.contacts_rounded,
                      size: 14,
                      color: EtoleColors.cyan,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Pick Contact',
                      style: TextStyle(
                        color: EtoleColors.cyan,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _toController,
            style: TextStyle(
              color: isDark ? const Color(0xFFF1EDE4) : Colors.black87,
              fontSize: 13,
            ),
            decoration: InputDecoration(
              hintText: 'client@example.com, accounts@studio.com',
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF0F1214)
                  : const Color(0xFFF7F5EE),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          // CC & BCC Expansion
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() => _showMore = !_showMore),
              child: Text(
                _showMore ? 'Hide CC / BCC' : 'More (CC / BCC)',
                style: const TextStyle(fontSize: 11, color: Color(0xFFB0A99F)),
              ),
            ),
          ),
          if (_showMore) ...[
            Text(
              'CC',
              style: EtoleTypography.labelCaps(
                color: isDark ? const Color(0xFFB0A99F) : Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _ccController,
              style: TextStyle(
                color: isDark ? const Color(0xFFF1EDE4) : Colors.black87,
                fontSize: 13,
              ),
              decoration: InputDecoration(
                hintText: 'copy@example.com',
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF0F1214)
                    : const Color(0xFFF7F5EE),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'BCC',
              style: EtoleTypography.labelCaps(
                color: isDark ? const Color(0xFFB0A99F) : Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _bccController,
              style: TextStyle(
                color: isDark ? const Color(0xFFF1EDE4) : Colors.black87,
                fontSize: 13,
              ),
              decoration: InputDecoration(
                hintText: 'archive@brianetole.com',
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF0F1214)
                    : const Color(0xFFF7F5EE),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Subject Field
          Text(
            'SUBJECT LINE',
            style: EtoleTypography.labelCaps(
              color: isDark ? const Color(0xFFB0A99F) : Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _subjectController,
            style: TextStyle(
              color: isDark ? const Color(0xFFF1EDE4) : Colors.black87,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF0F1214)
                  : const Color(0xFFF7F5EE),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Message Body Field
          Text(
            'MESSAGE BODY',
            style: EtoleTypography.labelCaps(
              color: isDark ? const Color(0xFFB0A99F) : Colors.black54,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _bodyController,
            maxLines: 7,
            style: TextStyle(
              color: isDark ? const Color(0xFFF1EDE4) : Colors.black87,
              fontSize: 13,
              height: 1.45,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF0F1214)
                  : const Color(0xFFF7F5EE),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Quick Placeholder chips
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: EmailTemplate.availablePlaceholders.take(5).map((ph) {
              return ActionChip(
                label: Text(
                  ph,
                  style: const TextStyle(
                    fontSize: 10,
                    color: EtoleColors.cyan,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                padding: EdgeInsets.zero,
                backgroundColor: isDark
                    ? const Color(0xFF1B2024)
                    : const Color(0xFFF0EBE1),
                side: BorderSide(
                  color: isDark
                      ? const Color(0xFF2C3238)
                      : const Color(0xFFDDD7CB),
                ),
                onPressed: () => _insertPlaceholder(ph),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Attachment Chip (tap to preview)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F1214) : const Color(0xFFF7F5EE),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF2C3238)
                    : const Color(0xFFDDD7CB),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _previewPdf,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC62828).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: Color(0xFFEF5350),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _previewPdf,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${doc.docNumber}.pdf',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isDark
                                ? const Color(0xFFF1EDE4)
                                : Colors.black87,
                          ),
                        ),
                        const Text(
                          'Tap to preview PDF',
                          style: TextStyle(
                            fontSize: 11,
                            color: EtoleColors.cyan,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Switch(
                  value: _attachPdf,
                  activeThumbColor: EtoleColors.cyan,
                  onChanged: (val) => setState(() => _attachPdf = val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandedPreview(bool isDark) {
    final doc = widget.completeDoc.document;
    final docType = DocTypeExtension.fromCode(doc.docType);
    final amountStr = CurrencyFormatter.format(
      doc.totalAmount,
      currencyCode: doc.currencyCode,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFDED7CA)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 16,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Obsidian Header Band
            Container(
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
              color: const Color(0xFF0A0C0D),
              child: Column(
                children: [
                  if (widget.completeDoc.brand.logoPath != null &&
                      widget.completeDoc.brand.logoPath!.isNotEmpty &&
                      (widget.completeDoc.brand.logoPath!.startsWith(
                            'assets/',
                          ) ||
                          File(widget.completeDoc.brand.logoPath!)
                              .existsSync())) ...[
                    widget.completeDoc.brand.logoPath!.startsWith('assets/')
                        ? Image.asset(
                            widget.completeDoc.brand.logoPath!,
                            height: 44,
                            fit: BoxFit.contain,
                          )
                        : Image.file(
                            File(widget.completeDoc.brand.logoPath!),
                            height: 44,
                            fit: BoxFit.contain,
                          ),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    'BRIAN ETOLE',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: const Color(0xFFF3EAD9),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'VISUALSTORYTELLER',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      color: Color(0xFFA79F90),
                    ),
                  ),
                ],
              ),
            ),
            // Ember Accent line
            Container(height: 3, color: EtoleColors.cyan),

            // Message Body Container
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Heading
                  Text(
                    _subjectController.text.trim(),
                    style: const TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C1510),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Paragraphs
                  Text(
                    _bodyController.text.trim(),
                    style: const TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 14,
                      height: 1.6,
                      color: Color(0xFF231F1C),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Document Summary Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF7F3EB),
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                      border: Border(
                        left: BorderSide(color: EtoleColors.cyan, width: 4),
                        top: BorderSide(color: Color(0xFFDFD8CB)),
                        right: BorderSide(color: Color(0xFFDFD8CB)),
                        bottom: BorderSide(color: Color(0xFFDFD8CB)),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${docType.displayName.toUpperCase()} • ${doc.docNumber}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                color: EtoleColors.cyan,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: EtoleColors.cyan,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                doc.status.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_selectedClient != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Client: ${_selectedClient!.name}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6A6156),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        const Text(
                          'AMOUNT DUE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: Color(0xFF7A7065),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          amountStr,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1C1510),
                          ),
                        ),
                        if (_attachPdf) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(
                                Icons.attach_file_rounded,
                                size: 14,
                                color: EtoleColors.cyan,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${doc.docNumber}.pdf attached',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF5C5248),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Divider(color: Color(0xFFEAE3D6), height: 1),
                  const SizedBox(height: 16),

                  // Personal Sign-off
                  const Text(
                    'Warm regards,',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF5C5248),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Creative Studio',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF141718),
                    ),
                  ),
                  const Text(
                    'Commercial Production & Creative Direction',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: EtoleColors.cyan,
                    ),
                  ),
                ],
              ),
            ),

            // Obsidian Footer Band
            Container(
              padding: const EdgeInsets.all(22),
              color: const Color(0xFF0A0C0D),
              child: const Column(
                children: [
                  Text(
                    'CREATIVE OS • PRODUCTION & COMMERCE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: Color(0xFFF3EAD9),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Nairobi, Kenya',
                    style: TextStyle(fontSize: 10, color: Color(0xFFA79F90)),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Films • Photography • Commercials • Studio',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFFA79F90),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Instagram · LinkedIn · WhatsApp',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFFF3EAD9),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'hello@brianetole.com • +254 718 013 579 • brianetole.com',
                    style: TextStyle(fontSize: 10, color: Color(0xFFA79F90)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
