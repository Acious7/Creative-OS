import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/dashboard_screen.dart';
import 'theme/cinematic_theme.dart';
import 'services/database_helper.dart';
import 'services/sync_service.dart';
void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    final dbHelper = DatabaseHelper();
    await dbHelper.database;
    runApp(
          MultiProvider(
                  providers: [
                            Provider<DatabaseHelper>.value(value: dbHelper),
                            Provider<SyncService>(create: (_) => SyncService()),
                          ],
                  child: const CreativeOS(),
                ),
        );
}
class CreativeOS extends StatelessWidget {
    const CreativeOS({super.key});
    @override
    Widget build(BuildContext context) {
          return MaterialApp(
                  title: 'Creative OS',
                  debugShowCheckedModeBanner: false,
                  theme: CinematicTheme.darkTheme,
                  home: const MainScreen(),
                );
    }
}
