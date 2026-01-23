import 'package:drift/native.dart';
import 'package:test/test.dart';

import 'package:maintenance_system/core/data/local/app_database.dart';
import 'package:maintenance_system/core/data/sync/drift_local_sync_adapter.dart';

void main() {
  group('DriftLocalSyncAdapter.applyServerChanges', () {
    late AppDatabase db;
    late DriftLocalSyncAdapter adapter;

    setUp(() {
      db = AppDatabase.forExecutor(NativeDatabase.memory());
      adapter = DriftLocalSyncAdapter(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('skips invalid technician rows and applies effectiveName fallback', () async {
      await adapter.applyServerChanges(serverChanges: {
        'technicians_cache': [
          {'id': ''},
          {'id': 't1', 'username': '', 'name': '', 'display_name': ''},
          {
            'id': 't2',
            'username': 'u2',
            'created_at': '2026-01-01T00:00:00Z',
            'updated_at': '2026-01-01T00:00:00Z',
          },
          {
            'id': 't3',
            'name': 'Name3',
            'created_at': '2026-01-01T00:00:00Z',
            'updated_at': '2026-01-01T00:00:00Z',
          },
          {
            'id': 't4',
            'display_name': 'Disp4',
            'created_at': '2026-01-01T00:00:00Z',
            'updated_at': '2026-01-01T00:00:00Z',
          },
        ],
        'inspections': const [],
        'tasks': const [],
      });

      final techs = await db.select(db.techniciansCache).get();
      final byId = {for (final t in techs) t.id: t};

      expect(byId.containsKey('t1'), isFalse);
      expect(byId['t2']?.name, equals('u2'));
      expect(byId['t3']?.name, equals('Name3'));
      expect(byId['t4']?.name, equals('Disp4'));
    });

    test('skips invalid inspection rows and parses completion boolean', () async {
      await adapter.applyServerChanges(serverChanges: {
        'technicians_cache': const [],
        'inspections': [
          {'id': '', 'aircraft_id': 'A1'},
          {'id': 'i2', 'aircraft_id': ''},
          {
            'id': 'i3',
            'aircraft_id': 'A3',
            'created_at': '2026-01-01T00:00:00Z',
            'updated_at': '2026-01-02T00:00:00Z',
            'is_completed': 1,
            'opened_at': '2026-01-01T12:00:00Z',
            'completed_at': '2026-01-02T12:00:00Z',
            'technician_id': null,
          },
          {
            'id': 'i4',
            'aircraft_id': 'A4',
            'created_at': '2026-01-01T00:00:00Z',
            'updated_at': '2026-01-02T00:00:00Z',
            'is_completed': 'false',
          },
        ],
        'tasks': const [],
      });

      final insps = await db.select(db.inspections).get();
      final byId = {for (final i in insps) i.id: i};

      expect(byId.containsKey('i2'), isFalse);

      expect(byId['i3']?.aircraftId, equals('A3'));
      expect(byId['i3']?.isCompleted, isTrue);
      expect(byId['i3']?.openedAt, isNotNull);
      expect(byId['i3']?.completedAt, isNotNull);

      expect(byId['i4']?.aircraftId, equals('A4'));
      expect(byId['i4']?.isCompleted, isFalse);
    });

    test('skips invalid task rows and parses completion boolean', () async {
      await adapter.applyServerChanges(serverChanges: {
        'technicians_cache': const [],
        'inspections': [
          {
            'id': 'i4',
            'aircraft_id': 'A4',
            'created_at': '2026-01-01T00:00:00Z',
            'updated_at': '2026-01-02T00:00:00Z',
            'is_completed': 0,
          },
        ],
        'tasks': [
          {'id': '', 'inspection_id': 'i4', 'title': 'T'},
          {'id': 'k2', 'inspection_id': '', 'title': 'T'},
          {'id': 'k3', 'inspection_id': 'i4', 'title': ''},
          {
            'id': 'k4',
            'inspection_id': 'i4',
            'title': 'Task 4',
            'created_at': '2026-01-01T00:00:00Z',
            'updated_at': '2026-01-02T00:00:00Z',
            'is_completed': 'yes',
            'result': 'ok',
            'notes': 'n',
          },
        ],
      });

      final tasks = await db.select(db.tasks).get();
      final byId = {for (final t in tasks) t.id: t};

      expect(byId.length, equals(1));
      expect(byId['k4']?.inspectionId, equals('i4'));
      expect(byId['k4']?.title, equals('Task 4'));
      expect(byId['k4']?.isCompleted, isTrue);
      expect(byId['k4']?.result, equals('ok'));
      expect(byId['k4']?.notes, equals('n'));
    });
  });
}
