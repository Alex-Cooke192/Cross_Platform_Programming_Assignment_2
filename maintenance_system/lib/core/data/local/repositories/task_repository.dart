import '../app_database.dart';

class TaskRepository {
  final AppDatabase db;

  TaskRepository(this.db);

  // ---- Reads (Streams) ----

  // Watch all tasks by inspection ID (inspection details screen)
  Stream<List<Task>> watchByInspectionId(String inspectionId) =>
      db.taskDao.watchByInspectionId(inspectionId);

  // Watch specific task by ID (task details screen)
  Stream<Task?> watchById(String taskId) => db.taskDao.watchById(taskId);

  // ---- Writes ----

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

  Future<void> setCompleted(String taskId, bool completed) async {
    await db.taskDao.setCompleted(taskId, completed);
  }

  Future<void> updateResultAndNotes({
    required String taskId,
    String? result,
    String? notes,
  }) async {
    await db.taskDao.updateResultAndNotes(
      taskId: taskId,
      result: result,
      notes: notes,
    );
  }

  Future<void> deleteTask(String taskId) async {
    await db.taskDao.deleteById(taskId);
  }

  Future<void> deleteTasksForInspection(String inspectionId) async {
    await db.taskDao.deleteByInspectionId(inspectionId);
  }

  // ---- Convenience helpers ----

  Future<void> markCompleted(String taskId) => setCompleted(taskId, true);

  Future<void> markOpen(String taskId) => setCompleted(taskId, false);
}
