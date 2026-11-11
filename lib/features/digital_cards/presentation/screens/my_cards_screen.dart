import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import '../../../../core/constants/app_design_tokens.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/theme/brand_theme_provider.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../providers/cards_providers.dart';
import 'card_editor_screen.dart';
import 'card_presentation_screen.dart';
import 'card_print_screen.dart';
import 'email_signature_screen.dart';
import 'nfc_management_screen.dart';

class MyCardsScreen extends ConsumerWidget {
  const MyCardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeBrand = ref.watch(activeBrandProvider);
    final cardsAsync = ref.watch(brandCardsProvider);
    final accent = ref.watch(activeAccentColorProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${activeBrand?.name ?? "My"} Digital Cards'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_card_outlined),
            tooltip: 'Create New Card Variation',
            onPressed: () => _createNewCard(context, ref, activeBrand!),
          ),
        ],
      ),
      body: cardsAsync.when(
        data: (cards) {
          if (cards.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.badge_outlined,
              title: 'No Digital Cards Yet',
              description: 'Create tailored business cards for your different services and roles.',
              actionLabel: 'Create Business Card',
              onAction: () {
                if (activeBrand != null)
                  _createNewCard(context, ref, activeBrand);
              },
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppDesignTokens.space16),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppDesignTokens.space16),
                child: AppCard(
                  variant: AppCardVariant.surface,
                  padding: const EdgeInsets.all(AppDesignTokens.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                card.cardTitle,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (card.isDefault) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'DEFAULT',
                                    style: TextStyle(
                                      color: accent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          PopupMenuButton<String>(
                            onSelected: (val) {
                              if (val == 'default') {
                                _setDefaultCard(ref, card);
                              } else if (val == 'duplicate') {
                                _duplicateCard(ref, card);
                              } else if (val == 'delete') {
                                _deleteCard(context, ref, card);
                              }
                            },
                            itemBuilder: (ctx) => [
                              if (!card.isDefault)
                                const PopupMenuItem(
                                  value: 'default',
                                  child: Row(
                                    children: [
                                      Icon(Icons.star_outline, size: 18),
                                      SizedBox(width: 8),
                                      Text('Make Default'),
                                    ],
                                  ),
                                ),
                              const PopupMenuItem(
                                value: 'duplicate',
                                child: Row(
                                  children: [
                                    Icon(Icons.copy_outlined, size: 18),
                                    SizedBox(width: 8),
                                    Text('Duplicate Card'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Move to Trash',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${card.personName} • ${card.personRole ?? "Creative"}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (card.tagline != null && card.tagline!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          card.tagline!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      const Divider(height: 24),
                      // Action buttons bar
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      CardPresentationScreen(card: card),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.qr_code_scanner, size: 16),
                            label: const Text('Show Card'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CardEditorScreen(card: card),
                                ),
                              );
                            },
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text('Edit'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      NfcManagementScreen(card: card),
                                ),
                              );
                            },
                            icon: const Icon(Icons.nfc_rounded, size: 16),
                            label: const Text('NFC'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CardPrintScreen(card: card),
                                ),
                              );
                            },
                            icon: const Icon(Icons.print_outlined, size: 16),
                            label: const Text('Print PDF'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      EmailSignatureScreen(card: card),
                                ),
                              );
                            },
                            icon: const Icon(Icons.email_outlined, size: 16),
                            label: const Text('Signature'),
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Future<void> _createNewCard(
    BuildContext context,
    WidgetRef ref,
    Brand brand,
  ) async {
    final db = ref.read(databaseProvider);
    final id = await db
        .into(db.businessCards)
        .insert(
          BusinessCardsCompanion.insert(
            brandId: brand.id,
            cardTitle: '${brand.name} Card Variation',
            personName: brand.name,
            personRole: const drift.Value('Creative Specialist'),
            companyName: drift.Value(brand.name),
            primaryPhone: drift.Value(brand.phone),
            email: drift.Value(brand.email),
            website: drift.Value(brand.website),
            address: drift.Value(brand.address),
            designStyle: const drift.Value('minimal'),
          ),
        );

    final newCard = await (db.select(
      db.businessCards,
    )..where((t) => t.id.equals(id))).getSingle();
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CardEditorScreen(card: newCard)),
      );
    }
  }

  Future<void> _setDefaultCard(WidgetRef ref, BusinessCard card) async {
    final db = ref.read(databaseProvider);
    // 1. Unset all defaults for this brand
    await (db.update(db.businessCards)
          ..where((t) => t.brandId.equals(card.brandId)))
        .write(const BusinessCardsCompanion(isDefault: drift.Value(false)));
    // 2. Set this card as default
    await (db.update(db.businessCards)..where((t) => t.id.equals(card.id)))
        .write(const BusinessCardsCompanion(isDefault: drift.Value(true)));
  }

  Future<void> _duplicateCard(WidgetRef ref, BusinessCard card) async {
    final db = ref.read(databaseProvider);
    await db
        .into(db.businessCards)
        .insert(
          BusinessCardsCompanion.insert(
            brandId: card.brandId,
            cardTitle: '${card.cardTitle} (Copy)',
            isDefault: const drift.Value(false),
            personName: card.personName,
            personRole: drift.Value(card.personRole),
            companyName: drift.Value(card.companyName),
            tagline: drift.Value(card.tagline),
            photoPath: drift.Value(card.photoPath),
            primaryPhone: drift.Value(card.primaryPhone),
            secondaryPhone: drift.Value(card.secondaryPhone),
            whatsappNumber: drift.Value(card.whatsappNumber),
            email: drift.Value(card.email),
            website: drift.Value(card.website),
            address: drift.Value(card.address),
            showreelUrl: drift.Value(card.showreelUrl),
            portfolioUrl: drift.Value(card.portfolioUrl),
            bookingUrl: drift.Value(card.bookingUrl),
            designStyle: drift.Value(card.designStyle),
            accentColorOverride: drift.Value(card.accentColorOverride),
            defaultQrMode: drift.Value(card.defaultQrMode),
            whatsappTemplate: drift.Value(card.whatsappTemplate),
          ),
        );
  }

  Future<void> _deleteCard(
    BuildContext context,
    WidgetRef ref,
    BusinessCard card,
  ) async {
    final db = ref.read(databaseProvider);
    await (db.update(
      db.businessCards,
    )..where((t) => t.id.equals(card.id))).write(
      BusinessCardsCompanion(
        isDeleted: const drift.Value(true),
        deletedAt: drift.Value(DateTime.now()),
      ),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Card moved to Trash')));
    }
  }
}
