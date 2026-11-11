import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/constants/app_design_tokens.dart';
import '../../../../core/theme/brand_theme_provider.dart';
import '../../../../core/widgets/app_card.dart';

class DigitalCardScreen extends ConsumerWidget {
  const DigitalCardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeBrand = ref.watch(activeBrandProvider);
    final accent = ref.watch(activeAccentColorProvider);
    final theme = Theme.of(context);

    final brandName = activeBrand?.name ?? 'Brian Etole';
    final email = activeBrand?.email ?? 'hello@brianetole.com';
    final phone = activeBrand?.phone ?? '+254 718 013 579';
    final website = activeBrand?.website ?? 'brianetole.com';
    final address = activeBrand?.address ?? 'Nairobi, Kenya';

    final vCardData =
        '''BEGIN:VCARD
VERSION:3.0
N:${brandName.split(' ').last};${brandName.split(' ').first};;;
FN:$brandName
ORG:$brandName
TITLE:Creative Film & Photography Studio
TEL;TYPE=CELL:$phone
EMAIL:$email
URL:$website
ADR:;;$address;;;;
END:VCARD''';

    return Scaffold(
      appBar: AppBar(title: Text('$brandName Business Card')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDesignTokens.spacingL),
          child: Column(
            children: [
              AppCard(
                variant: AppCardVariant.surface,
                padding: const EdgeInsets.all(AppDesignTokens.spacingL),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          brandName.isNotEmpty
                              ? brandName.substring(0, 1).toUpperCase()
                              : 'B',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDesignTokens.spacingM),
                    Text(
                      brandName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Film Production & Creative Consulting',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDesignTokens.spacingL),
                    Container(
                      padding: const EdgeInsets.all(AppDesignTokens.spacingM),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          AppDesignTokens.radiusL,
                        ),
                      ),
                      child: QrImageView(
                        data: vCardData,
                        version: QrVersions.auto,
                        size: 190.0,
                      ),
                    ),
                    const SizedBox(height: AppDesignTokens.spacingM),
                    Text(
                      'Scan with phone camera to save contact details',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                    const Divider(height: 32),
                    _buildInfoRow(context, Icons.phone_outlined, phone),
                    const SizedBox(height: AppDesignTokens.spacingS),
                    _buildInfoRow(context, Icons.email_outlined, email),
                    const SizedBox(height: AppDesignTokens.spacingS),
                    _buildInfoRow(context, Icons.language_rounded, website),
                  ],
                ),
              ),
              const SizedBox(height: AppDesignTokens.spacingL),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        final tempDir = await getTemporaryDirectory();
                        final vcfFile = File(
                          '${tempDir.path}/${brandName.replaceAll(' ', '_')}.vcf',
                        );
                        await vcfFile.writeAsString(vCardData);
                        await Share.shareXFiles([
                          XFile(vcfFile.path),
                        ], text: 'Contact Card for $brandName');
                      },
                      icon: const Icon(Icons.contact_phone_outlined),
                      label: const Text('Share .vcf Card'),
                    ),
                  ),
                  const SizedBox(width: AppDesignTokens.spacingM),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Share.share(
                          'Contact details for $brandName:\nPhone: $phone\nEmail: $email\nWebsite: $website',
                        );
                      },
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('Share Info'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: AppDesignTokens.spacingM),
        Text(
          text,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
