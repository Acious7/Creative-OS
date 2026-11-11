import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../../../../core/notifications/local_notification_service.dart';
import 'transcript_test_screen.dart';
import '../widgets/import_chat_sheet.dart';
import '../widgets/meeting_details_sheet.dart';

class MeetingsHubScreen extends ConsumerStatefulWidget {
  const MeetingsHubScreen({super.key});

  @override
  ConsumerState<MeetingsHubScreen> createState() => _MeetingsHubScreenState();
}

class _MeetingsHubScreenState extends ConsumerState<MeetingsHubScreen> {
  int _selectedFilter =
      0; // 0: All, 1: Pitch Briefs, 2: Production Alignments, 3: Completed

  void _showNewMeetingSheet(BuildContext context) {
    EtoleHaptics.selection();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NewMeetingBottomSheet(),
    );
  }

  void _showImportChatSheet(BuildContext context) {
    EtoleHaptics.selection();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ImportChatSheet(),
    );
  }

  void _showMeetingDetails(Meeting meeting) {
    EtoleHaptics.selection();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MeetingDetailsSheet(meetingId: meeting.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF080B0F),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Executive Top Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  // Reserve clearance for WorldContainer's floating < HUB pill
                  const SizedBox(width: 82),

                  // Brand & Module Title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MEETINGS & MEMORY',
                          style: EtoleTypography.h2.copyWith(
                            color: EtoleColors.cream,
                            letterSpacing: 2.2,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'Briefs, Decision Logs & Audio Memos',
                          style: TextStyle(
                            color: Color(0xFF2563EB),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Import WhatsApp / Call Button
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366)
                          .withValues(alpha: 0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(
                      Icons.contact_phone_rounded,
                      color: Color(0xFF25D366),
                      size: 18,
                    ),
                    tooltip: 'Record Call or Import Chat',
                    onPressed: () => _showImportChatSheet(context),
                  ),
                  const SizedBox(width: 8),

                  // New Meeting Brief Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => _showNewMeetingSheet(context),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text(
                      'New Brief',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Audio & Speech Intelligence Hero Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF12161F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  border: Border.all(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                    width: 1.1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Icon(
                        Icons.graphic_eq_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SPEECH & TRANSCRIPTION LAB',
                            style: TextStyle(
                              color: Color(0xFF93C5FD),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'On-Device Audio & Transcription Test Lab',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: const Size(0, 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        EtoleHaptics.selection();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TranscriptTestScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Open Lab',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 6),

            // 3. Filter Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildFilterTab(0, 'All Briefs'),
                  const SizedBox(width: 6),
                  _buildFilterTab(1, 'Pitch Briefs'),
                  const SizedBox(width: 6),
                  _buildFilterTab(2, 'Production Alignments'),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // 4. Live Meetings Stream
            Expanded(
              child: StreamBuilder<List<Meeting>>(
                stream:
                    (db.select(db.meetings)
                          ..where((t) => t.isDeleted.equals(false))
                          ..orderBy([
                            (t) => drift.OrderingTerm.desc(t.meetingDate),
                          ]))
                        .watch(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2563EB),
                      ),
                    );
                  }

                  final meetings = snapshot.data ?? [];

                  if (meetings.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.forum_outlined,
                            size: 48,
                            color: const Color(0xFF2563EB)
                                .withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No Meeting Briefs Logged',
                            style: EtoleTypography.h3.copyWith(
                              color: EtoleColors.cream,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Log creative briefs, pre-pro alignments, or client agreements.',
                            style: EtoleTypography.bodySmall(
                              color: EtoleColors.creamMuted,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () => _showNewMeetingSheet(context),
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text(
                              'Log First Brief',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    itemCount: meetings.length,
                    itemBuilder: (context, index) {
                      final meeting = meetings[index];
                      return _buildMeetingTile(meeting);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(int index, String label) {
    final isSelected = _selectedFilter == index;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        EtoleHaptics.light();
        setState(() => _selectedFilter = index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2563EB).withValues(alpha: 0.22)
              : const Color(0xFF13171B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB)
                : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 1.2 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : EtoleColors.creamSecondary,
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMeetingTile(Meeting meeting) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF14171B),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(10),
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        ),
        border: Border.all(
          color: const Color(0xFF2563EB).withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(10),
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(10),
          ),
          onTap: () => _showMeetingDetails(meeting),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        meeting.meetingType.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF60A5FA),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          dateFormat.format(meeting.meetingDate),
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 10.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF64748B),
                          size: 16,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  meeting.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (meeting.projectName != null &&
                    meeting.projectName!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    meeting.projectName!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NewMeetingBottomSheet extends ConsumerStatefulWidget {
  const _NewMeetingBottomSheet();

  @override
  ConsumerState<_NewMeetingBottomSheet> createState() =>
      _NewMeetingBottomSheetState();
}

class _NewMeetingBottomSheetState
    extends ConsumerState<_NewMeetingBottomSheet> {
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  String _meetingType = 'Pitch Alignment';

  static const List<String> _types = [
    'Pitch Alignment',
    'Pre-Production Shoot Scope',
    'Creative Treatment Review',
    'Budget & Contract Discussion',
    'Post-Production Review',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) return;
    final db = ref.read(databaseProvider);

    final newId = await db
        .into(db.meetings)
        .insert(
          MeetingsCompanion(
            title: drift.Value(_titleController.text.trim()),
            meetingType: drift.Value(_meetingType),
            projectName: drift.Value(
              _summaryController.text.trim().isNotEmpty
                  ? _summaryController.text.trim()
                  : null,
            ),
            meetingDate: drift.Value(DateTime.now()),
          ),
        );

    // Schedule automated post-meeting action item dispatch 1 hour after meeting
    await LocalNotificationService.schedulePostMeetingFollowUp(
      meetingId: newId,
      meetingTitle: _titleController.text.trim(),
      followUpTime: DateTime.now().add(const Duration(hours: 1)),
    );

    if (mounted) Navigator.pop(context);
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
                color: const Color(0xFF2563EB).withValues(alpha: 0.4),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Log Meeting / Creative Brief',
                      style: EtoleTypography.h2.copyWith(
                        color: EtoleColors.cream,
                        fontSize: 18,
                      ),
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
                const SizedBox(height: 16),
                Text(
                  'Brief Category',
                  style: EtoleTypography.labelSmall.copyWith(
                    color: EtoleColors.creamMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF191D22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _meetingType,
                      dropdownColor: const Color(0xFF191D22),
                      isExpanded: true,
                      style: const TextStyle(
                        color: EtoleColors.cream,
                        fontSize: 13,
                      ),
                      onChanged: (val) {
                        if (val != null) setState(() => _meetingType = val);
                      },
                      items: _types
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Brief Title',
                  style: EtoleTypography.labelSmall.copyWith(
                    color: EtoleColors.creamMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF191D22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: TextField(
                    controller: _titleController,
                    style: const TextStyle(
                      color: EtoleColors.cream,
                      fontSize: 14,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'e.g. Netflix Doc Pre-Production Alignment',
                      hintStyle: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Key Decisions & Summary',
                  style: EtoleTypography.labelSmall.copyWith(
                    color: EtoleColors.creamMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF191D22),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: TextField(
                    controller: _summaryController,
                    maxLines: 3,
                    style: const TextStyle(
                      color: EtoleColors.cream,
                      fontSize: 14,
                    ),
                    decoration: const InputDecoration(
                      hintText:
                          'Key deliverables, shoot dates, client promises...',
                      hintStyle: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _save,
                  child: const Text(
                    'Save Creative Brief',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
