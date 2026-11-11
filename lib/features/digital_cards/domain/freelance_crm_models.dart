import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/design_system/etole_colors.dart';

enum DealStage {
  lead,
  pitching,
  negotiating,
  won,
  lost;

  String get label {
    switch (this) {
      case DealStage.lead:
        return 'Inquiry / Lead';
      case DealStage.pitching:
        return 'Pitched / Proposal';
      case DealStage.negotiating:
        return 'Negotiation';
      case DealStage.won:
        return 'Won / Active';
      case DealStage.lost:
        return 'Archived / Lost';
    }
  }

  String get shortTag {
    switch (this) {
      case DealStage.lead:
        return 'LEAD';
      case DealStage.pitching:
        return 'PITCH';
      case DealStage.negotiating:
        return 'NEGO';
      case DealStage.won:
        return 'WON';
      case DealStage.lost:
        return 'PASS';
    }
  }

  Color get color {
    switch (this) {
      case DealStage.lead:
        return const Color(0xFF38B6DB); // Cyan
      case DealStage.pitching:
        return const Color(0xFFF59E0B); // Golden Amber
      case DealStage.negotiating:
        return const Color(0xFF8B5CF6); // Royal Violet
      case DealStage.won:
        return const Color(0xFF007A3D); // Emerald Green
      case DealStage.lost:
        return const Color(0xFF64748B); // Slate Muted
    }
  }

  IconData get icon {
    switch (this) {
      case DealStage.lead:
        return Icons.radar_outlined;
      case DealStage.pitching:
        return Icons.send_rounded;
      case DealStage.negotiating:
        return Icons.handshake_outlined;
      case DealStage.won:
        return Icons.check_circle_outline_rounded;
      case DealStage.lost:
        return Icons.archive_outlined;
    }
  }

  static DealStage fromString(String? val) {
    if (val == null) return DealStage.lead;
    final v = val.toLowerCase().trim();
    if (v == 'pitching' || v == 'pitch' || v == 'proposal')
      return DealStage.pitching;
    if (v == 'negotiating' || v == 'negotiation' || v == 'review')
      return DealStage.negotiating;
    if (v == 'won' || v == 'closed' || v == 'client') return DealStage.won;
    if (v == 'lost' || v == 'archived' || v == 'pass') return DealStage.lost;
    return DealStage.lead;
  }
}

class FreelanceDealInfo {
  final String? dealTitle;
  final double dealValue; // In KES
  final String serviceCategory;
  final bool isVip;
  final DealStage stage;
  final List<String> tags;

  const FreelanceDealInfo({
    this.dealTitle,
    this.dealValue = 0.0,
    this.serviceCategory = 'Directing & Film',
    this.isVip = false,
    this.stage = DealStage.lead,
    this.tags = const [],
  });

  static final NumberFormat _currencyFormatter = NumberFormat('#,##0', 'en_US');

  String get formattedValue => 'KES ${_currencyFormatter.format(dealValue)}';

  FreelanceDealInfo copyWith({
    String? dealTitle,
    double? dealValue,
    String? serviceCategory,
    bool? isVip,
    DealStage? stage,
    List<String>? tags,
  }) {
    return FreelanceDealInfo(
      dealTitle: dealTitle ?? this.dealTitle,
      dealValue: dealValue ?? this.dealValue,
      serviceCategory: serviceCategory ?? this.serviceCategory,
      isVip: isVip ?? this.isVip,
      stage: stage ?? this.stage,
      tags: tags ?? this.tags,
    );
  }

  static FreelanceDealInfo fromLead(NetworkingLead lead) {
    final stage = DealStage.fromString(lead.status);
    double value = 0.0;
    String? title;
    String category = 'Cinematography';
    bool vip = false;
    final List<String> extractedTags = [];

    if (lead.interestTagsJson != null &&
        lead.interestTagsJson!.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(lead.interestTagsJson!);
        if (decoded is Map<String, dynamic>) {
          if (decoded['dealValue'] != null) {
            value = (decoded['dealValue'] as num).toDouble();
          }
          title = decoded['dealTitle'] as String?;
          if (decoded['serviceCategory'] != null) {
            category = decoded['serviceCategory'] as String;
          }
          if (decoded['isVip'] == true) {
            vip = true;
          }
          if (decoded['tags'] is List) {
            extractedTags.addAll(List<String>.from(decoded['tags']));
          }
        } else if (decoded is List) {
          // Legacy list of string tags
          for (final item in decoded) {
            final str = item.toString().trim();
            if (str.toUpperCase() == 'VIP') {
              vip = true;
            } else if (str.toUpperCase().startsWith('KES')) {
              final cleaned = str.replaceAll(RegExp(r'[^\d.]'), '');
              final parsed = double.tryParse(cleaned);
              if (parsed != null) value = parsed;
            } else {
              extractedTags.add(str);
            }
          }
        }
      } catch (_) {}
    }

