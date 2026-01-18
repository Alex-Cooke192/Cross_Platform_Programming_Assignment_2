import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/inspections.dart';

part 'inspection_dao.g.dart';

@DriftAccessor(tables: [Inspections])
class InspectionDao extends DatabaseAccessor<AppDatabase>
    with _$InspectionDaoMixin {
  InspectionDao(super.db);

  /// Watch all inspections, newest first.
  Stream<List<Inspection>> watchAll() {
    return (select(inspections)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// Watch only open (not completed) inspections.
  Stream<List<Inspection>> watchOpen() {
    return (select(inspections)
          ..where((t) => t.isCompleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// Watch only completed inspections.
  Stream<List<Inspection>> watchCompleted() {
    return (select(inspections)
          ..where((t) => t.isCompleted.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.completedAt)]))
        .watch();
  }

  /// Watch a single inspection by id (for details screen)
  Stream<Inspection?> watchById(String id) {
    return (select(inspections)..where((t) => t.id.equals(id)))
        .watchSingleOrNull();
  }

  /// Create a new inspection. You pass the UUID.
  Future<void> insertInspection({
    required String id,
    required String aircraftId,
    String? technicianId,
  }) async {
    await into(inspections).insert(
      InspectionsCompanion.insert(
        id: id,
        aircraftId: aircraftId,
        technicianId: Value(technicianId),
        // createdAt defaults to now
        // isCompleted defaults to false
      ),
    );
  }

  /// Mark an inspection completed / not completed.
  Future<int> setCompleted(String inspectionId, bool completed) {
    return (update(inspections)..where((t) => t.id.equals(inspectionId))).write(
      InspectionsCompanion(
        isCompleted: Value(completed),
        completedAt: completed ? Value(DateTime.now()) : const Value(null),
      ),
    );
  }

  /// Assign (or unassign) a technician.
  Future<int> setTechnician(String inspectionId, String? technicianId) {
    return (update(inspections)..where((t) => t.id.equals(inspectionId))).write(
      InspectionsCompanion(
        technicianId: Value(technicianId),
      ),
    );
  }

  // Delete inspection by Id
  Future<int> deleteById(String id) {
    return (delete(inspections)..where((t) => t.id.equals(id))).go();
  }
}
