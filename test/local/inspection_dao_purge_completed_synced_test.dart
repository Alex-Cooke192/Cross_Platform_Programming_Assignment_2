import 'package:drift/native.dart';
import 'package:test/test.dart';

import 'package:maintenance_system/core/data/local/app_database.dart';

void main() {
  group('InspectionDao.purgeCompletedSynced', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forExecutor(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('deletes only completed + synced rows', () async {
      await db.inspectionDao.insertInspection(id: 'i1', aircraftId: 'A1');
      await db.inspectionDao.insertInspection(id: 'i2', aircraftId: 'A2');
      await db.inspectionDao.insertInspection(id: 'i3', aircraftId: 'A3');

      await db.inspectionDao.setCompleted('i1', true);
      await db.inspectionDao.setCompleted('i2', true);

      await db.inspectionDao.markSyncedByIds(['i1']);
      await db.inspectionDao.markSyncedByIds(['i3']);

      final purged = await db.inspectionDao.purgeCompletedSynced();
      expect(purged, equals(1));

      final r1 = await db.inspectionDao.watchById('i1').first;
      final r2 = await db.inspectionDao.watchById('i2').first;
      final r3 = await db.inspectionDao.watchById('i3').first;

      expect(r1, isNull);
      expect(r2, isNotNull);
      expect(r3, isNotNull);
    });

    test('applies olderThan cutoff against completedAt (UTC)', () async {
      await db.inspectionDao.insertInspection(id: 'i1', aircraftId: 'A1');
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
    });
  });
}
