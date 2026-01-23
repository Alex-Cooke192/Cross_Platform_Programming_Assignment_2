import 'package:drift/native.dart';
import 'package:test/test.dart';

import 'package:maintenance_system/core/data/local/app_database.dart';
import 'package:maintenance_system/core/data/local/daos/inspection_dao.dart';

void main() {
  group('InspectionDao writes', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forExecutor(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('setOpened sets openedAt and marks pending', () async {
      await db.inspectionDao.insertInspection(id: 'i1', aircraftId: 'A1', technicianId: 't1');

      await db.inspectionDao.markSyncedByIds(['i1']);

      await db.inspectionDao.setOpened('i1');

      final after = await db.inspectionDao.watchById('i1').first;
      expect(after, isNotNull);
      expect(after!.openedAt, isNotNull);
      expect(after.syncStatus, equals(kSyncPending));
    });

    test('setCompleted(true) sets completedAt, isCompleted and marks pending', () async {
      await db.inspectionDao.insertInspection(id: 'i1', aircraftId: 'A1');

      await db.inspectionDao.setCompleted('i1', true);

      final row = await db.inspectionDao.watchById('i1').first;
      expect(row, isNotNull);
      expect(row!.isCompleted, isTrue);
      expect(row.completedAt, isNotNull);
      expect(row.syncStatus, equals(kSyncPending));
    });

    test('setCompleted(false) clears completedAt and marks pending', () async {
      await db.inspectionDao.insertInspection(id: 'i1', aircraftId: 'A1');

      await db.inspectionDao.setCompleted('i1', true);
      await db.inspectionDao.setCompleted('i1', false);

      final row = await db.inspectionDao.watchById('i1').first;
      expect(row, isNotNull);
      expect(row!.isCompleted, isFalse);
      expect(row.completedAt, isNull);
      expect(row.syncStatus, equals(kSyncPending));
    });

    test('setTechnician updates technicianId and marks pending', () async {
      await db.inspectionDao.insertInspection(id: 'i1', aircraftId: 'A1', technicianId: null);

      await db.inspectionDao.markSyncedByIds(['i1']);

      await db.inspectionDao.setTechnician('i1', 't9');

      final row = await db.inspectionDao.watchById('i1').first;
      expect(row, isNotNull);
      expect(row!.technicianId, equals('t9'));
      expect(row.syncStatus, equals(kSyncPending));
    });
  });
}
