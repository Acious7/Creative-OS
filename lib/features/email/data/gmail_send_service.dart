import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../core/database/app_database.dart';
import '../../brands/domain/brand_social_links.dart';
import '../domain/branded_email_builder.dart';
import '../domain/email_template.dart';
import 'google_auth_service.dart';

class GoogleAuthRequiredException implements Exception {
  final String message;
  GoogleAuthRequiredException([
    this.message = 'Please sign in with Google to send emails.',
  ]);
  @override
  String toString() => message;
}

class GoogleAuthExpiredException implements Exception {
  final String message;
  GoogleAuthExpiredException([
    this.message = 'Google sign-in session expired. Please sign in again.',
  ]);
  @override
  String toString() => message;
}

class GmailNetworkException implements Exception {
  final String message;
  GmailNetworkException([
    this.message = 'No internet connection. Please check your network.',
  ]);
  @override
  String toString() => message;
}

class EmailAttachmentItem {
  final String filename;
  final Uint8List bytes;
  final String mimeType;
  final String? contentId;
  final bool isInline;

  EmailAttachmentItem({
    required this.filename,
    required this.bytes,
    this.mimeType = 'application/pdf',
    this.contentId,
    this.isInline = false,
  });
}

class GmailSendService {
  static final GoogleAuthService _authService = GoogleAuthService();

  static final Map<String, String> _brandedCidFilenames = {
    'logo': 'logo.png',
    'instagram': 'instagram.png',
    'youtube': 'youtube.png',
    'tiktok': 'tiktok.png',
    'linkedin': 'linkedin.png',
    'x': 'x.png',
    'facebook': 'facebook.png',
    'whatsapp': 'whatsapp.png',
  };

  static Map<String, Uint8List>? _cachedBrandedAssetBytes;

  /// Retrieves custom logo image bytes from active brand or explicit path
  static Future<Uint8List?> getCustomLogoBytes([
    String? explicitLogoPath,
  ]) async {
    try {
      String? path = explicitLogoPath;
      if (path == null || path.isEmpty) {
        final db = AppDatabase();
        try {
          final brands = await (db.select(
            db.brands,
          )..where((b) => b.isActive.equals(true))).get();
          if (brands.isNotEmpty) {
            final brand = brands.firstWhere(
              (b) => b.name.toLowerCase().contains('brian'),
              orElse: () => brands.first,
            );
            path = brand.logoPath;
          }
        } finally {
          await db.close();
        }
      }
      if (path != null && path.isNotEmpty) {
        if (path.startsWith('assets/')) {
          final data = await rootBundle.load(path);
          return data.buffer.asUint8List();
        }
        final file = File(path);
        if (await file.exists()) {
          return await file.readAsBytes();
        }
      }
    } catch (_) {}
    return null;
  }

  /// Loads the 8 tiny email branding PNGs from assets/email/
  static Future<List<EmailAttachmentItem>> getBrandedInlineAssets() async {
    if (_cachedBrandedAssetBytes == null) {
      final map = <String, Uint8List>{};
      for (final entry in _brandedCidFilenames.entries) {
        final cid = entry.key;
        final filename = entry.value;
        Uint8List? bytes;

        try {
          final byteData = await rootBundle.load('assets/email/$filename');
          bytes = byteData.buffer.asUint8List();
        } catch (_) {}

        if (bytes == null) {
          try {
            final file = File('assets/email/$filename');
            if (await file.exists()) {
              bytes = await file.readAsBytes();
            }
          } catch (_) {}
        }

        if (bytes != null) {
          map[cid] = bytes;
        }
      }
      _cachedBrandedAssetBytes = map;
    }

    return _cachedBrandedAssetBytes!.entries.map((e) {
      return EmailAttachmentItem(
        filename: _brandedCidFilenames[e.key] ?? '${e.key}.png',
        bytes: e.value,
        mimeType: 'image/png',
        contentId: e.key,
        isInline: true,
      );
    }).toList();
  }

