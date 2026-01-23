import 'package:maintenance_system/core/data/local/app_database.dart';
import 'package:maintenance_system/core/data/sync/local_sync_adapter.dart';

class DriftLocalSyncAdapter implements LocalSyncAdapter {
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
    // tableMap is expected to be: {"inserted":[...], "updated":[...], ...}
    if (tableMap is! Map) return const [];
    final v = tableMap[outcome];
    if (v is! List) return const [];
    return v.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
  }

  List<String> _combinedSyncedIds(dynamic tableMap) {
    // Mark these as synced: inserted + updated + skipped
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

    return <String, List<Map<String, dynamic>>>{
      'technicians_cache': techMaps,
      'inspections': inspMaps,
      'tasks': taskMaps,
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

    await db.transaction(() async {
      // FK-safe order: technicians -> inspections -> tasks

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
    // appliedIds expected:
    // {
    //   "technicians_cache": {"inserted":[...], "updated":[...], "skipped":[...], "conflict":[...]},
    //   "inspections": {"inserted":[...], ...},
    //   "tasks": {"inserted":[...], ...}
    // }

    final techMap = appliedIds['technicians_cache'];
    final inspMap = appliedIds['inspections'];
    final taskMap = appliedIds['tasks'];

    final techSynced = _combinedSyncedIds(techMap);
    final inspSynced = _combinedSyncedIds(inspMap);
    final taskSynced = _combinedSyncedIds(taskMap);

    final techConflicts = _idsFromOutcome(techMap, 'conflict');
    final inspConflicts = _idsFromOutcome(inspMap, 'conflict');
    final taskConflicts = _idsFromOutcome(taskMap, 'conflict');

    await db.transaction(() async {
      // Mark synced
      await db.technicianDao.markSyncedByIds(techSynced);
      await db.inspectionDao.markSyncedByIds(inspSynced);
      await db.taskDao.markSyncedByIds(taskSynced);

      // Mark conflicts
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
}

