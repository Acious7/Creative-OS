import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/etole_colors.dart';
import '../../../../core/design_system/etole_components.dart';
import '../../../../core/design_system/etole_typography.dart';
import '../../domain/hub_models.dart';

class WorldContainer extends ConsumerWidget {
  final EtoleWorld world;
  final Widget child;

  const WorldContainer({super.key, required this.world, required this.child});

  void _returnToHub(WidgetRef ref) {
    EtoleHaptics.light();
    ref.read(activeWorldProvider.notifier).state = null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _returnToHub(ref);
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? EtoleColors.darkBase : EtoleColors.lightBase,
        body: GestureDetector(
          // Swipe down from top edge to return to Hub
          onVerticalDragUpdate: (details) {
            if (details.globalPosition.dy < 120 &&
                details.primaryDelta != null &&
                details.primaryDelta! > 14) {
              _returnToHub(ref);
            }
          },
          child: Stack(
            children: [
              // 1. World Main Content
              Positioned.fill(child: child),

              // 2. Top-left Shard Back Pill (Floating Frosted Glass)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 12.0),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: EtoleGlassPill(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      onTap: () => _returnToHub(ref),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 13,
                            color: isDark
                                ? EtoleColors.cream
                                : EtoleColors.lightTextPrimary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'HUB',
                            style: EtoleTypography.labelCaps(
                              color: isDark
                                  ? EtoleColors.cream
                                  : EtoleColors.lightTextPrimary,
                            ).copyWith(fontSize: 10, letterSpacing: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
