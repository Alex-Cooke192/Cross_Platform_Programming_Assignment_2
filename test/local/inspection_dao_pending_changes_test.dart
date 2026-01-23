import 'package:drift/native.dart';
import 'package:test/test.dart';

import 'package:maintenance_system/core/data/local/app_database.dart';

void main() {
  group('InspectionDao.getPendingChanges', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forExecutor(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('returns only pending rows', () async {
      await db.inspectionDao.insertInspection(id: 'i1', aircraftId: 'A1', technicianId: 't1');
      await db.inspectionDao.insertInspection(id: 'i2', aircraftId: 'A2', technicianId: 't1');

      await db.inspectionDao.markSyncedByIds(['i2']);

      final pending = await db.inspectionDao.getPendingChanges();
      final ids = pending.map((r) => r.id).toList();

      expect(ids, contains('i1'));
      expect(ids, isNot(contains('i2')));
    });

    test('applies updatedAt > since filter', () async {
      await db.inspectionDao.insertInspection(id: 'i1', aircraftId: 'A1', technicianId: 't1');
      await db.inspectionDao.insertInspection(id: 'i2', aircraftId: 'A2', technicianId: 't1');

      final cutoff = DateTime.now().subtract(const Duration(seconds: 1));

      await db.inspectionDao.setOpened('i2');

      final filtered = await db.inspectionDao.getPendingChanges(since: cutoff);
      final ids = filtered.map((r) => r.id).toList();

      expect(ids, contains('i2'));
    });
  });
}
