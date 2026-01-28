/// Exposes access to locally-stored attachment files so that the SyncService
/// can upload blobs before running the metadata sync (/sync/jobs).
///
/// This keeps file transfer concerns separate from structured record sync.
abstract class LocalAttachmentUploadAdapter {
  /// Returns attachments that have a local file path and are pending upload.
  Future<List<PendingAttachmentUpload>> getPendingAttachmentUploads();

  /// Persists the remote storage key returned by the server after upload.
  Future<void> setAttachmentRemoteKey(String attachmentId, String remoteKey);
}

/// Simple DTO used during upload (no DB or Drift dependency).
class PendingAttachmentUpload {
  final String id;
  final String? localPath;

  PendingAttachmentUpload({
    required this.id,
    required this.localPath,
  });
}
