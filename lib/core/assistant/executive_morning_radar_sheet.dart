import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../database/app_database.dart';
import '../database/database_provider.dart';
import '../design_system/etole_colors.dart';
import '../design_system/etole_components.dart';
import '../design_system/etole_typography.dart';
import '../../features/digital_cards/domain/freelance_crm_models.dart';
import '../../features/digital_cards/presentation/providers/cards_providers.dart';
import '../../features/documents/data/document_repository.dart';
import '../../features/documents/presentation/providers/document_providers.dart';
import '../../features/documents/presentation/widgets/payment_chaser_sheet.dart';

class ExecutiveMorningRadarSheet extends ConsumerWidget {
  const ExecutiveMorningRadarSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ExecutiveMorningRadarSheet(),
    );
  }

  static final NumberFormat _currencyFormat = NumberFormat('#,##0', 'en_US');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentDocsAsync = ref.watch(recentDocumentsProvider);
    final leadsAsync = ref.watch(networkingLeadsProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFA0A0D10),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
                width: 1.5,
              ),
            ),
          ),
          padding: EdgeInsets.fromLTRB(20, 14, 20, 28 + bottomInset),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: EtoleColors.creamMuted.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Top Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFF59E0B)
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Icon(
                            Icons.wb_sunny_rounded,
                            color: Color(0xFFF59E0B),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CEO MORNING RADAR',
                              style: TextStyle(
                                color: Color(0xFFF59E0B),
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.6,
                              ),
                            ),
                            Text(
                              'Executive Studio Dispatch',
                              style: EtoleTypography.h3.copyWith(
                                color: EtoleColors.cream,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: EtoleColors.creamMuted,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 1. CASHFLOW HEALTH & KRA TAX ESCROW BREAKDOWN
                recentDocsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: Color(0xFFF59E0B)),
                  ),
                  error: (e, _) => Text(
                    'Error: $e',
                    style: const TextStyle(color: Colors.red),
                  ),
                  data: (docs) {
                    double totalInvoiced = 0.0;
                    double totalPaid = 0.0;
                    final List<DocumentWithClient> unpaidInvoices = [];

                    for (final dwc in docs) {
                      final doc = dwc.document;
                      if (doc.docType == 'invoice') {
                        totalInvoiced += doc.totalAmount;
                        if (doc.status == 'paid') {
                          totalPaid += doc.totalAmount;
                        } else {
                          unpaidInvoices.add(dwc);
                        }
                      }
                    }

                    final outstanding = totalInvoiced - totalPaid;
                    final estimatedWht = totalInvoiced * 0.05; // 5% WHT
                    final estimatedVat =
                        (totalInvoiced / 1.16) * 0.16; // 16% VAT portion
                    final netOperatingCash = totalPaid - estimatedVat;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cashflow Overview Strip
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF13171B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'CASHFLOW & REVENUE DISPATCH',
                                    style: TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF007A3D)
                                          .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: const Text(
                                      'KES ASSETS',
                                      style: TextStyle(
                                        color: Color(0xFF34D399),
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Cash Inflow (Paid)',
                                        style: TextStyle(
                                          color: Color(0xFF94A3B8),
                                          fontSize: 11,
                                        ),
                                      ),
                                      Text(
                                        'KES ${_currencyFormat.format(totalPaid)}',
                                        style: const TextStyle(
                                          color: Color(0xFF34D399),
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text(
                                        'Outstanding Debtors',
                                        style: TextStyle(
                                          color: Color(0xFF94A3B8),
                                          fontSize: 11,
                                        ),
                                      ),
                                      Text(
                                        'KES ${_currencyFormat.format(outstanding)}',
                                        style: const TextStyle(
                                          color: Color(0xFFFBBF24),
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),
                              const Divider(
                                color: Color(0x1AFFFFFF),
                                height: 1,
                              ),
                              const SizedBox(height: 10),

                              // KRA Tax Escrow Breakdown
                              const Text(
                                'KRA Tax & Net Operating Escrow:',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 10.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '• WHT (5% Client Retained): KES ${_currencyFormat.format(estimatedWht)}',
                                    style: const TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    '• VAT Escrow (16%): KES ${_currencyFormat.format(estimatedVat)}',
                                    style: const TextStyle(
                                      color: Color(0xFFEF4444),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '• Estimated Net Studio Profit: KES ${_currencyFormat.format(netOperatingCash > 0 ? netOperatingCash : 0)}',
                                style: const TextStyle(
                                  color: Color(0xFF38B6DB),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Outstanding Debtors List
                        if (unpaidInvoices.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'AGING DEBTORS (${unpaidInvoices.length} UNPAID)',
                                style: const TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const Text(
                                '1-Tap Chase Available',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...unpaidInvoices.take(3).map((dwc) {
                            final doc = dwc.document;
                            final client = dwc.client;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF14171B),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFEF4444)
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${client?.name ?? 'Client'} • #${doc.docNumber}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'KES ${_currencyFormat.format(doc.totalAmount)}',
                                        style: const TextStyle(
                                          color: Color(0xFFFBBF24),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFEF4444)
                                          .withValues(alpha: 0.2),
                                      foregroundColor: const Color(0xFFFCA5A5),
                                      elevation: 0,
                                      side: const BorderSide(
                                        color: Color(0xFFEF4444),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      minimumSize: const Size(0, 30),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () => PaymentChaserSheet.show(
                                      context,
                                      document: doc,
                                      client: client,
                                    ),
                                    child: const Text(
                                      'Chase',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 12),
                        ],
                      ],
                    );
                  },
                ),

                // 2. ACTIVE DEAL PIPELINE VELOCITY
                leadsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (leads) {
                    final activeDeals = leads.where((l) {
                      final deal = FreelanceDealInfo.fromLead(l);
                      return deal.dealValue > 0 &&
                          (deal.stage == DealStage.pitching ||
                              deal.stage == DealStage.negotiating);
                    }).toList();

                    if (activeDeals.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'HOT COMMERCIAL DEALS CLOSING',
                          style: TextStyle(
                            color: Color(0xFFF59E0B),
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...activeDeals.take(2).map((lead) {
                          final deal = FreelanceDealInfo.fromLead(lead);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF14171B),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFF59E0B)
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        deal.dealTitle ?? lead.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${lead.name} • ${deal.serviceCategory}',
                                        style: const TextStyle(
                                          color: Color(0xFF94A3B8),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    deal.formattedValue,
                                    style: const TextStyle(
                                      color: Color(0xFFFBBF24),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
