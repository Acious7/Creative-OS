import '../../../../core/database/app_database.dart';

class EmailSignatureResult {
  final String htmlSignature;
  final String plainTextSignature;
  final bool hasHostedLogo;

  EmailSignatureResult({
    required this.htmlSignature,
    required this.plainTextSignature,
    required this.hasHostedLogo,
  });
}

class EmailSignatureBuilder {
  static EmailSignatureResult buildSignature({
    required BusinessCard card,
    required Brand brand,
    String? customHostedLogoUrl,
  }) {
    final primaryColor = card.accentColorOverride ?? brand.accentColorHex;
    final logoUrl =
        (customHostedLogoUrl != null && customHostedLogoUrl.isNotEmpty)
        ? customHostedLogoUrl
        : (card.hostedLogoUrl != null && card.hostedLogoUrl!.isNotEmpty)
        ? card.hostedLogoUrl
        : null;

    final company = card.companyName ?? brand.name;
    final role = card.personRole ?? 'Creative Professional';

    // HTML Signature
    final sbHtml = StringBuffer();
    sbHtml.writeln(
      '<table cellpadding="0" cellspacing="0" border="0" style="font-family: Arial, sans-serif; font-size: 13px; color: #333333; line-height: 1.4;">',
    );
    sbHtml.writeln('  <tr>');
    if (logoUrl != null) {
      sbHtml.writeln('    <td valign="top" style="padding-right: 15px;">');
      sbHtml.writeln(
        '      <img src="$logoUrl" alt="$company Logo" width="80" style="width: 80px; max-width: 80px; height: auto; border: 0; display: block;" />',
      );
      sbHtml.writeln('    </td>');
      sbHtml.writeln(
        '    <td valign="top" style="border-left: 2px solid $primaryColor; padding-left: 15px;">',
      );
    } else {
      sbHtml.writeln(
        '    <td valign="top" style="border-left: 3px solid $primaryColor; padding-left: 12px;">',
      );
    }

    sbHtml.writeln(
      '      <div style="font-weight: bold; font-size: 15px; color: #111111;">${card.personName}</div>',
    );
    sbHtml.writeln(
      '      <div style="font-size: 12px; color: $primaryColor; font-weight: bold;">$role &bull; $company</div>',
    );

    if (card.tagline != null && card.tagline!.isNotEmpty) {
      sbHtml.writeln(
        '      <div style="font-size: 11px; color: #666666; font-style: italic; margin-top: 2px;">${card.tagline}</div>',
      );
    }

    sbHtml.writeln('      <div style="margin-top: 8px; font-size: 12px;">');
    if (card.primaryPhone != null && card.primaryPhone!.isNotEmpty) {
      sbHtml.writeln(
        '        <span style="color: #666666;">Phone:</span> <a href="tel:${card.primaryPhone}" style="color: #333333; text-decoration: none;">${card.primaryPhone}</a> &nbsp;|&nbsp; ',
      );
    }
    if (card.email != null && card.email!.isNotEmpty) {
      sbHtml.writeln(
        '        <span style="color: #666666;">Email:</span> <a href="mailto:${card.email}" style="color: $primaryColor; text-decoration: none;">${card.email}</a>',
      );
    }
    sbHtml.writeln('      </div>');

    if (card.website != null && card.website!.isNotEmpty) {
      final cleanWeb = card.website!.replaceFirst(RegExp(r'https?://'), '');
      sbHtml.writeln('      <div style="font-size: 12px;">');
      sbHtml.writeln(
        '        <span style="color: #666666;">Web:</span> <a href="${_cleanUrl(card.website!)}" style="color: $primaryColor; text-decoration: none; font-weight: bold;">$cleanWeb</a>',
      );
      sbHtml.writeln('      </div>');
    }

    if (card.showreelUrl != null && card.showreelUrl!.isNotEmpty) {
      sbHtml.writeln('      <div style="margin-top: 6px; font-size: 11px;">');
      sbHtml.writeln(
        '        <a href="${_cleanUrl(card.showreelUrl!)}" style="background-color: $primaryColor; color: #ffffff; padding: 3px 8px; text-decoration: none; border-radius: 3px; font-weight: bold; display: inline-block;">Watch Showreel &rarr;</a>',
      );
      sbHtml.writeln('      </div>');
    }

    sbHtml.writeln('    </td>');
    sbHtml.writeln('  </tr>');
    sbHtml.writeln('</table>');

    // Plain Text Signature
    final sbPlain = StringBuffer();
    sbPlain.writeln('${card.personName}');
    sbPlain.writeln('$role | $company');
    if (card.tagline != null && card.tagline!.isNotEmpty) {
      sbPlain.writeln('${card.tagline}');
    }
    sbPlain.writeln('---');
    if (card.primaryPhone != null)
      sbPlain.writeln('Phone: ${card.primaryPhone}');
    if (card.email != null) sbPlain.writeln('Email: ${card.email}');
    if (card.website != null) sbPlain.writeln('Web: ${card.website}');
    if (card.showreelUrl != null)
      sbPlain.writeln('Showreel: ${card.showreelUrl}');

    return EmailSignatureResult(
      htmlSignature: sbHtml.toString(),
      plainTextSignature: sbPlain.toString(),
      hasHostedLogo: logoUrl != null,
    );
  }

  static String _cleanUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return 'https://$url';
  }
}
