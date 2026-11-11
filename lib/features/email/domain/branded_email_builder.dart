import '../../brands/domain/brand_social_links.dart';

enum EmailTheme {
  cinemaSlate, // Option 1: Dark Cinema Slate (High contrast, cinematic header/footer)
  editorialGallery, // Option 2: Editorial Gallery (Warm minimal letterhead, understated luxury)
}

class BrandedEmailContent {
  final String html;
  final String plainText;

  BrandedEmailContent({required this.html, required this.plainText});
}

class BrandedEmailBuilder {
  static const String siteUrl = 'https://brianetole.com';
  static const String emailAssetsUrl = 'https://brianetole.com/email';

  /// Builds a fully-responsive, email-client-compatible HTML and plain-text email
  static BrandedEmailContent buildEmail({
    EmailTheme theme = EmailTheme.editorialGallery,
    required String recipientName,
    required String recipientEmail,
    required String heading,
    required String messageHtml,
    required String messagePlainText,
    String? clientName, // e.g. "Acme Studios"
    String? docDate, // e.g. "26 Oct 2026"
    String?
    docType, // e.g. "INVOICE", "QUOTATION", "RECEIPT", "CONTRACT", "RATE CARD"
    String? docNumber, // e.g. "BE-INV-2026-004"
    String? docAmount, // e.g. "KES 85,000.00"
    String? docDueDate, // e.g. "15 Nov 2026"
    String? statusLabel, // e.g. "Payment due 15 Nov"
    Map<String, String>?
    paymentDetails, // e.g. {"M-Pesa Buy Goods": "987 654", "Bank Name": "..."}
    bool hasPdfAttachment = true,
    bool hasCustomLogo = false,
    BrandSocialLinks? socialLinks,
  }) {
    final plainText = _buildPlainText(
      recipientName: recipientName,
      messagePlainText: messagePlainText,
      docType: docType,
      docNumber: docNumber,
      docAmount: docAmount,
      docDueDate: docDueDate,
      statusLabel: statusLabel,
      paymentDetails: paymentDetails,
      hasPdfAttachment: hasPdfAttachment,
      socialLinks: socialLinks,
    );

    final html = (theme == EmailTheme.cinemaSlate)
        ? _buildCinemaSlateHtml(
            recipientName: recipientName,
            heading: heading,
            messageHtml: messageHtml,
            docType: docType,
            docNumber: docNumber,
            docAmount: docAmount,
            docDueDate: docDueDate,
            statusLabel: statusLabel,
            paymentDetails: paymentDetails,
            hasPdfAttachment: hasPdfAttachment,
            hasCustomLogo: hasCustomLogo,
            socialLinks: socialLinks,
          )
        : _buildEditorialGalleryHtml(
            recipientName: recipientName,
            heading: heading,
            messageHtml: messageHtml,
            clientName: clientName,
            docDate: docDate,
            docType: docType,
            docNumber: docNumber,
            docAmount: docAmount,
            docDueDate: docDueDate,
            statusLabel: statusLabel,
            paymentDetails: paymentDetails,
            hasPdfAttachment: hasPdfAttachment,
            hasCustomLogo: hasCustomLogo,
            socialLinks: socialLinks,
          );

    return BrandedEmailContent(html: html, plainText: plainText);
  }

  /// Converts plain text into clean, styled HTML paragraphs for the message body
  static String plainTextToHtmlParagraphs(String text) {
    if (text.trim().isEmpty) return '';
    final paragraphs = text.split(RegExp(r'\r?\n\s*\r?\n'));
    return paragraphs
        .map((p) {
          final sanitized = p
              .replaceAll('&', '&amp;')
              .replaceAll('<', '&lt;')
              .replaceAll('>', '&gt;')
              .replaceAll('\r\n', '<br/>')
              .replaceAll('\n', '<br/>');
          return '<p style="margin: 0 0 16px 0; font-family: Arial, Helvetica, sans-serif; font-size: 15px; line-height: 1.65; color: #231f1c;">$sanitized</p>';
        })
        .join('\n');
  }

