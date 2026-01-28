import 'package:drift/drift.dart';
import '../sync/sync_constants.dart';
import 'package:maintenance_system/core/data/local/app_database.dart';
import 'package:maintenance_system/core/data/sync/local_sync_adapter.dart';
import 'package:maintenance_system/core/data/sync/i_local_attachment_upload_adapter.dart';

class DriftLocalSyncAdapter implements LocalSyncAdapter, LocalAttachmentUploadAdapter {
  DriftLocalSyncAdapter(this.db);

  final AppDatabase db;

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  bool _parseBool(dynamic v) {
    if (v is bool) return v;
    if (v is int) return v != 0;
    if (v is String) {
      final s = v.toLowerCase().trim();
      return s == 'true' || s == '1' || s == 'yes';
    }
    return false;
  }

  List<String> _idsFromOutcome(dynamic tableMap, String outcome) {
    if (tableMap is! Map) return const [];
    final v = tableMap[outcome];
    if (v is! List) return const [];
    return v.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
  }

  List<String> _combinedSyncedIds(dynamic tableMap) {
    final inserted = _idsFromOutcome(tableMap, 'inserted');
    final updated = _idsFromOutcome(tableMap, 'updated');
    final skipped = _idsFromOutcome(tableMap, 'skipped');
    return <String>{...inserted, ...updated, ...skipped}.toList();
  }

  // -----------------------
  // 1) Local -> Server (snake_case)
  // -----------------------
  @override
  Future<Map<String, List<Map<String, dynamic>>>> collectLocalChanges({
    DateTime? lastSyncAt,
  }) async {
    final techs = await db.technicianDao.getPendingChanges(since: lastSyncAt);
    final insps = await db.inspectionDao.getPendingChanges(since: lastSyncAt);
    final tasks = await db.taskDao.getPendingChanges(since: lastSyncAt);

    // Attachments: keep it metadata-only (no bytes). Only pending items.
    final atts = await db.attachmentsDao.getPendingMetadataSync();

    final techMaps = techs
        .map((t) => <String, dynamic>{
              'id': t.id,
              'name': t.name,
              'created_at': t.createdAt.toUtc().toIso8601String(),
              'updated_at': t.updatedAt.toUtc().toIso8601String(),
            })
        .toList();

    final inspMaps = insps
        .map((i) => <String, dynamic>{
              'id': i.id,
              'aircraft_id': i.aircraftId,
              'opened_at': i.openedAt?.toUtc().toIso8601String(),
              'created_at': i.createdAt.toUtc().toIso8601String(),
              'updated_at': i.updatedAt.toUtc().toIso8601String(),
              'is_completed': i.isCompleted ? 1 : 0,
              'completed_at': i.completedAt?.toUtc().toIso8601String(),
              'technician_id': i.technicianId,
            })
        .toList();

    final taskMaps = tasks
        .map((t) => <String, dynamic>{
              'id': t.id,
              'inspection_id': t.inspectionId,
              'title': t.title,
              'is_completed': t.isCompleted ? 1 : 0,
              'result': t.result,
              'notes': t.notes,
              'created_at': t.createdAt.toUtc().toIso8601String(),
              'updated_at': t.updatedAt.toUtc().toIso8601String(),
            })
        .toList();

    final attMaps = atts
        .map((a) => <String, dynamic>{
              'id': a.id,
              'task_id': a.taskId,
              'file_name': a.fileName,
              'mime_type': a.mimeType,
              'size_bytes': a.sizeBytes,
              'sha256': a.sha256,
              'remote_key': a.remoteKey,
              'created_at': a.createdAt.toUtc().toIso8601String(),
              'updated_at': a.updatedAt.toUtc().toIso8601String(),
            })
        .toList();

    return <String, List<Map<String, dynamic>>>{
      'technicians_cache': techMaps,
      'inspections': inspMaps,
      'tasks': taskMaps,
      'attachments': attMaps,
    };
  }

