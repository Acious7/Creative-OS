import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_colors.dart';
import '../database/app_database.dart';
import '../database/database_provider.dart';

final allBrandsStreamProvider = StreamProvider<List<Brand>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.brands)..where((b) => b.isActive.equals(true))).watch();
});

final activeBrandIdProvider = StateProvider<int>((ref) => 1);

/// In Etole, there is ONE identity: Brian Etole (VisualStoryteller).
final activeBrandProvider = Provider<Brand?>((ref) {
  final brandsAsync = ref.watch(allBrandsStreamProvider);

  return brandsAsync.when(
    data: (brands) {
      if (brands.isEmpty) return null;
      return brands.firstWhere(
        (b) => b.name.toLowerCase().contains('brian') || b.name.toLowerCase().contains('etole'),
        orElse: () => brands.first,
      );
    },
    loading: () {
      final list = brandsAsync.valueOrNull;
      if (list == null || list.isEmpty) return null;
      return list.firstWhere(
        (b) => b.name.toLowerCase().contains('brian') || b.name.toLowerCase().contains('etole'),
        orElse: () => list.first,
      );
    },
    error: (_, __) => null,
  );
});

/// Default hero accent from Brian Etole VisualStoryteller Quotation (#38B6DB Cyan / #F5A623 Gold)
const Color etoleCyan = Color(0xFF38B6DB);
const Color etoleGold = Color(0xFFF5A623);
const Color etoleOrange = etoleCyan; // Alias for seamless backwards compatibility

final activeAccentColorProvider = Provider<Color>((ref) {
  final brand = ref.watch(activeBrandProvider);
  if (brand == null) return etoleCyan;
  return AppColors.parseHex(brand.accentColorHex, fallback: etoleCyan);
});

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);
final isOledModeProvider = StateProvider<bool>((ref) => false);
final reduceMotionProvider = StateProvider<bool>((ref) => false);
final soundEnabledProvider = StateProvider<bool>((ref) => false);
final remindersLeadDaysProvider = StateProvider<int>((ref) => 1);
final remindersHourProvider = StateProvider<int>((ref) => 9);
final overdueRemindersEnabledProvider = StateProvider<bool>((ref) => true);
