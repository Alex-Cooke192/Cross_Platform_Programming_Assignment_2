import 'package:uuid/uuid.dart';

import '../core/data/local/app_database.dart';

class DevSeeder {
  final AppDatabase db;
  DevSeeder(this.db);

  static const _uuid = Uuid();

  Future<void> reseed() async {
    await db.transaction(() async {
      // Wipe tables (order matters if you add FKs later)
      await db.delete(db.tasks).go();
      await db.delete(db.inspections).go();
      await db.delete(db.techniciansCache).go();

      // -----------------------
      // 1) Insert 5 technicians
      // -----------------------
      final techNames = <String>[
        'tech.jane',
        'tech.ali',
        'tech.sam',
        'tech.rory',
        'tech.mina',
      ];

      final techIds = <String>[];
      for (final name in techNames) {
        final id = _uuid.v4();
        techIds.add(id);

        await db.into(db.techniciansCache).insert(
          TechniciansCacheCompanion.insert(
            id: id,
            name: name,
          ),
        );
      }

      // -----------------------
      // 2) Insert 7 inspections
      //    (rotate technicians)
      // -----------------------
      final aircraftIds = <String>[
        'G-ABCD',
        'G-EFGH',
        'G-IJKL',
        'G-MNOP',
        'G-QRST',
        'G-UVWX',
        'G-YZ12',
      ];

      final inspectionIds = <String>[];
      for (var i = 0; i < aircraftIds.length; i++) {
        final inspectionId = _uuid.v4();
        inspectionIds.add(inspectionId);

        final technicianId = techIds[i % techIds.length];
        final aircraftId = aircraftIds[i];

        await db.inspectionDao.insertInspection(
          id: inspectionId,
          aircraftId: aircraftId,
          technicianId: technicianId,
        );
      }

      // -----------------------
      // 3) Insert 2–3 tasks per inspection
      // -----------------------
      const taskPool = <String>[
        'Check brakes',
        'Check lights',
        'Inspect tires',
        'Check oil level',
        'Inspect flaps',
        'Test radios',
        'Verify instruments',
        'Check hydraulics',
        'Inspect landing gear',
        'Check battery',
        'Inspect fuel lines',
        'Check cabin safety kit',
      ];

      var taskCursor = 0;

      for (var i = 0; i < inspectionIds.length; i++) {
        final inspectionId = inspectionIds[i];

        // 2–3 tasks each: first 3 inspections get 3 tasks, rest get 2
        final tasksForThisInspection = i < 3 ? 3 : 2;

        for (var t = 0; t < tasksForThisInspection; t++) {
          final title = taskPool[taskCursor % taskPool.length];
          taskCursor++;

          await db.taskDao.insertTask(
            id: _uuid.v4(),
            inspectionId: inspectionId,
            title: title,
          );
        }
      }
    });
  }
}

