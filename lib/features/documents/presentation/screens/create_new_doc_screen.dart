import 'dart:ui';

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/document_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../providers/document_providers.dart';
import 'document_editor_screen.dart';

class CreateNewDocScreen extends ConsumerStatefulWidget {
  final int? preselectedClientId;
  final Function(DocType docType)? onNewDocument;

  const CreateNewDocScreen({
    super.key,
    this.preselectedClientId,
    this.onNewDocument,
  });

  @override
  ConsumerState<CreateNewDocScreen> createState() => _CreateNewDocScreenState();
}

class _CreateNewDocScreenState extends ConsumerState<CreateNewDocScreen> {
  void _openEditor(DocType docType, {int? invoiceId, Document? linkedInvoice}) {
    EtoleHaptics.light();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentEditorScreen(
          docType: docType,
          initialClientId:
              widget.preselectedClientId ?? linkedInvoice?.clientId,
          linkedInvoice: linkedInvoice,
        ),
      ),
    );
  }

  Future<void> _handleReceiptFlow() async {
    EtoleHaptics.light();
    final db = ref.read(databaseProvider);
    final invoices =
        await (db.select(db.documents)
              ..where((t) => t.docType.equals('invoice'))
              ..orderBy([(t) => drift.OrderingTerm.desc(t.issueDate)]))
            .get();

    if (!mounted) return;

    // Show Invoice Selection Sheet
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF14171A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SELECT INVOICE FOR RECEIPT',
                    style: EtoleTypography.labelCaps(color: EtoleColors.cyan),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: EtoleColors.creamSecondary,
                    ),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Pre-fills client, line items and payment total from an existing invoice.',
                style: GoogleFonts.inter(
                  color: EtoleColors.creamSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),

              // Standalone Option
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Color(0x33F3EAD9)),
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: EtoleColors.slate.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: EtoleColors.slate,
                    size: 18,
                  ),
                ),
                title: Text(
                  'Standalone Receipt',
                  style: GoogleFonts.inter(
                    color: EtoleColors.cream,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                subtitle: const Text(
                  'Create direct receipt without linking to an invoice',
                  style: TextStyle(
                    color: EtoleColors.creamSecondary,
                    fontSize: 11.5,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _openEditor(DocType.receipt);
                },
              ),

              if (invoices.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  'EXISTING INVOICES (${invoices.length})',
                  style: EtoleTypography.labelCaps(
                    color: EtoleColors.creamSecondary,
                  ).copyWith(fontSize: 10),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.4,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: invoices.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: Color(0x18F3EAD9), height: 1),
                    itemBuilder: (ctx, idx) {
                      final inv = invoices[idx];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              inv.docNumber,
                              style: GoogleFonts.inter(
                                color: EtoleColors.cream,
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(
                                inv.totalAmount,
                                currencyCode: inv.currencyCode,
                              ),
                              style: GoogleFonts.inter(
                                color: EtoleColors.gold,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          'Issued ${DateFormatter.format(inv.issueDate)} · Status: ${inv.status.toUpperCase()}',
                          style: GoogleFonts.inter(
                            color: EtoleColors.creamSecondary,
                            fontSize: 11.5,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: EtoleColors.creamSecondary,
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          _openEditor(DocType.receipt, linkedInvoice: inv);
                        },
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? EtoleColors.darkBase : EtoleColors.lightBase;
    final textColor = isDark ? EtoleColors.cream : EtoleColors.lightTextPrimary;
    final mutedColor = isDark
        ? EtoleColors.creamSecondary
        : EtoleColors.lightTextMuted;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textColor,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'CREATE NEW',
          style: GoogleFonts.playfairDisplay(
            color: textColor,
            letterSpacing: -0.2,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
        children: [
          Text(
            'CHOOSE DOCUMENT TYPE',
            style: EtoleTypography.labelCaps(color: mutedColor)
                .copyWith(fontSize: 11, letterSpacing: 1.5),
          ),
          const SizedBox(height: 14),

          // 1. QUOTATION
          _DocumentTypeWindowPane(
            docType: 'QUOTATION',
            accentColor: EtoleColors.cyan,
            description:
                'Itemized estimate, project proposal & valid-until terms',
            onTap: () => _openEditor(DocType.quotation),
            glimpse: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'BE-QT-2026-001',
                      style: GoogleFonts.spaceMono(
                        color: textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: EtoleColors.cyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: EtoleColors.cyan.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        'VALID 14 DAYS',
                        style: GoogleFonts.spaceMono(
                          color: EtoleColors.cyan,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Cinematography & Directing · 3 Production Days',
                  style: GoogleFonts.inter(color: mutedColor, fontSize: 11.5),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 2. INVOICE
          _DocumentTypeWindowPane(
            docType: 'INVOICE',
            accentColor: EtoleColors.green,
            description:
                'Commercial invoice with payment terms, KRA PIN & due date',
            onTap: () => _openEditor(DocType.invoice),
            glimpse: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'BE-INV-2026-001',
                      style: GoogleFonts.spaceMono(
                        color: textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: EtoleColors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: EtoleColors.green.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        'BALANCE DUE',
                        style: GoogleFonts.spaceMono(
                          color: EtoleColors.green,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'VAT 16% · Withholding Tax 5% · Bank & M-Pesa details attached',
                  style: GoogleFonts.inter(color: mutedColor, fontSize: 11.5),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 3. RECEIPT
          _DocumentTypeWindowPane(
            docType: 'RECEIPT',
            accentColor: EtoleColors.slate,
            description:
                'Official proof of payment voucher linked to invoice or direct',
            onTap: _handleReceiptFlow,
            glimpse: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'BE-REC-2026-001',
                      style: GoogleFonts.spaceMono(
                        color: textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'M-Pesa / Bank confirmation code attached',
                      style: GoogleFonts.inter(
                        color: mutedColor,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: EtoleColors.slate.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: EtoleColors.slate, width: 1.2),
                  ),
                  child: Text(
                    'PAID',
                    style: GoogleFonts.spaceMono(
                      color: EtoleColors.slate,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 4. RATE CARD
          _DocumentTypeWindowPane(
            docType: 'RATE CARD',
            accentColor: EtoleColors.gold,
            description:
                'Current standard package rates pulled from Services library',
            onTap: () => _openEditor(DocType.rateCard),
            glimpse: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'BE-RC-2026',
                      style: GoogleFonts.spaceMono(
                        color: textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: EtoleColors.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: EtoleColors.gold.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        'SERVICES & GEAR',
                        style: GoogleFonts.spaceMono(
                          color: EtoleColors.gold,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Cinematography day rate · Drone operator · Colour grading · Half day',
                  style: GoogleFonts.inter(color: mutedColor, fontSize: 11.5),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // 5. CONTRACT
          _DocumentTypeWindowPane(
            docType: 'CONTRACT',
            accentColor: EtoleColors.red,
            description: 'Legal agreement built from standard clauses with dual signing blocks',
            onTap: () => _openEditor(DocType.contract),
            glimpse: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'BE-CT-2026-001',
                      style: GoogleFonts.spaceMono(
                        color: textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: EtoleColors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: EtoleColors.red.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        'DUAL SIGNATURES',
                        style: GoogleFonts.spaceMono(
                          color: EtoleColors.red,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Copyright ownership · Usage license · Payment schedule · Cancellation clause',
                  style: GoogleFonts.inter(color: mutedColor, fontSize: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentTypeWindowPane extends StatefulWidget {
  final String docType;
  final String description;
  final Widget glimpse;
  final VoidCallback onTap;
  final Color? accentColor;

  const _DocumentTypeWindowPane({
    required this.docType,
    required this.description,
    required this.glimpse,
    required this.onTap,
    this.accentColor,
  });

  @override
  State<_DocumentTypeWindowPane> createState() =>
      _DocumentTypeWindowPaneState();
}

class _DocumentTypeWindowPaneState extends State<_DocumentTypeWindowPane> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? const Color(0xFF14171A).withValues(alpha: 0.85)
        : Colors.white;
    final borderColor = isDark
        ? const Color(0x33F3EAD9)
        : const Color(0xFFE5E7EB);
    final accent = widget.accentColor ?? EtoleColors.cyan;
    final mutedText = isDark
        ? EtoleColors.creamSecondary
        : EtoleColors.lightTextMuted;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24.0),
            topRight: Radius.circular(12.0),
            bottomLeft: Radius.circular(12.0),
            bottomRight: Radius.circular(12.0),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24.0),
                  topRight: Radius.circular(12.0),
                  bottomLeft: Radius.circular(12.0),
                  bottomRight: Radius.circular(12.0),
                ),
                border: Border.all(
                  color: _isPressed ? accent : borderColor,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                  if (_isPressed)
                    BoxShadow(
                      color: accent.withValues(alpha: 0.2),
                      blurRadius: 14,
                    ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.docType,
                        style: EtoleTypography.labelCaps(color: accent)
                            .copyWith(
                              fontSize: 13,
                              letterSpacing: 1.8,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 12,
                        color: mutedText,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.description,
                    style: GoogleFonts.inter(
                      color: mutedText.withValues(alpha: 0.85),
                      fontSize: 11.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Divider(color: borderColor, height: 1),
                  const SizedBox(height: 12),
                  widget.glimpse,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
