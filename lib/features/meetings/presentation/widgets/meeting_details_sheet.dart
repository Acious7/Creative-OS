import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_typography.dart';

class MeetingDetailsSheet extends ConsumerStatefulWidget {
  final int meetingId;

  const MeetingDetailsSheet({super.key, required this.meetingId});

  @override
  ConsumerState<MeetingDetailsSheet> createState() =>
      _MeetingDetailsSheetState();
}

class _MeetingDetailsSheetState extends ConsumerState<MeetingDetailsSheet> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;
  String? _currentlyPlayingPath;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playerState = state);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleAudio(String path) async {
    EtoleHaptics.selection();
    if (_playerState == PlayerState.playing && _currentlyPlayingPath == path) {
      await _audioPlayer.pause();
    } else {
      _currentlyPlayingPath = path;
      await _audioPlayer.play(DeviceFileSource(path));
    }
  }

  Future<void> _confirmDeleteMeeting(
    BuildContext context,
    Meeting meeting,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14171B),
        title: const Text(
          'Delete Meeting Record?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to remove "${meeting.title}"? This will move it to the trash archive.',
          style: const TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final db = ref.read(databaseProvider);
      await (db.update(db.meetings)..where((t) => t.id.equals(meeting.id)))
          .write(const MeetingsCompanion(isDeleted: drift.Value(true)));
      if (mounted) {
        Navigator.pop(context); // close details sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Meeting "${meeting.title}" deleted.'),
            action: SnackBarAction(
              label: 'Undo',
              textColor: EtoleColors.cyan,
              onPressed: () async {
                await (db.update(
                  db.meetings,
                )..where((t) => t.id.equals(meeting.id))).write(
                  const MeetingsCompanion(isDeleted: drift.Value(false)),
                );
              },
            ),
          ),
        );
      }
    }
  }

  void _showEditMeetingSheet(BuildContext context, Meeting meeting) {
    EtoleHaptics.selection();
    final titleCtrl = TextEditingController(text: meeting.title);
    final projectCtrl = TextEditingController(text: meeting.projectName ?? '');
    String type = meeting.meetingType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              color: const Color(0xFA121518),
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                24 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
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
                  Text(
                    'Edit Meeting / Brief Details',
                    style: EtoleTypography.h2.copyWith(
                      color: EtoleColors.cream,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: titleCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Meeting Title',
                      labelStyle: TextStyle(color: Color(0xFF60A5FA)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: projectCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Client or Project Name',
                      labelStyle: TextStyle(color: Color(0xFF60A5FA)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: type,
                    dropdownColor: const Color(0xFF1E242B),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Meeting Type',
                      labelStyle: TextStyle(color: Color(0xFF60A5FA)),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Pitch Alignment',
                        child: Text('Pitch Alignment'),
                      ),
                      DropdownMenuItem(
                        value: 'Pre-Production Shoot Scope',
                        child: Text('Pre-Production Shoot Scope'),
                      ),
                      DropdownMenuItem(
                        value: 'Creative Treatment Review',
                        child: Text('Creative Treatment Review'),
                      ),
                      DropdownMenuItem(
                        value: 'Budget & Contract Discussion',
                        child: Text('Budget & Contract Discussion'),
                      ),
                      DropdownMenuItem(
                        value: 'Post-Production Review',
                        child: Text('Post-Production Review'),
                      ),
                      DropdownMenuItem(
                        value: 'WhatsApp Chat',
                        child: Text('WhatsApp Chat'),
                      ),
                      DropdownMenuItem(
                        value: 'SMS Conversation',
                        child: Text('SMS Conversation'),
                      ),
                      DropdownMenuItem(
                        value: 'Phone Call',
                        child: Text('Phone Call'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => type = val);
                    },
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      if (titleCtrl.text.trim().isEmpty) return;
                      final db = ref.read(databaseProvider);
                      await (db.update(
                        db.meetings,
                      )..where((t) => t.id.equals(meeting.id))).write(
                        MeetingsCompanion(
                          title: drift.Value(titleCtrl.text.trim()),
                          projectName: drift.Value(projectCtrl.text.trim()),
                          meetingType: drift.Value(type),
                          updatedAt: drift.Value(DateTime.now()),
                        ),
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy • h:mm a');

    return StreamBuilder<Meeting>(
      stream: (db.select(
        db.meetings,
      )..where((t) => t.id.equals(widget.meetingId))).watchSingle(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF2563EB)),
          );
        }

        final meeting = snapshot.data!;

        // Parse participants
        List<String> participants = [];
        if (meeting.peopleJson != null && meeting.peopleJson!.isNotEmpty) {
          try {
            final list = jsonDecode(meeting.peopleJson!) as List<dynamic>;
            participants = list.map((e) => e.toString()).toList();
          } catch (_) {}
        }

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              color: const Color(0xFA121518),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.88,
              ),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
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
                  const SizedBox(height: 12),

                  // Top Action Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          meeting.meetingType.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF60A5FA),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: Color(0xFF60A5FA),
                              size: 20,
                            ),
                            tooltip: 'Edit Meeting',
                            onPressed: () =>
                                _showEditMeetingSheet(context, meeting),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Color(0xFFEF4444),
                              size: 20,
                            ),
                            tooltip: 'Delete Meeting',
                            onPressed: () =>
                                _confirmDeleteMeeting(context, meeting),
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
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Title & Metadata
                  Text(
                    meeting.title,
                    style: EtoleTypography.h2.copyWith(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateFormat.format(meeting.meetingDate),
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11.5,
                    ),
                  ),
                  if (meeting.locationOrLink != null &&
                      meeting.locationOrLink!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '📍 ${meeting.locationOrLink!}',
                      style: const TextStyle(
                        color: Color(0xFF60A5FA),
                        fontSize: 11,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  const EtoleHairline(),
                  const SizedBox(height: 10),

                  // Scrollable Body: Participants, Tasks, Audio, Notes
                  Expanded(
                    child: ListView(
                      children: [
                        // Participants chips
                        if (participants.isNotEmpty) ...[
                          const Text(
                            'PARTICIPANTS',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: participants
                                .map(
                                  (p) => Chip(
                                    backgroundColor: const Color(0xFF1E242B),
                                    side: BorderSide(
                                      color: Colors.white.withValues(
                                        alpha: 0.08,
                                      ),
                                    ),
                                    avatar: CircleAvatar(
                                      backgroundColor: const Color(0xFF2563EB),
                                      child: Text(
                                        p.isNotEmpty ? p[0].toUpperCase() : '?',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                    label: Text(
                                      p,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Linked Audio Recordings Stream
                        StreamBuilder<List<MeetingRecording>>(
                          stream:
                              (db.select(db.meetingRecordings)..where(
                                    (t) => t.meetingId.equals(meeting.id),
                                  ))
                                  .watch(),
                          builder: (context, recSnapshot) {
                            final recordings = recSnapshot.data ?? [];
                            if (recordings.isEmpty)
                              return const SizedBox.shrink();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'AUDIO RECORDINGS & MEMOS',
                                  style: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                ...recordings.map((rec) {
                                  final isPlaying =
                                      _playerState == PlayerState.playing &&
                                      _currentlyPlayingPath ==
                                          rec.audioFilePath;
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF19202A),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFF2563EB)
                                            .withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            isPlaying
                                                ? Icons
                                                      .pause_circle_filled_rounded
                                                : Icons
                                                      .play_circle_fill_rounded,
                                            color: const Color(0xFF60A5FA),
                                            size: 32,
                                          ),
                                          onPressed: () =>
                                              _toggleAudio(rec.audioFilePath),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Recording (${rec.durationSeconds}s)',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              Text(
                                                rec.audioFilePath
                                                    .split('/')
                                                    .last,
                                                style: const TextStyle(
                                                  color: Color(0xFF94A3B8),
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                const SizedBox(height: 14),
                              ],
                            );
                          },
                        ),

                        // Linked Tasks Stream
                        StreamBuilder<List<MeetingTask>>(
                          stream:
                              (db.select(db.meetingTasks)..where(
                                    (t) => t.meetingId.equals(meeting.id),
                                  ))
                                  .watch(),
                          builder: (context, taskSnapshot) {
                            final tasks = taskSnapshot.data ?? [];
                            if (tasks.isEmpty) return const SizedBox.shrink();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ACTION ITEMS & COMMITMENTS',
                                  style: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                ...tasks.map(
                                  (task) => Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF14171B),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.08,
                                        ),
                                      ),
                                    ),
                                    child: CheckboxListTile(
                                      value: task.isDone,
                                      activeColor: const Color(0xFF2563EB),
                                      title: Text(
                                        task.taskDescription,
                                        style: TextStyle(
                                          color: task.isDone
                                              ? const Color(0xFF64748B)
                                              : Colors.white,
                                          fontSize: 12.5,
                                          decoration: task.isDone
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                      subtitle: task.assignedBy != null
                                          ? Text(
                                              'Assigned: ${task.assignedBy!}',
                                              style: const TextStyle(
                                                color: Color(0xFF94A3B8),
                                                fontSize: 10.5,
                                              ),
                                            )
                                          : null,
                                      onChanged: (val) async {
                                        EtoleHaptics.selection();
                                        await (db.update(db.meetingTasks)
                                              ..where(
                                                (t) => t.id.equals(task.id),
                                              ))
                                            .write(
                                              MeetingTasksCompanion(
                                                isDone: drift.Value(
                                                  val ?? false,
                                                ),
                                              ),
                                            );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                              ],
                            );
                          },
                        ),

                        // Linked Notes Stream
                        StreamBuilder<List<MeetingNote>>(
                          stream:
                              (db.select(db.meetingNotes)..where(
                                    (t) => t.meetingId.equals(meeting.id),
                                  ))
                                  .watch(),
                          builder: (context, noteSnapshot) {
                            final notes = noteSnapshot.data ?? [];
                            if (notes.isEmpty) return const SizedBox.shrink();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'MINUTES, LOGS & NOTES',
                                  style: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                ...notes.map(
                                  (n) => Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF14171B),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.08,
                                        ),
                                      ),
                                    ),
                                    child: SelectableText(
                                      n.noteText,
                                      style: const TextStyle(
                                        color: Color(0xFFCBD5E1),
                                        fontSize: 12,
                                        height: 1.45,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
