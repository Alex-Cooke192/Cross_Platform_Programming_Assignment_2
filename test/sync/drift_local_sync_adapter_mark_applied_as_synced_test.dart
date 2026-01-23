import 'package:drift/native.dart';
import 'package:test/test.dart';

import 'package:maintenance_system/core/data/local/app_database.dart';
import 'package:maintenance_system/core/data/local/daos/inspection_dao.dart';
import 'package:maintenance_system/core/data/sync/drift_local_sync_adapter.dart';

void main() {
  group('DriftLocalSyncAdapter.markAppliedAsSynced', () {
    late AppDatabase db;
    late DriftLocalSyncAdapter adapter;

    setUp(() {
      db = AppDatabase.forExecutor(NativeDatabase.memory());
      adapter = DriftLocalSyncAdapter(db);
    });

    tearDown(() async {
      await db.close();
    });

    Future<void> seedInspections(List<String> ids) async {
      for (final id in ids) {
        await db.inspectionDao.insertInspection(id: id, aircraftId: 'A-$id');
      }
    }

    test('marks inserted+updated+skipped as synced and conflict as conflict', () async {
      await seedInspections(['i1', 'i3', 'i9']);

      final before = await (db.select(db.inspections)).get();
      expect(before.map((r) => r.syncStatus).toSet(), equals({kSyncPending}));

      await adapter.markAppliedAsSynced(
        applied: const {},
        appliedIds: {
          'technicians_cache': {
            'inserted': ['t1'],
            'updated': ['t2'],
            'skipped': ['t3'],
            'conflict': ['t9'],
          },
          'inspections': {
            'inserted': ['i1'],
            'updated': [],
            'skipped': ['i3'],
            'conflict': ['i9'],
          },
          'tasks': {
            'inserted': ['k1', 'k2'],
            'updated': ['k2', 'k3'],
            'skipped': [],
            'conflict': [],
          },
        },
      );

      final rows = await (db.select(db.inspections)).get();
      final byId = {for (final r in rows) r.id: r};

      expect(byId['i1']!.syncStatus, equals(kSyncSynced));
      expect(byId['i3']!.syncStatus, equals(kSyncSynced));
      expect(byId['i9']!.syncStatus, equals(kSyncConflict));
    });

    test('handles missing tables by leaving existing rows unchanged', () async {
      await seedInspections(['i1']);

      await adapter.markAppliedAsSynced(
        applied: const {},
        appliedIds: const {},
      );

      final row = await (db.select(db.inspections)..where((t) => t.id.equals('i1'))).getSingle();
      expect(row.syncStatus, equals(kSyncPending));
    });
  });
}
