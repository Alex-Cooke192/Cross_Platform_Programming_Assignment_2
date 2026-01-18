import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// Tables
import 'tables/inspections.dart';
import 'tables/tasks.dart';
import 'tables/technicians_cache.dart';

// DAOs
import 'daos/inspection_dao.dart';
import 'daos/task_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Inspections, Tasks, TechniciansCache],
  daos: [InspectionDao, TaskDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forExecutor(super.e);

  @override
  int get schemaVersion => 1;
}

extension DevReset on AppDatabase { 
  /// DEV ONLY: Wipes seeded tables and recreates the demo dataset 
  /// exactly as defined in DebugSeeder.seedIfEmpty(). 
  Future<void> devResetAndReseedDemoData() async {
    // Need to add logic (schema dependent) 
  } }

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'rampcheck.sqlite'));
    // ignore: avoid_print
    print('Database file path: ${file.path}');
    return NativeDatabase(file);
  });
}
