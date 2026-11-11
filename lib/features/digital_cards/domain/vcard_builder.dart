import 'dart:convert';

import '../../../../core/database/app_database.dart';

class VCardBuildResult {
  final String vCardString;
  final int byteSize;
  final List<String> dropRecommendations;
  final bool fitsNtag213;
  final bool fitsNtag215;
  final bool fitsNtag216;

  VCardBuildResult({
    required this.vCardString,
    required this.byteSize,
    required this.dropRecommendations,
    required this.fitsNtag213,
    required this.fitsNtag215,
    required this.fitsNtag216,
  });
}

class VCardBuilder {
  static VCardBuildResult buildVCard(
    BusinessCard card, {
    bool compactForNfc = false,
  }) {
    final nameParts = card.personName.trim().split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : card.personName;
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    final sb = StringBuffer();
    sb.writeln('BEGIN:VCARD');
    sb.writeln('VERSION:3.0');
    sb.writeln('N:$lastName;$firstName;;;');
    sb.writeln('FN:${card.personName}');

    if (card.companyName != null && card.companyName!.isNotEmpty) {
      sb.writeln('ORG:${card.companyName}');
    }
    if (card.personRole != null && card.personRole!.isNotEmpty) {
      sb.writeln('TITLE:${card.personRole}');
    }

    if (card.primaryPhone != null && card.primaryPhone!.isNotEmpty) {
      sb.writeln('TEL;TYPE=CELL:${card.primaryPhone}');
    }
    if (!compactForNfc &&
        card.secondaryPhone != null &&
        card.secondaryPhone!.isNotEmpty) {
      sb.writeln('TEL;TYPE=WORK:${card.secondaryPhone}');
    }

    if (card.email != null && card.email!.isNotEmpty) {
      sb.writeln('EMAIL;TYPE=INTERNET:${card.email}');
    }

    if (card.website != null && card.website!.isNotEmpty) {
      sb.writeln('URL:${_cleanUrl(card.website!)}');
    }

    if (!compactForNfc) {
      if (card.showreelUrl != null && card.showreelUrl!.isNotEmpty) {
        sb.writeln('URL;TYPE=SHOWREEL:${_cleanUrl(card.showreelUrl!)}');
      }
      if (card.portfolioUrl != null && card.portfolioUrl!.isNotEmpty) {
        sb.writeln('URL;TYPE=PORTFOLIO:${_cleanUrl(card.portfolioUrl!)}');
      }
      if (card.address != null && card.address!.isNotEmpty) {
        sb.writeln('ADR:;;${card.address};;;;');
      }
      if (card.tagline != null && card.tagline!.isNotEmpty) {
        sb.writeln('NOTE:${card.tagline}');
      }
    }

    sb.writeln('END:VCARD');

    final vCardStr = sb.toString();
    final bytes = utf8.encode(vCardStr).length;

    final recommendations = <String>[];
    if (bytes > 144) {
      if (card.address != null && card.address!.isNotEmpty)
        recommendations.add('Remove postal address');
      if (card.tagline != null && card.tagline!.isNotEmpty)
        recommendations.add('Remove tagline / note');
      if (card.secondaryPhone != null && card.secondaryPhone!.isNotEmpty)
        recommendations.add('Remove secondary phone');
      if (card.showreelUrl != null && card.showreelUrl!.isNotEmpty)
        recommendations.add('Use NFC URL mode instead of vCard');
    }

    return VCardBuildResult(
      vCardString: vCardStr,
      byteSize: bytes,
      dropRecommendations: recommendations,
      fitsNtag213: bytes <= 144,
      fitsNtag215: bytes <= 504,
      fitsNtag216: bytes <= 888,
    );
  }

  static String _cleanUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return 'https://$url';
  }
}
