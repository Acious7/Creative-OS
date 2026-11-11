import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../constants/document_constants.dart';
import '../database/app_database.dart';
import '../database/database_provider.dart';
import '../design_system/etole_colors.dart';
import '../design_system/etole_components.dart';
import '../design_system/etole_typography.dart';
import '../theme/brand_theme_provider.dart';
import '../../features/digital_cards/domain/freelance_crm_models.dart';
import '../../features/documents/presentation/screens/document_editor_screen.dart';
import 'executive_chief_of_staff.dart';
import 'gemini_chief_of_staff_service.dart';

class ExecutiveChiefOfStaffSheet extends ConsumerStatefulWidget {
  const ExecutiveChiefOfStaffSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ExecutiveChiefOfStaffSheet(),
    );
  }

  @override
  ConsumerState<ExecutiveChiefOfStaffSheet> createState() =>
      _ExecutiveChiefOfStaffSheetState();
}

class _ExecutiveChiefOfStaffSheetState
    extends ConsumerState<ExecutiveChiefOfStaffSheet> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioRecorder _audioRecorder = AudioRecorder();

  int _selectedTab = 0; // 0: AI Assistant Chat, 1: Quick Deal Logger
  bool _isGeminiConnected = false;
  bool _isProcessing = false;
  bool _isRecording = false;
  int _recordSeconds = 0;
  Timer? _recordTimer;
  String? _currentAudioPath;

  ExecutiveParsedIntent _parsed = const ExecutiveParsedIntent();

  final List<ChiefOfStaffMessage> _messages = [
    ChiefOfStaffMessage(
      sender: 'chief',
      text: 'Executive Chief of Staff online. I have analyzed your current studio slate, debtors, and cashflow. What is our objective today?',
      timestamp: DateTime.now(),
    ),
  ];

  final List<String> _presets = [
    'Had coffee with Sarah from Safaricom at Sarit. Wants a 3-part commercial docuseries for KES 850,000 starting next month. Send quotation by Friday.',
    'Met Kevin from East African Breweries at Serena. Pitching 4K cinema campaign. Budget KES 1.2M. Follow up Monday.',
    'Spoke with Amina at Ogilvy Nairobi. Client needs brand commercial directing. Budget KES 450,000. Send moodboard tomorrow.',
  ];

  @override
  void initState() {
    super.initState();
    _checkApiKey();
    _inputController.addListener(_onTextChanged);
  }

  Future<void> _checkApiKey() async {
    final hasKey = await GeminiChiefOfStaffService.hasApiKey();
    if (mounted) setState(() => _isGeminiConnected = hasKey);
  }

  void _onTextChanged() {
    if (_selectedTab == 1) {
      setState(() {
        _parsed = ExecutiveVoiceParser.parse(_inputController.text);
      });
    }
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _audioRecorder.dispose();
    _inputController.removeListener(_onTextChanged);
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- Voice Recording Logic ---
  Future<void> _toggleRecording() async {
    EtoleHaptics.medium();

    if (_isRecording) {
      // STOP recording
      try {
        final path = await _audioRecorder.stop();
        _recordTimer?.cancel();

        setState(() {
          _isRecording = false;
          _recordSeconds = 0;
          _currentAudioPath = path;
        });

        if (path != null && mounted) {
          EtoleHaptics.success();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF14171B),
              behavior: SnackBarBehavior.floating,
              content: const Row(
                children: [
                  Icon(
                    Icons.mic_none_rounded,
                    color: Color(0xFF00E5FF),
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Audio note captured! Processing voice directive...',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
              duration: const Duration(seconds: 3),
            ),
          );

          // Submit voice note directive
          _sendMessage(
            prompt: 'Processed executive voice note. Summarize directive.',
          );
        }
      } catch (e) {
        setState(() => _isRecording = false);
      }
    } else {
      // START recording
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone permission required for voice notes'),
              backgroundColor: Color(0xFFD32F2F),
            ),
          );
        }
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final path =
          '${dir.path}/executive_note_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );

      setState(() {
        _isRecording = true;
        _recordSeconds = 0;
      });

      _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) setState(() => _recordSeconds++);
      });
    }
  }

  // --- Send Message to AI Chief ---
  Future<void> _sendMessage({String? prompt}) async {
    final text = prompt ?? _inputController.text.trim();
    if (text.isEmpty) return;

    if (prompt == null) _inputController.clear();
    EtoleHaptics.light();

    setState(() {
      _messages.add(
        ChiefOfStaffMessage(
          sender: 'user',
          text: text,
          timestamp: DateTime.now(),
        ),
      );
      _isProcessing = true;
    });

    _scrollToBottom();

    final db = ref.read(databaseProvider);
    final reply = await GeminiChiefOfStaffService.askChiefOfStaff(
      query: text,
      db: db,
    );

    if (mounted) {
      setState(() {
        _messages.add(reply);
        _isProcessing = false;
        if (reply.extractedIntent != null) {
          _parsed = reply.extractedIntent!;
        }
      });
      EtoleHaptics.success();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // --- API Key Dialog ---
  Future<void> _openApiKeyDialog() async {
    final currentKey = await GeminiChiefOfStaffService.getApiKey() ?? '';
    final keyController = TextEditingController(text: currentKey);

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14171B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF00E5FF), width: 1.2),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bolt_rounded,
                color: Color(0xFF00E5FF),
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Google Gemini AI Setup',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connect your free Google Gemini API key to unlock real-time commercial reasoning, intelligent quote drafting, and autonomous deal extraction.',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF080B0F),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: const Text(
                'Get your 100% free key with no credit card at: aistudio.google.com',
                style: TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: keyController,
              obscureText: true,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Gemini API Key',
                labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                hintText: 'AIzaSy...',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: const Color(0xFF080B0F),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (currentKey.isNotEmpty)
            TextButton(
              onPressed: () async {
                await GeminiChiefOfStaffService.removeApiKey();
                await _checkApiKey();
                Navigator.pop(ctx);
              },
              child: const Text(
                'Disconnect',
                style: TextStyle(color: Color(0xFFD32F2F)),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final newKey = keyController.text.trim();
              if (newKey.isNotEmpty) {
                await GeminiChiefOfStaffService.setApiKey(newKey);
                await _checkApiKey();
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5FF),
              foregroundColor: const Color(0xFF080B0F),
            ),
            child: const Text(
              'Save Key',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // --- CRM & Quotation Commit ---
  Future<void> _commitToCrm({bool andDraftQuote = false}) async {
    if (_parsed.name == null || _parsed.name!.isEmpty) return;

    setState(() => _isProcessing = true);
    EtoleHaptics.success();

    final db = ref.read(databaseProvider);
    final activeBrand = ref.read(activeBrandProvider);
    if (activeBrand == null) return;

    final deal = FreelanceDealInfo(
      dealTitle: _parsed.organization != null
          ? '${_parsed.organization} ${_parsed.serviceCategory}'
          : '${_parsed.name} Campaign',
      dealValue: _parsed.dealValue,
      serviceCategory: _parsed.serviceCategory,
      isVip: _parsed.dealValue >= 500000,
      stage: _parsed.stage,
      tags: [_parsed.serviceCategory],
    );

    final promises = [
      {
        'text': _parsed.actionPromise ?? 'Send project quotation',
        'due':
            _parsed.targetDate?.toIso8601String() ??
            DateTime.now().add(const Duration(days: 2)).toIso8601String(),
        'done': false,
      },
    ];

    final leadId = await db
        .into(db.networkingLeads)
        .insert(
          NetworkingLeadsCompanion(
            brandId: drift.Value(activeBrand.id),
            name: drift.Value(_parsed.name!),
            organization: drift.Value(_parsed.organization),
            locationMet: drift.Value(_parsed.location),
            status: drift.Value(_parsed.stage.name),
            interestTagsJson: drift.Value(deal.toJsonString()),
            promisesJson: drift.Value(jsonEncode(promises)),
            followUpDate: drift.Value(_parsed.targetDate),
            notes: drift.Value(_inputController.text.trim()),
            dateMet: drift.Value(DateTime.now()),
          ),
        );

    setState(() => _isProcessing = false);

    if (!mounted) return;
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✨ Chief of Staff logged ${_parsed.name} into CRM!'),
        backgroundColor: const Color(0xFF14171B),
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (andDraftQuote) {
      final clientId = await db
          .into(db.clients)
          .insert(
            ClientsCompanion(
              name: drift.Value(_parsed.name!),
              organization: drift.Value(_parsed.organization),
              notes: drift.Value(
                'Generated by AI Chief of Staff from deal notes',
              ),
            ),
          );

      await (db.update(
        db.networkingLeads,
      )..where((t) => t.id.equals(leadId))).write(
        NetworkingLeadsCompanion(
          isClient: const drift.Value(true),
          convertedClientId: drift.Value(clientId),
        ),
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DocumentEditorScreen(
              docType: DocType.quotation,
              initialClientId: clientId,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Color(0xFF0D1013),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Color(0xFF00E5FF), width: 1.5)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 10),
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 10),

          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Pulsing Mic / Avatar
                InkWell(
                  onTap: _toggleRecording,
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _isRecording
                          ? const Color(0xFFD32F2F).withValues(alpha: 0.25)
                          : const Color(0xFF00E5FF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isRecording
                            ? const Color(0xFFD32F2F)
                            : const Color(0xFF00E5FF).withValues(alpha: 0.4),
                        width: _isRecording ? 1.8 : 1.0,
                      ),
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                      color: _isRecording
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF00E5FF),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Title & Mode status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'POCKET CHIEF OF STAFF',
                            style: TextStyle(
                              color: Color(0xFF00E5FF),
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: _openApiKeyDialog,
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _isGeminiConnected
                                    ? const Color(0xFF00E5FF)
                                          .withValues(alpha: 0.15)
                                    : Colors.white10,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: _isGeminiConnected
                                      ? const Color(0xFF00E5FF)
                                      : Colors.white24,
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.bolt_rounded,
                                    size: 10,
                                    color: _isGeminiConnected
                                        ? const Color(0xFF00E5FF)
                                        : Colors.white54,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    _isGeminiConnected
                                        ? 'GEMINI LIVE'
                                        : 'CONNECT KEY',
                                    style: TextStyle(
                                      color: _isGeminiConnected
                                          ? const Color(0xFF00E5FF)
                                          : Colors.white70,
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _isRecording
                            ? 'Recording 00:${_recordSeconds.toString().padLeft(2, '0')} (Tap to Finish)'
                            : 'Executive Studio AI Partner',
                        style: TextStyle(
                          color: _isRecording
                              ? const Color(0xFFEF4444)
                              : Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Tab Bar (Chat vs Quick Deal Logger)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildTabButton(0, 'AI Executive Chat', Icons.chat_rounded),
                const SizedBox(width: 8),
                _buildTabButton(1, 'Fast Deal Logger', Icons.bolt_rounded),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 16),

          // TAB 0: CONVERSATIONAL AI CHAT
          if (_selectedTab == 0) ...[
            // Quick Prompt Chips
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildQuickChip(
                    '⚡ Morning Briefing',
                    'Give me my studio morning briefing, debtors & cashflow status.',
                  ),
                  _buildQuickChip(
                    '💰 Who Owes Me?',
                    'Who owes me money and which invoices are overdue?',
                  ),
                  _buildQuickChip(
                    '🎬 Production Slate',
                    'What is the status of my active production slate?',
                  ),
                  _buildQuickChip(
                    '📝 Draft Quotation',
                    'Help me draft a commercial video production quotation.',
                  ),
                  _buildQuickChip(
                    '📊 Tax & Escrow',
                    'Calculate my 5% withholding tax and 16% VAT reserve for this month.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Message List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: _messages.length,
                itemBuilder: (context, idx) {
                  final msg = _messages[idx];
                  return _buildMessageBubble(msg);
                },
              ),
            ),

            if (_isProcessing)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF00E5FF),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isGeminiConnected
                          ? 'Chief of Staff reasoning with Gemini...'
                          : 'Chief of Staff scanning studio database...',
                      style: const TextStyle(
                        color: Color(0xFF00E5FF),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

            // Chat Input Box
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF14171B),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: TextField(
                        controller: _inputController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                        decoration: const InputDecoration(
                          hintText:
                              'Ask Chief of Staff or dictate instructions...',
                          hintStyle: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12.5,
                          ),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (v) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _toggleRecording,
                    icon: Icon(
                      _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                      color: _isRecording
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF00E5FF),
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF14171B),
                      side: const BorderSide(color: Colors.white12),
                    ),
                    tooltip: 'Record Voice Directive',
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () => _sendMessage(),
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Color(0xFF080B0F),
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5FF),
                    ),
                    tooltip: 'Send',
                  ),
                ],
              ),
            ),
          ],

          // TAB 1: FAST DEAL LOGGER
          if (_selectedTab == 1) ...[
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
                children: [
                  // Preset Quick Notes
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _presets.map((preset) {
                        final name = preset.split(' ')[2];
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              EtoleHaptics.light();
                              _inputController.text = preset;
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF14171B),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.bolt_rounded,
                                    size: 12,
                                    color: Color(0xFFF5A623),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Preset: $name',
                                    style: const TextStyle(
                                      color: Color(0xFFCBD5E1),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Note Textarea
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF14171B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: TextField(
                      controller: _inputController,
                      maxLines: 4,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        height: 1.45,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Speak or paste: e.g. "Met Sarah from Safaricom at Sarit. Wants a commercial docuseries for KES 850k. Send quote by Friday..."',
                        hintStyle: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12.5,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Live Extracted Intelligence Card
                  if (_inputController.text.trim().isNotEmpty) ...[
                    const Text(
                      'AI EXTRACTED COMMERCIAL INTEL',
                      style: TextStyle(
                        color: Color(0xFF00E5FF),
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF14181D),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF00E5FF)
                              .withValues(alpha: 0.35),
                          width: 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.person_rounded,
                                size: 16,
                                color: Color(0xFF00E5FF),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${_parsed.name ?? 'New Contact'}${_parsed.organization != null ? ' (${_parsed.organization})' : ''}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5A623)
                                      .withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _parsed.formattedValue,
                                  style: const TextStyle(
                                    color: Color(0xFFFBBF24),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.category_rounded,
                                size: 14,
                                color: Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _parsed.serviceCategory,
                                style: const TextStyle(
                                  color: Color(0xFFCBD5E1),
                                  fontSize: 12,
                                ),
                              ),
                              if (_parsed.location != null) ...[
                                const Text(
                                  ' • ',
                                  style: TextStyle(color: Colors.white24),
                                ),
                                Icon(
                                  Icons.location_on_outlined,
                                  size: 13,
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  _parsed.location!,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const Divider(color: Colors.white10, height: 16),
                          Row(
                            children: [
                              const Icon(
                                Icons.assignment_turned_in_rounded,
                                size: 14,
                                color: Color(0xFF00E5FF),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _parsed.actionPromise ?? 'Review notes',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                _parsed.targetDate != null
                                    ? DateFormat('MMM d')
                                          .format(_parsed.targetDate!)
                                    : 'In 2 days',
                                style: const TextStyle(
                                  color: Color(0xFF00E5FF),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _commitToCrm(andDraftQuote: false),
                            icon: const Icon(Icons.save_rounded, size: 16),
                            label: const Text('Log Deal into CRM'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E2631),
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _commitToCrm(andDraftQuote: true),
                            icon: const Icon(
                              Icons.receipt_long_rounded,
                              size: 16,
                            ),
                            label: const Text('Log & Draft Quote'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00E5FF),
                              foregroundColor: const Color(0xFF080B0F),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _selectedTab = index);
          EtoleHaptics.selection();
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF00E5FF).withValues(alpha: 0.15)
                : const Color(0xFF14171B),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF00E5FF) : Colors.white12,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? const Color(0xFF00E5FF) : Colors.white60,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF00E5FF) : Colors.white70,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickChip(String label, String prompt) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => _sendMessage(prompt: prompt),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF14171B),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChiefOfStaffMessage msg) {
    final isChief = msg.sender == 'chief';
    final dateFormat = DateFormat('h:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isChief
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isChief) ...[
                const Icon(
                  Icons.bolt_rounded,
                  size: 12,
                  color: Color(0xFF00E5FF),
                ),
                const SizedBox(width: 4),
                const Text(
                  'CHIEF OF STAFF',
                  style: TextStyle(
                    color: Color(0xFF00E5FF),
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                dateFormat.format(msg.timestamp),
                style: const TextStyle(color: Colors.white24, fontSize: 9.5),
              ),
            ],
          ),
          const SizedBox(height: 4),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isChief
                  ? const Color(0xFF14171B)
                  : const Color(0xFF1E2631),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(14),
                topRight: const Radius.circular(14),
                bottomLeft: Radius.circular(isChief ? 2 : 14),
                bottomRight: Radius.circular(isChief ? 14 : 2),
              ),
              border: Border.all(
                color: isChief
                    ? const Color(0xFF00E5FF).withValues(alpha: 0.3)
                    : Colors.white12,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  msg.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),

                if (msg.extractedIntent != null &&
                    msg.extractedIntent!.dealValue > 0) ...[
                  const Divider(color: Colors.white10, height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5A623).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          msg.extractedIntent!.formattedValue,
                          style: const TextStyle(
                            color: Color(0xFFF5A623),
                            fontWeight: FontWeight.bold,
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        msg.extractedIntent!.name ?? 'Lead',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],

                if (msg.suggestedAction != null) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 32,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (msg.suggestedAction == 'draft_quote') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DocumentEditorScreen(
                                docType: DocType.quotation,
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.receipt_long_rounded, size: 14),
                      label: Text(
                        msg.suggestedAction == 'draft_quote'
                            ? 'Open Quotation Editor'
                            : 'Execute Action',
                        style: const TextStyle(fontSize: 11),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E5FF),
                        foregroundColor: const Color(0xFF080B0F),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
