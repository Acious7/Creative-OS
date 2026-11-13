import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_colors.dart';
import '../database/app_database.dart';
import '../database/database_provider.dart';
import 'studio_theme.dart';

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
        (b) =>
            b.name.toLowerCase().contains('brian') ||
            b.name.toLowerCase().contains('etole'),
        orElse: () => brands.first,
      );
    },
    loading: () {
      final list = brandsAsync.valueOrNull;
      if (list == null || list.isEmpty) return null;
      return list.firstWhere(
        (b) =>
            b.name.toLowerCase().contains('brian') ||
            b.name.toLowerCase().contains('etole'),
        orElse: () => list.first,
      );
    },
    error: (_, __) => null,
  );
});

// --- Studio Theme Persistence & State ---
const String _kThemeIdKey = 'etole_studio_theme_id';
const String _kFollowDarkKey = 'etole_follow_system_dark';
const String _kMatchCardKey = 'etole_match_card_theme';

class StudioThemeSettings {
  final StudioThemeId themeId;
  final bool followSystemDark;
  final bool matchCardToTheme;

  const StudioThemeSettings({
    this.themeId = StudioThemeId.tribalOrange,
    this.followSystemDark = false,
    this.matchCardToTheme = false,
  });

  StudioThemeSettings copyWith({
    StudioThemeId? themeId,
    bool? followSystemDark,
    bool? matchCardToTheme,
  }) {
    return StudioThemeSettings(
      themeId: themeId ?? this.themeId,
      followSystemDark: followSystemDark ?? this.followSystemDark,
      matchCardToTheme: matchCardToTheme ?? this.matchCardToTheme,
    );
  }
}

class StudioThemeNotifier extends StateNotifier<StudioThemeSettings> {
  static const _storage = FlutterSecureStorage();

  StudioThemeNotifier() : super(const StudioThemeSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final themeStr = await _storage.read(key: _kThemeIdKey);
      final followStr = await _storage.read(key: _kFollowDarkKey);
      final matchStr = await _storage.read(key: _kMatchCardKey);

      StudioThemeId id = StudioThemeId.tribalOrange;
      if (themeStr != null) {
        id = StudioThemeId.values.firstWhere(
          (e) => e.name == themeStr,
          orElse: () => StudioThemeId.tribalOrange,
        );
      }

      state = StudioThemeSettings(
        themeId: id,
        followSystemDark: followStr == 'true',
        matchCardToTheme: matchStr == 'true',
      );
    } catch (_) {}
  }

  Future<void> setTheme(StudioThemeId id) => setThemeId(id);

  Future<void> setThemeId(StudioThemeId id) async {
    state = state.copyWith(themeId: id);
    try {
      await _storage.write(key: _kThemeIdKey, value: id.name);
    } catch (_) {}
  }

  Future<void> setFollowSystemDark(bool follow) async {
    state = state.copyWith(followSystemDark: follow);
    try {
      await _storage.write(key: _kFollowDarkKey, value: follow.toString());
    } catch (_) {}
  }

  Future<void> setMatchCardToTheme(bool match) async {
    state = state.copyWith(matchCardToTheme: match);
    try {
      await _storage.write(key: _kMatchCardKey, value: match.toString());
    } catch (_) {}
  }
}

final studioThemeSettingsProvider =
    StateNotifierProvider<StudioThemeNotifier, StudioThemeSettings>((ref) {
      return StudioThemeNotifier();
    });

/// Current active StudioThemeData taking into account settings and system dark mode
final currentStudioThemeProvider = Provider<StudioThemeData>((ref) {
  final settings = ref.watch(studioThemeSettingsProvider);
  if (settings.followSystemDark) {
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    if (brightness == Brightness.light &&
        settings.themeId != StudioThemeId.savannahLight) {
      return StudioThemeData.savannahLight;
    } else if (brightness == Brightness.dark &&
        settings.themeId == StudioThemeId.savannahLight) {
      return StudioThemeData.tribalOrange;
    }
  }
  return StudioThemeData.fromId(settings.themeId);
});

final matchCardToThemeProvider = Provider<bool>((ref) {
  return ref.watch(studioThemeSettingsProvider).matchCardToTheme;
});

final followSystemDarkModeProvider = Provider<bool>((ref) {
  return ref.watch(studioThemeSettingsProvider).followSystemDark;
});

/// Default hero accent from Brian Etole VisualStoryteller Quotation (#38B6DB Cyan / #F5A623 Gold)
const Color etoleCyan = Color(0xFF38B6DB);
const Color etoleGold = Color(0xFFF5A623);
const Color etoleOrange = Color(0xFFFF6B00); // Signature Tribal Orange

final activeAccentColorProvider = Provider<Color>((ref) {
  final theme = ref.watch(currentStudioThemeProvider);
  return theme.primaryAccent;
});

final themeModeProvider = Provider<ThemeMode>((ref) {
  final settings = ref.watch(studioThemeSettingsProvider);
  if (settings.followSystemDark) return ThemeMode.system;
  final theme = StudioThemeData.fromId(settings.themeId);
  return theme.isDark ? ThemeMode.dark : ThemeMode.light;
});

final isOledModeProvider = StateProvider<bool>((ref) => false);
final reduceMotionProvider = StateProvider<bool>((ref) => false);
final soundEnabledProvider = StateProvider<bool>((ref) => false);
final remindersLeadDaysProvider = StateProvider<int>((ref) => 1);
final remindersHourProvider = StateProvider<int>((ref) => 9);
final overdueRemindersEnabledProvider = StateProvider<bool>((ref) => true);