  /// Builds clean, reliable text links for Instagram, LinkedIn, and WhatsApp in cream/ember colours
  static String _buildSocialLinksHtml(BrandSocialLinks? socialLinks) {
    final links = socialLinks ?? BrandSocialLinks.defaultLinks;
    final socialItems = <String>[];

    // Instagram
    if (links.instagram != null && links.instagram!.trim().isNotEmpty) {
      final raw = links.instagram!.trim();
      final url = raw.startsWith('http') ? raw : 'https://$raw';
      socialItems.add(
        '<a href="$url" target="_blank" style="color: #f3ead9; text-decoration: none; font-family: Arial, sans-serif; font-size: 11px; font-weight: bold; letter-spacing: 1.2px; text-transform: uppercase;">Instagram</a>',
      );
    }

    // LinkedIn
    if (links.linkedin != null && links.linkedin!.trim().isNotEmpty) {
      final raw = links.linkedin!.trim();
      final url = raw.startsWith('http') ? raw : 'https://$raw';
      socialItems.add(
        '<a href="$url" target="_blank" style="color: #f3ead9; text-decoration: none; font-family: Arial, sans-serif; font-size: 11px; font-weight: bold; letter-spacing: 1.2px; text-transform: uppercase;">LinkedIn</a>',
      );
    }

    // WhatsApp (Cream text to match theme, NO green)
    if (links.whatsapp != null && links.whatsapp!.trim().isNotEmpty) {
      final raw = links.whatsapp!.trim();
      final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
      final url = 'https://wa.me/$digits';
      socialItems.add(
        '<a href="$url" target="_blank" style="color: #f3ead9; text-decoration: none; font-family: Arial, sans-serif; font-size: 11px; font-weight: bold; letter-spacing: 1.2px; text-transform: uppercase;">WhatsApp</a>',
      );
    }

    if (socialItems.isEmpty) return '';

    return '''
    <!-- Social Links (Cream / Ember, 100% Reliable In Gmail) -->
    <div style="margin-top: 16px; text-align: center;">
      ${socialItems.join(' <span style="color: #38B6DB; padding: 0 8px; font-size: 11px;">&bull;</span> ')}
    </div>''';
  }

