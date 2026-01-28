// attachment_repository.dart
import 'package:drift/drift.dart';
import '../app_database.dart';

class AttachmentsRepository {
  final AppDatabase db;

  AttachmentsRepository(this.db);

  // Reads
  Future<Attachment?> getForTask(String taskId) => db.attachmentsDao.getByTaskId(taskId);
  Stream<Attachment?> watchForTask(String taskId) => db.attachmentsDao.watchByTaskId(taskId);
  Future<List<Attachment>> getPendingUploads() => db.attachmentsDao.getPendingUploads();

  // Writes

  /// Create/replace the single attachment for a task.
  /// Use this when user "adds attachment" or "replaces attachment".
  Future<void> setForTask({
    required String attachmentId,
    required String taskId,
    required String fileName,
    required String mimeType,
    required int sizeBytes,
    String? sha256,
    String? localPath,
  }) {
    return db.attachmentsDao.replaceForTask(
      AttachmentsCompanion.insert(
        id: attachmentId,
        taskId: taskId,
        fileName: fileName,
        mimeType: mimeType,
        sizeBytes: sizeBytes,
        sha256: Value(sha256),
        localPath: Value(localPath),
        // optional fields
        remoteKey: const Value.absent(),
        syncStatus: const Value('pending'),
        // createdAt/updatedAt default in table
      ),
    );
  }

  Future<void> removeForTask(String taskId) async {
    await db.attachmentsDao.deleteByTaskId(taskId);
  }

  Future<void> markUploaded({
    required String attachmentId,
    required String remoteKey,
  }) async {
    await db.attachmentsDao.markSynced(attachmentId, remoteKey: remoteKey);
  }

  Future<void> markNeedsUpload(String attachmentId) async {
    await db.attachmentsDao.markPending(attachmentId);
  }
}
