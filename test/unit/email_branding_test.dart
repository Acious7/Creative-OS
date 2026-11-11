import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:creative_os/features/brands/domain/brand_social_links.dart';
import 'package:creative_os/features/email/domain/branded_email_builder.dart';
import 'package:creative_os/features/email/data/gmail_send_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BrandedEmailBuilder (Option 2: Editorial Gallery)', () {
    test('without custom logo: removes built-in logo and keeps wordmark and tagline', () {
      final content = BrandedEmailBuilder.buildEmail(
        theme: EmailTheme.editorialGallery,
        recipientName: 'Brian Etole',
        recipientEmail: 'hello@brianetole.com',
        heading: 'Test Branded Email',
        messageHtml: '<p>This is a test message.</p>',
        messagePlainText: 'This is a test message.',
        hasPdfAttachment: false,
        hasCustomLogo: false,
      );

      // 1. Must NOT contain built-in logo or cid:logo
      expect(content.html, isNot(contains('cid:logo')));
      expect(content.html, isNot(contains('cid:custom_logo')));

      // 2. Styled text wordmark and tagline must exist
      expect(content.html, contains('BRIAN ETOLE'));
      expect(content.html, contains('REAL STORIES &bull; IMAGINED WORLDS.'));
    });

    test('with custom logo: displays cid:custom_logo above wordmark', () {
      final content = BrandedEmailBuilder.buildEmail(
        theme: EmailTheme.editorialGallery,
        recipientName: 'Brian Etole',
        recipientEmail: 'hello@brianetole.com',
        heading: 'Test Custom Logo',
        messageHtml: '<p>Custom logo test.</p>',
        messagePlainText: 'Custom logo test.',
        hasPdfAttachment: false,
        hasCustomLogo: true,
      );

      expect(content.html, contains('src="cid:custom_logo"'));
      expect(content.html, contains('BRIAN ETOLE'));
    });

    test('footer socials show only Instagram, LinkedIn, and WhatsApp text links in cream/ember', () {
      final content = BrandedEmailBuilder.buildEmail(
        theme: EmailTheme.editorialGallery,
        recipientName: 'Brian Etole',
        recipientEmail: 'hello@brianetole.com',
        heading: 'Test Socials',
        messageHtml: '<p>Test socials.</p>',
        messagePlainText: 'Test socials.',
        hasPdfAttachment: false,
        socialLinks: const BrandSocialLinks(
          instagram: 'instagram.com/brianetole',
          linkedin: 'linkedin.com/in/brianetole',
          whatsapp: '+254 718 013 579',
        ),
      );

      // Clean text links present
      expect(content.html, contains('Instagram</a>'));
      expect(content.html, contains('LinkedIn</a>'));
      expect(content.html, contains('WhatsApp</a>'));

      // In cream color #f3ead9 and ember separator #ff6a1f
      expect(content.html, contains('color: #f3ead9'));
      expect(content.html, contains('color: #ff6a1f'));

      // NO green color allowed (WhatsApp was previously green #25d366)
      expect(content.html, isNot(contains('#25d366')));
      expect(content.html, isNot(contains('#25D366')));

      // YouTube, TikTok, X, and Facebook MUST BE REMOVED
      expect(content.html, isNot(contains('YouTube</a>')));
      expect(content.html, isNot(contains('TikTok</a>')));
      expect(content.html, isNot(contains('>X</a>')));
      expect(content.html, isNot(contains('Facebook</a>')));
      expect(content.html, isNot(contains('cid:youtube')));
      expect(content.html, isNot(contains('cid:tiktok')));
      expect(content.html, isNot(contains('cid:x')));
      expect(content.html, isNot(contains('cid:facebook')));
    });

    test('hides social link if field is empty or null', () {
      final content = BrandedEmailBuilder.buildEmail(
        theme: EmailTheme.editorialGallery,
        recipientName: 'Brian Etole',
        recipientEmail: 'hello@brianetole.com',
        heading: 'Test Partial Socials',
        messageHtml: '<p>Partial socials.</p>',
        messagePlainText: 'Partial socials.',
        hasPdfAttachment: false,
        socialLinks: const BrandSocialLinks(
          instagram: 'instagram.com/brianetole',
          linkedin: '',
          whatsapp: null,
        ),
      );

      expect(content.html, contains('Instagram</a>'));
      expect(content.html, isNot(contains('LinkedIn</a>')));
      expect(content.html, isNot(contains('WhatsApp</a>')));
    });

    test('Cinema Slate theme supports custom logo and editable 3 socials', () {
      final content = BrandedEmailBuilder.buildEmail(
        theme: EmailTheme.cinemaSlate,
        recipientName: 'Brian Etole',
        recipientEmail: 'hello@brianetole.com',
        heading: 'Cinema Slate Test',
        messageHtml: '<p>Cinema Slate test.</p>',
        messagePlainText: 'Cinema Slate test.',
        hasPdfAttachment: false,
        hasCustomLogo: true,
      );

      expect(content.html, contains('src="cid:custom_logo"'));
      expect(content.html, contains('Instagram</a>'));
      expect(content.html, contains('LinkedIn</a>'));
      expect(content.html, contains('WhatsApp</a>'));
      expect(content.html, isNot(contains('YouTube</a>')));
      expect(content.html, isNot(contains('TikTok</a>')));
      expect(content.html, isNot(contains('>X</a>')));
      expect(content.html, isNot(contains('Facebook</a>')));
    });
  });

  group('GmailSendService RFC 822 MIME builder', () {
    test('builds multipart/related MIME with custom logo CID attachment', () {
      final customLogoItem = EmailAttachmentItem(
        filename: 'logo.png',
        bytes: Uint8List.fromList(utf8.encode('custom_logo_png_bytes')),
        mimeType: 'image/png',
        contentId: 'custom_logo',
        isInline: true,
      );

      final rfc822 = GmailSendService.buildRfc822(
        fromName: 'Brian Etole',
        fromEmail: 'hello@brianetole.com',
        toEmails: ['hello@brianetole.com'],
        subject: 'MIME RFC 822 Custom Logo Test',
        plainTextBody: 'Plain text body',
        htmlBody: '<p>HTML body with <img src="cid:custom_logo"/></p>',
        attachments: [customLogoItem],
      );

      expect(rfc822, contains('From: =?UTF-8?B?'));
      expect(rfc822, contains('To: hello@brianetole.com'));
      expect(rfc822, contains('MIME-Version: 1.0'));
      expect(rfc822, contains('Content-Type: multipart/related; boundary="related_boundary_'));
      expect(rfc822, contains('Content-Type: multipart/alternative; boundary="alt_boundary_'));
      expect(rfc822, contains('Content-ID: <custom_logo>'));
      expect(rfc822, contains('Content-Disposition: inline; filename="logo.png"'));
    });

    test('builds multipart/mixed when regular PDF is present along with custom logo', () {
      final inlineLogo = EmailAttachmentItem(
        filename: 'logo.png',
        bytes: Uint8List.fromList(utf8.encode('logo_bytes')),
        mimeType: 'image/png',
        contentId: 'custom_logo',
        isInline: true,
      );

      final pdfDoc = EmailAttachmentItem(
        filename: 'BE-INV-2026-001.pdf',
        bytes: Uint8List.fromList(utf8.encode('%PDF-1.4 sample')),
        mimeType: 'application/pdf',
        isInline: false,
      );

      final rfc822 = GmailSendService.buildRfc822(
        fromName: 'Brian Etole',
        fromEmail: 'hello@brianetole.com',
        toEmails: ['hello@brianetole.com'],
        subject: 'Invoice Attached Test',
        plainTextBody: 'Plain text',
        htmlBody: '<p>Invoice with <img src="cid:custom_logo"/></p>',
        attachments: [inlineLogo, pdfDoc],
      );

      expect(rfc822, contains('Content-Type: multipart/mixed; boundary="mixed_boundary_'));
      expect(rfc822, contains('Content-Type: multipart/related; boundary="related_boundary_'));
      expect(rfc822, contains('Content-ID: <custom_logo>'));
      expect(rfc822, contains('Content-Disposition: inline; filename="logo.png"'));
      expect(rfc822, contains('Content-Disposition: attachment; filename="BE-INV-2026-001.pdf"'));
    });
  });
}
