// This converts data from domain format so its compatible with the sync engine 
abstract class LocalSyncAdapter {
  /// Return changes to send to server.
  /// Shape must match:
  /// {
  ///   "technicians_cache": [ {...}, ... ],
  ///   "inspections": [ {...}, ... ],
  ///   "tasks": [ {...}, ... ]
  /// }
  Future<Map<String, List<Map<String, dynamic>>>> collectLocalChanges({
    DateTime? lastSyncAt,
  });

  /// Apply server changes into local DB (typically upsert by id).
  Future<void> applyServerChanges({
    required Map<String, List<Map<String, dynamic>>> serverChanges,
  });

  /// Mark local items as synced based on server "applied" summary.
  /// If your server returns IDs or counts, handle it here.
  Future<void> markAppliedAsSynced({
  required Map<String, dynamic> applied,
  required Map<String, dynamic> appliedIds,
});

  // Delete all completed inspections once successful sync has been confirmed
  Future<void> purgeCompletedSynced({required Duration olderThan});

}
