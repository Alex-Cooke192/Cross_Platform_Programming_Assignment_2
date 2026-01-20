import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/tasks.dart';

part 'task_dao.g.dart';

const String kSyncPending = 'pending';
const String kSyncSynced = 'synced';
const String kSyncConflict = 'conflict';

@DriftAccessor(tables: [Tasks])
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin {
  TaskDao(super.db);

  // ---- Reads (Streams) ----

  Stream<List<Task>> watchByInspectionId(String inspectionId) {
    return (select(tasks)..where((t) => t.inspectionId.equals(inspectionId)))
        .watch();
  }

  Stream<Task?> watchById(String id) {
    return (select(tasks)..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  // ---- Writes (Local user actions) ----

  Future<void> insertTask({
    required String id,
    required String inspectionId,
    required String title,
  }) async {
    final now = DateTime.now();
    await into(tasks).insert(
      TasksCompanion.insert(
        id: id,
        inspectionId: inspectionId,
        title: title,
        // createdAt defaults to now
        updatedAt: Value(now),
        syncStatus: const Value(kSyncPending),
      ),
    );
  }

  Future<int> setCompleted(String taskId, bool completed) {
    final now = DateTime.now();
    return (update(tasks)..where((t) => t.id.equals(taskId))).write(
      TasksCompanion(
        isCompleted: Value(completed),
        updatedAt: Value(now),
        syncStatus: const Value(kSyncPending),
      ),
    );
  }

  Future<int> updateResultAndNotes({
    required String taskId,
    String? result,
    String? notes,
  }) {
    final now = DateTime.now();
    return (update(tasks)..where((t) => t.id.equals(taskId))).write(
      TasksCompanion(
        result: Value(result),
        notes: Value(notes),
        updatedAt: Value(now),
        syncStatus: const Value(kSyncPending),
      ),
    );
  }

  Future<int> deleteById(String id) {
    return (delete(tasks)..where((t) => t.id.equals(id))).go();
  }

  Future<int> deleteByInspectionId(String inspectionId) {
    return (delete(tasks)..where((t) => t.inspectionId.equals(inspectionId)))
        .go();
  }

  // ---- Sync helpers ----

  Future<List<Task>> getPendingChanges({DateTime? since}) {
    final q = select(tasks)..where((t) => t.syncStatus.equals(kSyncPending));
    if (since != null) {
      q.where((t) => t.updatedAt.isBiggerThanValue(since));
    }
    return q.get();
  }

  Future<void> upsertFromServer({
    required String id,
    required String inspectionId,
    required String title,
    required DateTime createdAt,
    required DateTime updatedAt,
    required bool isCompleted,
    String? result,
    String? notes,
  }) async {
    await into(tasks).insertOnConflictUpdate(
      TasksCompanion(
        id: Value(id),
        inspectionId: Value(inspectionId),
        title: Value(title),
        isCompleted: Value(isCompleted),
        result: Value(result),
        notes: Value(notes),
        createdAt: Value(createdAt),
        updatedAt: Value(updatedAt),
        syncStatus: const Value(kSyncSynced),
      ),
    );
  }

  Future<int> markSyncedByIds(List<String> ids) {
    if (ids.isEmpty) return Future.value(0);
    final now = DateTime.now();
    return (update(tasks)..where((t) => t.id.isIn(ids))).write(
      TasksCompanion(
        syncStatus: const Value(kSyncSynced),
        updatedAt: Value(now),
      ),
    );
  }

  Future<int> markConflictByIds(List<String> ids) {
    if (ids.isEmpty) return Future.value(0);
    final now = DateTime.now();
    return (update(tasks)..where((t) => t.id.isIn(ids))).write(
      TasksCompanion(
        syncStatus: const Value(kSyncConflict),
        updatedAt: Value(now),
      ),
    );
  }
}
