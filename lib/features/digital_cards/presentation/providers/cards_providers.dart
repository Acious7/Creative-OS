import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import '../../../../core/database/app_database.dart';
import '../../../../core/database/database_provider.dart';
import '../../../../core/theme/brand_theme_provider.dart';

// Stream of all cards for active brand
final brandCardsProvider = StreamProvider.autoDispose<List<BusinessCard>>((
  ref,
) {
  final db = ref.watch(databaseProvider);
  final activeBrand = ref.watch(activeBrandProvider);
  if (activeBrand == null) return Stream.value([]);
  return (db.select(db.businessCards)
        ..where(
          (t) => t.brandId.equals(activeBrand.id) & t.isDeleted.equals(false),
        )
        ..orderBy([
          (t) => drift.OrderingTerm(
            expression: t.isDefault,
            mode: drift.OrderingMode.desc,
          ),
        ]))
      .watch();
});

// Currently selected / default card for active brand
final selectedBrandCardProvider = StateProvider<BusinessCard?>((ref) => null);

// Stream of default card for active brand
final defaultBrandCardProvider = StreamProvider.autoDispose<BusinessCard?>((
  ref,
) {
  final db = ref.watch(databaseProvider);
  final activeBrand = ref.watch(activeBrandProvider);
  if (activeBrand == null) return Stream.value(null);
  return (db.select(db.businessCards)..where(
        (t) =>
            t.brandId.equals(activeBrand.id) &
            t.isDeleted.equals(false) &
            t.isDefault.equals(true),
      ))
      .watchSingleOrNull();
});

// Stream of all networking leads for active brand
final networkingLeadsProvider =
    StreamProvider.autoDispose<List<NetworkingLead>>((ref) {
      final db = ref.watch(databaseProvider);
      final activeBrand = ref.watch(activeBrandProvider);
      if (activeBrand == null) return Stream.value([]);
      return (db.select(db.networkingLeads)
            ..where(
              (t) =>
                  t.brandId.equals(activeBrand.id) & t.isDeleted.equals(false),
            )
            ..orderBy([
              (t) => drift.OrderingTerm(
                expression: t.createdAt,
                mode: drift.OrderingMode.desc,
              ),
            ]))
          .watch();
    });

// Stream of active networking events for active brand
final networkingEventsProvider =
    StreamProvider.autoDispose<List<NetworkingEvent>>((ref) {
      final db = ref.watch(databaseProvider);
      final activeBrand = ref.watch(activeBrandProvider);
      if (activeBrand == null) return Stream.value([]);
      return (db.select(db.networkingEvents)
            ..where(
              (t) =>
                  t.brandId.equals(activeBrand.id) & t.isDeleted.equals(false),
            )
            ..orderBy([
              (t) => drift.OrderingTerm(
                expression: t.startDate,
                mode: drift.OrderingMode.desc,
              ),
            ]))
          .watch();
    });

// Stream of currently active Event Mode event (if any)
final activeEventModeProvider = StreamProvider.autoDispose<NetworkingEvent?>((
  ref,
) {
  final db = ref.watch(databaseProvider);
  final activeBrand = ref.watch(activeBrandProvider);
  if (activeBrand == null) return Stream.value(null);
  return (db.select(db.networkingEvents)..where(
        (t) =>
            t.brandId.equals(activeBrand.id) &
            t.isDeleted.equals(false) &
            t.isEventModeActive.equals(true),
      ))
      .watchSingleOrNull();
});

// Count of leads needing follow-up
final pendingFollowUpsCountProvider = Provider.autoDispose<int>((ref) {
  final leads = ref.watch(networkingLeadsProvider).value ?? [];
  final now = DateTime.now();
  return leads
      .where(
        (l) =>
            l.followUpDate != null &&
            l.followUpDate!.isBefore(now.add(const Duration(days: 1))) &&
            l.followUpStatus == 'pending',
      )
      .length;
});

// Stream of leads met at a specific event
final eventLeadsProvider = StreamProvider.autoDispose
    .family<List<NetworkingLead>, int>((ref, eventId) {
      final db = ref.watch(databaseProvider);
      return (db.select(db.networkingLeads)
            ..where(
              (t) =>
                  t.isDeleted.equals(false) &
                  (t.eventId.equals(eventId) |
                      t.eventIdsJson.like('%$eventId%')),
            )
            ..orderBy([
              (t) => drift.OrderingTerm(
                expression: t.createdAt,
                mode: drift.OrderingMode.desc,
              ),
            ]))
          .watch();
    });

// Stream of single event by ID
final singleEventProvider = StreamProvider.autoDispose
    .family<NetworkingEvent?, int>((ref, eventId) {
      final db = ref.watch(databaseProvider);
      return (db.select(db.networkingEvents)
            ..where((t) => t.id.equals(eventId) & t.isDeleted.equals(false)))
          .watchSingleOrNull();
    });

// Stream of single lead by ID
final singleLeadProvider = StreamProvider.autoDispose
    .family<NetworkingLead?, int>((ref, leadId) {
      final db = ref.watch(databaseProvider);
      return (db.select(db.networkingLeads)
            ..where((t) => t.id.equals(leadId) & t.isDeleted.equals(false)))
          .watchSingleOrNull();
    });

// Stream of all events where a specific lead was met
final leadEventsProvider = StreamProvider.autoDispose
    .family<List<NetworkingEvent>, NetworkingLead>((ref, lead) {
      final db = ref.watch(databaseProvider);
      final allEvents = ref.watch(networkingEventsProvider).value ?? [];

      final matched = allEvents.where((e) {
        if (e.id == lead.eventId) return true;
        if (lead.eventIdsJson != null &&
            lead.eventIdsJson!.contains(e.id.toString()))
          return true;
        return false;
      }).toList();
      return Stream.value(matched);
    });
