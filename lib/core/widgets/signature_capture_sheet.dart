import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';

import '../constants/app_colors.dart';

class SignatureCaptureSheet extends StatefulWidget {
  final String title;
  final Function(String savedFilePath) onSignatureSaved;

  const SignatureCaptureSheet({
    super.key,
    this.title = 'Draw Digital Signature',
    required this.onSignatureSaved,
  });

  @override
  State<SignatureCaptureSheet> createState() => _SignatureCaptureSheetState();
}

class _SignatureCaptureSheetState extends State<SignatureCaptureSheet> {
  late SignatureController _controller;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 3.5,
      penColor: Colors.black,
      exportBackgroundColor: Colors.transparent,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveSignature() async {
    if (_controller.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign before saving')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final Uint8List? data = await _controller.toPngBytes();
      if (data != null) {
        final dir = await getApplicationDocumentsDirectory();
        final signaturesDir = Directory('${dir.path}/signatures');
        if (!await signaturesDir.exists()) {
          await signaturesDir.create(recursive: true);
        }
        final filePath =
            '${signaturesDir.path}/sig_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File(filePath);
        await file.writeAsBytes(data);

        if (mounted) {
          widget.onSignatureSaved(filePath);
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving signature: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Sign smoothly using your finger or stylus inside the box below.',
            style: TextStyle(fontSize: 12, color: AppColors.darkTextSecondary),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              color: Colors.white,
              height: 200,
              width: double.infinity,
              child: Stack(
                children: [
                  Signature(
                    controller: _controller,
                    height: 200,
                    width: double.infinity,
                    backgroundColor: Colors.white,
                  ),
                  Positioned(
                    bottom: 24,
                    left: 24,
                    right: 24,
                    child: Container(height: 1, color: Colors.black12),
                  ),
                  const Positioned(
                    bottom: 8,
                    left: 24,
                    child: Text(
                      'Sign above line',
                      style: TextStyle(color: Colors.black38, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  label: const Text('Clear'),
                  onPressed: () => _controller.clear(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Use Signature'),
                  onPressed: _isSaving ? null : _saveSignature,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
