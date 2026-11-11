import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';

class EditableAttachment {
  String filePath;
  String caption;
  bool includeInPdf;

  EditableAttachment({
    required this.filePath,
    this.caption = '',
    this.includeInPdf = true,
  });
}

class AttachmentsEditorCard extends StatefulWidget {
  final List<EditableAttachment> attachments;
  final VoidCallback onChanged;

  const AttachmentsEditorCard({
    super.key,
    required this.attachments,
    required this.onChanged,
  });

  @override
  State<AttachmentsEditorCard> createState() => _AttachmentsEditorCardState();
}

class _AttachmentsEditorCardState extends State<AttachmentsEditorCard> {
  final _picker = ImagePicker();

  Future<void> _pickFromFileManager() async {
    if (widget.attachments.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 10 attachments allowed per document'),
        ),
      );
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'webp', 'doc', 'docx'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          for (final f in result.files) {
            if (f.path != null && widget.attachments.length < 10) {
              widget.attachments.add(EditableAttachment(filePath: f.path!));
            }
          }
        });
        widget.onChanged();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error picking file: $e')));
      }
    }
  }

  Future<void> _pickAttachment(ImageSource source) async {
    if (widget.attachments.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 10 attachments allowed per document'),
        ),
      );
      return;
    }

    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 80,
      );

      if (photo != null) {
        setState(() {
          widget.attachments.add(EditableAttachment(filePath: photo.path));
        });
        widget.onChanged();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error picking photo: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Attachments (${widget.attachments.length}/10)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.folder_open_rounded),
                  tooltip: 'Browse Files & PDFs',
                  onPressed: _pickFromFileManager,
                ),
                IconButton(
                  icon: const Icon(Icons.camera_alt_outlined),
                  tooltip: 'Take Photo',
                  onPressed: () => _pickAttachment(ImageSource.camera),
                ),
                IconButton(
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  tooltip: 'Pick from Gallery',
                  onPressed: () => _pickAttachment(ImageSource.gallery),
                ),
              ],
            ),
          ],
        ),
        if (widget.attachments.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(
                    Icons.attachment_rounded,
                    color: AppColors.darkTextMuted,
                    size: 32,
                  ),
                  SizedBox(height: 6),
                  Text(
                    'No photos attached yet',
                    style: TextStyle(
                      color: AppColors.darkTextSecondary,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Attach sample frames, location photos, reference shots or receipts',
                    style: TextStyle(
                      color: AppColors.darkTextMuted,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ] else ...[
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.attachments.length,
            itemBuilder: (context, index) {
              final att = widget.attachments[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 60,
                          height: 60,
                          color: AppColors.darkCardElevated,
                          child: File(att.filePath).existsSync()
                              ? Image.file(
                                  File(att.filePath),
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              initialValue: att.caption,
                              decoration: const InputDecoration(
                                hintText: 'Short caption / description...',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                              ),
                              onChanged: (val) {
                                att.caption = val;
                                widget.onChanged();
                              },
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Checkbox(
                                  value: att.includeInPdf,
                                  onChanged: (val) {
                                    setState(() {
                                      att.includeInPdf = val ?? true;
                                    });
                                    widget.onChanged();
                                  },
                                ),
                                const Text(
                                  'Show on PDF page',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.statusOverdue,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            widget.attachments.removeAt(index);
                          });
                          widget.onChanged();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}
