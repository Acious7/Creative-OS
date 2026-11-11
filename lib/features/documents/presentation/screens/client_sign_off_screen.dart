import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signature/signature.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';

class ClientSignOffScreen extends ConsumerStatefulWidget {
  final Document document;
  final String clientName;

  const ClientSignOffScreen({
    super.key,
    required this.document,
    required this.clientName,
  });

  @override
  ConsumerState<ClientSignOffScreen> createState() =>
      _ClientSignOffScreenState();
}

class _ClientSignOffScreenState extends ConsumerState<ClientSignOffScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _titleController;
  late TextEditingController _orgController;

  late SignatureController _sigController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.clientName);
    _titleController = TextEditingController(text: 'Authorized Representative');
    _orgController = TextEditingController();

    _sigController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _orgController.dispose();
    _sigController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Client Acceptance — ${widget.document.docNumber}'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                color: AppColors.darkSurface,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CLIENT ACCEPTANCE & SIGN-OFF',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.darkTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'By signing below, I confirm acceptance of document #${widget.document.docNumber} and agree to the scope, deliverables, fees, and terms outlined.',
                        style: const TextStyle(fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Signer Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Please enter signer name'
                    : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title / Designation',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _orgController,
                      decoration: const InputDecoration(
                        labelText: 'Organization (Optional)',
                        prefixIcon: Icon(Icons.business_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Draw Signature Below:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  TextButton.icon(
                    onPressed: () => _sigController.clear(),
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    label: const Text('Clear'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 200,
                  color: Colors.white,
                  child: Signature(
                    controller: _sigController,
                    height: 200,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _saveSignOff,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text(
                    'Accept & Save Signature',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveSignOff() async {
    if (!_formKey.currentState!.validate()) return;
    if (_sigController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please draw signature on the pad'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final imageBytes = await _sigController.toPngBytes();
    if (imageBytes == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final sigPath = '${dir.path}/signatures/sig_${const Uuid().v4()}.png';
    final sigFile = File(sigPath);
    await sigFile.parent.create(recursive: true);
    await sigFile.writeAsBytes(imageBytes);

    final db = ref.read(databaseProvider);

    // Save signature record
    await db
        .into(db.documentSignatures)
        .insert(
          DocumentSignaturesCompanion.insert(
            documentId: widget.document.id,
            signerName: _nameController.text.trim(),
            signerTitle: drift.Value(_titleController.text.trim()),
            signerOrganization: drift.Value(_orgController.text.trim()),
            signatureImagePath: sigPath,
            signedAt: drift.Value(DateTime.now()),
          ),
        );

    // Update document status to accepted / signed
    await (db.update(db.documents)
          ..where((t) => t.id.equals(widget.document.id)))
        .write(const DocumentsCompanion(status: drift.Value('accepted')));

    // Log activity
    await db
        .into(db.documentActivityLogs)
        .insert(
          DocumentActivityLogsCompanion.insert(
            documentId: widget.document.id,
            action: const drift.Value('accepted'),
            actionType: const drift.Value('accepted'),
            description: drift.Value(
              'Client accepted & signed document on-screen (${_nameController.text.trim()})',
            ),
          ),
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document accepted and signed successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    }
  }
}
