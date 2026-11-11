import 'package:flutter/material.dart';

enum DocCategory {
  financial,
  commercial,
  legal,
}

enum DocType {
  quotation,
  invoice,
  receipt,
  rateCard,
  contract,
}

extension DocTypeExtension on DocType {
  String get code {
    switch (this) {
      case DocType.quotation:
        return 'quotation';
      case DocType.invoice:
        return 'invoice';
      case DocType.receipt:
        return 'receipt';
      case DocType.rateCard:
        return 'rate_card';
      case DocType.contract:
        return 'contract';
    }
  }

  String get displayName {
    switch (this) {
      case DocType.quotation:
        return 'Quotation';
      case DocType.invoice:
        return 'Invoice';
      case DocType.receipt:
        return 'Receipt';
      case DocType.rateCard:
        return 'Rate Card';
      case DocType.contract:
        return 'Contract';
    }
  }

  String get defaultPrefix {
    switch (this) {
      case DocType.quotation:
        return 'BE-QT';
      case DocType.invoice:
        return 'BE-INV';
      case DocType.receipt:
        return 'BE-REC';
      case DocType.rateCard:
        return 'BE-RC';
      case DocType.contract:
        return 'BE-CON';
    }
  }

  DocCategory get category {
    switch (this) {
      case DocType.quotation:
      case DocType.invoice:
      case DocType.receipt:
        return DocCategory.financial;
      case DocType.rateCard:
        return DocCategory.commercial;
      case DocType.contract:
        return DocCategory.legal;
    }
  }

  IconData get icon {
    switch (this) {
      case DocType.quotation:
        return Icons.request_quote_rounded;
      case DocType.invoice:
        return Icons.receipt_long_rounded;
      case DocType.receipt:
        return Icons.task_alt_rounded;
      case DocType.rateCard:
        return Icons.table_chart_rounded;
      case DocType.contract:
        return Icons.draw_rounded;
    }
  }

  bool get hasLineItems {
    switch (this) {
      case DocType.quotation:
      case DocType.invoice:
      case DocType.receipt:
      case DocType.rateCard:
        return true;
      case DocType.contract:
        return false;
    }
  }

  static DocType fromCode(String code) {
    final normalized = code.toLowerCase().trim();
    if (normalized == 'quotation' || normalized == 'qt') {
      return DocType.quotation;
    } else if (normalized == 'receipt' || normalized == 'rec') {
      return DocType.receipt;
    } else if (normalized == 'rate_card' || normalized == 'ratecard' || normalized == 'rc') {
      return DocType.rateCard;
    } else if (normalized == 'contract' ||
        normalized == 'service_agreement' ||
        normalized == 'nda' ||
        normalized == 'con' ||
        normalized == 'sa') {
      return DocType.contract;
    } else {
      return DocType.invoice;
    }
  }
}

class DocumentConstants {
  static const List<String> units = [
    'day',
    'hour',
    'half-day',
    'item',
    'session',
    'lump sum',
    'minute',
    'month',
    'km',
    'deliverable',
  ];

  static const List<String> currencies = [
    'KES',
    'USD',
    'EUR',
    'GBP',
  ];

  static const List<String> pdfTemplates = [
    'classic',
    'modern',
    'minimal',
    'bold',
  ];

  static const List<String> documentStatuses = [
    'draft',
    'sent',
    'accepted',
    'declined',
    'paid',
    'part-paid',
    'overdue',
    'cancelled',
  ];
}
