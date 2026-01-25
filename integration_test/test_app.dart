import 'package:flutter/material.dart';
import 'package:maintenance_system/models/sync_models.dart';
import 'package:provider/provider.dart';

import 'package:maintenance_system/core/session/current_technician.dart';
import 'package:maintenance_system/core/data/sync/i_sync_service.dart';
import 'package:maintenance_system/core/data/sync/sync_service.dart';
import 'package:maintenance_system/core/data/local/app_database.dart';

import 'package:maintenance_system/core/data/local/repositories/technician_repository.dart';
import 'package:maintenance_system/core/data/local/repositories/inspection_repository.dart';
import 'package:maintenance_system/core/data/local/repositories/task_repository.dart';

import 'package:maintenance_system/app_root.dart';

class NoopSyncService implements ISyncService {
  @override
  AuthStyle get authStyle => AuthStyle.bearer;

  @override
  Future<DateTime?> getLastSyncAt() async => null;

  @override
  Future<DateTime?> getLastTechSyncAt() async => null;

  @override
  Future<SyncResult> syncNow({required String apiKey}) async {
    return SyncResult(
      jobId: 'noop',
      serverTime: DateTime.now().toUtc(),
      applied: const {},
      conflicts: const {},
      serverChanges: const {},
    );
  }

  @override
  Future<SyncResult> syncTechnicians({required String apiKey}) async {
    return SyncResult(
      jobId: 'noop_techs',
      serverTime: DateTime.now().toUtc(),
      applied: const {},
      conflicts: const {},
      serverChanges: const {},
    );
  }

  @override
  void dispose() {}
}

Widget createTestApp({
  required AppDatabase db,
  ISyncService? overrideSyncService,
}) {
  return MultiProvider(
    providers: [
      Provider<AppDatabase>.value(value: db),

      Provider<TechnicianRepository>(
        create: (c) => TechnicianRepository(c.read<AppDatabase>()),
      ),
      Provider<InspectionRepository>(
        create: (c) => InspectionRepository(c.read<AppDatabase>()),
      ),
      Provider<TaskRepository>(
        create: (c) => TaskRepository(c.read<AppDatabase>()),
      ),

      ChangeNotifierProvider(create: (_) => CurrentTechnician()),

      Provider<ISyncService>(
        create: (_) => overrideSyncService ?? NoopSyncService(),
      ),
    ],
    child: MaterialApp(
      theme: ThemeData(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: NoTransitionsBuilder(),
            TargetPlatform.iOS: NoTransitionsBuilder(),
            TargetPlatform.macOS: NoTransitionsBuilder(),
            TargetPlatform.windows: NoTransitionsBuilder(),
            TargetPlatform.linux: NoTransitionsBuilder(),
            TargetPlatform.fuchsia: NoTransitionsBuilder(),
          },
        ),
      ),
      home: const AppRoot(),
    ),
  );
}

class NoTransitionsBuilder extends PageTransitionsBuilder {
  const NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child; // no animation at all
  }
}
