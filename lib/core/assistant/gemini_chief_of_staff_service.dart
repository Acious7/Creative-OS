import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../constants/document_constants.dart';
import '../database/app_database.dart';
import '../security/secure_storage_service.dart';
import '../utils/currency_formatter.dart';
import 'executive_chief_of_staff.dart';

class ChiefOfStaffMessage {
  final String sender; // 'user' or 'chief'
  final String text;
  final DateTime timestamp;
  final ExecutiveParsedIntent? extractedIntent;
  final String? suggestedAction; // 'draft_quote', 'open_whatsapp', 'view_slate'
  final dynamic actionPayload;

  const ChiefOfStaffMessage({
    required this.sender,
    required this.text,
    required this.timestamp,
    this.extractedIntent,
    this.suggestedAction,
    this.actionPayload,
  });
}

class GeminiChiefOfStaffService {
  static final SecureStorageService _secureStorage = SecureStorageService();
  static final NumberFormat _currFmt = NumberFormat('#,##0', 'en_US');

  /// Check if a Gemini API key is configured
  static Future<bool> hasApiKey() async {
    final key = await _secureStorage.getGeminiApiKey();
    return key != null && key.trim().isNotEmpty;
  }

  /// Save Gemini API key
  static Future<void> setApiKey(String key) async {
    await _secureStorage.saveGeminiApiKey(key.trim());
  }

  /// Remove Gemini API key
  static Future<void> removeApiKey() async {
    await _secureStorage.deleteGeminiApiKey();
  }

  /// Get current API key
  static Future<String?> getApiKey() async {
    return await _secureStorage.getGeminiApiKey();
  }

  /// Build live studio context from the SQLite database
  static Future<String> _buildStudioContext(AppDatabase db) async {
    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);

      // 1. Documents & Cashflow
      final docs = await db.select(db.documents).get();
      final paidThisMonth = docs
          .where(
            (d) =>
                d.docType.toLowerCase() == 'invoice' &&
                d.status.toLowerCase() == 'paid' &&
                d.issueDate.isAfter(monthStart),
          )
          .fold<double>(0.0, (acc, d) => acc + d.totalAmount);

      final overdueDocs = docs.where((d) {
        if (d.docType.toLowerCase() != 'invoice' ||
            d.status.toLowerCase() == 'paid') {
          return false;
        }
        final due = d.dueOrValidityDate;
        return due != null && due.isBefore(now);
      }).toList();

      final overdueTotal = overdueDocs.fold<double>(
        0.0,
        (acc, d) => acc + d.totalAmount,
      );

      // 2. Production Slate
      final projects = await db.select(db.productionProjects).get();
      final activeProjects = projects
          .where((p) => p.stage != 'archived')
          .toList();

      // 3. Leads & CRM
      final leads = await db.select(db.networkingLeads).get();
      final activeLeads = leads
          .where((l) => l.status != 'archived')
          .take(5)
          .toList();

