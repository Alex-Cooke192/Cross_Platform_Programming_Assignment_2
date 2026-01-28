import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/attachments.dart';

part 'attachments_dao.g.dart';

const String kSyncPending = 'pending';
const String kSyncSynced = 'synced';
const String kSyncConflict = 'conflict';

@DriftAccessor(tables: [Attachments])
class AttachmentsDao extends DatabaseAccessor<AppDatabase>
    with _$AttachmentsDaoMixin {
  AttachmentsDao(super.db);

  // ---- Reads ----

  Future<Attachment?> getByTaskId(String taskId) {
    return (select(attachments)..where((t) => t.taskId.equals(taskId)))
        .getSingleOrNull();
  }

  Stream<Attachment?> watchByTaskId(String taskId) {
    return (select(attachments)..where((t) => t.taskId.equals(taskId)))
        .watchSingleOrNull();
  }

  Future<List<Attachment>> getPendingUploads() {
    return (select(attachments)
          ..where((t) =>
              t.syncStatus.equals(kSyncPending) &
              t.localPath.isNotNull() &
              t.remoteKey.isNull()))
        .get();
  }

  // ---- Writes ----

  /// Insert or replace by PRIMARY KEY (id).
  /// Note: taskId is UNIQUE (1 attachment max per task).
  Future<void> upsert(AttachmentsCompanion entity) async {
    await into(attachments).insert(
      entity,
      mode: InsertMode.insertOrReplace,
    );
  }

  /// Enforces max-1 attachment per task by deleting any existing row for taskId
  /// and inserting the new one in a transaction.
  Future<void> replaceForTask(AttachmentsCompanion entity) async {
    final tid = entity.taskId.value;

    await transaction(() async {
      await deleteByTaskId(tid);
      await into(attachments).insert(entity);
    });
  }

  Future<int> deleteByTaskId(String taskId) {
    return (delete(attachments)..where((t) => t.taskId.equals(taskId))).go();
  }

  Future<int> deleteById(String id) {
    return (delete(attachments)..where((t) => t.id.equals(id))).go();
  }

  Future<int> markPending(String id) {
    final now = DateTime.now();
    return (update(attachments)..where((t) => t.id.equals(id))).write(
      AttachmentsCompanion(
        syncStatus: const Value(kSyncPending),
        updatedAt: Value(now),
      ),
    );
  }

  Future<int> markSynced(String id, {String? remoteKey}) {
    final now = DateTime.now();
    return (update(attachments)..where((t) => t.id.equals(id))).write(
      AttachmentsCompanion(
        syncStatus: const Value(kSyncSynced),
        remoteKey: remoteKey == null ? const Value.absent() : Value(remoteKey),
        updatedAt: Value(now),
      ),
    );
  }

  Future<int> setRemoteKey(String id, String remoteKey) {
    final now = DateTime.now();
    return (update(attachments)..where((t) => t.id.equals(id))).write(
      AttachmentsCompanion(
        remoteKey: Value(remoteKey),
        updatedAt: Value(now),
      ),
    );
  }
}
