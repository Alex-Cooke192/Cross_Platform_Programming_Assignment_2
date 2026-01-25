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
import 'daos/technician_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Inspections, Tasks, TechniciansCache],
  daos: [InspectionDao, TaskDao, TechnicianDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forExecutor(super.e);

  AppDatabase.forTesting(QueryExecutor executor) : super(executor); 

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys= ON'); 
        },
        onCreate: (Migrator m) async {
          // Fresh install: create everything with the latest schema
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // 1 -> 2: add sync fields
          if (from < 2) {
            // Inspections: add updated_at + sync_status
            await m.addColumn(inspections, inspections.updatedAt);
            await m.addColumn(inspections, inspections.syncStatus);

            // Tasks: add created_at + updated_at + sync_status
            await m.addColumn(tasks, tasks.createdAt);
            await m.addColumn(tasks, tasks.updatedAt);
            await m.addColumn(tasks, tasks.syncStatus);

            // TechniciansCache: add created_at + updated_at + sync_status
            await m.addColumn(techniciansCache, techniciansCache.createdAt);
            await m.addColumn(techniciansCache, techniciansCache.updatedAt);
            await m.addColumn(techniciansCache, techniciansCache.syncStatus);

            // Backfill older rows (important, because addColumn creates nulls on existing rows)
            final now = DateTime.now();

            // Set defaults for inspections
            await (update(inspections)).write(
              InspectionsCompanion(
                updatedAt: Value(now),
                syncStatus: const Value('synced'),
              ),
            );

            // Set defaults for tasks
            await (update(tasks)).write(
              TasksCompanion(
                createdAt: Value(now),
                updatedAt: Value(now),
                syncStatus: const Value('synced'),
              ),
            );

            // Set defaults for technicians_cache
            await (update(techniciansCache)).write(
              TechniciansCacheCompanion(
                createdAt: Value(now),
                updatedAt: Value(now),
                syncStatus: const Value('synced'),
              ),
            );
          }
        },
      );
}

extension DevReset on AppDatabase {
  Future<void> devResetAndReseedDemoData() async {
    // Keep for later
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'rampcheck.sqlite'));
    // ignore: avoid_print
    print('Database file path: ${file.path}');
    return NativeDatabase(file);
  });
}
