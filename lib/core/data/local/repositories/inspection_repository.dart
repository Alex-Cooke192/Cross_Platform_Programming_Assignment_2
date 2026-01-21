import 'package:drift/drift.dart';
import '../app_database.dart';

class InspectionRepository {
  final AppDatabase db;

  InspectionRepository(this.db);

  // ---- Reads (Streams) ----

  Stream<List<Inspection>> watchAll() => db.inspectionDao.watchAll();
  Stream<List<Inspection>> watchUnopened() => db.inspectionDao.watchUnopened();
  Stream<List<Inspection>> watchOpen() => db.inspectionDao.watchInProgress();
  Stream<List<Inspection>> watchCompleted() => db.inspectionDao.watchCompleted();
  Stream<Inspection?> watchById(String id) => db.inspectionDao.watchById(id);

  // ---- Reads (Counts) ----

  Stream<int> watchUnopenedCount() =>
      db.inspectionDao.watchUnopened().map((rows) => rows.length);

  Stream<int> watchOpenCount() =>
      db.inspectionDao.watchInProgress().map((rows) => rows.length);

  Stream<int> watchCompletedCount() =>
      db.inspectionDao.watchCompleted().map((rows) => rows.length);

  Stream<int> watchUnopenedByTechnician(String technicianId) =>
      db.inspectionDao.watchUnopenedByTechnician(technicianId).map((rows) => rows.length);

  Stream<int> watchInProgressByTechnician(String technicianId) =>
      db.inspectionDao.watchInProgressByTechnician(technicianId).map((rows) => rows.length);

  Stream<int> watchCompletedByTechnician(String technicianId) =>
      db.inspectionDao.watchCompletedByTechnician(technicianId).map((rows) => rows.length);

  // ---- Writes (Local user actions) ----
  // DAOs now handle updatedAt + syncStatus='pending'

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

  Future<void> setOpened(String inspectionId) => db.inspectionDao.setOpened(inspectionId);

  Future<void> setCompleted(String inspectionId, bool completed) =>
      db.inspectionDao.setCompleted(inspectionId, completed);

  Future<void> assignTechnician(String inspectionId, String? technicianId) =>
      db.inspectionDao.setTechnician(inspectionId, technicianId);

  Future<void> deleteInspection(String inspectionId) =>
      db.inspectionDao.deleteById(inspectionId);

  Future<void> markCompleted(String inspectionId) => setCompleted(inspectionId, true);

  Future<void> markOpen(String inspectionId) => setOpened(inspectionId);

  // ---- Sync (Server -> Local) ----
  // IMPORTANT: repo should not bypass DAO, because DAO sets syncStatus etc.

  Future<void> upsertFromServer({
    required String id,
    required String aircraftId,
    required DateTime createdAt,
    required DateTime updatedAt,
    required bool isCompleted,
    DateTime? openedAt,
    DateTime? completedAt,
    String? technicianId,
  }) {
    return db.inspectionDao.upsertFromServer(
      id: id,
      aircraftId: aircraftId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isCompleted: isCompleted,
      openedAt: openedAt,
      completedAt: completedAt,
      technicianId: technicianId,
    );
  }
}
