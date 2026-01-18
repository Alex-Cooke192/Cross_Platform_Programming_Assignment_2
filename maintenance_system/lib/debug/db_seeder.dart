import 'package:uuid/uuid.dart';

import '../core/data/local/app_database.dart';

class DevSeeder {
  final AppDatabase db;
  DevSeeder(this.db);

  Future<void> reseed() async {
    await db.transaction(() async {
      // Wipe tables (order matters if you add FKs later)
      await db.delete(db.tasks).go();
      await db.delete(db.inspections).go();
      await db.delete(db.techniciansCache).go();

      // Insert demo data
      final techId = const Uuid().v4();
      final inspectionId = const Uuid().v4();

      await db.into(db.techniciansCache).insert(
        TechniciansCacheCompanion.insert(
          id: techId,
          name: 'tech.jane',
        ),
      );

      await db.inspectionDao.insertInspection(
        id: inspectionId,
        aircraftId: 'G-ABCD',
        technicianId: techId,
      );

      await db.taskDao.insertTask(
        id: const Uuid().v4(),
        inspectionId: inspectionId,
        title: 'Check brakes',
      );

      await db.taskDao.insertTask(
        id: const Uuid().v4(),
        inspectionId: inspectionId,
        title: 'Check lights',
      );
    });
  }
}
