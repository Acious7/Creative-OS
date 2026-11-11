import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import '../../../../core/constants/app_design_tokens.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/theme/brand_theme_provider.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/email_signature_builder.dart';

class EmailSignatureScreen extends ConsumerStatefulWidget {
  final BusinessCard card;

  const EmailSignatureScreen({super.key, required this.card});

  @override
  ConsumerState<EmailSignatureScreen> createState() =>
      _EmailSignatureScreenState();
}

class _EmailSignatureScreenState extends ConsumerState<EmailSignatureScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _hostedLogoController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _hostedLogoController = TextEditingController(
      text: widget.card.hostedLogoUrl ?? '',
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _hostedLogoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeBrand = ref.watch(activeBrandProvider);
    final accent = ref.watch(activeAccentColorProvider);
    final theme = Theme.of(context);

    final sigResult = EmailSignatureBuilder.buildSignature(
      card: widget.card,
      brand: activeBrand!,
      customHostedLogoUrl: _hostedLogoController.text.trim(),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Signature Generator'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Rich HTML Signature'),
            Tab(text: 'Plain Text Signature'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Hosted Logo Image Notice
            Padding(
              padding: const EdgeInsets.all(AppDesignTokens.space12),
              child: AppCard(
                variant: AppCardVariant.surface,
                padding: const EdgeInsets.all(AppDesignTokens.space12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.image_search_rounded,
                          color: accent,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Hosted Logo Image URL (For Gmail/Outlook)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _hostedLogoController,
                      onChanged: (val) async {
                        setState(() {});
                        final db = ref.read(databaseProvider);
                        await (db.update(
                          db.businessCards,
                        )..where((t) => t.id.equals(widget.card.id))).write(
                          BusinessCardsCompanion(
                            hostedLogoUrl: drift.Value(val.trim()),
                          ),
                        );
                      },
                      decoration: const InputDecoration(
                        hintText: 'https://brianetole.com/assets/logo.png',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sigResult.hasHostedLogo
                          ? '✅ Logo image will load online in Gmail & Outlook.'
                          : '⚠️ No hosted logo URL. Signature will display clean colored text block.',
                      style: TextStyle(
                        fontSize: 11,
                        color: sigResult.hasHostedLogo
                            ? Colors.green.shade800
                            : Colors.amber.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tab View Preview & Code Output
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: HTML Preview & Raw Code
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDesignTokens.space12,
                    ),
                    child: ListView(
                      children: [
                        const Text(
                          'SIGNATURE PREVIEW:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.card.personName,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${widget.card.personRole ?? "Creative Professional"} • ${widget.card.companyName ?? activeBrand.name}',
                                style: TextStyle(
                                  color: accent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              if (widget.card.tagline != null)
                                Text(
                                  widget.card.tagline!,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                    fontSize: 11,
                                  ),
                                ),
                              const Divider(height: 16),
                              Text(
                                'Phone: ${widget.card.primaryPhone ?? ""}',
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'Email: ${widget.card.email ?? ""}',
                                style: TextStyle(color: accent, fontSize: 12),
                              ),
                              Text(
                                'Web: ${widget.card.website ?? ""}',
                                style: TextStyle(
                                  color: accent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'HTML CODE (COPY FOR GMAIL / OUTLOOK):',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SelectableText(
                            sigResult.htmlSignature,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tab 2: Plain Text Code
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDesignTokens.space12,
                    ),
                    child: ListView(
                      children: [
                        const Text(
                          'PLAIN TEXT SIGNATURE:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SelectableText(
                            sigResult.plainTextSignature,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Copy Action Button
            Padding(
              padding: const EdgeInsets.all(AppDesignTokens.space16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final isHtml = _tabController.index == 0;
                    Clipboard.setData(
                      ClipboardData(
                        text: isHtml
                            ? sigResult.htmlSignature
                            : sigResult.plainTextSignature,
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isHtml
                              ? 'HTML Signature copied for Gmail / Outlook!'
                              : 'Plain text signature copied!',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDesignTokens.radiusMd,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.copy_rounded, color: Colors.white),
                  label: const Text(
                    'Copy Signature to Clipboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