  // ==========================================
  // OPTION 1: THE DARK CINEMA SLATE
  // ==========================================
  static String _buildCinemaSlateHtml({
    required String recipientName,
    required String heading,
    required String messageHtml,
    String? docType,
    String? docNumber,
    String? docAmount,
    String? docDueDate,
    String? statusLabel,
    Map<String, String>? paymentDetails,
    required bool hasPdfAttachment,
    bool hasCustomLogo = false,
    BrandSocialLinks? socialLinks,
  }) {
    final hasDocCard = docType != null && docNumber != null;

    final docCardHtml = hasDocCard
        ? '''
        <!-- Document Summary Card -->
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="margin: 24px 0; background-color: #0f1213; border-radius: 12px; border: 1px solid #2a2d2e; border-left: 4px solid #38B6DB;">
          <tr>
            <td style="padding: 24px;">
              <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0">
                <tr>
                  <td>
                    <span style="font-family: Arial, Helvetica, sans-serif; font-size: 11px; font-weight: bold; letter-spacing: 2px; color: #38B6DB; text-transform: uppercase;">
                      $docType &bull; $docNumber
                    </span>
                  </td>
                  ${statusLabel != null ? '''
                  <td align="right">
                    <span style="background-color: rgba(255,106,31,0.15); border: 1px solid rgba(255,106,31,0.4); border-radius: 20px; padding: 4px 10px; font-family: Arial, sans-serif; font-size: 11px; font-weight: bold; color: #38B6DB;">
                      $statusLabel
                    </span>
                  </td>''' : ''}
                </tr>
                ${docAmount != null ? '''
                <tr>
                  <td colspan="2" style="padding-top: 14px; padding-bottom: 6px;">
                    <div style="font-family: Arial, Helvetica, sans-serif; font-size: 11px; color: #a79f90; text-transform: uppercase; letter-spacing: 1px;">Amount Due</div>
                    <div style="font-family: Arial, Helvetica, sans-serif; font-size: 30px; font-weight: 800; color: #f3ead9; letter-spacing: 0.5px; margin-top: 4px;">
                      $docAmount
                    </div>
                  </td>
                </tr>''' : ''}
                ${docDueDate != null ? '''
                <tr>
                  <td colspan="2" style="padding-bottom: 12px;">
                    <span style="font-family: Arial, sans-serif; font-size: 13px; color: #a79f90;">Payment due on or before </span>
                    <strong style="color: #f3ead9; font-size: 13px;">$docDueDate</strong>
                  </td>
                </tr>''' : ''}
                ${(paymentDetails != null && paymentDetails.isNotEmpty) ? '''
                <tr>
                  <td colspan="2" style="padding-top: 14px; border-top: 1px solid #2a2d2e;">
                    <div style="font-family: Arial, sans-serif; font-size: 11px; font-weight: bold; color: #a79f90; text-transform: uppercase; letter-spacing: 1.5px; margin-bottom: 8px;">
                      Payment Channels
                    </div>
                    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0">
                      ${paymentDetails.entries.map((e) => '''
                      <tr>
                        <td style="padding: 3px 0; font-family: Arial, sans-serif; font-size: 12px; color: #a79f90; width: 140px;">${e.key}:</td>
                        <td style="padding: 3px 0; font-family: Arial, sans-serif; font-size: 12px; color: #f3ead9; font-weight: bold;">${e.value}</td>
                      </tr>''').join()}
                    </table>
                  </td>
                </tr>''' : ''}
                ${hasPdfAttachment ? '''
                <tr>
                  <td colspan="2" style="padding-top: 14px; border-top: 1px solid #2a2d2e; font-family: Arial, sans-serif; font-size: 12px; color: #a79f90;">
                    <span style="color: #38B6DB;">&#128206;</span> The full $docType document has been attached as a high-resolution PDF.
                  </td>
                </tr>''' : ''}
              </table>
            </td>
          </tr>
        </table>'''
        : '';

    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="color-scheme" content="light dark">
  <meta name="supported-color-schemes" content="light dark">
  <title>$heading</title>
</head>
<body style="margin: 0; padding: 0; background-color: #0a0c0d; font-family: Arial, Helvetica, sans-serif; -webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%;">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color: #0a0c0d;">
    <tr>
      <td align="center" style="padding: 24px 12px;">
        <!-- Email Container (max 600px) -->
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="max-width: 600px; background-color: #fcfbf8; border-radius: 12px; overflow: hidden; box-shadow: 0 10px 30px rgba(0,0,0,0.5);">
          
          <!-- 1. Header Band -->
          <tr>
            <td style="background-color: #0a0c0d; padding: 28px 32px 20px 32px; border-bottom: 2px solid #38B6DB;">
              <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0">
                <tr>
                  <td>
                    <!-- Monogram & Wordmark -->
                    <table role="presentation" cellpadding="0" cellspacing="0" border="0">
                      <tr>
                        ${hasCustomLogo ? '''
                        <td valign="middle" style="padding-right: 14px;">
                          <img src="cid:custom_logo" alt="Logo" style="display: block; max-width: 120px; max-height: 48px; height: auto; border: 0; outline: none;" />
                        </td>''' : ''}
                        <td valign="middle">
                          <a href="$siteUrl" target="_blank" style="text-decoration: none;">
                            <span style="font-family: Arial, Helvetica, sans-serif; font-size: 20px; font-weight: 900; color: #f3ead9; letter-spacing: 2px; text-transform: uppercase;">
                              BRIAN ETOLE
                            </span>
                          </a>
                          <div style="font-family: Arial, Helvetica, sans-serif; font-size: 9px; font-weight: bold; letter-spacing: 2px; color: #a79f90; text-transform: uppercase; margin-top: 2px;">
                            REAL STORIES &bull; IMAGINED WORLDS.
                          </div>
                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- 2. Message Body -->
          <tr>
            <td style="padding: 36px 32px 28px 32px; background-color: #fcfbf8; color: #141718;">
              <div style="font-family: Arial, Helvetica, sans-serif; font-size: 15px; line-height: 1.65; color: #1c1510;">
                $messageHtml
              </div>

              $docCardHtml

              <!-- Sign-off -->
              <div style="margin-top: 32px; padding-top: 20px; border-top: 1px solid #e8e2d5;">
                <p style="margin: 0; font-family: Arial, sans-serif; font-size: 14px; color: #5c5248;">Warm regards,</p>
                <p style="margin: 4px 0 0 0; font-family: Arial, sans-serif; font-size: 16px; font-weight: bold; color: #141718;">Brian Etole</p>
                <p style="margin: 2px 0 0 0; font-family: Arial, sans-serif; font-size: 12px; color: #38B6DB; font-weight: 600; letter-spacing: 0.5px;">Hybrid Filmmaker &bull; Photographer</p>
              </div>
            </td>
          </tr>

          <!-- 3. Footer Band (brianetole.com matched) -->
          <tr>
            <td style="background-color: #0a0c0d; padding: 32px 32px; color: #f3ead9; border-top: 1px solid #2a2d2e;">
              <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0">
                <!-- Location & Role -->
                <tr>
                  <td align="center" style="padding-bottom: 16px;">
                    <div style="font-family: Arial, sans-serif; font-size: 12px; font-weight: bold; letter-spacing: 1.5px; color: #f3ead9; text-transform: uppercase;">
                      BRIAN ETOLE &bull; HYBRID FILMMAKER &bull; PHOTOGRAPHER
                    </div>
                    <div style="font-family: Arial, sans-serif; font-size: 11px; color: #a79f90; margin-top: 4px;">
                      Nairobi, Kenya &bull; Available for international commissions
                    </div>
                  </td>
                </tr>

                <!-- Site Navigation Links -->
                <tr>
                  <td align="center" style="padding-bottom: 12px;">
                    <table role="presentation" cellpadding="0" cellspacing="0" border="0">
                      <tr>
                        <td style="padding: 0 10px;"><a href="$siteUrl/films" target="_blank" style="font-family: Arial, sans-serif; font-size: 11px; font-weight: bold; color: #a79f90; text-decoration: none; text-transform: uppercase; letter-spacing: 1px;">Films</a></td>
                        <td style="color: #2a2d2e;">&bull;</td>
                        <td style="padding: 0 10px;"><a href="$siteUrl/photography" target="_blank" style="font-family: Arial, sans-serif; font-size: 11px; font-weight: bold; color: #a79f90; text-decoration: none; text-transform: uppercase; letter-spacing: 1px;">Photography</a></td>
                        <td style="color: #2a2d2e;">&bull;</td>
                        <td style="padding: 0 10px;"><a href="$siteUrl/journal" target="_blank" style="font-family: Arial, sans-serif; font-size: 11px; font-weight: bold; color: #a79f90; text-decoration: none; text-transform: uppercase; letter-spacing: 1px;">Journal</a></td>
                        <td style="color: #2a2d2e;">&bull;</td>
                        <td style="padding: 0 10px;"><a href="$siteUrl/hire-me" target="_blank" style="font-family: Arial, sans-serif; font-size: 11px; font-weight: bold; color: #38B6DB; text-decoration: none; text-transform: uppercase; letter-spacing: 1px;">Hire Me</a></td>
                      </tr>
                    </table>
                  </td>
                </tr>

                <!-- Social Links (Cream / Ember, 100% Reliable In Gmail) -->
                <tr>
                  <td align="center" style="padding-bottom: 16px;">
                    ${_buildSocialLinksHtml(socialLinks)}
                  </td>
                </tr>

                <!-- Direct Inquiries & Newsletter -->
                <tr>
                  <td align="center" style="border-top: 1px solid #2a2d2e; padding-top: 20px; font-family: Arial, sans-serif; font-size: 12px; color: #a79f90; line-height: 1.6;">
                    <div>
                      <a href="mailto:hello@brianetole.com" style="color: #f3ead9; text-decoration: none; font-weight: bold;">hello@brianetole.com</a> &bull; 
                      <a href="tel:+254718013579" style="color: #f3ead9; text-decoration: none;">+254 718 013 579</a> &bull; 
                      <a href="$siteUrl" target="_blank" style="color: #38B6DB; text-decoration: none;">brianetole.com</a>
                    </div>
                    <div style="margin-top: 10px; font-size: 11px; color: #a79f90;">
                      <em>Join The Director's Cut &mdash; new films, field stories and first access to prints and lessons.</em>
                    </div>
                  </td>
                </tr>

                <!-- Copyright -->
                <tr>
                  <td align="center" style="padding-top: 16px; font-family: Arial, sans-serif; font-size: 11px; color: #666666;">
                    &copy; 2026 Brian Etole &bull; <a href="$siteUrl/privacy" target="_blank" style="color: #666666; text-decoration: underline;">Privacy Policy</a>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>
''';
  }

  // ==========================================
  // OPTION 2: THE EDITORIAL GALLERY
  // ==========================================
  static String _buildEditorialGalleryHtml({
    required String recipientName,
    required String heading,
    required String messageHtml,
    String? clientName,
    String? docDate,
    String? docType,
    String? docNumber,
    String? docAmount,
    String? docDueDate,
    String? statusLabel,
    Map<String, String>? paymentDetails,
    required bool hasPdfAttachment,
    bool hasCustomLogo = false,
    BrandSocialLinks? socialLinks,
  }) {
    final hasDocCard = docType != null && docNumber != null;

    final docCardHtml = hasDocCard
        ? '''
        <!-- Document Summary Card -->
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="margin: 28px 0; background-color: #f7f3eb; border: 1px solid #dfd8cb; border-left: 4px solid #38B6DB; border-radius: 4px;">
          <tr>
            <td style="padding: 24px 26px;">
              <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0">
                <!-- Doc Reference Header -->
                <tr>
                  <td>
                    <div style="font-family: Arial, sans-serif; font-size: 11px; font-weight: bold; letter-spacing: 2px; color: #38B6DB; text-transform: uppercase;">
                      $docType &bull; $docNumber
                    </div>
                    ${(clientName != null || docDate != null || docDueDate != null) ? '''
                    <div style="font-family: Georgia, serif; font-size: 12px; color: #6a6156; margin-top: 4px;">
                      ${clientName != null ? 'Client: <strong style="color: #1c1510;">$clientName</strong>' : ''}
                      ${(clientName != null && docDate != null) ? ' &bull; ' : ''}
                      ${docDate != null ? 'Date: $docDate' : ''}
                      ${(docDueDate != null) ? ' &bull; Due: <strong style="color: #1c1510;">$docDueDate</strong>' : ''}
                    </div>''' : ''}
                  </td>
                  ${statusLabel != null ? '''
                  <td align="right" valign="top">
                    <span style="display: inline-block; padding: 4px 10px; background-color: #38B6DB; color: #ffffff; font-family: Arial, sans-serif; font-size: 10px; font-weight: bold; letter-spacing: 1px; text-transform: uppercase; border-radius: 3px;">
                      $statusLabel
                    </span>
                  </td>''' : ''}
                </tr>

                <!-- Amount Section -->
                ${docAmount != null ? '''
                <tr>
                  <td colspan="2" style="padding-top: 18px; padding-bottom: 6px;">
                    <div style="font-family: Arial, sans-serif; font-size: 10px; font-weight: bold; color: #7a7065; text-transform: uppercase; letter-spacing: 1.5px;">Amount Due</div>
                    <div style="font-family: Arial, sans-serif; font-size: 30px; font-weight: 800; color: #1c1510; letter-spacing: -0.5px; margin-top: 2px;">
                      $docAmount
                    </div>
                  </td>
                </tr>''' : ''}

                <!-- Payment Details Section -->
                ${(paymentDetails != null && paymentDetails.isNotEmpty) ? '''
                <tr>
                  <td colspan="2" style="padding-top: 14px; border-top: 1px dashed #d5cdbe;">
                    <div style="font-family: Arial, sans-serif; font-size: 10px; font-weight: bold; color: #38B6DB; text-transform: uppercase; letter-spacing: 1.5px; margin-bottom: 8px;">
                      Payment Channels
                    </div>
                    <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0">
                      ${paymentDetails.entries.map((e) => '''
                      <tr>
                        <td style="padding: 2px 0; font-family: Arial, sans-serif; font-size: 12px; color: #5c5248; width: 140px;">${e.key}:</td>
                        <td style="padding: 2px 0; font-family: Arial, sans-serif; font-size: 12px; color: #1c1510; font-weight: bold;">${e.value}</td>
                      </tr>''').join()}
                    </table>
                  </td>
                </tr>''' : ''}

                <!-- PDF Note -->
                ${hasPdfAttachment ? '''
                <tr>
                  <td colspan="2" style="padding-top: 14px; border-top: 1px solid #e0d8ca; font-family: Arial, sans-serif; font-size: 11px; color: #5c5248;">
                    &#128206; The full <strong>$docType</strong> is attached as a high-resolution PDF.
                  </td>
                </tr>''' : ''}
              </table>
            </td>
          </tr>
        </table>'''
        : '';

    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$heading</title>
</head>
<body style="margin: 0; padding: 0; background-color: #f2eee5; font-family: Arial, Helvetica, sans-serif; -webkit-text-size-adjust: 100%; -ms-text-size-adjust: 100%;">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="background-color: #f2eee5;">
    <tr>
      <td align="center" style="padding: 28px 12px;">
        <!-- Email Container -->
        <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0" style="max-width: 600px; background-color: #ffffff; border: 1px solid #ded7ca; box-shadow: 0 4px 18px rgba(0,0,0,0.06); border-radius: 4px; overflow: hidden;">
          
          <!-- 1. Header Band (Obsidian with optional custom logo, BE Monogram & Tagline) -->
          <tr>
            <td style="background-color: #0a0c0d; padding: 26px 32px 20px 32px; text-align: center;">
              <table role="presentation" width="100%" cellpadding="0" cellspacing="0" border="0">
                <tr>
                  <td align="center">
                    <a href="$siteUrl" target="_blank" style="text-decoration: none; display: inline-block;">
                      ${hasCustomLogo ? '''
                      <img src="cid:custom_logo" alt="" style="display: block; margin: 0 auto 12px auto; max-width: 140px; max-height: 52px; height: auto; border: 0; outline: none;" />
                      ''' : ''}
                      <span style="font-family: Arial, Helvetica, sans-serif; font-size: 22px; font-weight: 900; letter-spacing: 3.5px; color: #f3ead9; text-transform: uppercase;">
                        BRIAN ETOLE
                      </span>
                    </a>
                    <div style="font-family: Arial, sans-serif; font-size: 9px; font-weight: bold; letter-spacing: 2px; color: #a79f90; text-transform: uppercase; margin-top: 4px;">
                      REAL STORIES &bull; IMAGINED WORLDS.
                    </div>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Ember Orange Accent Line -->
          <tr>
            <td height="3" style="background-color: #38B6DB; line-height: 3px; font-size: 3px;">&nbsp;</td>
          </tr>

          <!-- 2. Message Body -->
          <tr>
            <td style="padding: 34px 32px; background-color: #fcfbf8; color: #1c1510;">
              <div style="font-family: Arial, Helvetica, sans-serif; font-size: 15px; line-height: 1.65; color: #231f1c;">
                $messageHtml
              </div>

              $docCardHtml

              <!-- Sign-off (strictly personal branding, never mentioning app name) -->
              <div style="margin-top: 32px; padding-top: 20px; border-top: 1px solid #eae3d6;">
                <div style="font-family: Georgia, serif; font-size: 14px; font-style: italic; color: #5c5248;">Warm regards,</div>
                <div style="font-family: Arial, sans-serif; font-size: 17px; font-weight: bold; color: #141718; margin-top: 4px;">Brian Etole</div>
                <div style="font-family: Arial, sans-serif; font-size: 12px; color: #38B6DB; font-weight: 600; letter-spacing: 0.5px; margin-top: 2px;">
                  Hybrid Filmmaker &bull; Photographer
                </div>
              </div>
            </td>
          </tr>

          <!-- 3. Footer Band (brianetole.com matched) -->
          <tr>
            <td style="background-color: #0a0c0d; padding: 30px 28px; color: #f3ead9; border-top: 1px solid #2a2d2e; text-align: center;">
              
              <!-- Title & Tagline -->
              <div style="font-family: Arial, sans-serif; font-size: 12px; font-weight: bold; letter-spacing: 1.5px; color: #f3ead9; text-transform: uppercase;">
                BRIAN ETOLE &bull; HYBRID FILMMAKER &bull; PHOTOGRAPHER
              </div>
              <div style="font-family: Arial, sans-serif; font-size: 11px; color: #a79f90; margin-top: 3px;">
                Nairobi, Kenya
              </div>

              <!-- Navigation Links -->
              <div style="margin-top: 16px;">
                <table role="presentation" cellpadding="0" cellspacing="0" border="0" align="center">
                  <tr>
                    <td style="padding: 0 8px;"><a href="$siteUrl/films" target="_blank" style="font-family: Arial, sans-serif; font-size: 11px; font-weight: bold; color: #a79f90; text-decoration: none; text-transform: uppercase; letter-spacing: 1px;">Films</a></td>
                    <td style="color: #2a2d2e;">&bull;</td>
                    <td style="padding: 0 8px;"><a href="$siteUrl/photography" target="_blank" style="font-family: Arial, sans-serif; font-size: 11px; font-weight: bold; color: #a79f90; text-decoration: none; text-transform: uppercase; letter-spacing: 1px;">Photography</a></td>
                    <td style="color: #2a2d2e;">&bull;</td>
                    <td style="padding: 0 8px;"><a href="$siteUrl/journal" target="_blank" style="font-family: Arial, sans-serif; font-size: 11px; font-weight: bold; color: #a79f90; text-decoration: none; text-transform: uppercase; letter-spacing: 1px;">Journal</a></td>
                    <td style="color: #2a2d2e;">&bull;</td>
                    <td style="padding: 0 8px;"><a href="$siteUrl/hire-me" target="_blank" style="font-family: Arial, sans-serif; font-size: 11px; font-weight: bold; color: #38B6DB; text-decoration: none; text-transform: uppercase; letter-spacing: 1px;">Hire me</a></td>
                  </tr>
                </table>
              </div>

              <!-- Social Links (Cream / Ember, 100% Reliable In Gmail) -->
              ${_buildSocialLinksHtml(socialLinks)}

              <!-- Contact Direct -->
              <div style="margin-top: 18px; font-family: Arial, sans-serif; font-size: 11px; color: #a79f90;">
                <a href="mailto:hello@brianetole.com" style="color: #a79f90; text-decoration: none;">hello@brianetole.com</a> &bull;
                <a href="tel:+254718013579" style="color: #a79f90; text-decoration: none;">+254 718 013 579</a> &bull;
                <a href="$siteUrl" target="_blank" style="color: #38B6DB; text-decoration: none;">brianetole.com</a>
              </div>

              <!-- Newsletter Callout -->
              <div style="margin-top: 16px; padding: 10px 14px; background-color: #0f1213; border: 1px solid #25292b; border-radius: 4px; display: inline-block;">
                <a href="$siteUrl" target="_blank" style="font-family: Arial, sans-serif; font-size: 11px; color: #d4ccbd; text-decoration: none;">
                  Join <strong style="color: #38B6DB;">The Director&rsquo;s Cut</strong> &mdash; new films, field stories &amp; masterclasses &rarr;
                </a>
              </div>

              <!-- Copyright -->
              <div style="margin-top: 16px; font-family: Arial, sans-serif; font-size: 10px; color: #5a5f61;">
                &copy; 2026 Brian Etole &bull; <a href="$siteUrl/privacy" target="_blank" style="color: #5a5f61; text-decoration: none;">Privacy Policy</a>
              </div>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>
''';
  }

