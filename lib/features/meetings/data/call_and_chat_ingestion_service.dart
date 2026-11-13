import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';

/// Structured analysis result of ingested chat or call
class IngestedCommunicationMinutes {
  final String title;
  final String conversationType; // 'whatsapp', 'sms', 'phone_call'
  final String? clientOrContactName;
  final String? phoneNumber;
  final DateTime conversationDate;
  final List<String> participants;
  final String summary;
  final List<String> agreementsAndPromises;
  final List<String> actionItems;
  final String fullTranscript;

  const IngestedCommunicationMinutes({
    required this.title,
    required this.conversationType,
    this.clientOrContactName,
    this.phoneNumber,
    required this.conversationDate,
    required this.participants,
    required this.summary,
    required this.agreementsAndPromises,
    required this.actionItems,
    required this.fullTranscript,
  });
}

class CallAndChatIngestionService {
  /// Parse exported WhatsApp chat text or pasted conversation into structured meeting minutes
  static IngestedCommunicationMinutes parseWhatsAppChat(
    String rawText, {
    String? defaultProjectName,
  }) {
    final lines = rawText.split('\n');
    final participantsSet = <String>{};
    final actionItems = <String>[];
    final agreements = <String>[];
    final buffer = StringBuffer();
    DateTime conversationDate = DateTime.now();

    // Regex matching WhatsApp formats:
    // [12/04/2026, 14:30:12] Person Name: Message
    // 12/04/2026, 14:30 - Person Name: Message
    // 4/12/26, 2:30 PM - Person Name: Message
    final waRegex1 = RegExp(
      r'^\[?(\d{1,4}[-/.]\d{1,2}[-/.]\d{1,4}),?\s+(\d{1,2}:\d{2}(?::\d{2})?(?:\s*[APap][Mm])?)\]?\s*[-:]?\s*([^:]+):\s*(.*)$',
    );

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      final match = waRegex1.firstMatch(trimmed);
      if (match != null) {
        final dateStr = match.group(1);
        final author = match.group(3)?.trim() ?? 'Unknown';
        final message = match.group(4)?.trim() ?? '';

        if (!author.toLowerCase().contains('encryption') &&
            !author.toLowerCase().contains('messages and calls') &&
            author.isNotEmpty) {
          participantsSet.add(author);
        }

        buffer.writeln('$author: $message');

        _scanLineForCommitments(message, agreements, actionItems, author);
      } else {
        // Continuation line or SMS line without prefix
        buffer.writeln(trimmed);
        _scanLineForCommitments(trimmed, agreements, actionItems, 'Speaker');
      }
    }

    final participants = participantsSet.toList();
    final primaryContact = participants.firstWhere(
      (p) =>
          !p.toLowerCase().contains('brian') &&
          !p.toLowerCase().contains('me') &&
          !p.toLowerCase().contains('you'),
      orElse: () => participants.isNotEmpty ? participants.first : 'Client',
    );

    final title = defaultProjectName != null && defaultProjectName.isNotEmpty
        ? '$defaultProjectName · WhatsApp Alignment'
        : 'WhatsApp Discussion with $primaryContact';

    final summary = _buildSummary(
      type: 'WhatsApp Chat',
      contact: primaryContact,
      participants: participants,
      agreementsCount: agreements.length,
      actionCount: actionItems.length,
    );

