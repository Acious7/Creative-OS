import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nfc_manager/nfc_manager.dart';

import '../../../../core/constants/app_design_tokens.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/brand_theme_provider.dart';
import '../../domain/vcard_builder.dart';

class NfcManagementScreen extends ConsumerStatefulWidget {
  final BusinessCard card;

  const NfcManagementScreen({super.key, required this.card});

  @override
  ConsumerState<NfcManagementScreen> createState() =>
      _NfcManagementScreenState();
}

class _NfcManagementScreenState extends ConsumerState<NfcManagementScreen> {
  bool _isNfcAvailable = false;
  bool _isChecking = true;
  bool _isWriting = false;
  bool _lockTag = false;
  String _recordType = 'vcard'; // 'vcard' or 'url'

  @override
  void initState() {
    super.initState();
    _checkNfcAvailability();
  }

  Future<void> _checkNfcAvailability() async {
    final available = await NfcManager.instance.isAvailable();
    if (mounted) {
      setState(() {
        _isNfcAvailable = available;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = ref.watch(activeAccentColorProvider);

    final vCardRes = VCardBuilder.buildVCard(widget.card, compactForNfc: true);
    final urlStr =
        widget.card.showreelUrl ??
        widget.card.website ??
        'https://brianetole.com';
    final payloadSize = _recordType == 'vcard'
        ? vCardRes.byteSize
        : urlStr.length + 10;

    return Scaffold(
      appBar: AppBar(title: const Text('NFC Card & Tag Manager')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppDesignTokens.space16),
          children: [
            // NFC Availability Status Banner
            if (_isChecking)
              const LinearProgressIndicator()
            else if (!_isNfcAvailable)
              Container(
                padding: const EdgeInsets.all(AppDesignTokens.space16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
                  border: Border.all(color: Colors.amber.shade700),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.amber.shade900,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NFC Not Enabled or Supported',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Please turn on NFC in phone settings to write or read physical cards.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Write Card to Tag Config Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDesignTokens.radiusLg),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppDesignTokens.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.nfc_rounded, color: accent),
                        const SizedBox(width: 8),
                        Text(
                          'Write "${widget.card.cardTitle}" to Tag',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Payload Selector
                    Text(
                      'Select Record Type to Encode:',
                      style: theme.textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'vcard',
                          label: Text('Full Contact (vCard)'),
                          icon: Icon(Icons.contact_phone_outlined),
                        ),
                        ButtonSegment(
                          value: 'url',
                          label: Text('Direct Web / Showreel'),
                          icon: Icon(Icons.link_rounded),
                        ),
                      ],
                      selected: {_recordType},
                      onSelectionChanged: (val) {
                        setState(() => _recordType = val.first);
                      },
                    ),

                    const SizedBox(height: 16),

                    // Payload summary details
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withAlpha(128),
                        borderRadius: BorderRadius.circular(
                          AppDesignTokens.radiusMd,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _recordType == 'vcard'
                                    ? 'Target: Contact Card (vCard 3.0)'
                                    : 'Target: URL Redirect',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                '$payloadSize Bytes',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: payloadSize > 137
                                      ? Colors.orange.shade800
                                      : Colors.green.shade800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _recordType == 'vcard'
                                ? 'Compact contact data optimized for NTAG213 (144B) / NTAG215 (504B).'
                                : 'Opens: $urlStr',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Lock Tag Option
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Make Tag Read-Only (Permanent Lock)',
                        style: TextStyle(fontSize: 14),
                      ),
                      subtitle: const Text(
                        'Warning: Once locked, the NFC tag cannot be overwritten or reused.',
                        style: TextStyle(fontSize: 12),
                      ),
                      value: _lockTag,
                      activeColor: Colors.red,
                      onChanged: (val) =>
                          setState(() => _lockTag = val ?? false),
                    ),

                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: (_isNfcAvailable && !_isWriting)
                            ? _startNfcWrite
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _lockTag
                              ? Colors.red.shade700
                              : accent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppDesignTokens.radiusMd,
                            ),
                          ),
                        ),
                        icon: _isWriting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.nfc_rounded,
                                color: Colors.white,
                              ),
                        label: Text(
                          _isWriting
                              ? 'Hold phone near NFC tag...'
                              : 'Write to NFC Tag',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Tag Compatibility Guide
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: const Padding(
                padding: EdgeInsets.all(AppDesignTokens.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Supported NFC Tags & Cards',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• NTAG213 (144 bytes): Best for URL redirect or compact vCard.\n'
                      '• NTAG215 (504 bytes): Recommended for complete vCard.\n'
                      '• NTAG216 (888 bytes): High capacity for all details.\n'
                      'Works with smart metal cards, wooden NFC cards, stickers, and key fobs.',
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startNfcWrite() {
    setState(() => _isWriting = true);

    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        try {
          final ndef = Ndef.from(tag);
          if (ndef == null || !ndef.isWritable) {
            _stopNfcSession(error: 'Tag is not NDEF writable or locked.');
            return;
          }

          final String payload;
          if (_recordType == 'vcard') {
            payload = VCardBuilder.buildVCard(
              widget.card,
              compactForNfc: true,
            ).vCardString;
          } else {
            payload =
                widget.card.showreelUrl ??
                widget.card.website ??
                'https://brianetole.com';
          }

          final record = _recordType == 'vcard'
              ? NdefRecord.createMime(
                  'text/vcard',
                  Uint8List.fromList(Uri.encodeComponent(payload).codeUnits),
                )
              : NdefRecord.createUri(Uri.parse(payload));

          final message = NdefMessage([record]);
          await ndef.write(message);

          if (_lockTag && ndef.isWritable) {
            await ndef.writeLock();
          }

          _stopNfcSession(success: 'Successfully written to NFC tag!');
        } catch (e) {
          _stopNfcSession(error: 'Failed to write tag: $e');
        }
      },
    );
  }

  void _stopNfcSession({String? success, String? error}) {
    NfcManager.instance.stopSession();
    if (mounted) {
      setState(() => _isWriting = false);
      if (success != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(success), backgroundColor: Colors.green),
        );
      } else if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    }
  }
}