  // ==========================================
  // PLAIN TEXT FALLBACK
  // ==========================================
  static String _buildPlainText({
    required String recipientName,
    required String messagePlainText,
    String? docType,
    String? docNumber,
    String? docAmount,
    String? docDueDate,
    String? statusLabel,
    Map<String, String>? paymentDetails,
    required bool hasPdfAttachment,
    BrandSocialLinks? socialLinks,
  }) {
    final sb = StringBuffer();
    sb.writeln('BRIAN ETOLE');
    sb.writeln('REAL STORIES. IMAGINED WORLDS.');
    sb.writeln('----------------------------------------------------');
    sb.writeln();
    sb.writeln(messagePlainText.trim());
    sb.writeln();

    if (docType != null && docNumber != null) {
      sb.writeln('----------------------------------------------------');
      sb.writeln('$docType: $docNumber');
      if (statusLabel != null) sb.writeln('Status: $statusLabel');
      if (docAmount != null) sb.writeln('Amount: $docAmount');
      if (docDueDate != null) sb.writeln('Due Date: $docDueDate');
      if (paymentDetails != null && paymentDetails.isNotEmpty) {
        sb.writeln('Payment Details:');
        for (final entry in paymentDetails.entries) {
          sb.writeln('  ${entry.key}: ${entry.value}');
        }
      }
      if (hasPdfAttachment) {
        sb.writeln('Attachment: $docNumber.pdf');
      }
      sb.writeln('----------------------------------------------------');
      sb.writeln();
    }

    sb.writeln('Warm regards,');
    sb.writeln('Brian Etole');
    sb.writeln('Hybrid Filmmaker · Photographer');
    sb.writeln('Nairobi, Kenya');
    sb.writeln();
    sb.writeln(
      'hello@brianetole.com | +254 718 013 579 | https://brianetole.com',
    );
    sb.writeln(
      'Films: https://brianetole.com/films | Photography: https://brianetole.com/photography',
    );

    final links = socialLinks ?? BrandSocialLinks.defaultLinks;
    final socialTextParts = <String>[];
    if (links.instagram != null && links.instagram!.trim().isNotEmpty) {
      final clean = links.instagram!.trim().replaceFirst(
        RegExp(r'^https?://'),
        '',
      );
      socialTextParts.add('Instagram: https://$clean');
    }
    if (links.linkedin != null && links.linkedin!.trim().isNotEmpty) {
      final clean = links.linkedin!.trim().replaceFirst(
        RegExp(r'^https?://'),
        '',
      );
      socialTextParts.add('LinkedIn: https://$clean');
    }
    if (links.whatsapp != null && links.whatsapp!.trim().isNotEmpty) {
      final digits = links.whatsapp!.trim().replaceAll(RegExp(r'[^0-9]'), '');
      socialTextParts.add('WhatsApp: https://wa.me/$digits');
    }
    if (socialTextParts.isNotEmpty) {
      sb.writeln(socialTextParts.join(' | '));
    }
    sb.writeln('© 2026 Brian Etole. All rights reserved.');

    return sb.toString();
  }

