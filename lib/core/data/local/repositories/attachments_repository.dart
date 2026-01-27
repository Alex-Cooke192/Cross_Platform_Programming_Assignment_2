// attachment_repository.dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../daos/attachments_dao.dart';

class AttachmentsRepository {
  final AttachmentsDao _dao;

  AttachmentsRepository(this._dao);

  // Reads
  Future<Attachment?> getForTask(String taskId) => _dao.getByTaskId(taskId);
  Stream<Attachment?> watchForTask(String taskId) => _dao.watchByTaskId(taskId);
  Future<List<Attachment>> getPendingUploads() => _dao.getPendingUploads();

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
    return _dao.replaceForTask(
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
    await _dao.deleteByTaskId(taskId);
  }

  Future<void> markUploaded({
    required String attachmentId,
    required String remoteKey,
  }) async {
    await _dao.markSynced(attachmentId, remoteKey: remoteKey);
  }

  Future<void> markNeedsUpload(String attachmentId) async {
    await _dao.markPending(attachmentId);
  }
}