    // Default title if empty
    title ??= (lead.organization != null && lead.organization!.isNotEmpty)
        ? '${lead.organization} Campaign'
        : '${lead.name} Project';

    return FreelanceDealInfo(
      dealTitle: title,
      dealValue: value,
      serviceCategory: category,
      isVip: vip,
      stage: stage,
      tags: extractedTags,
    );
  }

  String toJsonString() {
    final map = {
      'dealTitle': dealTitle,
      'dealValue': dealValue,
      'serviceCategory': serviceCategory,
      'isVip': isVip,
      'tags': tags,
    };
    return jsonEncode(map);
  }
}

class FreelancePitchTemplate {
  final String title;
  final String subtitle;
  final IconData icon;
  final String Function({
    required String clientName,
    String? organization,
    String? eventLocation,
    String? notes,
  })
  generator;

  const FreelancePitchTemplate({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.generator,
  });

  static List<FreelancePitchTemplate> get allTemplates => [
    FreelancePitchTemplate(
      title: 'Post-Event Catch Up & Reel',
      subtitle: 'Warm follow-up sharing commercial portfolio',
      icon: Icons.movie_filter_outlined,
      generator: ({required clientName, organization, eventLocation, notes}) {
        final loc = (eventLocation != null && eventLocation.isNotEmpty)
            ? ' at $eventLocation'
            : '';
        final org = (organization != null && organization.isNotEmpty)
            ? ' with the team at $organization'
            : '';
        final n = (notes != null && notes.isNotEmpty)
            ? '\n\nRegarding our conversation: "$notes"'
            : '';
        return 'Hi $clientName! Really enjoyed connecting$loc$org. Brian Etole here from Brian Etole Productions (Director & Hybrid Filmmaker).$n\n\nI’d love to share our latest commercial reel and explore visual storytelling collaborations for your upcoming projects. When is a good time this week for a brief coffee or intro chat?';
      },
    ),
    FreelancePitchTemplate(
      title: 'Commercial Rate Card & Proposal Pitch',
      subtitle: 'Pitch full-package video production & directing',
      icon: Icons.request_quote_outlined,
      generator: ({required clientName, organization, eventLocation, notes}) {
        final org = (organization != null && organization.isNotEmpty)
            ? ' for $organization'
            : '';
        return 'Hello $clientName,\n\nFollowing up on our discussions regarding upcoming visual productions$org. I’ve put together our updated commercial rate guide and scope options (covering concept development, 4K/6K cinema capture, and high-end post-production).\n\nLet me know if you would like me to draft an initial scope breakdown or quotation for your review!';
      },
    ),
    FreelancePitchTemplate(
      title: 'Quotation Follow-Up & Alignment',
      subtitle: 'Check in on a drafted quotation / proposal',
      icon: Icons.fact_check_outlined,
      generator: ({required clientName, organization, eventLocation, notes}) {
        return 'Hi $clientName! Hope you’re having a fantastic week. Just touching base regarding the project quotation and scope we prepared. I’m happy to walk through any line items or tailor the production package to match your target budget. Let me know what works best!';
      },
    ),
    FreelancePitchTemplate(
      title: 'VIP Network Check-In',
      subtitle: 'Casual relationship nurturing for high-profile clients',
      icon: Icons.star_border_rounded,
      generator: ({required clientName, organization, eventLocation, notes}) {
        return 'Hi $clientName, Brian here. Saw your recent updates and wanted to say congratulations on the momentum! Would love to reconnect over a quick coffee or call soon to catch up.';
      },
    ),
  ];
}
