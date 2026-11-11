import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_design_tokens.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/theme/brand_theme_provider.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/skeleton_loader.dart';

final paymentProfilesProvider = StreamProvider<List<PaymentProfile>>((ref) {
  final db = ref.watch(databaseProvider);
  final activeBrand = ref.watch(activeBrandProvider);
  if (activeBrand == null) return Stream.value([]);
  return (db.select(db.paymentProfiles)
        ..where((tbl) => tbl.brandId.equals(activeBrand.id))
        ..orderBy([(tbl) => drift.OrderingTerm.desc(tbl.isDefault)]))
      .watch();
});

class PaymentProfilesScreen extends ConsumerWidget {
  const PaymentProfilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeBrand = ref.watch(activeBrandProvider);
    final accent = ref.watch(activeAccentColorProvider);
    final profilesAsync = ref.watch(paymentProfilesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('${activeBrand?.name ?? "Brand"} Payment Profiles'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openProfileEditor(context, ref, activeBrand?.id),
        backgroundColor: accent,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: profilesAsync.when(
        data: (profiles) {
          if (profiles.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.account_balance_rounded,
              title: 'No Payment Profiles',
              description: 'Add payment profiles for KES, USD, EUR or GBP with M-Pesa or Bank details.',
              actionLabel: 'Create KES Profile',
              onAction: () => _openProfileEditor(context, ref, activeBrand?.id),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDesignTokens.spacingM,
              vertical: AppDesignTokens.spacingM,
            ),
            itemCount: profiles.length,
            itemBuilder: (ctx, idx) {
              final item = profiles[idx];
              return Padding(
                padding: const EdgeInsets.only(
                  bottom: AppDesignTokens.spacingS,
                ),
                child: AppCard(
                  variant: AppCardVariant.surface,
                  padding: const EdgeInsets.all(AppDesignTokens.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(
                                    AppDesignTokens.radiusS,
                                  ),
                                ),
                                child: Text(
                                  item.currencyCode,
                                  style: TextStyle(
                                    color: accent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppDesignTokens.spacingM),
                              Text(
                                item.profileName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          if (item.isDefault)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'DEFAULT',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppDesignTokens.spacingM),
                      if (item.mpesaPaybillNumber != null &&
                          item.mpesaPaybillNumber!.isNotEmpty) ...[
                        Text(
                          'M-Pesa: ${item.mpesaPaybillNumber}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.darkTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      if (item.bankName != null &&
                          item.bankName!.isNotEmpty) ...[
                        Text(
                          'Bank: ${item.bankName} (${item.accountName ?? ""})',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.darkTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],
                      if (item.onlinePaymentType != null &&
                          item.onlinePaymentType!.isNotEmpty) ...[
                        Text(
                          '${item.onlinePaymentType}: ${item.onlinePaymentLinkOrEmail}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.darkTextSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppDesignTokens.spacingM),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () => _openProfileEditor(
                              context,
                              ref,
                              activeBrand?.id,
                              profile: item,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: AppColors.error,
                            ),
                            onPressed: () =>
                                _deleteProfile(context, ref, item.id),
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
        loading: () => const Padding(
          padding: EdgeInsets.all(AppDesignTokens.spacingM),
          child: SkeletonListPlaceholder(count: 3),
        ),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _openProfileEditor(
    BuildContext context,
    WidgetRef ref,
    int? brandId, {
    PaymentProfile? profile,
  }) {
    if (brandId == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDesignTokens.radiusXl),
        ),
      ),
      builder: (ctx) => _PaymentProfileForm(brandId: brandId, profile: profile),
    );
  }

  Future<void> _deleteProfile(
    BuildContext context,
    WidgetRef ref,
    int profileId,
  ) async {
    final db = ref.read(databaseProvider);
    await (db.delete(
      db.paymentProfiles,
    )..where((t) => t.id.equals(profileId))).go();
  }
}

class _PaymentProfileForm extends ConsumerStatefulWidget {
  final int brandId;
  final PaymentProfile? profile;

  const _PaymentProfileForm({required this.brandId, this.profile});

  @override
  ConsumerState<_PaymentProfileForm> createState() =>
      _PaymentProfileFormState();
}

class _PaymentProfileFormState extends ConsumerState<_PaymentProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late String _currency;
  late TextEditingController _nameController;
  late TextEditingController _mpesaPaybillController;
  late TextEditingController _mpesaTillController;
  late TextEditingController _bankNameController;
  late TextEditingController _branchController;
  late TextEditingController _accNameController;
  late TextEditingController _accNoController;
  late TextEditingController _swiftController;
  late TextEditingController _ibanController;
  late TextEditingController _onlineTypeController;
  late TextEditingController _onlineDetailController;
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _currency = p?.currencyCode ?? 'KES';
    _nameController = TextEditingController(
      text: p?.profileName ?? 'Main $_currency Payment Profile',
    );
    _mpesaPaybillController = TextEditingController(
      text: p?.mpesaPaybillNumber ?? '',
    );
    _mpesaTillController = TextEditingController(
      text: p?.mpesaTillNumber ?? '',
    );
    _bankNameController = TextEditingController(text: p?.bankName ?? '');
    _branchController = TextEditingController(text: p?.bankBranch ?? '');
    _accNameController = TextEditingController(text: p?.accountName ?? '');
    _accNoController = TextEditingController(text: p?.accountNumber ?? '');
    _swiftController = TextEditingController(text: p?.swiftBic ?? '');
    _ibanController = TextEditingController(text: p?.iban ?? '');
    _onlineTypeController = TextEditingController(
      text: p?.onlinePaymentType ?? '',
    );
    _onlineDetailController = TextEditingController(
      text: p?.onlinePaymentLinkOrEmail ?? '',
    );
    _isDefault = p?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mpesaPaybillController.dispose();
    _mpesaTillController.dispose();
    _bankNameController.dispose();
    _branchController.dispose();
    _accNameController.dispose();
    _accNoController.dispose();
    _swiftController.dispose();
    _ibanController.dispose();
    _onlineTypeController.dispose();
    _onlineDetailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom:
            MediaQuery.of(context).viewInsets.bottom + AppDesignTokens.spacingL,
        top: AppDesignTokens.spacingL,
        left: AppDesignTokens.spacingL,
        right: AppDesignTokens.spacingL,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.profile == null
                    ? 'New Payment Profile'
                    : 'Edit Payment Profile',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _currency,
                decoration: const InputDecoration(labelText: 'Currency'),
                items: ['KES', 'USD', 'EUR', 'GBP']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _currency = val;
                      _nameController.text = 'Main $_currency Payment Profile';
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Profile Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              if (_currency == 'KES') ...[
                TextFormField(
                  controller: _mpesaPaybillController,
                  decoration: const InputDecoration(
                    labelText: 'M-Pesa Paybill / Till Details',
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _bankNameController,
                decoration: const InputDecoration(labelText: 'Bank Name'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _accNameController,
                      decoration: const InputDecoration(
                        labelText: 'Account Name',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _accNoController,
                      decoration: const InputDecoration(
                        labelText: 'Account Number',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_currency != 'KES') ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _swiftController,
                        decoration: const InputDecoration(
                          labelText: 'SWIFT / BIC',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _ibanController,
                        decoration: const InputDecoration(
                          labelText: 'IBAN (Optional)',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _onlineTypeController,
                        decoration: const InputDecoration(
                          labelText: 'Online Provider (Wise/PayPal/Payoneer)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _onlineDetailController,
                        decoration: const InputDecoration(
                          labelText: 'Email / Link',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Set as Default for Currency'),
                value: _isDefault,
                onChanged: (v) => setState(() => _isDefault = v),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  child: const Text('Save Payment Profile'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final db = ref.read(databaseProvider);

    if (_isDefault) {
      // Clear existing default for currency
      await (db.update(db.paymentProfiles)..where(
            (t) =>
                t.brandId.equals(widget.brandId) &
                t.currencyCode.equals(_currency),
          ))
          .write(const PaymentProfilesCompanion(isDefault: drift.Value(false)));
    }

    if (widget.profile == null) {
      await db
          .into(db.paymentProfiles)
          .insert(
            PaymentProfilesCompanion.insert(
              brandId: widget.brandId,
              currencyCode: _currency,
              profileName: _nameController.text.trim(),
              mpesaPaybillNumber: drift.Value(
                _mpesaPaybillController.text.trim(),
              ),
              mpesaTillNumber: drift.Value(_mpesaTillController.text.trim()),
              bankName: drift.Value(_bankNameController.text.trim()),
              bankBranch: drift.Value(_branchController.text.trim()),
              accountName: drift.Value(_accNameController.text.trim()),
              accountNumber: drift.Value(_accNoController.text.trim()),
              swiftBic: drift.Value(_swiftController.text.trim()),
              iban: drift.Value(_ibanController.text.trim()),
              onlinePaymentType: drift.Value(_onlineTypeController.text.trim()),
              onlinePaymentLinkOrEmail: drift.Value(
                _onlineDetailController.text.trim(),
              ),
              isDefault: drift.Value(_isDefault),
            ),
          );
    } else {
      await (db.update(
        db.paymentProfiles,
      )..where((t) => t.id.equals(widget.profile!.id))).write(
        PaymentProfilesCompanion(
          currencyCode: drift.Value(_currency),
          profileName: drift.Value(_nameController.text.trim()),
          mpesaPaybillNumber: drift.Value(_mpesaPaybillController.text.trim()),
          mpesaTillNumber: drift.Value(_mpesaTillController.text.trim()),
          bankName: drift.Value(_bankNameController.text.trim()),
          bankBranch: drift.Value(_branchController.text.trim()),
          accountName: drift.Value(_accNameController.text.trim()),
          accountNumber: drift.Value(_accNoController.text.trim()),
          swiftBic: drift.Value(_swiftController.text.trim()),
          iban: drift.Value(_ibanController.text.trim()),
          onlinePaymentType: drift.Value(_onlineTypeController.text.trim()),
          onlinePaymentLinkOrEmail: drift.Value(
            _onlineDetailController.text.trim(),
          ),
          isDefault: drift.Value(_isDefault),
        ),
      );
    }

    if (mounted) Navigator.pop(context);
  }
}
