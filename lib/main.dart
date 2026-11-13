import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/automation/studio_automation_service.dart';
import 'core/notifications/local_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/brand_theme_provider.dart';
import 'features/navigation/presentation/main_shell.dart';
import 'features/security/presentation/app_lock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications early
  await LocalNotificationService.init();

  // Initialize background automation watchdog (WorkManager)
  await StudioAutomationService.initBackgroundWorkmanager();

  // Set immersive dark UI overlay by default
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const ProviderScope(child: EtoleApp()));
}

class EtoleApp extends ConsumerStatefulWidget {
  const EtoleApp({super.key});

  @override
  ConsumerState<EtoleApp> createState() => _EtoleAppState();
}

class _EtoleAppState extends ConsumerState<EtoleApp> {
  bool _isAuthenticated = false;

  @override
  Widget build(BuildContext context) {
    final studioTheme = ref.watch(currentStudioThemeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Etole',
      debugShowCheckedModeBanner: false,
      theme: studioTheme.toMaterialThemeData(),
      darkTheme: studioTheme.toMaterialThemeData(),
      themeMode: themeMode,
      home: _isAuthenticated
          ? const MainShell()
          : AppLockScreen(
              onAuthenticated: () {
                setState(() {
                  _isAuthenticated = true;
                });
              },
            ),
    );
  }
}
