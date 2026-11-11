import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quick_actions/quick_actions.dart';

import '../../../core/assistant/executive_chief_of_staff_sheet.dart';
import '../../../core/assistant/executive_morning_radar_sheet.dart';
import '../../../core/automation/studio_automation_service.dart';
import '../../../core/constants/document_constants.dart';
import '../../digital_cards/presentation/screens/card_presentation_screen.dart';
import '../../digital_cards/presentation/screens/network_hub_screen.dart';
import '../../documents/presentation/screens/document_detail_screen.dart';
import '../../documents/presentation/screens/document_editor_screen.dart';
import '../../documents/presentation/screens/docs_home_screen.dart';
import '../../hub/domain/hub_models.dart';
import '../../hub/presentation/screens/hub_screen.dart';
import '../../hub/presentation/widgets/world_container.dart';
import '../../meetings/presentation/screens/meetings_hub_screen.dart';
import '../../production/presentation/screens/production_hub_screen.dart';
import '../../settings/presentation/screens/settings_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  @override
  void initState() {
    super.initState();
    _setupQuickActions();
    _checkInitialOpenTarget();
    _initAutomations();
  }

  void _initAutomations() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      StudioAutomationService.runHealthCheck(ref);
    });
  }

  void _checkInitialOpenTarget() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final openTarget = ref.read(openAppToProvider);
      if (openTarget == OpenAppToTarget.card) {
        ref.read(activeWorldProvider.notifier).state = EtoleWorld.brian;
      }
    });
  }

  void _setupQuickActions() {
    try {
      const quickActions = QuickActions();
      quickActions.initialize((shortcutType) {
        if (!mounted) return;
        switch (shortcutType) {
          case 'show_card':
            ref.read(activeWorldProvider.notifier).state = EtoleWorld.brian;
            break;
          case 'new_quote':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const DocumentEditorScreen(docType: DocType.quotation),
              ),
            );
            break;
          case 'chief_of_staff':
            ExecutiveChiefOfStaffSheet.show(context);
            break;
          case 'morning_radar':
            ExecutiveMorningRadarSheet.show(context);
            break;
        }
      });
      quickActions.setShortcutItems(<ShortcutItem>[
        const ShortcutItem(
          type: 'new_quote',
          localizedTitle: 'New Quotation',
          icon: 'ic_launcher',
        ),
        const ShortcutItem(
          type: 'chief_of_staff',
          localizedTitle: 'Chief of Staff',
          icon: 'ic_launcher',
        ),
        const ShortcutItem(
          type: 'morning_radar',
          localizedTitle: 'Morning Radar',
          icon: 'ic_launcher',
        ),
        const ShortcutItem(
          type: 'show_card',
          localizedTitle: 'Present Card',
          icon: 'ic_launcher',
        ),
      ]);
    } catch (_) {}
  }

  void _onNewDocumentSelected(DocType docType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => DocumentEditorScreen(docType: docType),
      ),
    );
  }

  void _onOpenDocument(int docId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => DocumentDetailScreen(documentId: docId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeWorld = ref.watch(activeWorldProvider);

    // When at the Hub: Render HubScreen with the 4 floating shards & living background
    if (activeWorld == null) {
      return HubScreen(
        onWorldSelected: (world) {
          ref.read(activeWorldProvider.notifier).state = world;
        },
      );
    }

    // Inside a World: Render the chosen world inside WorldContainer with shard back navigation
    Widget worldContent;
    switch (activeWorld) {
      case EtoleWorld.production:
        worldContent = const ProductionHubScreen();
        break;
      case EtoleWorld.brian:
        worldContent = const CardPresentationScreen();
        break;
      case EtoleWorld.network:
        worldContent = const NetworkHubScreen();
        break;
      case EtoleWorld.docs:
        worldContent = DocsHomeScreen(
          onOpenDocument: _onOpenDocument,
          onNewDocument: _onNewDocumentSelected,
        );
        break;
      case EtoleWorld.meetings:
        worldContent = const MeetingsHubScreen();
        break;
      case EtoleWorld.settings:
        worldContent = const SettingsScreen();
        break;
    }

    return WorldContainer(world: activeWorld, child: worldContent);
  }
}
