class SyncResult {
  final String jobId;
  final DateTime serverTime;
  final Map<String, dynamic> applied;
  final Map<String, dynamic> conflicts;
  final Map<String, dynamic> serverChanges;

  SyncResult({
    required this.jobId,
    required this.serverTime,
    required this.applied,
    required this.conflicts,
    required this.serverChanges,
  });

  bool get hasConflicts {
    bool anyListHasItems(dynamic v) => v is List && v.isNotEmpty;
    return conflicts.values.any(anyListHasItems);
  }
}

class SyncException implements Exception {
  final String message;
  final int? statusCode;

  SyncException(this.message, {this.statusCode});

  @override
  String toString() => statusCode == null
      ? 'SyncException: $message'
      : 'SyncException($statusCode): $message';
}
