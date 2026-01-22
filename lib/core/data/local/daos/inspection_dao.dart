import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/inspections.dart';

part 'inspection_dao.g.dart';

const String kSyncPending = 'pending';
const String kSyncSynced = 'synced';
const String kSyncConflict = 'conflict';

@DriftAccessor(tables: [Inspections])
class InspectionDao extends DatabaseAccessor<AppDatabase>
    with _$InspectionDaoMixin {
  InspectionDao(super.db);

  // ---- Reads (Streams) ----

  Stream<List<Inspection>> watchAll() {
    return (select(inspections)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Stream<List<Inspection>> watchUnopened() {
    return (select(inspections)
          ..where((i) => i.openedAt.isNull() & i.isCompleted.equals(false))
          ..orderBy([(i) => OrderingTerm.desc(i.createdAt)]))
        .watch();
  }

  Stream<List<Inspection>> watchInProgress() {
    return (select(inspections)
          ..where((t) =>
              t.isCompleted.equals(false) &
              t.openedAt.isNotNull() &
              t.completedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Stream<List<Inspection>> watchCompleted() {
    return (select(inspections)
          ..where((t) => t.isCompleted.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.completedAt)]))
        .watch();
  }

  Stream<List<Inspection>> watchByTechnician(String technicianId) {
    return (select(inspections)..where((tbl) => tbl.technicianId.equals(technicianId)))
        .watch();
  }

  Stream<List<Inspection>> watchUnopenedByTechnician(String technicianId) {
    return (select(inspections)
          ..where((tbl) =>
              tbl.technicianId.equals(technicianId) & tbl.openedAt.isNull()))
        .watch();
  }

  Stream<List<Inspection>> watchInProgressByTechnician(String technicianId) {
    return (select(inspections)
          ..where((tbl) =>
              tbl.technicianId.equals(technicianId) &
              tbl.openedAt.isNotNull() &
              tbl.completedAt.isNull()))
        .watch();
  }

  Stream<List<Inspection>> watchCompletedByTechnician(String technicianId) {
    return (select(inspections)
          ..where((tbl) =>
              tbl.technicianId.equals(technicianId) & tbl.completedAt.isNotNull()))
        .watch();
  }

  Stream<Inspection?> watchById(String id) {
    return (select(inspections)..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  // ---- Writes (Local user actions) ----
  // Always mark pending + bump updatedAt

  Future<void> insertInspection({
    required String id,
    required String aircraftId,
    String? technicianId,
  }) async {
    final now = DateTime.now();

    await into(inspections).insert(
      InspectionsCompanion.insert(
        id: id,
        aircraftId: aircraftId,
        technicianId: Value(technicianId),
        // createdAt defaults to now
        updatedAt: Value(now),
        syncStatus: const Value(kSyncPending),
      ),
    );
  }

  Future<int> setOpened(String id) {
    final now = DateTime.now();
    return (update(inspections)..where((i) => i.id.equals(id))).write(
      InspectionsCompanion(
        openedAt: Value(now),
        updatedAt: Value(now),
        syncStatus: const Value(kSyncPending),
      ),
    );
  }

  Future<int> setCompleted(String inspectionId, bool completed) {
    final now = DateTime.now();
    return (update(inspections)..where((t) => t.id.equals(inspectionId))).write(
      InspectionsCompanion(
        isCompleted: Value(completed),
        completedAt: completed ? Value(now) : const Value(null),
        updatedAt: Value(now),
        syncStatus: const Value(kSyncPending),
      ),
    );
  }

  Future<int> setTechnician(String inspectionId, String? technicianId) {
    final now = DateTime.now();
    return (update(inspections)..where((t) => t.id.equals(inspectionId))).write(
      InspectionsCompanion(
        technicianId: Value(technicianId),
        updatedAt: Value(now),
        syncStatus: const Value(kSyncPending),
      ),
    );
  }

  Future<int> deleteById(String id) {
    // If you want deletions to sync, we’d implement tombstones instead of hard delete.
    return (delete(inspections)..where((t) => t.id.equals(id))).go();
  }

  // ---- Sync helpers (Adapter will call these) ----

  /// Get inspections needing upload.
  Future<List<Inspection>> getPendingChanges({DateTime? since}) {
    final q = select(inspections)..where((t) => t.syncStatus.equals(kSyncPending));
    if (since != null) {
      q.where((t) => t.updatedAt.isBiggerThanValue(since));
    }
    return q.get();
  }

  /// Apply one inspection row from server (upsert) and mark as synced.
  Future<void> upsertFromServer({
    required String id,
    required String aircraftId,
    required DateTime createdAt,
    required DateTime updatedAt,
    required bool isCompleted,
    DateTime? openedAt,
    DateTime? completedAt,
    String? technicianId,
  }) async {
    await into(inspections).insertOnConflictUpdate(
      InspectionsCompanion(
        id: Value(id),
        aircraftId: Value(aircraftId),
        createdAt: Value(createdAt),
        updatedAt: Value(updatedAt),
        openedAt: Value(openedAt),
        isCompleted: Value(isCompleted),
        completedAt: Value(completedAt),
        technicianId: Value(technicianId),
        syncStatus: const Value(kSyncSynced),
      ),
    );
  }

  /// Mark a set of IDs as synced.
  Future<int> markSyncedByIds(List<String> ids) {
    if (ids.isEmpty) return Future.value(0);
    final now = DateTime.now();
    return (update(inspections)..where((t) => t.id.isIn(ids))).write(
      InspectionsCompanion(
        syncStatus: const Value(kSyncSynced),
        updatedAt: Value(now),
      ),
    );
  }

  /// Mark a set of IDs as conflict.
  Future<int> markConflictByIds(List<String> ids) {
    if (ids.isEmpty) return Future.value(0);
    final now = DateTime.now();
    return (update(inspections)..where((t) => t.id.isIn(ids))).write(
      InspectionsCompanion(
        syncStatus: const Value(kSyncConflict),
        updatedAt: Value(now),
      ),
    );
  }

  Future<int> purgeCompletedSynced({Duration? olderThan}) async {
    final cutoff = olderThan == null
        ? null
        : DateTime.now().toUtc().subtract(olderThan);

    return transaction(() async {
      final query = select(inspections)
        ..where((i) => i.completedAt.isNotNull() & i.syncStatus.equals('synced'));

      if (cutoff != null) {
        query.where((i) => i.completedAt.isSmallerOrEqualValue(cutoff));
      }

      final eligible = await query.get();
      if (eligible.isEmpty) return 0;

      // With ON DELETE CASCADE on tasks.inspectionId, this deletes tasks automatically.
      for (final insp in eligible) {
        await (delete(inspections)..where((i) => i.id.equals(insp.id))).go();
      }

      return eligible.length;
    });
  }
}