    return IngestedCommunicationMinutes(
      title: title,
      conversationType: 'whatsapp',
      clientOrContactName: primaryContact,
      conversationDate: conversationDate,
      participants: participants,
      summary: summary,
      agreementsAndPromises: agreements,
      actionItems: actionItems,
      fullTranscript: buffer.toString(),
    );
  }

  /// Parse SMS conversation export or pasted SMS messages
  static IngestedCommunicationMinutes parseSmsThread(
    String rawText, {
    String? contactName,
    String? phoneNumber,
  }) {
    final lines = rawText.split('\n');
    final agreements = <String>[];
    final actionItems = <String>[];
    final buffer = StringBuffer();

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      buffer.writeln(trimmed);
      _scanLineForCommitments(
        trimmed,
        agreements,
        actionItems,
        contactName ?? 'Client',
      );
    }

    final contact = contactName ?? phoneNumber ?? 'Client';
    final title = 'SMS Minutes · $contact';

    final summary = _buildSummary(
      type: 'SMS Message Thread',
      contact: contact,
      participants: [contact, 'Studio Lead'],
      agreementsCount: agreements.length,
      actionCount: actionItems.length,
    );

    return IngestedCommunicationMinutes(
      title: title,
      conversationType: 'sms',
      clientOrContactName: contact,
      phoneNumber: phoneNumber,
      conversationDate: DateTime.now(),
      participants: [contact, 'Studio Lead'],
      summary: summary,
      agreementsAndPromises: agreements,
      actionItems: actionItems,
      fullTranscript: buffer.toString(),
    );
  }

  /// Create Meeting Minutes from a recorded Phone Call
  static IngestedCommunicationMinutes buildPhoneCallMinutes({
    required String contactName,
    required String phoneNumber,
    required String callDirection, // 'Incoming' or 'Outgoing'
    required int durationSeconds,
    required String recapNotes,
    String? audioFilePath,
  }) {
    final durationStr = durationSeconds > 0
        ? '${durationSeconds ~/ 60}m ${durationSeconds % 60}s'
        : 'Brief Call';

    final agreements = <String>[];
    final actionItems = <String>[];

    final lines = recapNotes.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      _scanLineForCommitments(trimmed, agreements, actionItems, contactName);
    }

    final title = 'Phone Call · $contactName ($callDirection)';
    final summary =
        '$callDirection phone call with $contactName ($phoneNumber), lasting $durationStr. '
        'Key discussion captured directly into executive studio minutes.';

    return IngestedCommunicationMinutes(
      title: title,
      conversationType: 'phone_call',
      clientOrContactName: contactName,
      phoneNumber: phoneNumber,
      conversationDate: DateTime.now(),
      participants: [contactName, 'Studio Lead'],
      summary: summary,
      agreementsAndPromises: agreements,
      actionItems: actionItems,
      fullTranscript: recapNotes,
    );
  }

  /// Commit the ingested communication into official database tables
  static Future<int> saveToDatabase({
    required AppDatabase db,
    required IngestedCommunicationMinutes minutes,
    String? audioPath,
    int? audioDurationSeconds,
  }) async {
    // 1. Insert into Meetings table
    final meetingId = await db
        .into(db.meetings)
        .insert(
          MeetingsCompanion(
            title: drift.Value(minutes.title),
            meetingDate: drift.Value(minutes.conversationDate),
            meetingType: drift.Value(
              minutes.conversationType == 'whatsapp'
                  ? 'WhatsApp Chat'
                  : minutes.conversationType == 'sms'
                  ? 'SMS Conversation'
                  : 'Phone Call',
            ),
            projectName: drift.Value(minutes.clientOrContactName),
            locationOrLink: drift.Value(
              minutes.phoneNumber != null
                  ? 'Tel: ${minutes.phoneNumber}'
                  : minutes.conversationType.toUpperCase(),
            ),
            peopleJson: drift.Value(jsonEncode(minutes.participants)),
            consentNoted: const drift.Value(true),
            isCompleted: const drift.Value(true),
            isDeleted: const drift.Value(false),
          ),
        );

    // 2. Insert Meeting Note with summary & full transcript
    final noteContent = StringBuffer();
    noteContent.writeln('📋 EXECUTIVE SUMMARY:');
    noteContent.writeln(minutes.summary);
    if (minutes.agreementsAndPromises.isNotEmpty) {
      noteContent.writeln('\n🤝 AGREED TERMS & COMMITMENTS:');
      for (final a in minutes.agreementsAndPromises) {
        noteContent.writeln('• $a');
      }
    }
    if (minutes.fullTranscript.isNotEmpty) {
      noteContent.writeln('\n📝 CONVERSATION LOG:');
      noteContent.writeln(minutes.fullTranscript);
    }

    await db
        .into(db.meetingNotes)
        .insert(
          MeetingNotesCompanion(
            meetingId: drift.Value(meetingId),
            timestampMs: const drift.Value(0),
            noteText: drift.Value(noteContent.toString()),
          ),
        );

    // 3. Insert Meeting Tasks for each detected action item
    for (final task in minutes.actionItems) {
      await db
          .into(db.meetingTasks)
          .insert(
            MeetingTasksCompanion(
              meetingId: drift.Value(meetingId),
              taskDescription: drift.Value(task),
              assignedBy: drift.Value(minutes.clientOrContactName ?? 'Client'),
              projectName: drift.Value(minutes.clientOrContactName),
              isDone: const drift.Value(false),
            ),
          );
    }

    // 4. Attach audio recording if provided
    if (audioPath != null && audioPath.isNotEmpty) {
      await db
          .into(db.meetingRecordings)
          .insert(
            MeetingRecordingsCompanion(
              meetingId: drift.Value(meetingId),
              audioFilePath: drift.Value(audioPath),
              durationSeconds: drift.Value(audioDurationSeconds ?? 0),
              isTranscribed: const drift.Value(false),
            ),
          );
    }

    return meetingId;
  }

  // --- Internal NLP heuristics for Kenyan/East African commercial video production ---

  static void _scanLineForCommitments(
    String line,
    List<String> agreements,
    List<String> actionItems,
    String author,
  ) {
    final lower = line.toLowerCase();

    // Check for financial commitments or rate agreements
    if (lower.contains('kes') ||
        lower.contains('ksh') ||
        lower.contains('rate') ||
        lower.contains('budget') ||
        lower.contains('deposit') ||
        lower.contains('quote') ||
        lower.contains('price') ||
        lower.contains('advance') ||
        lower.contains('agreed') ||
        lower.contains('deal') ||
        lower.contains('approved')) {
      agreements.add('[$author] $line');
    }

    // Check for deliverables / dates
    if (lower.contains('shoot date') ||
        lower.contains('deadline') ||
        lower.contains('delivery') ||
        lower.contains('deliver by') ||
        lower.contains('location') ||
        lower.contains('call sheet')) {
      agreements.add('[$author] $line');
    }

    // Check for action items
    if (lower.startsWith('please') ||
        lower.contains('send me') ||
        lower.contains('will send') ||
        lower.contains('will prepare') ||
        lower.contains('i will') ||
        lower.contains('we will') ||
        lower.contains('let me know') ||
        lower.contains('follow up') ||
        lower.contains('check on') ||
        lower.contains('invoice me') ||
        lower.contains('share the') ||
        lower.contains('book')) {
      actionItems.add('[$author] $line');
    }
  }

  static String _buildSummary({
    required String type,
    required String contact,
    required List<String> participants,
    required int agreementsCount,
    required int actionCount,
  }) {
    final participantStr = participants.isNotEmpty
        ? participants.join(', ')
        : contact;
    return '$type ingested involving $participantStr. Identified $agreementsCount deal terms/promises and $actionCount actionable follow-up items for executive production tracking.';
  }
}
