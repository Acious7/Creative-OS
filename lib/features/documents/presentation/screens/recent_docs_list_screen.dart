import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/document_constants.dart';
import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../providers/document_providers.dart';
import 'create_new_doc_screen.dart';
import 'document_detail_screen.dart';

class RecentDocsListScreen extends ConsumerStatefulWidget {
  final Function(int docId)? onOpenDocument;

  const RecentDocsListScreen({super.key, this.onOpenDocument});

  @override
  ConsumerState<RecentDocsListScreen> createState() =>
      _RecentDocsListScreenState();
}

class _RecentDocsListScreenState extends ConsumerState<RecentDocsListScreen> {
  String _selectedType = 'All';

  final List<String> _typeFilters = [
    'All',
    'Quotation',
    'Invoice',
    'Receipt',
    'Rate Card',
    'Contract',
  ];

  void _openDoc(int id) {
    EtoleHaptics.light();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DocumentDetailScreen(documentId: id)),
    );
  }

  void _createFirstDoc() {
    EtoleHaptics.light();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateNewDocScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final docsAsync = ref.watch(recentDocumentsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0C0E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0C0E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: EtoleColors.cream,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'RECENT DOCS',
          style: EtoleTypography.h2.copyWith(
            color: EtoleColors.cream,
            letterSpacing: 2.0,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            height: 44,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0x18F3EAD9), width: 1),
              ),
            ),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _typeFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final type = _typeFilters[index];
                final isSelected = _selectedType == type;
                return GestureDetector(
                  onTap: () {
                    EtoleHaptics.selection();
                    setState(() => _selectedType = type);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected
                              ? EtoleColors.cyan
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      type.toUpperCase(),
                      style: GoogleFonts.spaceMono(
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? EtoleColors.cyan
                            : EtoleColors.creamSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: docsAsync.when(
        data: (docs) {
          final filtered = docs.where((dwc) {
            if (_selectedType == 'All') return true;
            final docType = DocTypeExtension.fromCode(dwc.document.docType);
            switch (_selectedType) {
              case 'Quotation':
                return docType == DocType.quotation;
              case 'Invoice':
                return docType == DocType.invoice;
              case 'Receipt':
                return docType == DocType.receipt;
              case 'Rate Card':
                return docType == DocType.rateCard;
              case 'Contract':
                return docType == DocType.contract;
              default:
                return true;
            }
          }).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      color: EtoleColors.creamSecondary,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No documents yet',
                      style: GoogleFonts.inter(
                        color: EtoleColors.cream,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _selectedType == 'All'
                          ? 'Create your first quotation, invoice, receipt, or agreement.'
                          : 'No $_selectedType documents on record.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: EtoleColors.creamSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: EtoleColors.cyan,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _createFirstDoc,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(
                        'Create your first document',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final dwc = filtered[index];
              final doc = dwc.document;
              final client = dwc.client;
              final docType = DocTypeExtension.fromCode(doc.docType);

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _openDoc(doc.id),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14171A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0x22F3EAD9),
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Line 1: Type, Number, Stamp
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                docType.displayName.toUpperCase(),
                                style: GoogleFonts.spaceMono(
                                  color: EtoleColors.cyan,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '·',
                                style: TextStyle(
                                  color: EtoleColors.creamSecondary.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                doc.docNumber,
                                style: GoogleFonts.inter(
                                  color: EtoleColors.cream,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          _StampBadge(status: doc.status),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Line 2: Client
                      Text(
                        client != null
                            ? '${client.name}${client.organization != null && client.organization!.isNotEmpty ? " (${client.organization})" : ""}'
                            : 'Unassigned Client',
                        style: GoogleFonts.inter(
                          color: EtoleColors.cream,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 8),

                      // Line 3: Date & Amount for this doc only
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormatter.format(doc.issueDate),
                            style: GoogleFonts.inter(
                              color: EtoleColors.creamSecondary,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(
                              doc.totalAmount,
                              currencyCode: doc.currencyCode,
                            ),
                            style: GoogleFonts.inter(
                              color: EtoleColors.gold,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: EtoleColors.cyan),
        ),
        error: (err, _) => Center(
          child: Text(
            'Error loading documents: $err',
            style: const TextStyle(color: EtoleColors.creamSecondary),
          ),
        ),
      ),
    );
  }
}

class _StampBadge extends StatelessWidget {
  final String status;

  const _StampBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase().trim();
    Color borderColor;
    Color textColor;

    switch (s) {
      case 'paid':
        borderColor = EtoleColors.green;
        textColor = EtoleColors.green;
        break;
      case 'sent':
        borderColor = EtoleColors.cyan;
        textColor = EtoleColors.cyan;
        break;
      case 'overdue':
        borderColor = EtoleColors.red;
        textColor = EtoleColors.red;
        break;
      case 'cancelled':
      case 'canceled':
        borderColor = const Color(0xFF6B645B); // deep stone
        textColor = const Color(0xFF6B645B);
        break;
      case 'draft':
      default:
        borderColor = const Color(0xFF8C8275); // muted warm stone
        textColor = const Color(0xFF8C8275);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: borderColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: borderColor.withValues(alpha: 0.8),
          width: 1.0,
        ),
      ),
      child: Text(
        s.toUpperCase(),
        style: GoogleFonts.spaceMono(
          color: textColor,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
