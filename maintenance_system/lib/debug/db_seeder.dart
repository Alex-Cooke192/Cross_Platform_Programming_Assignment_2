import 'package:drift/drift.dart' as drift;
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

      // 1) Insert 5 technicians
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

      // 2) Build 7 inspections with a spread of states
      final now = DateTime.now();

      final seededInspections = <({
        String aircraftId,
        String status,
        DateTime? openedAt,
        DateTime? completedAt,
        bool isCompleted, 
      })>[
        // Unopened / outstanding (not opened yet)
        (aircraftId: 'G-ABCD', status: 'outstanding', openedAt: null, completedAt: null, isCompleted: false),
        (aircraftId: 'G-EFGH', status: 'outstanding', openedAt: null, completedAt: null, isCompleted: false),

        // Opened / in progress
        (aircraftId: 'G-IJKL', status: 'in_progress', openedAt: now.subtract(const Duration(hours: 6)), completedAt: null, isCompleted: false),
        (aircraftId: 'G-MNOP', status: 'in_progress', openedAt: now.subtract(const Duration(hours: 4)), completedAt: null, isCompleted: false),
        (aircraftId: 'G-QRST', status: 'in_progress', openedAt: now.subtract(const Duration(hours: 2)), completedAt: null, isCompleted: false),

        // Completed (awaiting sync)
        (aircraftId: 'G-UVWX', status: 'completed_awaiting_sync', openedAt: now.subtract(const Duration(days: 1, hours: 3)), completedAt: now.subtract(const Duration(days: 1, hours: 1)), isCompleted: true),
        (aircraftId: 'G-YZ12', status: 'completed_awaiting_sync', openedAt: now.subtract(const Duration(days: 2, hours: 5)), completedAt: now.subtract(const Duration(days: 2, hours: 2)), isCompleted: true),
      ];

      final inspectionIds = <String>[];

      for (var i = 0; i < seededInspections.length; i++) {
        final seed = seededInspections[i];
        final inspectionId = _uuid.v4();
        inspectionIds.add(inspectionId);

        final technicianId = techIds[i % techIds.length];

        await db.into(db.inspections).insert(
          InspectionsCompanion.insert(
            id: inspectionId,
            aircraftId: seed.aircraftId,
            technicianId: drift.Value(technicianId),
            openedAt: seed.openedAt == null
              ? const drift.Value.absent()
              : drift.Value(seed.openedAt),

            completedAt: seed.completedAt == null
              ? const drift.Value.absent()
              : drift.Value(seed.completedAt),
            isCompleted: drift.Value(seed.isCompleted))
          ); 
        
      // 3) Insert 2–3 tasks per inspection
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
        final insp = seededInspections[i];

        final tasksForThisInspection = i < 3 ? 3 : 2;

        for (var t = 0; t < tasksForThisInspection; t++) {
          final title = taskPool[taskCursor % taskPool.length];
          taskCursor++;

          // Mark completed fields for completed inspections.
          final isCompleted = insp.status == 'completed_awaiting_sync';

          await db.into(db.tasks).insert(
            TasksCompanion.insert(
              id: _uuid.v4(),
              inspectionId: inspectionId,
              title: title,
              
              isCompleted: drift.Value(isCompleted),
              ),
            );
          }
        }
      }
    });
  }
}


