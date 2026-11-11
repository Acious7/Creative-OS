import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_design_tokens.dart';
import '../../digital_cards/domain/business_card_ocr_service.dart';
import '../domain/smart_capture_service.dart';

class SmartCaptureSheet extends StatefulWidget {
  final Function(ParsedBusinessCard card) onContactParsed;

  const SmartCaptureSheet({super.key, required this.onContactParsed});

  @override
  State<SmartCaptureSheet> createState() => _SmartCaptureSheetState();
}

class _SmartCaptureSheetState extends State<SmartCaptureSheet> {
  final TextEditingController _textController = TextEditingController();
  bool _isScanning = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _scanWithCamera() async {
    setState(() => _isScanning = true);
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );
      if (image != null) {
        final parsed = await BusinessCardOcrService.scanAndParseCard(
          image.path,
        );
        if (mounted) {
          setState(() {
            _textController.text = parsed.rawText.isNotEmpty
                ? parsed.rawText
                : '${parsed.name}\n${parsed.title}\n${parsed.organization}\n${parsed.phone}\n${parsed.email}';
          });
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  void _parseText() {
    final raw = _textController.text.trim();
    if (raw.isEmpty) return;

    final card = SmartCaptureService.parseBusinessCard(raw);
    widget.onContactParsed(card);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppDesignTokens.space16,
        right: AppDesignTokens.space16,
        top: AppDesignTokens.space16,
        bottom:
            MediaQuery.of(context).viewInsets.bottom + AppDesignTokens.space16,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF14171B),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDesignTokens.radiusXl),
        ),
        border: Border(top: BorderSide(color: Color(0xFF00E5FF), width: 1.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.document_scanner_rounded,
                    color: Color(0xFF00E5FF),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Smart Business Card OCR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Scan physical business card with camera or paste text to extract contact & CRM details.',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          ),
          const SizedBox(height: 12),

          // Scan with Camera Button
          OutlinedButton.icon(
            onPressed: _isScanning ? null : _scanWithCamera,
            icon: _isScanning
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF00E5FF),
                    ),
                  )
                : const Icon(
                    Icons.camera_alt_rounded,
                    color: Color(0xFF00E5FF),
                  ),
            label: Text(
              _isScanning ? 'Processing OCR Scan...' : 'Scan Card with Camera',
              style: const TextStyle(
                color: Color(0xFF00E5FF),
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF00E5FF)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _textController,
            maxLines: 5,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Jane Doe\nDirector of Photography\nNairobi Films Ltd\n+254 712 345 678\njane@example.com',
              hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
              filled: true,
              fillColor: const Color(0xFF080B0F),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDesignTokens.radiusMd),
                borderSide: const BorderSide(color: Colors.white24),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _parseText,
            icon: const Icon(Icons.check_rounded, color: Color(0xFF080B0F)),
            label: const Text(
              'Extract & Review Contact',
              style: TextStyle(
                color: Color(0xFF080B0F),
                fontWeight: FontWeight.w800,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5FF),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
