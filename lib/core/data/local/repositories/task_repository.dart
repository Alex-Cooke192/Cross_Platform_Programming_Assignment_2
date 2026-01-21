import '../app_database.dart';

class TaskRepository {
  final AppDatabase db;

  TaskRepository(this.db);

  // ---- Reads (Streams) ----

  Stream<List<Task>> watchByInspectionId(String inspectionId) =>
      db.taskDao.watchByInspectionId(inspectionId);
      
  Stream<List<Task>> watchByInspectionIds(List<String> inspectionIds) {
    return db.taskDao.watchByInspectionIds(inspectionIds);
  }

  Stream<Task?> watchById(String taskId) => db.taskDao.watchById(taskId);

  // ---- Writes (Local user actions) ----
  // DAOs now handle updatedAt & syncStatus='pending'

  Future<void> createTask({
    required String id,
    required String inspectionId,
    required String title,
  }) {
    return db.taskDao.insertTask(
      id: id,
      inspectionId: inspectionId,
      title: title,
    );
  }

  Future<void> setCompleted(String taskId, bool completed) =>
      db.taskDao.setCompleted(taskId, completed);

  Future<void> updateResultAndNotes({
    required String taskId,
    String? result,
    String? notes,
  }) {
    return db.taskDao.updateResultAndNotes(
      taskId: taskId,
      result: result,
      notes: notes,
    );
  }

  Future<void> deleteTask(String taskId) => db.taskDao.deleteById(taskId);

  Future<void> deleteTasksForInspection(String inspectionId) =>
      db.taskDao.deleteByInspectionId(inspectionId);

  Future<void> markCompleted(String taskId) => setCompleted(taskId, true);

  Future<void> markOpen(String taskId) => setCompleted(taskId, false);

  // ---- Sync (Server -> Local) ----

  Future<void> upsertFromServer({
    required String id,
    required String inspectionId,
    required String title,
    required DateTime createdAt,
    required DateTime updatedAt,
    required bool isCompleted,
    String? result,
    String? notes,
  }) {
    return db.taskDao.upsertFromServer(
      id: id,
      inspectionId: inspectionId,
      title: title,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isCompleted: isCompleted,
      result: result,
      notes: notes,
    );
  }
}
