import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/database/database_provider.dart';
import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../../data/call_and_chat_ingestion_service.dart';

class ImportChatSheet extends ConsumerStatefulWidget {
  const ImportChatSheet({super.key});

  @override
  ConsumerState<ImportChatSheet> createState() => _ImportChatSheetState();
}

class _ImportChatSheetState extends ConsumerState<ImportChatSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // WhatsApp / SMS Tab State
  final _chatTextCtrl = TextEditingController();
  final _clientNameCtrl = TextEditingController();
  IngestedCommunicationMinutes? _parsedMinutes;
  bool _isAnalyzing = false;

  // Phone Call Tab State
  final _callerNameCtrl = TextEditingController();
  final _callerPhoneCtrl = TextEditingController();
  final _callNotesCtrl = TextEditingController();
  String _callDirection = 'Incoming';
  int _callDurationMinutes = 5;

  // Audio Recording State
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordedAudioPath;
  int _recordingDuration = 0;
  DateTime? _recordingStart;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatTextCtrl.dispose();
    _clientNameCtrl.dispose();
    _callerNameCtrl.dispose();
    _callerPhoneCtrl.dispose();
    _callNotesCtrl.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    EtoleHaptics.selection();
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null && data.text!.isNotEmpty) {
      setState(() {
        _chatTextCtrl.text = data.text!;
      });
      _analyzeChat();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Clipboard is empty')));
      }
    }
  }

  void _analyzeChat() {
    final text = _chatTextCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _isAnalyzing = true);
    final result = CallAndChatIngestionService.parseWhatsAppChat(
      text,
      defaultProjectName: _clientNameCtrl.text.trim().isNotEmpty
          ? _clientNameCtrl.text.trim()
          : null,
    );

    setState(() {
      _parsedMinutes = result;
      if (_clientNameCtrl.text.trim().isEmpty &&
          result.clientOrContactName != null) {
        _clientNameCtrl.text = result.clientOrContactName!;
      }
      _isAnalyzing = false;
    });
  }

  Future<void> _pickContact() async {
    try {
      EtoleHaptics.selection();
      if (await FlutterContacts.requestPermission(readonly: true)) {
        final picked = await FlutterContacts.openExternalPick();
        if (picked != null) {
          final full = await FlutterContacts.getContact(picked.id) ?? picked;
          setState(() {
            _callerNameCtrl.text = full.displayName;
            if (full.phones.isNotEmpty) {
              _callerPhoneCtrl.text = full.phones.first.number;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking contact: $e');
    }
  }

  Future<void> _toggleAudioRecording() async {
    try {
      EtoleHaptics.selection();
      if (_isRecording) {
        final path = await _audioRecorder.stop();
        final duration = _recordingStart != null
            ? DateTime.now().difference(_recordingStart!).inSeconds
            : 0;
        setState(() {
          _isRecording = false;
          _recordedAudioPath = path;
          _recordingDuration = duration;
        });
      } else {
        if (await _audioRecorder.hasPermission()) {
          final dir = await getApplicationDocumentsDirectory();
          final path =
              '${dir.path}/call_minutes_${DateTime.now().millisecondsSinceEpoch}.m4a';
          await _audioRecorder.start(
            const RecordConfig(encoder: AudioEncoder.aacLc),
            path: path,
          );
          setState(() {
            _isRecording = true;
            _recordingStart = DateTime.now();
            _recordedAudioPath = null;
          });
        }
      }
    } catch (e) {
      debugPrint('Error with recording: $e');
    }
  }

  Future<void> _saveChatMinutes() async {
    if (_parsedMinutes == null) return;
    EtoleHaptics.success();
    final db = ref.read(databaseProvider);
    await CallAndChatIngestionService.saveToDatabase(
      db: db,
      minutes: _parsedMinutes!,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WhatsApp / SMS Minutes Saved & Logged!'),
          backgroundColor: Color(0xFF00C853),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  Future<void> _saveCallMinutes() async {
    final caller = _callerNameCtrl.text.trim();
    if (caller.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter caller name')));
      return;
    }

    EtoleHaptics.success();
    final minutes = CallAndChatIngestionService.buildPhoneCallMinutes(
      contactName: caller,
      phoneNumber: _callerPhoneCtrl.text.trim().isNotEmpty
          ? _callerPhoneCtrl.text.trim()
          : 'Unknown',
      callDirection: _callDirection,
      durationSeconds: _callDurationMinutes * 60,
      recapNotes: _callNotesCtrl.text.trim(),
      audioFilePath: _recordedAudioPath,
    );

    final db = ref.read(databaseProvider);
    await CallAndChatIngestionService.saveToDatabase(
      db: db,
      minutes: minutes,
      audioPath: _recordedAudioPath,
      audioDurationSeconds: _recordingDuration,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone Call Minutes & Commitments Logged!'),
          backgroundColor: Color(0xFF00C853),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  Future<void> _openWhatsApp() async {
    EtoleHaptics.selection();
    final uri = Uri.parse('whatsapp://');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      final webUri = Uri.parse('https://web.whatsapp.com');
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFA121518),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: const Color(0xFF25D366).withValues(alpha: 0.5),
                width: 1.2,
              ),
            ),
          ),
          padding: EdgeInsets.fromLTRB(20, 14, 20, 24 + bottomInset),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: EtoleColors.creamMuted.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Top Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF25D366)
                                .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.contact_phone_rounded,
                            color: Color(0xFF25D366),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'COMMUNICATION INGESTION',
                              style: EtoleTypography.labelCaps(
                                color: const Color(0xFF25D366),
                              ),
                            ),
                            Text(
                              'Record Calls & Ingest Chats',
                              style: EtoleTypography.h3.copyWith(
                                color: EtoleColors.cream,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: EtoleColors.creamMuted,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Tab Selector
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B2026),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: const Color(0xFF25D366).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF25D366)),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFF94A3B8),
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    tabs: const [
                      Tab(iconMargin: EdgeInsets.zero, text: 'WhatsApp & SMS'),
                      Tab(
                        iconMargin: EdgeInsets.zero,
                        text: 'Record / Log Call',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Tab Views (Using animated switcher or manual conditional for proper height inside sheet)
                AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, _) {
                    return _tabController.index == 0
                        ? _buildChatIngestionTab()
                        : _buildCallIngestionTab();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- TAB 1: WhatsApp & SMS Chat Ingestion ---
  Widget _buildChatIngestionTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Paste Conversation or Export',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              children: [
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF25D366),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: _openWhatsApp,
                  icon: const Icon(Icons.open_in_new_rounded, size: 14),
                  label: const Text(
                    'Open WhatsApp',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: EtoleColors.cyan,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: _pasteFromClipboard,
                  icon: const Icon(Icons.paste_rounded, size: 14),
                  label: const Text('Paste', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _chatTextCtrl,
          maxLines: 5,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Paste chat thread here (e.g. "[10:30, 12/04/2026] Alex: Can we confirm 120k for the 3-day shoot?")...',
            hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            filled: true,
            fillColor: const Color(0xFF15191E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          onChanged: (_) => _analyzeChat(),
        ),
        if (_isAnalyzing) ...[
          const SizedBox(height: 8),
          const LinearProgressIndicator(
            color: Color(0xFF25D366),
            backgroundColor: Color(0xFF1E242B),
          ),
        ],
        const SizedBox(height: 12),

        TextField(
          controller: _clientNameCtrl,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            labelText: 'Client or Project Name (Optional)',
            labelStyle: const TextStyle(color: Color(0xFF25D366), fontSize: 12),
            filled: true,
            fillColor: const Color(0xFF15191E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        if (_parsedMinutes != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1B2026),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF25D366).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _parsedMinutes!.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${_parsedMinutes!.participants.length} Speakers',
                        style: const TextStyle(
                          color: Color(0xFF25D366),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _parsedMinutes!.summary,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                  ),
                ),
                if (_parsedMinutes!.agreementsAndPromises.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Detected Commitments & Deals:',
                    style: TextStyle(
                      color: Color(0xFFFBBF24),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ..._parsedMinutes!.agreementsAndPromises
                      .take(3)
                      .map(
                        (a) => Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '• $a',
                            style: const TextStyle(
                              color: Color(0xFFE2E8F0),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                ],
                if (_parsedMinutes!.actionItems.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Follow-up Tasks:',
                    style: TextStyle(
                      color: Color(0xFF60A5FA),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ..._parsedMinutes!.actionItems
                      .take(3)
                      .map(
                        (t) => Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '✓ $t',
                            style: const TextStyle(
                              color: Color(0xFFE2E8F0),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _parsedMinutes != null ? _saveChatMinutes : null,
          icon: const Icon(Icons.bookmark_added_rounded, size: 18),
          label: const Text(
            'Save as Official Meeting Minutes',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ],
    );
  }

  // --- TAB 2: Phone Call Minutes Logger ---
  Widget _buildCallIngestionTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _callerNameCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Contact / Caller Name',
                  labelStyle: const TextStyle(
                    color: Color(0xFF25D366),
                    fontSize: 12,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF15191E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF1E242B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(
                Icons.contacts_rounded,
                color: Color(0xFF25D366),
              ),
              tooltip: 'Pick Contact',
              onPressed: _pickContact,
            ),
          ],
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _callerPhoneCtrl,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  labelStyle: const TextStyle(
                    color: Color(0xFF25D366),
                    fontSize: 12,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF15191E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF15191E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _callDirection,
                  dropdownColor: const Color(0xFF1E242B),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  items: const [
                    DropdownMenuItem(
                      value: 'Incoming',
                      child: Text('Incoming'),
                    ),
                    DropdownMenuItem(
                      value: 'Outgoing',
                      child: Text('Outgoing'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _callDirection = val);
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Audio Recording Memo Banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _isRecording
                ? const Color(0xFF3B151E)
                : const Color(0xFF15191E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isRecording
                  ? const Color(0xFFEF4444)
                  : Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: _isRecording
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF25D366),
                ),
                icon: Icon(
                  _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                  color: Colors.white,
                ),
                onPressed: _toggleAudioRecording,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isRecording
                          ? 'Recording Call Audio / Voice Memo...'
                          : _recordedAudioPath != null
                          ? 'Audio Recorded (${_recordingDuration}s ready)'
                          : 'Record Voice Memo or Call Audio',
                      style: TextStyle(
                        color: _isRecording
                            ? const Color(0xFFFCA5A5)
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _isRecording
                          ? 'Tap red square to stop and attach to minutes'
                          : 'Captures voice recap directly into Whisper speech model',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        TextField(
          controller: _callNotesCtrl,
          maxLines: 4,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Key discussion recap & promises (e.g. "Agreed on KES 150,000 budget for 2-day shoot. Brian to send contract by 5 PM.")...',
            hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            filled: true,
            fillColor: const Color(0xFF15191E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _saveCallMinutes,
          icon: const Icon(Icons.phone_callback_rounded, size: 18),
          label: const Text(
            'Save Call as Meeting Minutes',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
