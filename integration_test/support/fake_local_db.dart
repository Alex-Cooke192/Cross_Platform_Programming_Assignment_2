import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:maintenance_system/core/data/local/app_database.dart';

class FakeLocalDbHarness {
  FakeLocalDbHarness._(this.db, this._dbFile);

  final AppDatabase db;
  final File? _dbFile;

  static Future<FakeLocalDbHarness> create({bool inMemory = true}) async {
    if (inMemory) {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      return FakeLocalDbHarness._(db, null);
    }

    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, 'integration_test_fake_db.sqlite'));
    if (await file.exists()) {
      await file.delete();
    }

    final db = AppDatabase.forTesting(NativeDatabase(file));
    return FakeLocalDbHarness._(db, file);
  }

  Future<void> seedAssumedData() async {
    // Wrap seeding in a transaction to keep it fast/atomic.
    await db.transaction(() async {
      // 1) Technician: tech.jane must exist
      await db.into(db.techniciansCache).insert(
        TechniciansCacheCompanion.insert(
          id: 'tech_001',          // required for CurrentTechnician().setTechnician(...)
          name: 'tech.jane',    // used by TechnicianRepository.getByUsername
        ),
        mode: InsertMode.insertOrReplace,
      );

      // 2) One unopened inspection with tasks (index 0 must exist)
      const inspectionId = 'insp_001';

      await db.into(db.inspections).insert(
        InspectionsCompanion.insert(
          id: inspectionId,
          aircraftId: 'A320-G-EZAA',
          technicianId: Value('tech_001'),
          openedAt: const Value(null),
          completedAt: const Value(null),
          syncStatus: Value('synced'),
        ),
        mode: InsertMode.insertOrReplace,
      );

      // 3) Tasks for the inspection (must be >= 1)
      await db.into(db.tasks).insert(
        TasksCompanion.insert(
          id: 'task_001',
          inspectionId: inspectionId,
          title: 'Check oil level',
          isCompleted: const Value(false),
          result: const Value(null),
          notes: const Value(null),
        ),
        mode: InsertMode.insertOrReplace,
      );

      await db.into(db.tasks).insert(
        TasksCompanion.insert(
          id: 'task_002',
          inspectionId: inspectionId,
          title: 'Inspect tires',
          isCompleted: const Value(false),
          result: const Value(null),
          notes: const Value(null),
        ),
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  Future<void> dispose() async {
    await db.close();
    if (_dbFile != null) {
      try {
        if (await _dbFile.exists()) await _dbFile.delete();
      } catch (e) {
        debugPrint('FakeLocalDbHarness cleanup failed: $e');
      }
    }
  }
}
