import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';

enum EtoleWorld {
  production,
  brian,
  network,
  docs,
  meetings,
  settings;

  String get displayName {
    switch (this) {
      case EtoleWorld.production:
        return 'PRODUCTION';
      case EtoleWorld.brian:
        return 'STAGE';
      case EtoleWorld.network:
        return 'NETWORK';
      case EtoleWorld.docs:
        return 'DOCS';
      case EtoleWorld.meetings:
        return 'MEETINGS';
      case EtoleWorld.settings:
        return 'SETTINGS';
    }
  }

  String get subtitle {
    switch (this) {
      case EtoleWorld.production:
        return 'THE SET';
      case EtoleWorld.brian:
        return 'DIGITAL CARD';
      case EtoleWorld.network:
        return 'THE CONSTELLATION';
      case EtoleWorld.docs:
        return 'THE DESK';
      case EtoleWorld.meetings:
        return 'THE MEMORY';
      case EtoleWorld.settings:
        return 'THE WORKSHOP';
    }
  }

  List<String> get letterSequence {
    return displayName.split('');
  }
}

/// The currently active world in Etole (null = The Hub)
final activeWorldProvider = StateProvider<EtoleWorld?>((ref) => null);

/// Active gyro/drag tilt angles (tiltX, tiltY) in range [-1.0, 1.0]
final hubTiltProvider = StateProvider<(double, double)>((ref) => (0.0, 0.0));

/// Open app to target preference
enum OpenAppToTarget { hub, card }

final openAppToProvider = StateProvider<OpenAppToTarget>(
  (ref) => OpenAppToTarget.hub,
);

/// Check if any networking event/occasion is scheduled for today
final hasTodayOccasionProvider = StreamProvider<bool>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(
    db.networkingEvents,
  )..where((e) => e.isDeleted.equals(false))).watch().map((events) {
    final now = DateTime.now();
    return events.any(
      (e) =>
          e.startDate.year == now.year &&
          e.startDate.month == now.month &&
          e.startDate.day == now.day,
    );
  });
});

/// Check if any document is overdue
final hasOverdueDocsProvider = StreamProvider<bool>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(
    db.documents,
  )..where((d) => d.isDeleted.equals(false))).watch().map((docs) {
    final now = DateTime.now();
    return docs.any(
      (d) =>
          d.status.toLowerCase() == 'overdue' ||
          (d.status.toLowerCase() != 'paid' &&
              d.status.toLowerCase() != 'cancelled' &&
              d.dueOrValidityDate != null &&
              d.dueOrValidityDate!.isBefore(now)),
    );
  });
});

/// Latest active production project for Studio OS Dashboard
final upcomingProductionProvider = StreamProvider<ProductionProject?>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.productionProjects)
        ..where((p) => p.isDeleted.equals(false))
        ..orderBy([
          (p) => drift.OrderingTerm(
            expression: p.updatedAt,
            mode: drift.OrderingMode.desc,
          ),
        ])
        ..limit(1))
      .watchSingleOrNull();
});
