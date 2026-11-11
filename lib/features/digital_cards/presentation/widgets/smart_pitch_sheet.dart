import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../../domain/freelance_crm_models.dart';

class SmartPitchSheet extends StatefulWidget {
  final NetworkingLead lead;
  final String? eventLocation;

  const SmartPitchSheet({super.key, required this.lead, this.eventLocation});

  static Future<void> show(
    BuildContext context, {
    required NetworkingLead lead,
    String? eventLocation,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SmartPitchSheet(lead: lead, eventLocation: eventLocation),
    );
  }

  @override
  State<SmartPitchSheet> createState() => _SmartPitchSheetState();
}

class _SmartPitchSheetState extends State<SmartPitchSheet> {
  int _selectedTemplateIndex = 0;
  late TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _updateMessage();
  }

  void _updateMessage() {
    final template =
        FreelancePitchTemplate.allTemplates[_selectedTemplateIndex];
    final generated = template.generator(
      clientName: widget.lead.name,
      organization: widget.lead.organization,
      eventLocation: widget.eventLocation ?? widget.lead.locationMet,
      notes: widget.lead.notes,
    );
    _messageController.text = generated;
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendWhatsApp() async {
    final phone = widget.lead.whatsapp ?? widget.lead.phone;
    if (phone == null || phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No phone number saved. Copied pitch message to clipboard!',
          ),
          backgroundColor: Color(0xFF141719),
        ),
      );
      await Clipboard.setData(ClipboardData(text: _messageController.text));
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
          const SnackBar(content: Text('Copied pitch message to clipboard!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final templates = FreelancePitchTemplate.allTemplates;

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
                color: const Color(0xFF25D366).withValues(alpha: 0.4),
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
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: const Color(0xFF25D366)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF25D366)
                                  .withValues(alpha: 0.35),
                            ),
                          ),
                          child: const Icon(
                            Icons.send_rounded,
                            color: Color(0xFF25D366),
                            size: 17,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SMART 1-TAP PITCH',
                              style: EtoleTypography.labelCaps(
                                color: const Color(0xFF25D366),
                              ).copyWith(fontSize: 10.5, letterSpacing: 1.6),
                            ),
                            Text(
                              'Pitching ${widget.lead.name}',
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

                // Template Chips
                Text(
                  'Choose Commercial Pitch Angle:',
                  style: EtoleTypography.labelSmall.copyWith(
                    color: EtoleColors.creamMuted,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(templates.length, (i) {
                      final t = templates[i];
                      final isSelected = _selectedTemplateIndex == i;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            EtoleHaptics.selection();
                            setState(() {
                              _selectedTemplateIndex = i;
                              _updateMessage();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF25D366)
                                        .withValues(alpha: 0.18)
                                  : const Color(0xFF191D22),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF25D366)
                                    : Colors.white.withValues(alpha: 0.08),
                                width: isSelected ? 1.2 : 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  t.icon,
                                  size: 14,
                                  color: isSelected
                                      ? const Color(0xFF25D366)
                                      : EtoleColors.creamMuted,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  t.title,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : EtoleColors.creamSecondary,
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 16),

                // Editable Pitch Preview
                Text(
                  'Personalized Pitch Message',
                  style: EtoleTypography.labelSmall.copyWith(
                    color: EtoleColors.creamMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16191D),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: TextField(
                    controller: _messageController,
                    maxLines: 7,
                    style: const TextStyle(
                      color: EtoleColors.cream,
                      fontSize: 13.5,
                      height: 1.45,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        onPressed: _sendWhatsApp,
                        icon: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 18,
                        ),
                        label: const Text(
                          'Send via WhatsApp',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: EtoleColors.cream,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
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
                              content: Text('Pitch copied to clipboard!'),
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
