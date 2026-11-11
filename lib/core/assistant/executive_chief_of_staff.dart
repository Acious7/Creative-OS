import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/app_database.dart';
import '../../features/digital_cards/domain/freelance_crm_models.dart';

class ExecutiveParsedIntent {
  final String? name;
  final String? organization;
  final double dealValue;
  final String serviceCategory;
  final String? location;
  final String? actionPromise;
  final DateTime? targetDate;
  final DealStage stage;

  const ExecutiveParsedIntent({
    this.name,
    this.organization,
    this.dealValue = 0.0,
    this.serviceCategory = 'Commercial Production',
    this.location,
    this.actionPromise,
    this.targetDate,
    this.stage = DealStage.pitching,
  });

  static final NumberFormat _currencyFormat = NumberFormat('#,##0', 'en_US');
  String get formattedValue => 'KES ${_currencyFormat.format(dealValue)}';
}

class ExecutiveVoiceParser {
  static const Set<String> _stopWords = {
    'had',
    'coffee',
    'met',
    'with',
    'called',
    'spoke',
    'talking',
    'talked',
    'meeting',
    'client',
    'wants',
    'pitched',
    'agreed',
    'the',
    'a',
    'an',
    'to',
    'from',
    'at',
    'in',
    'for',
    'i',
    'we',
  };

