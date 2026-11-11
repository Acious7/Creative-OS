import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/automation/automation_recipe_engine.dart';
import '../../../../core/automation/models/automation_recipe.dart';
import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_typography.dart';

class CreateRecipeSheet extends StatefulWidget {
  final AutomationRecipe? recipeToEdit;
  final VoidCallback onSaved;

  const CreateRecipeSheet({
    super.key,
    this.recipeToEdit,
    required this.onSaved,
  });

  @override
  State<CreateRecipeSheet> createState() => _CreateRecipeSheetState();
}

class _CreateRecipeSheetState extends State<CreateRecipeSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _condValController;

  late AutomationTrigger _trigger;
  late String _conditionType;
  late AutomationAction _action;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.recipeToEdit;
    _titleController = TextEditingController(text: r?.title ?? '');
    _descController = TextEditingController(text: r?.description ?? '');
    _condValController = TextEditingController(text: r?.conditionValue ?? '');
    _trigger = r?.trigger ?? AutomationTrigger.quoteAccepted;
    _conditionType = r?.conditionType ?? 'always';
    _action = r?.action ?? AutomationAction.createDepositInvoice;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _condValController.dispose();
    super.dispose();
  }

  IconData _getTriggerIcon(AutomationTrigger t) {
    switch (t) {
      case AutomationTrigger.quoteAccepted:
        return Icons.verified_rounded;
      case AutomationTrigger.invoicePaid:
        return Icons.payments_rounded;
      case AutomationTrigger.dealStageChanged:
        return Icons.auto_graph_rounded;
      case AutomationTrigger.meetingConcluded:
        return Icons.groups_rounded;
      case AutomationTrigger.shootWrapped:
        return Icons.movie_filter_rounded;
      case AutomationTrigger.invoiceOverdue:
        return Icons.warning_amber_rounded;
      case AutomationTrigger.vipInactive:
        return Icons.star_border_purple500_rounded;
    }
  }

  IconData _getActionIcon(AutomationAction a) {
    switch (a) {
      case AutomationAction.createDepositInvoice:
        return Icons.receipt_long_rounded;
      case AutomationAction.advanceProjectStage:
        return Icons.skip_next_rounded;
      case AutomationAction.prefillCrewPayouts:
        return Icons.account_balance_wallet_rounded;
      case AutomationAction.draftContract:
        return Icons.description_rounded;
      case AutomationAction.sendWhatsAppChaser:
        return Icons.chat_bubble_outline_rounded;
      case AutomationAction.postNotificationAlert:
        return Icons.notifications_active_rounded;
      case AutomationAction.tagAsVip:
        return Icons.workspace_premium_rounded;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    EtoleHaptics.medium();

    final r = AutomationRecipe(
      id: widget.recipeToEdit?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      description: _descController.text.trim().isNotEmpty
          ? _descController.text.trim()
          : 'Custom autonomous recipe created by executive.',
      isEnabled: widget.recipeToEdit?.isEnabled ?? true,
      trigger: _trigger,
      conditionType: _conditionType,
      conditionValue: _condValController.text.trim(),
      action: _action,
      triggerCount: widget.recipeToEdit?.triggerCount ?? 0,
      lastTriggeredAt: widget.recipeToEdit?.lastTriggeredAt,
      isBuiltIn: widget.recipeToEdit?.isBuiltIn ?? false,
    );

    await AutomationRecipeEngine.saveRecipe(r);

    if (mounted) {
      EtoleHaptics.success();
      widget.onSaved();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Color(0xFF0D0F14),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.recipeToEdit == null
                          ? 'NEW AUTOMATION PIPELINE'
                          : 'EDIT AUTOMATION PIPELINE',
                      style: EtoleTypography.h2.copyWith(
                        color: Colors.white,
                        fontSize: 16,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Trigger ➔ Condition Filter ➔ Automated Action',
                      style: TextStyle(
                        color: Color(0xFF00E5FF),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 24),

          // Body Form
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                children: [
                  // STEP 1: TRIGGER
                  _buildSectionHeader(
                    step: '1',
                    title: 'WHEN THIS EVENT OCCURS (TRIGGER)',
                    color: const Color(0xFF00E5FF),
                  ),
                  const SizedBox(height: 10),
                  ...AutomationTrigger.values.map((t) {
                    final isSelected = _trigger == t;
                    return InkWell(
                      onTap: () {
                        setState(() => _trigger = t);
                        EtoleHaptics.selection();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF00E5FF).withValues(alpha: 0.12)
                              : const Color(0xFF14171B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF00E5FF)
                                : Colors.white12,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getTriggerIcon(t),
                              color: isSelected
                                  ? const Color(0xFF00E5FF)
                                  : Colors.white70,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                t.displayName,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFFCBD5E1),
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF00E5FF),
                                size: 18,
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),

                  // STEP 2: CONDITION FILTER
                  _buildSectionHeader(
                    step: '2',
                    title: 'AND ONLY IF (CONDITION FILTER)',
                    color: const Color(0xFFF5A623),
                  ),
                  const SizedBox(height: 10),
                  _buildConditionChoice(
                    type: 'always',
                    title: 'Always Execute',
                    subtitle: 'Fire immediately whenever the trigger is fired.',
                    icon: Icons.all_inclusive_rounded,
                  ),
                  _buildConditionChoice(
                    type: 'min_amount',
                    title: 'Document Amount Exceeds Threshold',
                    subtitle:
                        'Only trigger for deals or invoices above KES value.',
                    icon: Icons.attach_money_rounded,
                  ),
                  if (_conditionType == 'min_amount')
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 12,
                        right: 12,
                        bottom: 12,
                      ),
                      child: TextFormField(
                        controller: _condValController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Minimum Value in KES',
                          labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                          hintText: 'e.g. 150000',
                          hintStyle: const TextStyle(color: Colors.white30),
                          prefixText: 'KES ',
                          prefixStyle: const TextStyle(
                            color: Color(0xFF00E5FF),
                            fontWeight: FontWeight.bold,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF14171B),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xFFF5A623),
                            ),
                          ),
                        ),
                      ),
                    ),
                  _buildConditionChoice(
                    type: 'stage_equals',
                    title: 'Status or Stage Equals',
                    subtitle: 'Only trigger if stage contains keyword (e.g. won, hot, priority).',
                    icon: Icons.filter_alt_rounded,
                  ),
                  if (_conditionType == 'stage_equals')
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 12,
                        right: 12,
                        bottom: 12,
                      ),
                      child: TextFormField(
                        controller: _condValController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Stage Keyword',
                          labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                          hintText: 'e.g. won or retainer',
                          hintStyle: const TextStyle(color: Colors.white30),
                          filled: true,
                          fillColor: const Color(0xFF14171B),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xFFF5A623),
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // STEP 3: ACTION
                  _buildSectionHeader(
                    step: '3',
                    title: 'THEN PERFORM AUTOMATION (ACTION)',
                    color: const Color(0xFF007A3D),
                  ),
                  const SizedBox(height: 10),
                  ...AutomationAction.values.map((a) {
                    final isSelected = _action == a;
                    return InkWell(
                      onTap: () {
                        setState(() => _action = a);
                        EtoleHaptics.selection();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF007A3D).withValues(alpha: 0.18)
                              : const Color(0xFF14171B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF00E5FF)
                                : Colors.white12,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getActionIcon(a),
                              color: isSelected
                                  ? const Color(0xFF00E5FF)
                                  : Colors.white70,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                a.displayName,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFFCBD5E1),
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF00E5FF),
                                size: 18,
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),

                  // STEP 4: DETAILS
                  _buildSectionHeader(
                    step: '4',
                    title: 'NAME YOUR PIPELINE',
                    color: const Color(0xFF4A90E2),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _titleController,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please enter a title'
                        : null,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Pipeline Title',
                      labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      hintText: 'e.g. VIP Auto-Chaser on Overdue',
                      hintStyle: const TextStyle(color: Colors.white30),
                      filled: true,
                      fillColor: const Color(0xFF14171B),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descController,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Brief Description / Notes',
                      labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      hintText:
                          'e.g. Auto-dispatches WhatsApp payment follow-up',
                      hintStyle: const TextStyle(color: Colors.white30),
                      filled: true,
                      fillColor: const Color(0xFF14171B),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Bottom Bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: const BoxDecoration(
              color: Color(0xFF14171B),
              border: Border(top: BorderSide(color: Colors.white12)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF080B0F),
                        ),
                      )
                    : const Icon(Icons.bolt_rounded, color: Color(0xFF080B0F)),
                label: Text(
                  widget.recipeToEdit == null
                      ? 'DEPLOY RECIPE PIPELINE'
                      : 'SAVE PIPELINE CHANGES',
                  style: const TextStyle(
                    color: Color(0xFF080B0F),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String step,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.2),
          ),
          child: Text(
            step,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
            fontSize: 11.5,
          ),
        ),
      ],
    );
  }

  Widget _buildConditionChoice({
    required String type,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _conditionType == type;
    return InkWell(
      onTap: () {
        setState(() => _conditionType = type);
        EtoleHaptics.selection();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFF5A623).withValues(alpha: 0.12)
              : const Color(0xFF14171B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFF5A623) : Colors.white12,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFF5A623) : Colors.white70,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFFCBD5E1),
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : Colors.white38,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFFF5A623),
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}
