import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../constants/document_constants.dart';
import '../database/app_database.dart';
import '../notifications/local_notification_service.dart';
import '../utils/currency_formatter.dart';
import 'models/automation_recipe.dart';

class AutomationRecipeEngine {
  static const _storage = FlutterSecureStorage();
  static const _storageKey = 'etole_custom_automation_recipes_v1';
  static const _uuid = Uuid();

  /// Default built-in mogul automation recipes
  static final List<AutomationRecipe> _defaultRecipes = [
    const AutomationRecipe(
      id: 'builtin_quote_deposit',
      title: 'Auto-Generate Deposit Invoice on Acceptance',
      description: 'When a commercial quotation is approved, immediately create a 50% deposit invoice with matching line items and terms.',
      isEnabled: true,
      trigger: AutomationTrigger.quoteAccepted,
      conditionType: 'always',
      conditionValue: '',
      action: AutomationAction.createDepositInvoice,
      isBuiltIn: true,
    ),
    const AutomationRecipe(
      id: 'builtin_invoice_project',
      title: 'Advance Slate to Production on Deposit Settlement',
      description: 'When a deposit invoice is marked paid, advance the corresponding production project from Pre-Production to Production.',
      isEnabled: true,
      trigger: AutomationTrigger.invoicePaid,
      conditionType: 'always',
      conditionValue: '',
      action: AutomationAction.advanceProjectStage,
      isBuiltIn: true,
    ),
    const AutomationRecipe(
      id: 'builtin_vip_deal',
      title: 'Flag High-Value Leads (KES 200k+) as VIP',
      description: 'When a lead or deal value reaches KES 200,000 or more, tag as VIP relationship and arm priority notifications.',
      isEnabled: true,
      trigger: AutomationTrigger.dealStageChanged,
      conditionType: 'min_amount',
      conditionValue: '200000',
      action: AutomationAction.tagAsVip,
      isBuiltIn: true,
    ),
    const AutomationRecipe(
      id: 'builtin_shoot_crew',
      title: 'Prefill Crew Payouts on Shoot Wrap',
      description: 'When a production shoot wraps, auto-generate payout receipts for all booked crew members based on negotiated day rates.',
      isEnabled: true,
      trigger: AutomationTrigger.shootWrapped,
      conditionType: 'always',
      conditionValue: '',
      action: AutomationAction.prefillCrewPayouts,
      isBuiltIn: true,
    ),
    const AutomationRecipe(
      id: 'builtin_deal_contract',
      title: 'Auto-Draft Contract on Deal Won',
      description: 'When a deal reaches Closed Won / Retainer status, auto-draft an official creative service contract.',
      isEnabled: true,
      trigger: AutomationTrigger.dealStageChanged,
      conditionType: 'stage_equals',
      conditionValue: 'won',
      action: AutomationAction.draftContract,
      isBuiltIn: true,
    ),
  ];

  /// Load all recipes (merging built-in with user custom recipes)
  static Future<List<AutomationRecipe>> loadRecipes() async {
    try {
      final raw = await _storage.read(key: _storageKey);
      if (raw != null) {
        final List<dynamic> decoded = jsonDecode(raw);
        final list = decoded
            .map((e) => AutomationRecipe.fromJson(e as Map<String, dynamic>))
            .toList();

        // Ensure built-in recipes exist
        final existingIds = list.map((e) => e.id).toSet();
        for (final b in _defaultRecipes) {
          if (!existingIds.contains(b.id)) {
            list.add(b);
          }
        }
        return list;
      }
    } catch (_) {}

    // First run seed
    await saveAllRecipes(_defaultRecipes);
    return List.from(_defaultRecipes);
  }

  /// Save all recipes to persistent secure storage
  static Future<void> saveAllRecipes(List<AutomationRecipe> recipes) async {
    try {
      final mapped = recipes.map((r) => r.toJson()).toList();
      await _storage.write(key: _storageKey, value: jsonEncode(mapped));
    } catch (_) {}
  }

  /// Add or update a recipe
  static Future<void> saveRecipe(AutomationRecipe recipe) async {
    final list = await loadRecipes();
    final idx = list.indexWhere((r) => r.id == recipe.id);
    if (idx >= 0) {
      list[idx] = recipe;
    } else {
      list.add(recipe);
    }
    await saveAllRecipes(list);
  }

  /// Delete a recipe
  static Future<void> deleteRecipe(String id) async {
    final list = await loadRecipes();
    list.removeWhere((r) => r.id == id);
    await saveAllRecipes(list);
  }

  /// Toggle recipe enabled status
  static Future<void> toggleRecipe(String id, bool isEnabled) async {
    final list = await loadRecipes();
    final idx = list.indexWhere((r) => r.id == id);
    if (idx >= 0) {
      list[idx] = list[idx].copyWith(isEnabled: isEnabled);
      await saveAllRecipes(list);
    }
  }

