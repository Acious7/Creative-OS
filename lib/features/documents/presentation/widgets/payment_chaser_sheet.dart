import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../../../../core/utils/currency_formatter.dart';

class PaymentChaserSheet extends StatefulWidget {
  final Document document;
  final Client? client;

  const PaymentChaserSheet({super.key, required this.document, this.client});

  static Future<void> show(
    BuildContext context, {
    required Document document,
    Client? client,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PaymentChaserSheet(document: document, client: client),
    );
  }

  @override
  State<PaymentChaserSheet> createState() => _PaymentChaserSheetState();
}

class _PaymentChaserSheetState extends State<PaymentChaserSheet> {
  int _selectedTone = 0; // 0: Friendly, 1: Production Milestone, 2: Formal
  late TextEditingController _messageController;

  final List<String> _toneLabels = [
    'Friendly Check-in',
    'Milestone Due Notice',
    'Official Finance Notice',
  ];

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _generateMessage();
  }

  void _generateMessage() {
    final clientName = widget.client?.name ?? 'Client';
    final amountFormatted = CurrencyFormatter.format(
      widget.document.totalAmount,
      currencyCode: widget.document.currencyCode,
    );
    final docNum = widget.document.docNumber;

    String msg;
    if (_selectedTone == 0) {
      msg =
          'Hi $clientName! Hope you’re having a great week. Just touching base regarding invoice $docNum ($amountFormatted). Please let me know if your finance team needs any additional details or documents to process the settlement. Thank you!';
    } else if (_selectedTone == 1) {
      msg =
          'Hello $clientName, Brian here from Brian Etole Productions. Following up on invoice $docNum ($amountFormatted). To ensure our shoot dates, cinema crew bookings, and post-production timeline remain locked, we kindly request settlement of this milestone balance. Let me know if you need any assistance!';
    } else {
      msg =
          'Dear $clientName,\n\nPlease note invoice #$docNum in the amount of $amountFormatted is currently outstanding. Kindly arrange for settlement to our M-Pesa Till or Bank Wire accounts as specified on the invoice. We appreciate your prompt turnaround.';
    }
    _messageController.text = msg;
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendWhatsApp() async {
    final phone = widget.client?.phone;
    if (phone == null || phone.trim().isEmpty) {
      await Clipboard.setData(ClipboardData(text: _messageController.text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No client phone saved. Copied message to clipboard!',
            ),
          ),
        );
      }
      return;
    }

    final clean = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse(
      'https://wa.me/$clean?text=${Uri.encodeComponent(_messageController.text)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (mounted) Navigator.pop(context);
    } else {
      await Clipboard.setData(ClipboardData(text: _messageController.text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Copied payment reminder to clipboard!'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final amountFormatted = CurrencyFormatter.format(
      widget.document.totalAmount,
      currencyCode: widget.document.currencyCode,
    );

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFA121518),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
          ),
          padding: EdgeInsets.fromLTRB(20, 14, 20, 24 + bottomInset),
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

                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFEF4444)
                                  .withValues(alpha: 0.35),
                            ),
                          ),
                          child: const Icon(
                            Icons.monetization_on_outlined,
                            color: Color(0xFFEF4444),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PAYMENT RADAR & CHASER',
                              style: TextStyle(
                                color: Color(0xFFEF4444),
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.4,
                              ),
                            ),
                            Text(
                              'Invoice #${widget.document.docNumber}',
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
                const SizedBox(height: 14),

                // Amount & Client Capsule
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF191D22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Client',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            widget.client?.name ?? 'Direct Client',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Outstanding Balance',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            amountFormatted,
                            style: const TextStyle(
                              color: Color(0xFFFBBF24),
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Tone Selector
                const Text(
                  'Reminder Tone:',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(_toneLabels.length, (i) {
                    final isSelected = _selectedTone == i;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: i < _toneLabels.length - 1 ? 6 : 0,
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            EtoleHaptics.selection();
                            setState(() {
                              _selectedTone = i;
                              _generateMessage();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFEF4444)
                                        .withValues(alpha: 0.2)
                                  : const Color(0xFF191D22),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFEF4444)
                                    : Colors.white.withValues(alpha: 0.08),
                                width: isSelected ? 1.2 : 0.8,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _toneLabels[i].split(' ').first,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF94A3B8),
                                fontSize: 11.5,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 14),

                // Message Text
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14171B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: TextField(
                    controller: _messageController,
                    maxLines: 5,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.45,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Actions
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _sendWhatsApp,
                        icon: const Icon(Icons.send_rounded, size: 16),
                        label: const Text(
                          'Chase via WhatsApp',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        EtoleHaptics.light();
                        await Clipboard.setData(
                          ClipboardData(text: _messageController.text),
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Payment reminder copied!'),
                            ),
                          );
                        }
                      },
                      child: const Icon(Icons.copy_rounded, size: 18),
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
