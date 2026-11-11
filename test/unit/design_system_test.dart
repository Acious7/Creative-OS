import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:creative_os/core/design_system/etole_colors.dart';
import 'package:creative_os/core/design_system/etole_spacing.dart';
import 'package:creative_os/core/design_system/etole_typography.dart';
import 'package:creative_os/features/settings/presentation/screens/design_system_gallery_screen.dart';

void main() {
  group('Etole Design System Tokens', () {
    test('EtoleColors holds correct Afrofuturist studio palette', () {
      expect(EtoleColors.darkBase, const Color(0xFF0A0C0D));
      expect(EtoleColors.oledBase, const Color(0xFF000000));
      expect(EtoleColors.cream, const Color(0xFFF3EAD9));
      expect(EtoleColors.muted, const Color(0xFFA79F90));
      expect(EtoleColors.ember, const Color(0xFFFF6A1F));
    });

    test('EtoleSpacing conforms strictly to 4, 8, 12, 16, 24, 32, 48, 64 scale', () {
      expect(EtoleSpacing.s4, 4.0);
      expect(EtoleSpacing.s8, 8.0);
      expect(EtoleSpacing.s12, 12.0);
      expect(EtoleSpacing.s16, 16.0);
      expect(EtoleSpacing.s24, 24.0);
      expect(EtoleSpacing.s32, 32.0);
      expect(EtoleSpacing.s48, 48.0);
      expect(EtoleSpacing.s64, 64.0);
      expect(EtoleSpacing.minTapTarget, 48.0);
      expect(EtoleSpacing.screenGutter, 24.0);
    });

    test('EtoleTypography defines display BebasNeue & body Inter with tabular figures', () {
      final hero = EtoleTypography.heroDisplay();
      expect(hero.fontFamily, 'BebasNeue');
      expect(hero.fontSize, 48.0);

      final body = EtoleTypography.body();
      expect(body.fontFamily, 'Inter');
      expect(body.fontSize, 14.0);

      final tabular = EtoleTypography.tabularAmount();
      expect(tabular.fontFeatures, isNotEmpty);
      expect(tabular.fontFeatures!.first.feature, 'tnum');
    });

    testWidgets('DesignSystemGalleryScreen renders without error', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DesignSystemGalleryScreen(),
          ),
        ),
      );

      expect(find.text('DESIGN SYSTEM'), findsOneWidget);
      expect(find.text('SHARDS & WORLDS'), findsOneWidget);
      expect(find.text('01 · TYPOGRAPHY'), findsOneWidget);
    });
  });
}