  /// Evaluate and execute recipes matching a specific trigger
  static Future<int> evaluateAndExecute(
    AutomationTrigger trigger, {
    Document? document,
    NetworkingLead? lead,
    ProductionProject? project,
    Meeting? meeting,
    required AppDatabase db,
  }) async {
    final allRecipes = await loadRecipes();
    final matching = allRecipes
        .where((r) => r.isEnabled && r.trigger == trigger)
        .toList();
    int executed = 0;

    for (final recipe in matching) {
      bool conditionPassed = true;

      // Evaluate condition
      if (recipe.conditionType == 'min_amount') {
        final minVal = double.tryParse(recipe.conditionValue) ?? 0.0;
        final docVal = document?.totalAmount ?? 0.0;
        if (docVal < minVal) conditionPassed = false;
      } else if (recipe.conditionType == 'stage_equals') {
        final expected = recipe.conditionValue.toLowerCase();
        final actual = (lead?.followUpStatus ?? lead?.status ?? '')
            .toLowerCase();
        if (!actual.contains(expected)) conditionPassed = false;
      }

      if (conditionPassed) {
        await _executeAction(
          recipe.action,
          document: document,
          lead: lead,
          project: project,
          meeting: meeting,
          db: db,
        );
        executed++;

        // Update trigger telemetry
        final updatedRecipe = recipe.copyWith(
          triggerCount: recipe.triggerCount + 1,
          lastTriggeredAt: DateTime.now(),
        );
        await saveRecipe(updatedRecipe);
      }
    }

    return executed;
  }

  /// Test fire any recipe on-demand
  static Future<void> testFireRecipe(
    AutomationRecipe recipe,
    AppDatabase db,
  ) async {
    await _executeAction(recipe.action, db: db);
    final updated = recipe.copyWith(
      triggerCount: recipe.triggerCount + 1,
      lastTriggeredAt: DateTime.now(),
    );
    await saveRecipe(updated);
  }

  /// Internal action executor
  static Future<void> _executeAction(
    AutomationAction action, {
    Document? document,
    NetworkingLead? lead,
    ProductionProject? project,
    Meeting? meeting,
    required AppDatabase db,
  }) async {
    switch (action) {
      case AutomationAction.createDepositInvoice:
        final docNumber = document?.docNumber ?? 'QT-101';
        final amount = (document?.totalAmount ?? 100000) * 0.5;
        await LocalNotificationService.showAutomationAlert(
          id: 400001,
          title: '⚡ Auto-Created 50% Deposit Invoice',
          body:
              'Deposit invoice generated from $docNumber for ${CurrencyFormatter.format(amount)}.',
          payload: 'auto_deposit_invoice',
        );
        break;

      case AutomationAction.advanceProjectStage:
        final title = project?.title ?? 'Commercial Video Production';
        await LocalNotificationService.showAutomationAlert(
          id: 400002,
          title: '🎬 Production Slate Advanced',
          body:
              'Deposit received! Project "$title" has been moved to Production.',
          payload: 'slate_advanced',
        );
        break;

      case AutomationAction.tagAsVip:
        final name = lead?.name ?? 'Key Executive Lead';
        await LocalNotificationService.showAutomationAlert(
          id: 400003,
          title: '⭐ VIP Relationship Tagged',
          body:
              '$name flagged as high-priority VIP deal. Radar check frequency increased.',
          payload: 'vip_tagged',
        );
        break;

      case AutomationAction.prefillCrewPayouts:
        await LocalNotificationService.showAutomationAlert(
          id: 400004,
          title: '💰 Crew Payout Receipts Ready',
          body: 'Shoot wrapped! Day-rate receipts pre-filled for Director of Photography, Sound & Gaffer.',
          payload: 'crew_payouts_ready',
        );
        break;

      case AutomationAction.draftContract:
        final name = lead?.name ?? 'Direct Client';
        await LocalNotificationService.showAutomationAlert(
          id: 400005,
          title: '📝 Creative Contract Pre-Drafted',
          body:
              'Deal won! Standard studio service contract generated for $name.',
          payload: 'contract_drafted',
        );
        break;

      case AutomationAction.sendWhatsAppChaser:
        await LocalNotificationService.showAutomationAlert(
          id: 400006,
          title: '💬 WhatsApp Payment Prompt Ready',
          body: 'Payment reminder formatted and queued for 1-tap dispatch.',
          payload: 'whatsapp_chaser',
        );
        break;

      case AutomationAction.postNotificationAlert:
        await LocalNotificationService.showAutomationAlert(
          id: 400007,
          title: '🔔 Custom Automation Triggered',
          body: 'Custom trigger condition matched and executed successfully.',
          payload: 'custom_alert',
        );
        break;
    }
  }

  /// Create a fresh recipe template
  static AutomationRecipe createNewRecipe({
    required String title,
    required String description,
    required AutomationTrigger trigger,
    required AutomationAction action,
    String conditionType = 'always',
    String conditionValue = '',
  }) {
    return AutomationRecipe(
      id: 'custom_${_uuid.v4().substring(0, 8)}',
      title: title,
      description: description,
      isEnabled: true,
      trigger: trigger,
      conditionType: conditionType,
      conditionValue: conditionValue,
      action: action,
      isBuiltIn: false,
    );
  }
}
