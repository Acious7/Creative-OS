import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../../domain/business_card_ocr_service.dart';
import '../screens/card_review_screen.dart';

class ScanBusinessCardSheet extends StatefulWidget {
  final int locationId;
  final String locationName;

  const ScanBusinessCardSheet({
    super.key,
    required this.locationId,
    required this.locationName,
  });

  static Future<int?> show(
    BuildContext context, {
    required int locationId,
    required String locationName,
  }) {
    EtoleHaptics.selection();
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ScanBusinessCardSheet(
        locationId: locationId,
        locationName: locationName,
      ),
    );
  }

  @override
  State<ScanBusinessCardSheet> createState() => _ScanBusinessCardSheetState();
}

class _ScanBusinessCardSheetState extends State<ScanBusinessCardSheet> {
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;
  String _statusText = 'Ready to scan';

  Future<void> _captureWithCamera() async {
    try {
      EtoleHaptics.selection();
      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2400,
        maxHeight: 2400,
        imageQuality: 92,
      );

      if (picked != null && mounted) {
        await _processImage(picked.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera error: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      EtoleHaptics.selection();
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2400,
        maxHeight: 2400,
        imageQuality: 92,
      );

      if (picked != null && mounted) {
        await _processImage(picked.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gallery error: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _processImage(String path) async {
    setState(() {
      _isProcessing = true;
      _statusText = 'Reading card text on-device (ML Kit)...';
    });

    final parsed = await BusinessCardOcrService.scanAndParseCard(path);

    if (mounted) {
      setState(() => _isProcessing = false);
      // Close sheet and open review screen
      Navigator.pop(context);

      final personId = await CardReviewScreen.show(
        context,
        parsedData: parsed,
        locationId: widget.locationId,
        locationName: widget.locationName,
      );

      // Return the saved personId to the caller
      if (personId != null && mounted) {
        // Handled in caller
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          color: const Color(0xFA11151A),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.document_scanner_rounded,
                      color: Color(0xFFF59E0B),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SCAN BUSINESS CARD',
                          style: EtoleTypography.labelCaps(
                            color: const Color(0xFFF59E0B),
                          ),
                        ),
                        Text(
                          'Add Person at ${widget.locationName}',
                          style: EtoleTypography.subheading(color: Colors.white)
                              .copyWith(fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white60,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Card-Shaped Guide Frame Illustration
              Container(
                width: double.infinity,
                height: 175,
                decoration: BoxDecoration(
                  color: const Color(0xFF161C24),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Corner guide lines (standard viewfinder corners)
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: CustomPaint(
                          painter: _CardViewfinderPainter(
                            color: const Color(0xFFF59E0B),
                          ),
                        ),
                      ),
                    ),
                    if (_isProcessing)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _statusText,
                            style: const TextStyle(
                              color: Color(0xFFF59E0B),
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.crop_landscape_rounded,
                            size: 40,
                            color: const Color(0xFFF59E0B)
                                .withValues(alpha: 0.8),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Align Card Inside Guide Frame',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'On-device text extraction • Stored safely on phone',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons: Camera & Gallery (Rule: "Capture with the camera (card-shaped guide frame) or pick a photo from the gallery")
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isProcessing ? null : _captureWithCamera,
                      icon: const Icon(Icons.camera_alt_rounded, size: 18),
                      label: const Text(
                        'Take Photo',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isProcessing ? null : _pickFromGallery,
                      icon: const Icon(Icons.photo_library_rounded, size: 18),
                      label: const Text(
                        'From Gallery',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
}

/// Custom painter for the 4 viewfinder corners framing a business card
class _CardViewfinderPainter extends CustomPainter {
  final Color color;

  _CardViewfinderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLen = 22.0;

    // Top-Left
    canvas.drawLine(const Offset(0, 0), const Offset(cornerLen, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, cornerLen), paint);

    // Top-Right
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width - cornerLen, 0),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, cornerLen),
      paint,
    );

    // Bottom-Left
    canvas.drawLine(
      Offset(0, size.height),
      Offset(cornerLen, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(0, size.height - cornerLen),
      paint,
    );

    // Bottom-Right
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width - cornerLen, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width, size.height - cornerLen),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
