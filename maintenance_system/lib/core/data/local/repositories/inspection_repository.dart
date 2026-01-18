import 'package:drift/drift.dart';
import '../app_database.dart';

class InspectionRepository {
  final AppDatabase db;

  InspectionRepository(this.db);

  // ---- Reads (Streams) ----

  Stream<List<Inspection>> watchAll() => db.inspectionDao.watchAll();

  Stream<List<Inspection>> watchOpen() => db.inspectionDao.watchOpen();

  Stream<List<Inspection>> watchCompleted() => db.inspectionDao.watchCompleted();

  Stream<Inspection?> watchById(String id) => db.inspectionDao.watchById(id);

  // ---- Writes ----

  Future<void> createInspection({
    required String id,
    required String aircraftId,
    String? technicianId,
  }) {
    return db.inspectionDao.insertInspection(
      id: id,
      aircraftId: aircraftId,
      technicianId: technicianId,
    );
  }

  Future<void> setCompleted(String inspectionId, bool completed) async {
    await db.inspectionDao.setCompleted(inspectionId, completed);
  }

  Future<void> assignTechnician(String inspectionId, String? technicianId) async {
    await db.inspectionDao.setTechnician(inspectionId, technicianId);
  }

  Future<void> deleteInspection(String inspectionId) async {
    await db.inspectionDao.deleteById(inspectionId);
  }

  // Mark completed/ope functions
  Future<void> markCompleted(String inspectionId) =>
      setCompleted(inspectionId, true);

  Future<void> markOpen(String inspectionId) =>
      setCompleted(inspectionId, false);

  // Updates a local inspection with the data from the server (update if it exists, insert if not)
  Future<void> upsertFromServer({
    required String id,
    required String aircraftId,
    required DateTime createdAt,
    required bool isCompleted,
    DateTime? completedAt,
    String? technicianId,
  }) async {
    await db.into(db.inspections).insertOnConflictUpdate(
      InspectionsCompanion(
        id: Value(id),
        aircraftId: Value(aircraftId),
        createdAt: Value(createdAt),
        isCompleted: Value(isCompleted),
        completedAt: Value(completedAt),
        technicianId: Value(technicianId),
      ),
    );
  }
}
