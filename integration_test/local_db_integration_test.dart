import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:drift/native.dart';

import 'package:maintenance_system/core/data/local/app_database.dart';
import 'package:maintenance_system/core/data/local/daos/inspection_dao.dart';
import 'package:maintenance_system/core/data/sync/drift_local_sync_adapter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('local db integration', () {
    late AppDatabase db;
    late DriftLocalSyncAdapter adapter;

    setUp(() {
      db = AppDatabase.forExecutor(NativeDatabase.memory());
      adapter = DriftLocalSyncAdapter(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('DAO write paths + pending query + purge + sync adapter', () async {
      await db.inspectionDao.insertInspection(id: 'i1', aircraftId: 'A1', technicianId: 't1');
      await db.inspectionDao.insertInspection(id: 'i2', aircraftId: 'A2', technicianId: 't1');

      final initial = await (db.select(db.inspections)).get();
      expect(initial.length, equals(2));
      expect(initial.map((r) => r.syncStatus).toSet(), equals({kSyncPending}));

      await db.inspectionDao.markSyncedByIds(['i2']);

      final afterMarkSynced = await (db.select(db.inspections)).get();
      final byId1 = {for (final r in afterMarkSynced) r.id: r};
      expect(byId1['i2']!.syncStatus, equals(kSyncSynced));
      expect(byId1['i1']!.syncStatus, equals(kSyncPending));

      await db.inspectionDao.setOpened('i1');

      final afterOpen = await db.inspectionDao.watchById('i1').first;
      expect(afterOpen, isNotNull);
      expect(afterOpen!.openedAt, isNotNull);
      expect(afterOpen.syncStatus, equals(kSyncPending));

      final cutoff = DateTime.now().subtract(const Duration(seconds: 1));
      final pendingSince = await db.inspectionDao.getPendingChanges(since: cutoff);
      final pendingIds = pendingSince.map((r) => r.id).toList();
      expect(pendingIds, contains('i1'));

      await db.inspectionDao.setCompleted('i1', true);
      await db.inspectionDao.markSyncedByIds(['i1']);

      final purgedNone = await db.inspectionDao.purgeCompletedSynced(
        olderThan: const Duration(days: 9999),
      );
      expect(purgedNone, equals(0));

      final purgedAll = await db.inspectionDao.purgeCompletedSynced(
        olderThan: const Duration(seconds: 0),
      );
      expect(purgedAll, equals(1));

      final i1AfterPurge = await db.inspectionDao.watchById('i1').first;
      expect(i1AfterPurge, isNull);

      await adapter.applyServerChanges(serverChanges: {
        'technicians_cache': [
          {
            'id': 't9',
            'username': 'tech.nine',
            'created_at': '2026-01-01T00:00:00Z',
            'updated_at': '2026-01-01T00:00:00Z',
          },
        ],
        'inspections': [
          {
            'id': 'i_server',
            'aircraft_id': 'A-SRV',
            'created_at': '2026-01-01T00:00:00Z',
            'updated_at': '2026-01-02T00:00:00Z',
            'is_completed': 1,
            'opened_at': '2026-01-01T12:00:00Z',
            'completed_at': '2026-01-02T12:00:00Z',
            'technician_id': 't9',
          },
        ],
        'tasks': [
          {
            'id': 'k_server',
            'inspection_id': 'i_server',
            'title': 'Server task',
            'created_at': '2026-01-01T00:00:00Z',
            'updated_at': '2026-01-02T00:00:00Z',
            'is_completed': 'yes',
            'result': 'ok',
            'notes': 'n',
          },
        ],
      });

      final serverInsp = await db.inspectionDao.watchById('i_server').first;
      expect(serverInsp, isNotNull);
      expect(serverInsp!.aircraftId, equals('A-SRV'));
      expect(serverInsp.isCompleted, isTrue);
      expect(serverInsp.openedAt, isNotNull);
      expect(serverInsp.completedAt, isNotNull);
      expect(serverInsp.syncStatus, equals(kSyncSynced));

      final serverTasks = await (db.select(db.tasks)..where((t) => t.id.equals('k_server')))
          .getSingleOrNull();
      expect(serverTasks, isNotNull);
      expect(serverTasks!.inspectionId, equals('i_server'));
      expect(serverTasks.title, equals('Server task'));
      expect(serverTasks.isCompleted, isTrue);

      await db.inspectionDao.insertInspection(id: 'i_local', aircraftId: 'A-LOC');
      final beforeMark = await db.inspectionDao.watchById('i_local').first;
      expect(beforeMark, isNotNull);
      expect(beforeMark!.syncStatus, equals(kSyncPending));

      await adapter.markAppliedAsSynced(
        applied: const {},
        appliedIds: {
          'technicians_cache': {
            'inserted': const [],
            'updated': const [],
            'skipped': const [],
            'conflict': const [],
          },
          'inspections': {
            'inserted': ['i_local'],
            'updated': const [],
            'skipped': const [],
            'conflict': const [],
          },
          'tasks': {
            'inserted': const [],
            'updated': const [],
            'skipped': const [],
            'conflict': const [],
          },
        },
      );

      final afterMark = await db.inspectionDao.watchById('i_local').first;
      expect(afterMark, isNotNull);
      expect(afterMark!.syncStatus, equals(kSyncSynced));
    });
  });
}
