import 'package:drift/drift.dart';
import '../app_database.dart';

class InspectionRepository {
  final AppDatabase db;

  InspectionRepository(this.db);

  // ---- Reads (Streams) ----

  Stream<List<Inspection>> watchAll() => db.inspectionDao.watchAll();

  Stream<List<Inspection>> watchUnopened() => db.inspectionDao.watchUnopened();

  Stream<List<Inspection>> watchOpen() => db.inspectionDao.watchOpen();

  Stream<List<Inspection>> watchCompleted() => db.inspectionDao.watchCompleted();

  Stream<Inspection?> watchById(String id) => db.inspectionDao.watchById(id);

  // ---- Reads (Counts) ----
  Stream<int> watchUnopenedCount() =>
      db.inspectionDao.watchUnopened().map((rows) => rows.length);

  Stream<int> watchOpenCount() =>
      db.inspectionDao.watchOpen().map((rows) => rows.length);

  Stream<int> watchCompletedCount() =>
      db.inspectionDao.watchCompleted().map((rows) => rows.length);

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

  Future<void> setOpened(String inspectionId) async {
    await db.inspectionDao.setOpened(inspectionId);
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


  // Mark completed/open functions 
  // These are wrappers around the 'set' functions -> 
  // they require a bool so can change the state both ways, 
  // whereas these wrappers are specific instances of the above methods
  Future<void> markCompleted(String inspectionId) =>
      setCompleted(inspectionId, true);

  Future<void> markOpen(String inspectionId) =>
      setOpened(inspectionId);

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