  // -----------------------
  // 2) Server -> Local (snake_case)
  // -----------------------
  @override
  Future<void> applyServerChanges({
    required Map<String, List<Map<String, dynamic>>> serverChanges,
  }) async {
    final techs = serverChanges['technicians_cache'] ?? const [];
    final insps = serverChanges['inspections'] ?? const [];
    final tasks = serverChanges['tasks'] ?? const [];
    final atts = serverChanges['attachments'] ?? const [];

    await db.transaction(() async {
      // FK-safe order: technicians -> inspections -> tasks -> attachments

      for (final t in techs) {
        final id = (t['id'] ?? '').toString();
        if (id.isEmpty) continue;

        final username = (t['username'] ?? '').toString().trim();
        final name = (t['name'] ?? '').toString().trim();
        final displayName = (t['display_name'] ?? '').toString().trim();

        final effectiveName =
            username.isNotEmpty ? username : (name.isNotEmpty ? name : displayName);

        if (effectiveName.isEmpty) continue;

        final createdAt = _parseDate(t['created_at']) ?? DateTime.now();
        final updatedAt = _parseDate(t['updated_at']) ?? DateTime.now();

        await db.technicianDao.upsertFromServer(
          id: id,
          name: effectiveName,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );
      }

      for (final i in insps) {
        final id = (i['id'] ?? '').toString();
        final aircraftId = (i['aircraft_id'] ?? '').toString();
        if (id.isEmpty || aircraftId.isEmpty) continue;

        final createdAt = _parseDate(i['created_at']) ?? DateTime.now();
        final updatedAt = _parseDate(i['updated_at']) ?? DateTime.now();

        await db.inspectionDao.upsertFromServer(
          id: id,
          aircraftId: aircraftId,
          createdAt: createdAt,
          updatedAt: updatedAt,
          isCompleted: _parseBool(i['is_completed']),
          openedAt: _parseDate(i['opened_at']),
          completedAt: _parseDate(i['completed_at']),
          technicianId: (i['technician_id'] as String?),
        );
      }

      for (final tk in tasks) {
        final id = (tk['id'] ?? '').toString();
        final inspectionId = (tk['inspection_id'] ?? '').toString();
        final title = (tk['title'] ?? '').toString();
        if (id.isEmpty || inspectionId.isEmpty || title.isEmpty) continue;

        final createdAt = _parseDate(tk['created_at']) ?? DateTime.now();
        final updatedAt = _parseDate(tk['updated_at']) ?? DateTime.now();

        await db.taskDao.upsertFromServer(
          id: id,
          inspectionId: inspectionId,
          title: title,
          createdAt: createdAt,
          updatedAt: updatedAt,
          isCompleted: _parseBool(tk['is_completed']),
          result: (tk['result'] as String?),
          notes: (tk['notes'] as String?),
        );
      }

      for (final a in atts) {
        final id = (a['id'] ?? '').toString();
        final taskId = (a['task_id'] ?? '').toString();
        final fileName = (a['file_name'] ?? '').toString();
        final mimeType = (a['mime_type'] ?? '').toString();

        if (id.isEmpty || taskId.isEmpty || fileName.isEmpty || mimeType.isEmpty) {
          continue;
        }

        final createdAt = _parseDate(a['created_at']) ?? DateTime.now();
        final updatedAt = _parseDate(a['updated_at']) ?? DateTime.now();

        // Preserve localPath so we don't wipe the on-device file reference
        final existing = await db.attachmentsDao.getByTaskId(taskId);
        final preservedLocalPath = existing?.localPath;

        await db.attachmentsDao.upsert(
          AttachmentsCompanion(
            id: Value(id),
            taskId: Value(taskId),
            fileName: Value(fileName),
            mimeType: Value(mimeType),
            sizeBytes: Value((a['size_bytes'] as int?) ?? 0),
            sha256: Value(a['sha256'] as String?),
            localPath: Value(preservedLocalPath),
            remoteKey: Value(a['remote_key'] as String?),
            createdAt: Value(createdAt),
            updatedAt: Value(updatedAt),
            syncStatus: const Value(kSyncSynced),
          ),
        );
      }
    });
  }

  // -----------------------
  // 3) Mark synced/conflict using applied_ids
  // -----------------------
  @override
  Future<void> markAppliedAsSynced({
    required Map<String, dynamic> applied,
    required Map<String, dynamic> appliedIds,
  }) async {
    final techMap = appliedIds['technicians_cache'];
    final inspMap = appliedIds['inspections'];
    final taskMap = appliedIds['tasks'];
    final attMap = appliedIds['attachments'];

    final techSynced = _combinedSyncedIds(techMap);
    final inspSynced = _combinedSyncedIds(inspMap);
    final taskSynced = _combinedSyncedIds(taskMap);
    final attInserted = _idsFromOutcome(attMap, 'inserted');
    final attUpdated  = _idsFromOutcome(attMap, 'updated');
    final attSynced   = <String>{...attInserted, ...attUpdated}.toList();

    final techConflicts = _idsFromOutcome(techMap, 'conflict');
    final inspConflicts = _idsFromOutcome(inspMap, 'conflict');
    final taskConflicts = _idsFromOutcome(taskMap, 'conflict');
    // Conflict marking
    // final attConflicts = _idsFromOutcome(attMap, 'conflict');

    await db.transaction(() async {
      await db.technicianDao.markSyncedByIds(techSynced);
      await db.inspectionDao.markSyncedByIds(inspSynced);
      await db.taskDao.markSyncedByIds(taskSynced);

      // AttachmentsDao does not have markSyncedByIds/markConflictByIds,
      // so we mark one-by-one using existing methods.
      for (final id in attSynced) {
        await db.attachmentsDao.markSynced(id);
      }
      /*
      CONFLICT MARKING TO BE ADDED
      for (final id in attConflicts) {
        // You don't currently have markConflict in AttachmentsDao.
        // If you want true conflict marking, add a markConflict(id) method.
        // For now, we leave conflicts unmodified to stay within your current DAO methods.
      }
      */

      await db.technicianDao.markConflictByIds(techConflicts);
      await db.inspectionDao.markConflictByIds(inspConflicts);
      await db.taskDao.markConflictByIds(taskConflicts);
    });
  }

  @override
  Future<void> purgeCompletedSynced({required Duration olderThan}) async {
    await db.inspectionDao.purgeCompletedSynced(olderThan: olderThan);
  }

  @override
  Future<bool> hasAnyData() async {
    final row = await (db.select(db.inspections)..limit(1)).getSingleOrNull();
    return row != null;
  }

  @override
  Future<bool> hasAnyTechnicians() async {
    final row = await (db.select(db.techniciansCache)..limit(1)).getSingleOrNull();
    return row != null;
  }

  // -----------------------
  // Attachment upload helpers
  // -----------------------
  @override
  Future<List<PendingAttachmentUpload>> getPendingAttachmentUploads() async {
    final rows = await db.attachmentsDao.getPendingUploads();
    return rows
        .map((a) => PendingAttachmentUpload(
              id: a.id,
              localPath: a.localPath,
            ))
        .toList();
  }

  @override
  Future<void> setAttachmentRemoteKey(
      String attachmentId, String remoteKey) async {
    await db.attachmentsDao.setRemoteKey(attachmentId, remoteKey);
  }
}
