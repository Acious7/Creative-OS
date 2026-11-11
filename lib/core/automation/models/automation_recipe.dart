import 'dart:convert';

enum AutomationTrigger {
  quoteAccepted,
  invoicePaid,
  dealStageChanged,
  meetingConcluded,
  shootWrapped,
  invoiceOverdue,
  vipInactive,
}

extension AutomationTriggerExt on AutomationTrigger {
  String get displayName {
    switch (this) {
      case AutomationTrigger.quoteAccepted:
        return 'Quotation Accepted / Commissioned';
      case AutomationTrigger.invoicePaid:
        return 'Invoice Marked Paid / Deposit Received';
      case AutomationTrigger.dealStageChanged:
        return 'Deal Moved to Closed Won / Retainer';
      case AutomationTrigger.meetingConcluded:
        return 'Meeting Concluded';
      case AutomationTrigger.shootWrapped:
        return 'Production Shoot Wrapped';
      case AutomationTrigger.invoiceOverdue:
        return 'Invoice Becomes Overdue';
      case AutomationTrigger.vipInactive:
        return 'VIP Contact Inactive (>30 Days)';
    }
  }

  String get shortCode {
    switch (this) {
      case AutomationTrigger.quoteAccepted:
        return 'QUOTE_ACCEPTED';
      case AutomationTrigger.invoicePaid:
        return 'INVOICE_PAID';
      case AutomationTrigger.dealStageChanged:
        return 'DEAL_CLOSED_WON';
      case AutomationTrigger.meetingConcluded:
        return 'MEETING_CONCLUDED';
      case AutomationTrigger.shootWrapped:
        return 'SHOOT_WRAPPED';
      case AutomationTrigger.invoiceOverdue:
        return 'INVOICE_OVERDUE';
      case AutomationTrigger.vipInactive:
        return 'VIP_INACTIVE';
    }
  }
}

enum AutomationAction {
  createDepositInvoice,
  advanceProjectStage,
  prefillCrewPayouts,
  draftContract,
  sendWhatsAppChaser,
  postNotificationAlert,
  tagAsVip,
}

extension AutomationActionExt on AutomationAction {
  String get displayName {
    switch (this) {
      case AutomationAction.createDepositInvoice:
        return 'Auto-Generate 50% Deposit Invoice';
      case AutomationAction.advanceProjectStage:
        return 'Advance Project Stage (Pre-Prod ➔ Production)';
      case AutomationAction.prefillCrewPayouts:
        return 'Prefill Crew Payout Receipts from Roster';
      case AutomationAction.draftContract:
        return 'Auto-Draft Creative Service Contract';
      case AutomationAction.sendWhatsAppChaser:
        return 'Prompt WhatsApp Payment Chaser';
      case AutomationAction.postNotificationAlert:
        return 'Push High-Priority Notification Alert';
      case AutomationAction.tagAsVip:
        return 'Tag Lead as VIP Relationship';
    }
  }

  String get shortCode {
    switch (this) {
      case AutomationAction.createDepositInvoice:
        return 'GENERATE_DEPOSIT_INVOICE';
      case AutomationAction.advanceProjectStage:
        return 'ADVANCE_PROJECT_STAGE';
      case AutomationAction.prefillCrewPayouts:
        return 'PREFILL_CREW_PAYOUTS';
      case AutomationAction.draftContract:
        return 'DRAFT_CONTRACT';
      case AutomationAction.sendWhatsAppChaser:
        return 'WHATSAPP_CHASER';
      case AutomationAction.postNotificationAlert:
        return 'PUSH_ALERT';
      case AutomationAction.tagAsVip:
        return 'TAG_VIP';
    }
  }
}

class AutomationRecipe {
  final String id;
  final String title;
  final String description;
  final bool isEnabled;
  final AutomationTrigger trigger;
  final String conditionType; // 'always', 'min_amount', 'stage_equals'
  final String conditionValue;
  final AutomationAction action;
  final int triggerCount;
  final DateTime? lastTriggeredAt;
  final bool isBuiltIn;

  const AutomationRecipe({
    required this.id,
    required this.title,
    required this.description,
    this.isEnabled = true,
    required this.trigger,
    this.conditionType = 'always',
    this.conditionValue = '',
    required this.action,
    this.triggerCount = 0,
    this.lastTriggeredAt,
    this.isBuiltIn = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'isEnabled': isEnabled,
    'trigger': trigger.name,
    'conditionType': conditionType,
    'conditionValue': conditionValue,
    'action': action.name,
    'triggerCount': triggerCount,
    'lastTriggeredAt': lastTriggeredAt?.toIso8601String(),
    'isBuiltIn': isBuiltIn,
  };

  factory AutomationRecipe.fromJson(Map<String, dynamic> json) {
    return AutomationRecipe(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      isEnabled: json['isEnabled'] as bool? ?? true,
      trigger: AutomationTrigger.values.firstWhere(
        (e) => e.name == json['trigger'],
        orElse: () => AutomationTrigger.quoteAccepted,
      ),
      conditionType: json['conditionType'] as String? ?? 'always',
      conditionValue: json['conditionValue'] as String? ?? '',
      action: AutomationAction.values.firstWhere(
        (e) => e.name == json['action'],
        orElse: () => AutomationAction.postNotificationAlert,
      ),
      triggerCount: json['triggerCount'] as int? ?? 0,
      lastTriggeredAt: json['lastTriggeredAt'] != null
          ? DateTime.tryParse(json['lastTriggeredAt'] as String)
          : null,
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
    );
  }

  AutomationRecipe copyWith({
    String? id,
    String? title,
    String? description,
    bool? isEnabled,
    AutomationTrigger? trigger,
    String? conditionType,
    String? conditionValue,
    AutomationAction? action,
    int? triggerCount,
    DateTime? lastTriggeredAt,
    bool? isBuiltIn,
  }) {
    return AutomationRecipe(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isEnabled: isEnabled ?? this.isEnabled,
      trigger: trigger ?? this.trigger,
      conditionType: conditionType ?? this.conditionType,
      conditionValue: conditionValue ?? this.conditionValue,
      action: action ?? this.action,
      triggerCount: triggerCount ?? this.triggerCount,
      lastTriggeredAt: lastTriggeredAt ?? this.lastTriggeredAt,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
    );
  }
}