  // ==========================================
  // SAMPLE DEMO GENERATORS
  // ==========================================

  /// Sample 1: Real-world Invoice Email
  static BrandedEmailContent buildSampleInvoiceEmail({
    required EmailTheme theme,
    bool hasCustomLogo = false,
    BrandSocialLinks? socialLinks,
  }) {
    const heading =
        'Invoice BE-INV-2026-004 — Documentary Production & Photography';
    const messageHtml = '''
<p style="margin: 0 0 16px 0;">Hello Maya,</p>
<p style="margin: 0 0 16px 0;">Thank you for partnering with me on the <strong>Mara Wildlife Conservation Documentary</strong> production. It has been a profound privilege documenting these human stories in the field.</p>
<p style="margin: 0 0 16px 0;">Please find attached the official invoice <strong>BE-INV-2026-004</strong> for the final production and color grading phase.</p>
<p style="margin: 0;">If you have any questions or require additional documentation for your accounts department, please feel free to reach out directly.</p>
''';

    const messagePlainText = '''
Hello Maya,

Thank you for partnering with me on the Mara Wildlife Conservation Documentary production. It has been a profound privilege documenting these human stories in the field.

Please find attached the official invoice BE-INV-2026-004 for the final production and color grading phase.

If you have any questions or require additional documentation for your accounts department, please feel free to reach out directly.
''';

    return buildEmail(
      theme: theme,
      recipientName: 'Maya Lin',
      recipientEmail: 'hello@brianetole.com',
      heading: heading,
      messageHtml: messageHtml,
      messagePlainText: messagePlainText,
      docType: 'INVOICE',
      docNumber: 'BE-INV-2026-004',
      docAmount: 'KES 85,000.00',
      docDueDate: '15 Nov 2026',
      statusLabel: 'Payment Due 15 Nov',
      paymentDetails: {
        'M-Pesa Buy Goods': '987 654 (Brian Etole)',
        'Bank Name': 'NCBA Bank Kenya',
        'Account Name': 'Brian Etole Media',
        'Account Number': '100 248 9301',
      },
      hasPdfAttachment: true,
      hasCustomLogo: hasCustomLogo,
      socialLinks: socialLinks,
    );
  }