      return '''
--- LIVE STUDIO STATE (${DateFormat('yyyy-MM-dd HH:mm').format(now)}) ---
- Principal: Brian Etole (Director, Commercial Cinematographer & VisualStoryteller)
- Verified Paid Revenue This Month: KES ${_currFmt.format(paidThisMonth)}
- Overdue Invoices: ${overdueDocs.length} overdue (Total outstanding: KES ${_currFmt.format(overdueTotal)})
${overdueDocs.map((d) => "  • Invoice ${d.docNumber}: KES ${_currFmt.format(d.totalAmount)} (Due ${d.dueOrValidityDate != null ? DateFormat('MMM d').format(d.dueOrValidityDate!) : 'Past due'})").join('\n')}
- Active Production Projects (${activeProjects.length}):
${activeProjects.map((p) => "  • [${p.stage.toUpperCase()}] ${p.title} (Budget: KES ${_currFmt.format(p.budgetAmount)})").join('\n')}
- Recent Active Leads:
${activeLeads.map((l) => "  • ${l.name} (${l.organization ?? 'Independent'}) - Status: ${l.status}").join('\n')}
-------------------------------------------------------------
''';
    } catch (_) {
      return '--- STUDIO CONTEXT UNAVAILABLE ---';
    }
  }

  /// Process an executive prompt using Gemini AI (with intelligent local fallback)
  static Future<ChiefOfStaffMessage> askChiefOfStaff({
    required String query,
    required AppDatabase db,
  }) async {
    final apiKey = await _secureStorage.getGeminiApiKey();

    if (apiKey != null && apiKey.trim().isNotEmpty) {
      try {
        final result = await _callGeminiApi(apiKey.trim(), query, db);
        if (result != null) return result;
      } catch (_) {
        // Fall back gracefully to offline engine
      }
    }

    // Intelligent Offline Engine
    return await _runOfflineChiefEngine(query, db);
  }

  /// Call Google Gemini REST API (gemini-1.5-flash / gemini-2.0-flash)
  static Future<ChiefOfStaffMessage?> _callGeminiApi(
    String apiKey,
    String query,
    AppDatabase db,
  ) async {
    final contextText = await _buildStudioContext(db);

    final systemInstruction =
        '''
You are Brian Etole's personal Executive Chief of Staff & Studio AI Partner inside the Etole Studio app.
Brian Etole is a premier Kenyan commercial cinematographer, director, and visual storyteller.
Currency: Kenyan Shillings (KES).
Tone: Concise, ultra-competent, loyal, executive, proactive, commercial acumen. Keep replies punchy and under 3-4 paragraphs.
You have real-time access to the studio's live state:
$contextText

INSTRUCTIONS:
1. When asked about revenue, overdue debtors, slate, or taxes, cite the exact numbers from the studio state.
2. If Brian dictates or pastes a meeting note or deal, ALWAYS extract the business intent into a JSON codeblock at the end of your response:
```json
{
  "intent": "deal_extracted",
  "name": "Contact Name",
  "organization": "Company or null",
  "dealValue": 150000,
  "serviceCategory": "Commercial Production",
  "location": "Location or null",
  "actionPromise": "Action to take",
  "targetDate": "YYYY-MM-DD",
  "stage": "pitching"
}
```
3. If Brian asks you to draft a quotation, list recommended line items with realistic rates (Director Day Rate: KES 80k-150k, RED/Arri Camera Package: KES 60k-100k, Sound Recordist: KES 35k, Color Grading: KES 50k-80k).
4. If Brian asks for a WhatsApp chaser, provide a courteous but firm Kenyan commercial reminder formatted with bold text.
''';

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
    );

    final body = jsonEncode({
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': '$systemInstruction\n\nEXECUTIVE USER: $query'},
          ],
        },
      ],
      'generationConfig': {'temperature': 0.3, 'maxOutputTokens': 1000},
    });

    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      final candidates = data['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final text =
            candidates[0]['content']['parts'][0]['text'] as String? ?? '';

        // Check for JSON block
        ExecutiveParsedIntent? parsed;
        String cleanText = text;
        final jsonRegex = RegExp(r'```json\s*(\{[\s\S]*?\})\s*```');
        final match = jsonRegex.firstMatch(text);
        if (match != null) {
          try {
            final jsonStr = match.group(1)!;
            final map = jsonDecode(jsonStr);
            if (map['intent'] == 'deal_extracted' || map['name'] != null) {
              parsed = ExecutiveParsedIntent(
                name: map['name'] as String?,
                organization: map['organization'] as String?,
                dealValue: (map['dealValue'] as num?)?.toDouble() ?? 0.0,
                serviceCategory:
                    map['serviceCategory'] as String? ??
                    'Commercial Production',
                location: map['location'] as String?,
                actionPromise: map['actionPromise'] as String?,
                targetDate: map['targetDate'] != null
                    ? DateTime.tryParse(map['targetDate'] as String)
                    : null,
              );
              cleanText = text.replaceAll(match.group(0)!, '').trim();
            }
          } catch (_) {}
        }

        return ChiefOfStaffMessage(
          sender: 'chief',
          text: cleanText,
          timestamp: DateTime.now(),
          extractedIntent: parsed,
          suggestedAction: parsed != null ? 'draft_quote' : null,
        );
      }
    }

    return null;
  }

  /// Intelligent Offline Chief of Staff Engine
  static Future<ChiefOfStaffMessage> _runOfflineChiefEngine(
    String query,
    AppDatabase db,
  ) async {
    final q = query.toLowerCase().trim();
    final now = DateTime.now();

    // 1. Briefing / Radar / Overview
    if (q.contains('briefing') ||
        q.contains('radar') ||
        q.contains('summary') ||
        q.contains('morning') ||
        q.contains('how are we doing') ||
        q.contains('status')) {
      final monthStart = DateTime(now.year, now.month, 1);
      final docs = await db.select(db.documents).get();
      final paidThisMonth = docs
          .where(
            (d) =>
                d.docType.toLowerCase() == 'invoice' &&
                d.status.toLowerCase() == 'paid' &&
                d.issueDate.isAfter(monthStart),
          )
          .fold<double>(0.0, (acc, d) => acc + d.totalAmount);

      final overdueDocs = docs.where((d) {
        if (d.docType.toLowerCase() != 'invoice' ||
            d.status.toLowerCase() == 'paid') {
          return false;
        }
        final due = d.dueOrValidityDate;
        return due != null && due.isBefore(now);
      }).toList();

      final overdueTotal = overdueDocs.fold<double>(
        0.0,
        (acc, d) => acc + d.totalAmount,
      );

      final projects = await db.select(db.productionProjects).get();
      final activeCount = projects.where((p) => p.stage != 'archived').length;

      final reply =
          '''Good day, Brian. Here is your studio intelligence briefing:

• Cashflow MTD: Verified inflow of KES ${_currFmt.format(paidThisMonth)}.
• Debtors Alert: ${overdueDocs.length} overdue invoice(s) totaling KES ${_currFmt.format(overdueTotal)}.
• Production Slate: $activeCount active project(s) across pre-production and production.
• KRA Escrow Estimate: Set aside KES ${_currFmt.format(paidThisMonth * 0.16)} for VAT and 5% WHT reserve.

All systems and background watchdogs are nominal.''';

      return ChiefOfStaffMessage(
        sender: 'chief',
        text: reply,
        timestamp: DateTime.now(),
        suggestedAction: overdueDocs.isNotEmpty ? 'open_whatsapp' : null,
      );
    }

    // 2. Overdue Invoices / Debtors
    if (q.contains('overdue') ||
        q.contains('debt') ||
        q.contains('debtor') ||
        q.contains('who owes') ||
        q.contains('unpaid')) {
      final docs = await db.select(db.documents).get();
      final overdueDocs = docs.where((d) {
        if (d.docType.toLowerCase() != 'invoice' ||
            d.status.toLowerCase() == 'paid') {
          return false;
        }
        final due = d.dueOrValidityDate;
        return due != null && due.isBefore(now);
      }).toList();

      if (overdueDocs.isEmpty) {
        return ChiefOfStaffMessage(
          sender: 'chief',
          text: 'Clean ledger, Brian! Zero overdue invoices currently on record. All billed commercial clients are up-to-date.',
          timestamp: DateTime.now(),
        );
      }

      final total = overdueDocs.fold<double>(
        0.0,
        (acc, d) => acc + d.totalAmount,
      );
      final items = overdueDocs
          .map(
            (d) =>
                '• Invoice ${d.docNumber}: KES ${_currFmt.format(d.totalAmount)} (Due ${d.dueOrValidityDate != null ? DateFormat('MMM d').format(d.dueOrValidityDate!) : 'Overdue'})',
          )
          .join('\n');

      return ChiefOfStaffMessage(
        sender: 'chief',
        text:
            'You have ${overdueDocs.length} overdue invoice(s) totaling KES ${_currFmt.format(total)}:\n\n$items\n\nWould you like me to prepare a 1-tap WhatsApp payment chaser?',
        timestamp: DateTime.now(),
        suggestedAction: 'open_whatsapp',
      );
    }

    // 3. Slate / Projects
    if (q.contains('slate') ||
        q.contains('project') ||
        q.contains('shoot') ||
        q.contains('film')) {
      final projects = await db.select(db.productionProjects).get();
      final active = projects.where((p) => p.stage != 'archived').toList();

      if (active.isEmpty) {
        return ChiefOfStaffMessage(
          sender: 'chief',
          text: 'No active shoots currently in the pipeline. Ready to pitch and slate new commercial productions.',
          timestamp: DateTime.now(),
        );
      }

      final items = active
          .map(
            (p) =>
                '• ${p.title} [${p.stage.toUpperCase()}] — Budget: KES ${_currFmt.format(p.budgetAmount)}',
          )
          .join('\n');

      return ChiefOfStaffMessage(
        sender: 'chief',
        text:
            'Here is your current Production Slate (${active.length} active):\n\n$items\n\nAll call-sheets and gear manifests are accessible under the Slate tab.',
        timestamp: DateTime.now(),
        suggestedAction: 'view_slate',
      );
    }

    // 4. Note / Deal / Voice Dictation Extraction
    final parsed = ExecutiveVoiceParser.parse(query);
    if (parsed.dealValue > 0 ||
        (parsed.name != null && parsed.name != 'New Lead')) {
      final orgStr = parsed.organization != null
          ? ' from ${parsed.organization}'
          : '';
      final valStr = parsed.dealValue > 0
          ? ' with a budget of KES ${_currFmt.format(parsed.dealValue)}'
          : '';

      final reply =
          'Captured! I have extracted commercial details for **${parsed.name}**$orgStr$valStr for ${parsed.serviceCategory}.\n\n'
          'Promise logged: "${parsed.actionPromise}" due ${DateFormat('MMM d, yyyy').format(parsed.targetDate ?? now.add(const Duration(days: 2)))}.\n\n'
          'Tap below to commit to CRM or immediately draft an official quotation.';

      return ChiefOfStaffMessage(
        sender: 'chief',
        text: reply,
        timestamp: DateTime.now(),
        extractedIntent: parsed,
        suggestedAction: 'draft_quote',
      );
    }

    // 5. Default General Executive Reply
    return ChiefOfStaffMessage(
      sender: 'chief',
      text:
          'Understood, Brian. I am monitoring your ledger, active slate, and client deliverables. '
          'You can ask me for a morning briefing, overdue debtor check, production slate status, or dictate commercial meeting notes to instantly log leads and draft quotations.\n\n'
          '💡 *Tip: Connect your free Gemini API key in the top bar to enable live conversational reasoning and proposal drafting.*',
      timestamp: DateTime.now(),
    );
  }
}
