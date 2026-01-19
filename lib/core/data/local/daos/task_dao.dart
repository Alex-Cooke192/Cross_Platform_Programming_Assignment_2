import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tasks.dart';

part 'task_dao.g.dart';

@DriftAccessor(tables: [Tasks])
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin {
  TaskDao(super.db);

  /// Watch tasks for a given inspection (most common query).
  Stream<List<Task>> watchByInspectionId(String inspectionId) {
    return (select(tasks)..where((t) => t.inspectionId.equals(inspectionId)))
        .watch();
  }

  /// Watch a single task by id (task details screen).
  Stream<Task?> watchById(String id) {
    return (select(tasks)..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  /// Insert a task (you pass UUID + inspectionId).
  Future<void> insertTask({
    required String id,
    required String inspectionId,
    required String title,
  }) async {
    await into(tasks).insert(
      TasksCompanion.insert(
        id: id,
        inspectionId: inspectionId,
        title: title,
        // isCompleted defaults to false
      ),
    );
  }

  /// Mark task completed / not completed.
  Future<int> setCompleted(String taskId, bool completed) {
    return (update(tasks)..where((t) => t.id.equals(taskId))).write(
      TasksCompanion(
        isCompleted: Value(completed),
      ),
    );
  }

  /// Update result + notes (nullable).
  Future<int> updateResultAndNotes({
    required String taskId,
    String? result,
    String? notes,
  }) {
    return (update(tasks)..where((t) => t.id.equals(taskId))).write(
      TasksCompanion(
        result: Value(result),
        notes: Value(notes),
      ),
    );
  }

  /// Optional helpers
  Future<int> deleteById(String id) {
    return (delete(tasks)..where((t) => t.id.equals(id))).go();
  }

  Future<int> deleteByInspectionId(String inspectionId) {
    return (delete(tasks)..where((t) => t.inspectionId.equals(inspectionId)))
        .go();
  }
}
