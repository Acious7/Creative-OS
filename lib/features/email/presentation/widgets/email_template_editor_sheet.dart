import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../../domain/email_template.dart';

class EmailTemplateEditorSheet extends StatefulWidget {
  final EmailTemplate template;
  final ValueChanged<EmailTemplate> onSaved;

  const EmailTemplateEditorSheet({
    super.key,
    required this.template,
    required this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    required EmailTemplate template,
    required ValueChanged<EmailTemplate> onSaved,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          EmailTemplateEditorSheet(template: template, onSaved: onSaved),
    );
  }

  @override
  State<EmailTemplateEditorSheet> createState() =>
      _EmailTemplateEditorSheetState();
}

class _EmailTemplateEditorSheetState extends State<EmailTemplateEditorSheet> {
  late final TextEditingController _subjectController;
  late final TextEditingController _bodyController;
  final FocusNode _bodyFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController(text: widget.template.subject);
    _bodyController = TextEditingController(text: widget.template.body);
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    _bodyFocusNode.dispose();
    super.dispose();
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

  void _resetToDefault() {
    final defaultTpl = EmailTemplate.defaults[widget.template.type]!;
    setState(() {
      _subjectController.text = defaultTpl.subject;
      _bodyController.text = defaultTpl.body;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Reset to default template')));
  }

  void _save() async {
    final updated = widget.template.copyWith(
      subject: _subjectController.text.trim(),
      body: _bodyController.text.trim(),
    );
    await EmailTemplateRepository.saveTemplate(updated);
    widget.onSaved(updated);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.template.label} template updated'),
          backgroundColor: const Color(0xFF1B5E20),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);

    return Container(
      height: mediaQuery.size.height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14181B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: isDark ? const Color(0xFF2C3238) : const Color(0xFFE5E0D5),
        ),
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

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EDIT TEMPLATE',
                        style: EtoleTypography.labelCaps(
                          color: EtoleColors.cyan,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.template.label,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                          color: isDark
                              ? const Color(0xFFF1EDE4)
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _resetToDefault,
                  child: const Text(
                    'Reset',
                    style: TextStyle(color: Color(0xFFB0A99F)),
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: EtoleColors.cyan,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _save,
                  child: const Text('Save'),
                ),
              ],
            ),
          ),

          const EtoleHairline(),

          // Scrollable Editor Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SUBJECT LINE',
                    style: EtoleTypography.labelCaps(
                      color: isDark ? const Color(0xFFB0A99F) : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _subjectController,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFF1EDE4) : Colors.black87,
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
                        borderSide: BorderSide(
                          color: isDark
                              ? const Color(0xFF2C3238)
                              : const Color(0xFFE2DDD2),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: isDark
                              ? const Color(0xFF2C3238)
                              : const Color(0xFFE2DDD2),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: EtoleColors.cyan),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Placeholder chips
                  Text(
                    'TAP TO INSERT PLACEHOLDER',
                    style: EtoleTypography.labelCaps(
                      color: isDark ? const Color(0xFFB0A99F) : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: EmailTemplate.availablePlaceholders.map((ph) {
                      return ActionChip(
                        label: Text(
                          ph,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: EtoleColors.cyan,
                          ),
                        ),
                        backgroundColor: isDark
                            ? const Color(0xFF1B2024)
                            : const Color(0xFFF0EBE1),
                        side: BorderSide(
                          color: isDark
                              ? const Color(0xFF2C3238)
                              : const Color(0xFFDDD7CB),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 0,
                        ),
                        onPressed: () => _insertPlaceholder(ph),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'MESSAGE BODY',
                    style: EtoleTypography.labelCaps(
                      color: isDark ? const Color(0xFFB0A99F) : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bodyController,
                    focusNode: _bodyFocusNode,
                    maxLines: 12,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: isDark ? const Color(0xFFF1EDE4) : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF0F1214)
                          : const Color(0xFFF7F5EE),
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: isDark
                              ? const Color(0xFF2C3238)
                              : const Color(0xFFE2DDD2),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: isDark
                              ? const Color(0xFF2C3238)
                              : const Color(0xFFE2DDD2),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: EtoleColors.cyan),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Note: Your professional header, document summary card, sign-off ("Brian Etole · Hybrid Filmmaker · Photographer"), and brianetole.com footer are automatically rendered around this message.',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: isDark ? const Color(0xFF9E9E9E) : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
