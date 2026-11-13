import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/document_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../clients/presentation/screens/client_detail_screen.dart';
import '../../../clients/presentation/screens/clients_list_screen.dart';
import '../../data/document_repository.dart';
import '../providers/document_providers.dart';
import 'create_new_doc_screen.dart';
import 'document_detail_screen.dart';
import 'document_editor_screen.dart';
import 'recent_docs_list_screen.dart';
import '../../../../core/theme/brand_theme_provider.dart';
import '../../../../core/theme/studio_theme.dart';

class DocsHomeScreen extends ConsumerStatefulWidget {
  final Function(int docId)? onOpenDocument;
  final Function(DocType docType)? onNewDocument;

  const DocsHomeScreen({super.key, this.onOpenDocument, this.onNewDocument});

  @override
  ConsumerState<DocsHomeScreen> createState() => _DocsHomeScreenState();
}

class _DocsHomeScreenState extends ConsumerState<DocsHomeScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  DocType? _selectedDocTypeFilter;

  static final NumberFormat _currencyFormat = NumberFormat('#,##0', 'en_US');
  StudioThemeData _theme = StudioThemeData.tribalOrange;
  Color get _accent => _theme.primaryAccent;
  Color get _bg => _theme.backgroundBase;
  Color get _cardBg => _theme.surfaceCardColor;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openDocumentDetail(int docId) {
    EtoleHaptics.light();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentDetailScreen(documentId: docId),
      ),
    );
  }

  void _openClientDetail(Client client) {
    EtoleHaptics.light();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientDetailScreen(
          client: client,
          onOpenDocument: _openDocumentDetail,
        ),
      ),
    );
  }

  void _createNewDocument(DocType docType) {
    EtoleHaptics.selection();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DocumentEditorScreen(docType: docType)),
    );
  }

  @override
  Widget build(BuildContext context) {
    _theme = ref.watch(currentStudioThemeProvider);
    final recentDocsAsync = ref.watch(recentDocumentsProvider);
    final clientsAsync = ref.watch(allClientsStreamProvider);

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Executive Top Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  // Reserve clearance for WorldContainer's floating < HUB pill
                  const SizedBox(width: 82),

                  // Title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DOCS & FINANCE',
                          style: EtoleTypography.h2.copyWith(
                            color: EtoleColors.cream,
                            letterSpacing: 2.2,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Quotations, Invoices & Commercial Scope',
                          style: EtoleTypography.labelSmall.copyWith(
                            color: const Color(0xFF007A3D),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Contacts Directory Button
                  IconButton(
                    icon: const Icon(
                      Icons.people_alt_outlined,
                      color: Color(0xFF007A3D),
                      size: 21,
                    ),
                    tooltip: 'Client Directory',
                    onPressed: () {
                      EtoleHaptics.light();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ClientsListScreen(
                            onOpenDocument: _openDocumentDetail,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // 2. Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _searchQuery.isNotEmpty
                        ? const Color(0xFF007A3D)
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF007A3D),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (val) {
                          setState(() => _searchQuery = val.trim());
                        },
                        style: const TextStyle(
                          color: EtoleColors.cream,
                          fontSize: 13.5,
                        ),
                        cursorColor: const Color(0xFF007A3D),
                        decoration: const InputDecoration(
                          hintText:
                              'Search quotation #, client, amount, or scope...',
                          hintStyle: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12.5,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: const Icon(
                          Icons.close_rounded,
                          color: EtoleColors.creamMuted,
                          size: 16,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // 3. Mogul Financial Telemetry KPI Strip
            recentDocsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (docs) {
                double totalInvoiced = 0.0;
                double totalPaid = 0.0;
                double totalQuotes = 0.0;

                for (final dwc in docs) {
                  final doc = dwc.document;
                  final docType = DocTypeExtension.fromCode(doc.docType);
                  if (docType == DocType.invoice) {
                    totalInvoiced += doc.totalAmount;
                    if (doc.status == 'paid') {
                      totalPaid += doc.totalAmount;
                    }
                  } else if (docType == DocType.quotation) {
                    totalQuotes += doc.totalAmount;
                  }
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildMetricChip(
                          icon: Icons.receipt_long_outlined,
                          accentColor: const Color(0xFF007A3D),
                          title: 'TOTAL INVOICED',
                          value: 'KES ${_currencyFormat.format(totalInvoiced)}',
                        ),
                        const SizedBox(width: 8),
                        _buildMetricChip(
                          icon: Icons.check_circle_outline_rounded,
                          accentColor: const Color(0xFF38B6DB),
                          title: 'PAID REVENUE',
                          value: 'KES ${_currencyFormat.format(totalPaid)}',
                        ),
                        const SizedBox(width: 8),
                        _buildMetricChip(
                          icon: Icons.request_quote_outlined,
                          accentColor: const Color(0xFFF59E0B),
                          title: 'PITCHED QUOTES',
                          value: 'KES ${_currencyFormat.format(totalQuotes)}',
                        ),
                        const SizedBox(width: 8),
                        _buildMetricChip(
                          icon: Icons.folder_open_rounded,
                          accentColor: const Color(0xFF2563EB),
                          title: 'ALL DOCUMENTS',
                          value: '${docs.length} Docs',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 8),

            // 4. Quick Action Create Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildQuickCreateButton(
                    label: 'Quote',
                    icon: Icons.request_quote_outlined,
                    color: const Color(0xFF38B6DB),
                    onTap: () => _createNewDocument(DocType.quotation),
                  ),
                  const SizedBox(width: 8),
                  _buildQuickCreateButton(
                    label: 'Invoice',
                    icon: Icons.receipt_long_rounded,
                    color: const Color(0xFF007A3D),
                    onTap: () => _createNewDocument(DocType.invoice),
                  ),
                  const SizedBox(width: 8),
                  _buildQuickCreateButton(
                    label: 'Contract',
                    icon: Icons.description_outlined,
                    color: const Color(0xFFF59E0B),
                    onTap: () => _createNewDocument(DocType.contract),
                  ),
                  const SizedBox(width: 8),
                  _buildQuickCreateButton(
                    label: 'Receipt',
                    icon: Icons.bookmark_added_outlined,
                    color: const Color(0xFF2563EB),
                    onTap: () => _createNewDocument(DocType.receipt),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // 5. Document Type Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(null, 'All Documents'),
                    _buildFilterChip(DocType.quotation, 'Quotations'),
                    _buildFilterChip(DocType.invoice, 'Invoices'),
                    _buildFilterChip(DocType.contract, 'Contracts'),
                    _buildFilterChip(DocType.receipt, 'Receipts'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // 6. Documents List / Search Results
            Expanded(
              child: recentDocsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF007A3D)),
                ),
                error: (err, _) => Center(
                  child: Text(
                    'Error: $err',
                    style: const TextStyle(color: EtoleColors.cream),
                  ),
                ),
                data: (allDocs) {
                  List<DocumentWithClient> docs = allDocs;

                  // Apply type filter
                  if (_selectedDocTypeFilter != null) {
                    docs = docs
                        .where(
                          (dwc) =>
                              dwc.document.docType ==
                              _selectedDocTypeFilter!.code,
                        )
                        .toList();
                  }

                  // Apply search query
                  if (_searchQuery.isNotEmpty) {
                    final query = _searchQuery.toLowerCase();
                    docs = docs.where((dwc) {
                      final doc = dwc.document;
                      final client = dwc.client;
                      final matchNum = doc.docNumber.toLowerCase().contains(
                        query,
                      );
                      final matchClient =
                          client?.name.toLowerCase().contains(query) ?? false;
                      final matchOrg =
                          client?.organization?.toLowerCase().contains(query) ??
                          false;
                      final matchAmount = doc.totalAmount.toString().contains(
                        query,
                      );
                      return matchNum || matchClient || matchOrg || matchAmount;
                    }).toList();
                  }

                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 48,
                            color: const Color(0xFF007A3D)
                                .withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No documents match "$_searchQuery"'
                                : 'No ${_selectedDocTypeFilter?.displayName ?? 'documents'} created yet',
                            style: EtoleTypography.h3.copyWith(
                              color: EtoleColors.cream,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Draft a commercial quotation or invoice with 1 tap.',
                            style: EtoleTypography.bodySmall(
                              color: EtoleColors.creamMuted,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final dwc = docs[index];
                      return _buildDocumentTile(dwc);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricChip({
    required IconData icon,
    required Color accentColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.35),
          width: 0.9,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: accentColor),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCreateButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.35),
              width: 0.9,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(DocType? docType, String label) {
    final isSelected = _selectedDocTypeFilter == docType;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          EtoleHaptics.light();
          setState(() => _selectedDocTypeFilter = docType);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF007A3D).withValues(alpha: 0.22)
                : _cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF007A3D)
                  : Colors.white.withValues(alpha: 0.08),
              width: isSelected ? 1.2 : 0.8,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : EtoleColors.creamSecondary,
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentTile(DocumentWithClient dwc) {
    final doc = dwc.document;
    final client = dwc.client;
    final docType = DocTypeExtension.fromCode(doc.docType);

    Color typeColor;
    switch (docType) {
      case DocType.quotation:
        typeColor = const Color(0xFF38B6DB);
        break;
      case DocType.invoice:
        typeColor = const Color(0xFF007A3D);
        break;
      case DocType.contract:
        typeColor = const Color(0xFFF59E0B);
        break;
      case DocType.receipt:
        typeColor = const Color(0xFF2563EB);
        break;
      case DocType.rateCard:
        typeColor = const Color(0xFF9333EA);
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF14171B),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(10),
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
        border: Border.all(color: typeColor.withValues(alpha: 0.3), width: 1.0),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openDocumentDetail(doc.id),
          child: Padding(
            padding: const EdgeInsets.all(13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Doc Type Icon Capsule
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: typeColor.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Icon(
                    docType == DocType.quotation
                        ? Icons.request_quote_outlined
                        : (docType == DocType.invoice
                              ? Icons.receipt_long_rounded
                              : (docType == DocType.contract
                                    ? Icons.description_outlined
                                    : Icons.bookmark_added_outlined)),
                    color: typeColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Main Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            doc.docNumber,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: typeColor.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              docType.displayName.toUpperCase(),
                              style: TextStyle(
                                color: typeColor,
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        client?.name ?? 'Direct Client',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormatter.format(doc.issueDate),
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // Amount & Status
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.format(
                        doc.totalAmount,
                        currencyCode: doc.currencyCode,
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: doc.status == 'paid'
                            ? const Color(0xFF007A3D).withValues(alpha: 0.2)
                            : (doc.status == 'sent'
                                  ? const Color(0xFF38B6DB)
                                        .withValues(alpha: 0.2)
                                  : Colors.white.withValues(alpha: 0.08)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        doc.status.toUpperCase(),
                        style: TextStyle(
                          color: doc.status == 'paid'
                              ? const Color(0xFF34D399)
                              : (doc.status == 'sent'
                                    ? const Color(0xFF38B6DB)
                                    : const Color(0xFF94A3B8)),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