  /// Build RFC 822 MIME message supporting Plain Text, HTML, Inline Images (CID), and Attachments
  static String buildRfc822({
    required String fromName,
    required String fromEmail,
    required List<String> toEmails,
    List<String> ccEmails = const [],
    List<String> bccEmails = const [],
    required String subject,
    required String plainTextBody,
    String? htmlBody,
    List<EmailAttachmentItem> attachments = const [],
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final mixedBoundary = 'mixed_boundary_$timestamp';
    final relatedBoundary = 'related_boundary_$timestamp';
    final altBoundary = 'alt_boundary_$timestamp';
    final sb = StringBuffer();

    // From Header
    final encodedFromName = fromName.isNotEmpty
        ? '=?UTF-8?B?${base64.encode(utf8.encode(fromName))}?='
        : '';
    final fromHeader = encodedFromName.isNotEmpty
        ? '$encodedFromName <$fromEmail>'
        : fromEmail;

    // To Header
    final toHeader = toEmails.join(', ');

    // Subject Header
    final encodedSubject = '=?UTF-8?B?${base64.encode(utf8.encode(subject))}?=';

    sb.write('From: $fromHeader\r\n');
    sb.write('To: $toHeader\r\n');
    if (ccEmails.isNotEmpty) {
      sb.write('Cc: ${ccEmails.join(', ')}\r\n');
    }
    if (bccEmails.isNotEmpty) {
      sb.write('Bcc: ${bccEmails.join(', ')}\r\n');
    }
    sb.write('Subject: $encodedSubject\r\n');
    sb.write('MIME-Version: 1.0\r\n');

    final inlineAttachments = attachments
        .where((a) => a.isInline && a.contentId != null)
        .toList();
    final regularAttachments = attachments.where((a) => !a.isInline).toList();
    final hasInline = inlineAttachments.isNotEmpty;
    final hasRegular = regularAttachments.isNotEmpty;
    final hasHtml = htmlBody != null && htmlBody.trim().isNotEmpty;

    void writeAttachmentPart(EmailAttachmentItem att, String boundary) {
      sb.write('--$boundary\r\n');
      sb.write('Content-Type: ${att.mimeType}; name="${att.filename}"\r\n');
      sb.write('Content-Transfer-Encoding: base64\r\n');
      if (att.isInline && att.contentId != null) {
        sb.write('Content-ID: <${att.contentId}>\r\n');
        sb.write(
          'Content-Disposition: inline; filename="${att.filename}"\r\n\r\n',
        );
      } else {
        sb.write(
          'Content-Disposition: attachment; filename="${att.filename}"\r\n\r\n',
        );
      }

      final b64 = base64.encode(att.bytes);
      for (int i = 0; i < b64.length; i += 76) {
        final end = (i + 76 < b64.length) ? i + 76 : b64.length;
        sb.write('${b64.substring(i, end)}\r\n');
      }
      sb.write('\r\n');
    }

    void writeAlternativePart() {
      sb.write(
        'Content-Type: multipart/alternative; boundary="$altBoundary"\r\n\r\n',
      );

      // Plain text
      sb.write('--$altBoundary\r\n');
      sb.write('Content-Type: text/plain; charset=utf-8\r\n');
      sb.write('Content-Transfer-Encoding: base64\r\n\r\n');
      sb.write('${base64.encode(utf8.encode(plainTextBody))}\r\n\r\n');

      // HTML
      if (hasHtml) {
        sb.write('--$altBoundary\r\n');
        sb.write('Content-Type: text/html; charset=utf-8\r\n');
        sb.write('Content-Transfer-Encoding: base64\r\n\r\n');
        sb.write('${base64.encode(utf8.encode(htmlBody))}\r\n\r\n');
      }

      sb.write('--$altBoundary--\r\n\r\n');
    }

    void writeRelatedBody() {
      sb.write(
        'Content-Type: multipart/related; boundary="$relatedBoundary"\r\n\r\n',
      );

      // Part 1 of related: the alternative text/html
      sb.write('--$relatedBoundary\r\n');
      writeAlternativePart();

      // Inline parts (images referenced by cid:...)
      for (final inlineAtt in inlineAttachments) {
        writeAttachmentPart(inlineAtt, relatedBoundary);
      }

      sb.write('--$relatedBoundary--\r\n\r\n');
    }

    if (hasRegular) {
      // Top-level is multipart/mixed
      sb.write(
        'Content-Type: multipart/mixed; boundary="$mixedBoundary"\r\n\r\n',
      );

      sb.write('--$mixedBoundary\r\n');
      if (hasInline) {
        writeRelatedBody();
      } else if (hasHtml) {
        writeAlternativePart();
      } else {
        sb.write('Content-Type: text/plain; charset=utf-8\r\n');
        sb.write('Content-Transfer-Encoding: base64\r\n\r\n');
        sb.write('${base64.encode(utf8.encode(plainTextBody))}\r\n\r\n');
      }

      for (final att in regularAttachments) {
        writeAttachmentPart(att, mixedBoundary);
      }

      sb.write('--$mixedBoundary--\r\n');
    } else {
      // No regular attachments
      if (hasInline) {
        // Top-level is multipart/related
        writeRelatedBody();
      } else if (hasHtml) {
        // Top-level is multipart/alternative
        writeAlternativePart();
      } else {
        // Plain text only
        sb.write('Content-Type: text/plain; charset=utf-8\r\n');
        sb.write('Content-Transfer-Encoding: base64\r\n\r\n');
        sb.write('${base64.encode(utf8.encode(plainTextBody))}\r\n');
      }
    }

    return sb.toString();
  }

  /// Sends an email through Gmail API
  static Future<bool> sendEmail({
    required String recipientEmail,
    List<String> additionalToEmails = const [],
    String? recipientName,
    List<String> ccEmails = const [],
    List<String> bccEmails = const [],
    required String subject,
    required String bodyText,
    String? htmlBody,
    Uint8List? attachmentBytes,
    String? attachmentFilename,
    Uint8List? customLogoBytes,
    List<EmailAttachmentItem> extraAttachments = const [],
    bool allowInteractiveSignIn = true,
  }) async {
    var account = await _authService.getSavedAccount();
    var accessToken = await _authService.ensureValidAccessToken(
      allowInteractive: allowInteractiveSignIn,
    );
    account ??= await _authService.getSavedAccount();

    if (accessToken == null || account == null) {
      throw GoogleAuthRequiredException(
        'Google sign-in needed to send emails. Please tap Reconnect in Settings → Email.',
      );
    }

    final allAttachments = <EmailAttachmentItem>[];

    // If email has HTML with CID references, attach custom logo or fallback inline images
    if (htmlBody != null && htmlBody.contains('cid:')) {
      if (htmlBody.contains('cid:custom_logo')) {
        final logoBytes = customLogoBytes ?? await getCustomLogoBytes();
        if (logoBytes != null) {
          allAttachments.add(
            EmailAttachmentItem(
              filename: 'logo.png',
              bytes: logoBytes,
              mimeType: 'image/png',
              contentId: 'custom_logo',
              isInline: true,
            ),
          );
        }
      }
      if (htmlBody.contains('cid:logo') ||
          htmlBody.contains('cid:instagram') ||
          htmlBody.contains('cid:linkedin') ||
          htmlBody.contains('cid:whatsapp')) {
        final inlineImages = await getBrandedInlineAssets();
        allAttachments.addAll(inlineImages);
      }
    }

    if (attachmentBytes != null && attachmentFilename != null) {
      final isPdf = attachmentFilename.toLowerCase().endsWith('.pdf');
      allAttachments.add(
        EmailAttachmentItem(
          filename: attachmentFilename,
          bytes: attachmentBytes,
          mimeType: isPdf ? 'application/pdf' : 'image/png',
        ),
      );
    }
    allAttachments.addAll(extraAttachments);

    final toList = <String>[
      recipientEmail,
      ...additionalToEmails,
    ].map((e) => e.trim()).where((e) => e.isNotEmpty).toSet().toList();

    final rfc822Content = buildRfc822(
      fromName: 'Brian Etole',
      fromEmail: account.email,
      toEmails: toList,
      ccEmails: ccEmails,
      bccEmails: bccEmails,
      subject: subject,
      plainTextBody: bodyText,
      htmlBody: htmlBody,
      attachments: allAttachments,
    );

    Future<http.Response> postMessage(String token) async {
      return await http.post(
        Uri.parse(
          'https://gmail.googleapis.com/upload/gmail/v1/users/me/messages/send?uploadType=media',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'message/rfc822',
        },
        body: utf8.encode(rfc822Content),
      );
    }

    http.Response response;
    try {
      response = await postMessage(accessToken);

      // If token expired, try refreshing once
      if (response.statusCode == 401) {
        final refreshedToken = await _authService.ensureValidAccessToken(
          allowInteractive: allowInteractiveSignIn,
        );
        if (refreshedToken != null) {
          response = await postMessage(refreshedToken);
        } else {
          throw GoogleAuthExpiredException();
        }
      }
    } on SocketException {
      throw GmailNetworkException();
    } on http.ClientException {
      throw GmailNetworkException();
    }

    if (response.statusCode == 200 || response.statusCode == 202) {
      return true;
    } else if (response.statusCode == 401) {
      throw GoogleAuthExpiredException();
    } else {
      throw Exception(
        'Gmail API Error (${response.statusCode}): ${response.body}',
      );
    }
  }

  /// Helper to generate a clean sample PDF
  static Future<Uint8List> _generateSamplePdf({
    required String title,
    required String docNumber,
    required String subtitle,
    required List<List<String>> rows,
  }) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'BRIAN ETOLE',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#0A0C0D'),
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'VISUALSTORYTELLER',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#38B6DB'),
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        title.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#0A0C0D'),
                        ),
                      ),
                      pw.Text(
                        docNumber,
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColor.fromHex('#5C5248'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(color: PdfColor.fromHex('#38B6DB'), thickness: 2),
              pw.SizedBox(height: 20),
              pw.Text(
                subtitle,
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: PdfColor.fromHex('#E0D8CA')),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 11,
                ),
                headerDecoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F5F0E8'),
                ),
                cellStyle: const pw.TextStyle(fontSize: 10),
                cellPadding: const pw.EdgeInsets.all(8),
                headers: ['Item / Service', 'Description', 'Rate / Amount'],
                data: rows,
              ),
              pw.Spacer(),
              pw.Divider(color: PdfColor.fromHex('#E0D8CA')),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'hello@brianetole.com · +254 718 013 579',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColor.fromInt(0xFF777777),
                    ),
                  ),
                  pw.Text(
                    'brianetole.com · Nairobi, Kenya',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColor.fromInt(0xFF777777),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
    return await pdf.save();
  }

  /// Sends Option 1: Cinema Slate (Invoice) to hello@brianetole.com
  static Future<bool> sendOption1CinemaSlate() async {
    final account = await _authService.getSavedAccount();
    if (account == null) throw GoogleAuthRequiredException();

    final customLogo = await getCustomLogoBytes();
    final socialLinks = await BrandSocialLinksRepository.getSocialLinks();

    final content = BrandedEmailBuilder.buildSampleInvoiceEmail(
      theme: EmailTheme.cinemaSlate,
      hasCustomLogo: customLogo != null,
      socialLinks: socialLinks,
    );

    final pdfBytes = await _generateSamplePdf(
      title: 'Invoice',
      docNumber: 'BE-INV-2026-004',
      subtitle:
          'Mara Wildlife Conservation Documentary — Production & Color Grading',
      rows: [
        [
          'Principal Cinematography (4 Days)',
          'Field 4K RAW capture, drone aerials & lighting',
          'KES 50,000.00',
        ],
        [
          'Sound Design & 5.1 Mix',
          'Location ambisonics, Foley restoration & audio cleanup',
          'KES 15,000.00',
        ],
        [
          'ACES Cinematic Color Grade',
          'Master finish, theatrical tone curve & web deliverables',
          'KES 20,000.00',
        ],
      ],
    );

    return await sendEmail(
      recipientEmail: account.email,
      recipientName: 'Brian Etole',
      subject: '[Design Option 1: Cinema Slate] Invoice BE-INV-2026-004 — Mara Documentary',
      bodyText: content.plainText,
      htmlBody: content.html,
      attachmentBytes: pdfBytes,
      attachmentFilename: 'BE-INV-2026-004.pdf',
      customLogoBytes: customLogo,
    );
  }

  /// Sends Option 2: Editorial Gallery (Intro) to hello@brianetole.com
  static Future<bool> sendOption2EditorialGallery() async {
    final account = await _authService.getSavedAccount();
    if (account == null) throw GoogleAuthRequiredException();

    final customLogo = await getCustomLogoBytes();
    final socialLinks = await BrandSocialLinksRepository.getSocialLinks();

    final content = BrandedEmailBuilder.buildSampleIntroEmail(
      theme: EmailTheme.editorialGallery,
      hasCustomLogo: customLogo != null,
      socialLinks: socialLinks,
    );

    final pdfBytes = await _generateSamplePdf(
      title: 'Production Rate Card',
      docNumber: 'BE-RC-2026',
      subtitle: 'Brian Etole 2026 Standard Production & Direction Rates',
      rows: [
        [
          'Documentary Directing (Day Rate)',
          'Full on-set creative direction, interview facilitation',
          'KES 25,000 / day',
        ],
        [
          'Hybrid DP / Cinematography Kit',
          'Sony FX series, prime glass, wireless audio & aerials',
          'KES 35,000 / day',
        ],
        [
          'Executive Post-Production Pack',
          'Offline edit, sound design, ACES grade & master export',
          'KES 40,000 / project',
        ],
      ],
    );

    return await sendEmail(
      recipientEmail: account.email,
      recipientName: 'Brian Etole',
      subject: '[Design Option 2: Editorial Gallery] Welcome & Portfolio Intro — Brian Etole',
      bodyText: content.plainText,
      htmlBody: content.html,
      attachmentBytes: pdfBytes,
      attachmentFilename: 'BE-RC-2026-RateCard.pdf',
      customLogoBytes: customLogo,
    );
  }

  /// Sends BOTH Option 1 and Option 2 to hello@brianetole.com
  static Future<void> sendBothDesignOptions() async {
    await sendOption1CinemaSlate();
    // Brief 1.5s delay to ensure separate timestamps in Gmail inbox
    await Future.delayed(const Duration(milliseconds: 1500));
    await sendOption2EditorialGallery();
  }

  /// Sends a test email using the chosen Editorial Gallery design with inline branding
  static Future<bool> sendTestEmail({String? toEmail}) async {
    var account = await _authService.getSavedAccount();
    if (account == null) {
      account = await _authService.signIn();
      if (account == null) {
        throw GoogleAuthRequiredException(
          'Google sign-in needed to send test email. Please tap Reconnect.',
        );
      }
    }

    final targetEmail = (toEmail != null && toEmail.isNotEmpty)
        ? toEmail
        : account.email;
    final testTpl = await EmailTemplateRepository.getTemplate(
      EmailTemplateType.test,
    );
    final firstName = account.displayName.trim().isNotEmpty
        ? account.displayName.trim().split(' ').first
        : 'Brian';

    final renderedSubject = testTpl.renderSubject({'first_name': firstName});
    final renderedBody = testTpl.renderBody({'first_name': firstName});
    final messageHtml = BrandedEmailBuilder.plainTextToHtmlParagraphs(
      renderedBody,
    );

    final customLogo = await getCustomLogoBytes();
    final socialLinks = await BrandSocialLinksRepository.getSocialLinks();

    final content = BrandedEmailBuilder.buildEmail(
      theme: EmailTheme.editorialGallery,
      recipientName: account.displayName,
      recipientEmail: targetEmail,
      heading: renderedSubject,
      messageHtml: messageHtml,
      messagePlainText: renderedBody,
      hasPdfAttachment: false,
      hasCustomLogo: customLogo != null,
      socialLinks: socialLinks,
    );

    return await sendEmail(
      recipientEmail: targetEmail,
      recipientName: account.displayName,
      subject: renderedSubject,
      bodyText: content.plainText,
      htmlBody: content.html,
      customLogoBytes: customLogo,
    );
  }

  /// Fallback to open the system email app or Gmail with attachment
  static Future<void> openInExternalEmailApp({
    required String recipientEmail,
    List<String> additionalToEmails = const [],
    required String subject,
    required String bodyText,
    required Uint8List attachmentBytes,
    required String attachmentFilename,
    List<EmailAttachmentItem> extraAttachments = const [],
  }) async {
    final tempDir = await getTemporaryDirectory();
    final xfiles = <XFile>[];

    final file = File('${tempDir.path}/$attachmentFilename');
    await file.writeAsBytes(attachmentBytes);
    xfiles.add(XFile(file.path));

    for (final att in extraAttachments) {
      final extraFile = File('${tempDir.path}/${att.filename}');
      await extraFile.writeAsBytes(att.bytes);
      xfiles.add(XFile(extraFile.path));
    }

    final allRecipients = <String>[
      recipientEmail,
      ...additionalToEmails,
    ].map((e) => e.trim()).where((e) => e.isNotEmpty).join(', ');

    await Share.shareXFiles(
      xfiles,
      subject: subject,
      text: '$bodyText\n\n(Recipients: $allRecipients)',
    );
  }
}
