import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum EmailTemplateType {
  quotation,
  invoice,
  receipt,
  rateCard,
  contract,
  intro,
  test,
}

class EmailTemplate {
  final EmailTemplateType type;
  final String label;
  final String description;
  final String subject;
  final String body;

  const EmailTemplate({
    required this.type,
    required this.label,
    required this.description,
    required this.subject,
    required this.body,
  });

  EmailTemplate copyWith({String? subject, String? body}) {
    return EmailTemplate(
      type: type,
      label: label,
      description: description,
      subject: subject ?? this.subject,
      body: body ?? this.body,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'subject': subject,
    'body': body,
  };

  factory EmailTemplate.fromJson(
    Map<String, dynamic> json,
    EmailTemplate defaultTemplate,
  ) {
    return defaultTemplate.copyWith(
      subject: json['subject'] as String?,
      body: json['body'] as String?,
    );
  }

  static const List<String> availablePlaceholders = [
    '{first_name}',
    '{client_name}',
    '{document_number}',
    '{amount}',
    '{due_date}',
    '{project}',
    '{payment_channels}',
    '{showreel_url}',
    '{rate_card_url}',
  ];

  static final Map<EmailTemplateType, EmailTemplate> defaults = {
    EmailTemplateType.quotation: const EmailTemplate(
      type: EmailTemplateType.quotation,
      label: 'Quotation',
      description: 'Used when sending production estimates and quotes',
      subject: 'Quotation {document_number} — {project}',
      body: '''Dear {first_name},

Thank you for reaching out regarding the {project} project. It is a pleasure to connect with you.

Please find attached quotation {document_number} outlining the complete scope of production, cinematography deliverables, and associated costs.

This quotation is valid until {due_date}. Please review the schedule and items at your convenience, and let me know if you would like to adjust any details.

Looking forward to bringing this vision to life.''',
    ),
    EmailTemplateType.invoice: const EmailTemplate(
      type: EmailTemplateType.invoice,
      label: 'Invoice',
      description:
          'Used when billing clients with amount due & payment channels',
      subject: 'Invoice {document_number} — {project}',
      body: '''Dear {first_name},

Thank you for partnering with me on {project}. It has been a privilege documenting these stories.

Please find attached the official invoice {document_number} for the amount of {amount}, due on or before {due_date}.

Payment Details:
{payment_channels}

If your accounts department requires any additional vendor details or an E-TIMS confirmation, please do not hesitate to let me know.''',
    ),
    EmailTemplateType.receipt: const EmailTemplate(
      type: EmailTemplateType.receipt,
      label: 'Receipt',
      description: 'Payment confirmation and receipt acknowledgment',
      subject: 'Receipt {document_number} — Thank you for your payment',
      body: '''Dear {first_name},

Thank you! This is to acknowledge receipt of payment for invoice {document_number} in the amount of {amount}.

Please find attached your official payment receipt for your records.

I truly appreciate your timely settlement and look forward to our continued collaboration on upcoming creative projects.''',
    ),
    EmailTemplateType.rateCard: const EmailTemplate(
      type: EmailTemplateType.rateCard,
      label: 'Rate Card',
      description: 'Standard day rates, kit specs, and production tiers',
      subject: 'Production Rate Card 2026 — Creative Studio',
      body: '''Hello {first_name},

Thank you for your interest in our creative production services.

Please find attached our current 2026 Rate Card, detailing standard rates for directing, commercial cinematography, audio capture, and post-production color finishing.

You can also explore our portfolio and commercial work at:
https://brianetole.com

We would be happy to discuss your project requirements and tailor an estimate specifically for your production timeline.''',
    ),
    EmailTemplateType.contract: const EmailTemplate(
      type: EmailTemplateType.contract,
      label: 'Contract',
      description: 'Production agreements, releases, and clause contracts',
      subject: 'Contract {document_number} — Please review and sign',
      body: '''Dear {first_name},

I hope this finds you well.

Attached is the production agreement {document_number} for {project}.

Please review the terms, licensing, and deliverables schedule. Once confirmed, you can sign and return a copy so we can lock in the production dates.

Feel free to reach out directly if you have any questions.''',
    ),
    EmailTemplateType.intro: const EmailTemplate(
      type: EmailTemplateType.intro,
      label: 'Welcome / Introduction',
      description: 'Sent to new networking contacts with bio, card & reel link',
      subject:
          'Great meeting you — Creative Studio | Production & Creative Direction',
      body: '''Hello {first_name},

It was a real pleasure connecting with you recently at {project}.

As discussed, we are a creative production studio specializing in authentic commercial storytelling, cinematic field visuals, and creative direction.

You can view our digital business card and showreels here:
Portfolio: https://brianetole.com

Attached is our 2026 Rate Card for your future reference. Whenever a story, campaign, or event arises that calls for cinematic treatment, we would love to collaborate.''',
    ),
    EmailTemplateType.test: const EmailTemplate(
      type: EmailTemplateType.test,
      label: 'Test Connection',
      description: 'Used to test email API connection and template rendering',
      subject: 'Creative OS — Email Integration Test',
      body: '''Hello {first_name},

This is a live test from your email integration. Outgoing emails are rendered using your signature editorial aesthetic.

All document details, payment channels, and PDF attachments are rendered directly below.''',
    ),
  };

  /// Render subject with placeholder replacement
  String renderSubject(Map<String, String> values) {
    var result = subject;
    values.forEach((key, val) {
      result = result.replaceAll('{$key}', val);
      result = result.replaceAll('{$key}'.toLowerCase(), val);
    });
    return result;
  }

  /// Render body with placeholder replacement
  String renderBody(Map<String, String> values) {
    var result = body;
    values.forEach((key, val) {
      result = result.replaceAll('{$key}', val);
      result = result.replaceAll('{$key}'.toLowerCase(), val);
    });
    return result;
  }
}

class EmailTemplateRepository {
  static const _storagePrefix = 'etole_email_template_';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<EmailTemplate> getTemplate(EmailTemplateType type) async {
    final defaultTpl = EmailTemplate.defaults[type]!;
    try {
      final raw = await _storage.read(key: '$_storagePrefix${type.name}');
      if (raw == null) return defaultTpl;

      final decoded = json.decode(raw) as Map<String, dynamic>;
      return EmailTemplate.fromJson(decoded, defaultTpl);
    } catch (_) {
      return defaultTpl;
    }
  }

  static Future<void> saveTemplate(EmailTemplate template) async {
    try {
      await _storage.write(
        key: '$_storagePrefix${template.type.name}',
        value: json.encode(template.toJson()),
      );
    } catch (_) {}
  }

  static Future<void> resetTemplate(EmailTemplateType type) async {
    try {
      await _storage.delete(key: '$_storagePrefix${type.name}');
    } catch (_) {}
  }

  static Future<Map<EmailTemplateType, EmailTemplate>> getAllTemplates() async {
    final result = <EmailTemplateType, EmailTemplate>{};
    for (final type in EmailTemplateType.values) {
      result[type] = await getTemplate(type);
    }
    return result;
  }
}