  /// Sample 2: Real-world Intro / Welcome Email
  static BrandedEmailContent buildSampleIntroEmail({
    required EmailTheme theme,
    bool hasCustomLogo = false,
    BrandSocialLinks? socialLinks,
  }) {
    const heading =
        'Great connecting in Nairobi — Brian Etole (Hybrid Filmmaker & Photographer)';
    const messageHtml =
        '''
<p style="margin: 0 0 16px 0;">Hello Alex,</p>
<p style="margin: 0 0 16px 0;">It was wonderful meeting you earlier today! As promised, I wanted to follow up with my digital card and creative portfolio details.</p>
<p style="margin: 0 0 16px 0;">I produce <strong>documentary films, photography, and AI-driven storytelling</strong> for NGOs, brands, and independent creators with something real to say. My craft is grounded in camera truth and human preservation.</p>
<p style="margin: 0 0 16px 0;">You can explore my latest film projects and documentary photography at <a href="$siteUrl" target="_blank" style="color: #38B6DB; font-weight: bold; text-decoration: underline;">brianetole.com</a>, or catch my latest field work on Instagram <a href="https://instagram.com/brianetole" target="_blank" style="color: #38B6DB; text-decoration: underline;">@brianetole</a>.</p>
<p style="margin: 0;">I have also attached my 2026 Production Rate Card for your review. Let's find time next week to discuss your upcoming project!</p>
''';

    const messagePlainText = '''
Hello Alex,

It was wonderful meeting you earlier today! As promised, I wanted to follow up with my digital card and creative portfolio details.

I produce documentary films, photography, and AI-driven storytelling for NGOs, brands, and independent creators with something real to say. My craft is grounded in camera truth and human preservation.

You can explore my latest film projects and documentary photography at https://brianetole.com, or catch my latest field work on Instagram @brianetole.

I have also attached my 2026 Production Rate Card for your review. Let's find time next week to discuss your upcoming project!
''';

    return buildEmail(
      theme: theme,
      recipientName: 'Alex Mercer',
      recipientEmail: 'hello@brianetole.com',
      heading: heading,
      messageHtml: messageHtml,
      messagePlainText: messagePlainText,
      docType: 'RATE CARD',
      docNumber: 'BE-RC-2026',
      statusLabel: '2026 Production Rates',
      hasPdfAttachment: true,
      hasCustomLogo: hasCustomLogo,
      socialLinks: socialLinks,
    );
  }
}
