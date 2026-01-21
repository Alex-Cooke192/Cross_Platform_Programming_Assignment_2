import 'package:flutter/material.dart';
import 'package:maintenance_system/app_root.dart';
import 'package:maintenance_system/core/data/local/repositories/task_repository.dart';
import 'package:provider/provider.dart';
import 'package:maintenance_system/core/data/sync/sync_service.dart';

import 'core/data/local/app_database.dart';
import 'core/data/local/repositories/inspection_repository.dart';
import 'core/data/local/repositories/technician_repository.dart';
import 'core/session/current_technician.dart';
import 'core/theme/theme_controller.dart';
import 'config/app_themes.dart';

class App extends StatelessWidget {
  final AppDatabase database;
  final SyncService syncService; 

  const App({
    super.key,
    required this.database,
    required this.syncService, 
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Session state
        ChangeNotifierProvider(
          create: (_) => CurrentTechnician(),
        ),

        // Repositories (backed by the same DB instance)
        Provider(
          create: (_) => InspectionRepository(database),
        ),
        Provider(
          create: (_) => TechnicianRepository(database),
        ),
        Provider(
          create: (_) => TaskRepository(database), 
        ), 
        Provider<SyncService>.value(value: syncService),
      ],
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeController.themeMode,
        builder: (context, themeMode, _) {
          return MaterialApp(
            title: 'RampCheck',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            debugShowCheckedModeBanner: false,
            home: const AppRoot(),
          );
        },
      ),
    );
  }
}
