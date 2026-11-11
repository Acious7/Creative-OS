import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../../domain/freelance_crm_models.dart';

class EditDealSheet extends ConsumerStatefulWidget {
  final NetworkingLead lead;
  final VoidCallback? onSaved;

  const EditDealSheet({super.key, required this.lead, this.onSaved});

  static Future<void> show(
    BuildContext context, {
    required NetworkingLead lead,
    VoidCallback? onSaved,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditDealSheet(lead: lead, onSaved: onSaved),
    );
  }

  @override
  ConsumerState<EditDealSheet> createState() => _EditDealSheetState();
}

class _EditDealSheetState extends ConsumerState<EditDealSheet> {
  late TextEditingController _titleController;
  late TextEditingController _valueController;
  late DealStage _stage;
  late String _serviceCategory;
  late bool _isVip;
  final List<String> _tags = [];
  final TextEditingController _tagInputController = TextEditingController();

  static const List<String> _categories = [
    'Directing & Film',
    'Commercial Cinematography',
    'Post & Color Grading',
    'Creative Direction',
    'Documentary Production',
    'Still Photography',
  ];

  @override
  void initState() {
    super.initState();
    final deal = FreelanceDealInfo.fromLead(widget.lead);
    _titleController = TextEditingController(text: deal.dealTitle ?? '');
    _valueController = TextEditingController(
      text: deal.dealValue > 0 ? deal.dealValue.toInt().toString() : '',
    );
    _stage = deal.stage;
    _serviceCategory = deal.serviceCategory;
    _isVip = deal.isVip;
    _tags.addAll(deal.tags);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _valueController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    EtoleHaptics.selection();
    final db = ref.read(databaseProvider);
    final val =
        double.tryParse(
          _valueController.text.replaceAll(RegExp(r'[^\d.]'), ''),
        ) ??
        0.0;

    final updatedDeal = FreelanceDealInfo(
      dealTitle: _titleController.text.trim().isNotEmpty
          ? _titleController.text.trim()
          : null,
      dealValue: val,
      serviceCategory: _serviceCategory,
      isVip: _isVip,
      stage: _stage,
      tags: _tags,
    );

    await (db.update(
      db.networkingLeads,
    )..where((t) => t.id.equals(widget.lead.id))).write(
      NetworkingLeadsCompanion(
        status: drift.Value(_stage.name),
        interestTagsJson: drift.Value(updatedDeal.toJsonString()),
        updatedAt: drift.Value(DateTime.now()),
      ),
    );

    widget.onSaved?.call();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
                color: EtoleColors.cyan.withValues(alpha: 0.35),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'COMMERCIAL DEAL / PITCH',
                          style: EtoleTypography.labelCaps(
                            color: EtoleColors.cyan,
                          ).copyWith(fontSize: 11, letterSpacing: 1.6),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.lead.name,
                          style: EtoleTypography.h2.copyWith(
                            color: EtoleColors.cream,
                            fontSize: 18,
                          ),
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
                const SizedBox(height: 18),

                // Deal Stage Selector
                Text(
                  'Pipeline Stage',
                  style: EtoleTypography.labelSmall.copyWith(
                    color: EtoleColors.creamMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: DealStage.values.map((s) {
                    final isSelected = _stage == s;
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        EtoleHaptics.selection();
                        setState(() => _stage = s);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? s.color.withValues(alpha: 0.22)
                              : const Color(0xFF1B1F24),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? s.color
                                : Colors.white.withValues(alpha: 0.08),
                            width: isSelected ? 1.4 : 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              s.icon,
                              size: 14,
                              color: isSelected
                                  ? s.color
                                  : EtoleColors.creamMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              s.label,
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
                    );
                  }).toList(),
                ),

                const SizedBox(height: 18),

                // Deal Title / Campaign Name
                Text(
                  'Campaign / Project Title',
                  style: EtoleTypography.labelSmall.copyWith(
                    color: EtoleColors.creamMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1E22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: TextField(
                    controller: _titleController,
                    style: const TextStyle(
                      color: EtoleColors.cream,
                      fontSize: 14,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'e.g. Safaricom 4K Commercial Shoot',
                      hintStyle: TextStyle(
                        color: EtoleColors.creamMuted,
                        fontSize: 13,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Estimated Budget Value (KES)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Estimated Deal Value (KES)',
                      style: EtoleTypography.labelSmall.copyWith(
                        color: EtoleColors.creamMuted,
                      ),
                    ),
                    Text(
                      'In Kenya Shillings',
                      style: EtoleTypography.labelSmall.copyWith(
                        color: const Color(0xFFF59E0B),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1E22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                    ),
                  ),
                  child: TextField(
                    controller: _valueController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      color: Color(0xFFFBBF24),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      prefixText: 'KES  ',
                      prefixStyle: TextStyle(
                        color: Color(0xFFF59E0B),
                        fontWeight: FontWeight.bold,
                      ),
                      hintText: '0',
                      hintStyle: TextStyle(
                        color: EtoleColors.creamMuted,
                        fontSize: 15,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Value Quick Presets
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [75000, 150000, 300000, 600000, 1200000].map((
                      preset,
                    ) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            EtoleHaptics.light();
                            setState(
                              () => _valueController.text = preset.toString(),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF181C20),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Text(
                              'KES ${(preset / 1000).toInt()}k',
                              style: const TextStyle(
                                color: EtoleColors.creamMuted,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 18),

                // Service Category
                Text(
                  'Service Offering',
                  style: EtoleTypography.labelSmall.copyWith(
                    color: EtoleColors.creamMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1E22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _categories.contains(_serviceCategory)
                          ? _serviceCategory
                          : _categories.first,
                      dropdownColor: const Color(0xFF1A1E22),
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: EtoleColors.cyan,
                      ),
                      isExpanded: true,
                      style: const TextStyle(
                        color: EtoleColors.cream,
                        fontSize: 13,
                      ),
                      onChanged: (val) {
                        if (val != null) setState(() => _serviceCategory = val);
                      },
                      items: _categories
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // VIP & Priority Switch
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _isVip
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
                        : const Color(0xFF1A1E22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isVip
                          ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isVip
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: _isVip
                                ? const Color(0xFFF59E0B)
                                : EtoleColors.creamMuted,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mark as VIP / Priority Client',
                                style: EtoleTypography.bodyMedium.copyWith(
                                  color: EtoleColors.cream,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                'Prioritized on your Radar and Studio Overview',
                                style: EtoleTypography.labelSmall.copyWith(
                                  color: EtoleColors.creamMuted,
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Switch(
                        value: _isVip,
                        activeColor: const Color(0xFFF59E0B),
                        onChanged: (val) {
                          EtoleHaptics.selection();
                          setState(() => _isVip = val);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Save Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EtoleColors.cyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _save,
                  child: const Text(
                    'Save Commercial Deal',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