  /// Parses unstructured executive voice dictations or notes into structured business actions
  static ExecutiveParsedIntent parse(String rawText) {
    final text = rawText.trim();
    if (text.isEmpty) return const ExecutiveParsedIntent();

    // 1. Extract Monetary Value (KES, k, m, million, thousand, 500k, 1.2M, etc.)
    double value = 0.0;
    final valueRegex = RegExp(
      r'(?:(?:kes|ksh|sh|budget|worth|for|deal of)\s*)?([0-9]+(?:\.[0-9]+)?)\s*(k|m|million|thousand|bob)?\b',
      caseSensitive: false,
    );

    for (final match in valueRegex.allMatches(text)) {
      final numStr = match.group(1);
      final multiplier = match.group(2)?.toLowerCase();
      if (numStr != null) {
        double parsed = double.tryParse(numStr) ?? 0.0;
        // Don't treat tiny numbers (like "3" in 3-part) as currency unless tagged with k/m/kes
        final fullMatch = match.group(0)!.toLowerCase();
        final hasCurrencyCue =
            fullMatch.contains('kes') ||
            fullMatch.contains('ksh') ||
            fullMatch.contains('sh') ||
            fullMatch.contains('budget') ||
            multiplier != null;

        if (multiplier == 'm' || multiplier == 'million') {
          parsed *= 1000000;
        } else if (multiplier == 'k' || multiplier == 'thousand') {
          parsed *= 1000;
        }

        if (hasCurrencyCue && parsed > value) {
          value = parsed;
        }
      }
    }

    if (value == 0.0) {
      // Direct number check with commas (e.g. 850,000)
      final directNumRegex = RegExp(r'\b([0-9]{1,3}(?:,[0-9]{3})+)\b');
      final directMatch = directNumRegex.firstMatch(text);
      if (directMatch != null) {
        final clean = directMatch.group(1)!.replaceAll(',', '');
        value = double.tryParse(clean) ?? 0.0;
      }
    }

    // 2. Extract Person & Organization Name
    String? name;
    String? org;

    // Pattern A: "with [Name] from [Org]" or "met [Name] at [Org]" (case-insensitive)
    final withFromRegex = RegExp(
      r'(?:with|met|called|talking to|talked to|spoke with|meeting with)\s+([A-Za-z]+(?:\s+[A-Za-z]+)?)\s+(?:from|at|of)\s+([A-Za-z0-9\s&]+?)(?:\s+(?:at|for|wants|in|regarding|\.|$))',
      caseSensitive: false,
    );
    final matchWithFrom = withFromRegex.firstMatch(text);
    if (matchWithFrom != null) {
      name = _capitalize(matchWithFrom.group(1)?.trim());
      org = _capitalize(matchWithFrom.group(2)?.trim());
    } else {
      // Pattern B: Just "with [Name]" or "met [Name]"
      final withRegex = RegExp(
        r'(?:with|met|called|talking to|talked to|spoke with|meeting with)\s+([A-Za-z]+(?:\s+[A-Za-z]+)?)',
        caseSensitive: false,
      );
      final matchWith = withRegex.firstMatch(text);
      if (matchWith != null) {
        name = _capitalize(matchWith.group(1)?.trim());
      }
    }

    // Check for explicit org words like "Safaricom", "EABL", "KCB", "Coca Cola", "Ogilvy"
    final orgKeywords = [
      'safaricom',
      'eabl',
      'east african breweries',
      'kcb',
      'equity',
      'ogilvy',
      'standard media',
      'nation',
      'coca cola',
      'airtel',
      'stanbic',
      'red cross',
      'unicef',
      'undp',
      'ncba',
      'britam',
    ];
    final lowerText = text.toLowerCase();
    for (final kw in orgKeywords) {
      if (lowerText.contains(kw)) {
        org = _capitalize(kw);
        break;
      }
    }

    // Filter out stop words from name
    if (name != null) {
      final nameParts = name.split(' ');
      if (nameParts.every((p) => _stopWords.contains(p.toLowerCase()))) {
        name = null;
      }
    }

    // Fallback name if none found: look for capitalized words
    if (name == null) {
      final capRegex = RegExp(r'\b[A-Z][a-z]+\b');
      final caps = capRegex
          .allMatches(text)
          .map((m) => m.group(0)!)
          .where((w) => !_stopWords.contains(w.toLowerCase()))
          .toList();
      if (caps.isNotEmpty) {
        name = caps.take(2).join(' ');
      }
    }

    // 3. Extract Service Category
    String category = 'Commercial Production';
    if (lowerText.contains('doc') || lowerText.contains('documentary')) {
      category = 'Documentary Production';
    } else if (lowerText.contains('commercial') ||
        lowerText.contains('ad ') ||
        lowerText.contains('campaign')) {
      category = 'Commercial Cinematography';
    } else if (lowerText.contains('directing') ||
        lowerText.contains('director')) {
      category = 'Directing & Film';
    } else if (lowerText.contains('photo') ||
        lowerText.contains('photoshoot')) {
      category = 'Still Photography';
    } else if (lowerText.contains('color') ||
        lowerText.contains('post') ||
        lowerText.contains('edit')) {
      category = 'Post & Color Grading';
    } else if (lowerText.contains('music video') || lowerText.contains('mv')) {
      category = 'Music Video Production';
    }

    // 4. Extract Location
    String? location;
    final locRegex = RegExp(
      r'(?:at|in)\s+([A-Za-z\s]+?)(?:\s+(?:hotel|restaurant|centre|mall|street|building|sarit|serena|westgate|cbd|nairobi|karen|kilimani))',
      caseSensitive: false,
    );
    final locMatch = locRegex.firstMatch(text);
    if (locMatch != null) {
      location = _capitalize(locMatch.group(0)!.trim());
    } else {
      // Check popular Nairobi locations
      for (final loc in [
        'sarit',
        'serena',
        'westgate',
        'cbd',
        'karen',
        'kilimani',
        'westlands',
        'village market',
        'two rivers',
        'yaya',
        'nairobi',
      ]) {
        if (lowerText.contains(loc)) {
          location = _capitalize(loc);
          break;
        }
      }
    }

    // 5. Extract Promise / Action Item
    String? action;
    if (lowerText.contains('send quote') ||
        lowerText.contains('send quotation') ||
        lowerText.contains('quote by') ||
        lowerText.contains('quotation by')) {
      action = 'Send project quotation & commercial scope';
    } else if (lowerText.contains('follow up') ||
        lowerText.contains('check in') ||
        lowerText.contains('call back')) {
      action = 'Follow up with alignment check';
    } else if (lowerText.contains('moodboard') ||
        lowerText.contains('treatment') ||
        lowerText.contains('pitch deck')) {
      action = 'Deliver creative treatment & visual moodboard';
    } else if (lowerText.contains('call') ||
        lowerText.contains('meeting') ||
        lowerText.contains('zoom')) {
      action = 'Schedule alignment call';
    } else if (lowerText.contains('contract') ||
        lowerText.contains('agreement')) {
      action = 'Draft and send creative service contract';
    }

    // 6. Target Date Parsing
    DateTime? targetDate;
    final now = DateTime.now();
    if (lowerText.contains('tomorrow')) {
      targetDate = now.add(const Duration(days: 1));
    } else if (lowerText.contains('friday')) {
      final daysUntilFriday = (DateTime.friday - now.weekday + 7) % 7;
      targetDate = now.add(
        Duration(days: daysUntilFriday == 0 ? 7 : daysUntilFriday),
      );
    } else if (lowerText.contains('monday')) {
      final daysUntilMonday = (DateTime.monday - now.weekday + 7) % 7;
      targetDate = now.add(
        Duration(days: daysUntilMonday == 0 ? 7 : daysUntilMonday),
      );
    } else if (lowerText.contains('next week')) {
      targetDate = now.add(const Duration(days: 7));
    } else if (lowerText.contains('next month')) {
      targetDate = DateTime(now.year, now.month + 1, 1);
    }

    return ExecutiveParsedIntent(
      name: name ?? (value > 0 ? 'Commercial Lead' : 'New Contact'),
      organization: org,
      dealValue: value,
      serviceCategory: category,
      location: location,
      actionPromise: action ?? 'Review notes and align project scope',
      targetDate: targetDate ?? now.add(const Duration(days: 2)),
      stage: value > 0 ? DealStage.pitching : DealStage.lead,
    );
  }

  static String _capitalize(String? s) {
    if (s == null || s.isEmpty) return '';
    return s
        .split(' ')
        .map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }
}
