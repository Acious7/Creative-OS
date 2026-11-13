import 'document_constants.dart';

class DocTypeDefaultContent {
  final String title;
  final String introText;
  final String termsConditions;
  final String closingNotes;

  const DocTypeDefaultContent({
    required this.title,
    required this.introText,
    required this.termsConditions,
    required this.closingNotes,
  });
}

class DocumentTypeDefaults {
  static DocTypeDefaultContent getDefaults(DocType docType) {
    switch (docType) {
      case DocType.quotation:
        return const DocTypeDefaultContent(
          title: 'Quotation',
          introText: 'Thank you for your business enquiry. I am pleased to submit this commercial quotation for the requested production and creative services detailed below.',
          termsConditions: '1. Commercial Validity: 14 days from date of issue.\n2. Payment Terms: 50% deposit upon commissioning, 50% upon final deliverable handover.\n3. Turnaround: Standard editing cycles apply with up to 2 consolidated revision rounds included.\n4. Copyright: Master deliverables and broadcast rights transfer upon full settlement of all fees.',
          closingNotes: 'To confirm this booking and commission work, please sign and return an accepted copy or issue a corresponding Purchase Order.',
        );

      case DocType.invoice:
        return const DocTypeDefaultContent(
          title: 'Invoice',
          introText: 'Thank you for your business. Please find below the invoice for creative and media services rendered.',
          termsConditions: '1. Payment Due Date: Strictly within 14 days of invoice date unless agreed otherwise in writing.\n2. Withholding Tax: Where applicable, please share Withholding Tax (WHT) certificates upon settlement.\n3. Late Payments: Overdue balances may incur a 2.5% monthly administration fee.',
          closingNotes: 'Payment is appreciated via bank transfer or M-Pesa to the verified details below.',
        );

      case DocType.receipt:
        return const DocTypeDefaultContent(
          title: 'Receipt',
          introText: 'I gratefully acknowledge receipt of payment for services rendered as specified below.',
          termsConditions: '1. Official acknowledgment of settled invoice / deposit.\n2. Retain this receipt for your accounting and audit records.\n3. Payment received subject to bank / mobile clearance.',
          closingNotes: 'Thank you for your business. We value our creative partnership.',
        );

      case DocType.rateCard:
        return const DocTypeDefaultContent(
          title: 'Rate Card',
          introText: 'Standard rate card and service catalog for cinematography, photography, directing, and post-production services.',
          termsConditions: '1. Day rates are based on a standard 10-hour working day (including 1-hour meal break).\n2. Overtime hours are charged at 1.5x standard hourly rate.\n3. Travel, accommodation, and per diems for upcountry or international shoots are billed separately at cost.',
          closingNotes: 'Custom package bundles and retainer agreements are available on request.',
        );

      case DocType.contract:
        return const DocTypeDefaultContent(
          title: 'Creative & Production Contract',
          introText: 'This agreement is entered into between the Service Provider and the Client to govern the provision of creative production and media services.',
          termsConditions: '1. Scope of Work: Services rendered strictly according to the agreed brief and quotation.\n2. Revision Limits: Up to 2 rounds of consolidated feedback included in the base fee.\n3. Payment Schedule: 50% deposit upon contract execution, 50% balance upon final deliverable sign-off.\n4. Intellectual Property: Master deliverable copyright transfers to Client upon receipt of 100% full payment.\n5. Jurisdiction: This Agreement is governed by the Laws of Kenya.',
          closingNotes:
              'Duly executed by authorized representatives of both parties.',
        );
    }
  }
}
