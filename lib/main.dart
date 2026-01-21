import 'package:flutter/material.dart';
import 'package:maintenance_system/core/data/sync/sync_service.dart';
import 'package:maintenance_system/core/data/sync/drift_local_sync_adapter.dart';

import 'core/data/local/app_database.dart';
import 'debug/db_seeder.dart';
import 'app.dart'; 

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = AppDatabase();

  final syncService = SyncService(
    baseUrl: 'http://127.0.0.1:5050',
    clientId: 'device-uuid-goes-here',
    local: DriftLocalSyncAdapter(db),
  );

  // Debug-only seed
  assert(() {
    DevSeeder(db).reseed();
    return true;
  }());

  runApp(App(database: db, syncService: syncService));
}
