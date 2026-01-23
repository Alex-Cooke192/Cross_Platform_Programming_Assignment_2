import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/technicians_cache.dart';

part 'technician_dao.g.dart';

const String kSyncPending = 'pending';
const String kSyncSynced = 'synced';
const String kSyncConflict = 'conflict';

@DriftAccessor(tables: [TechniciansCache])
class TechnicianDao extends DatabaseAccessor<AppDatabase>
    with _$TechnicianDaoMixin {
  TechnicianDao(super.db);

  Stream<List<TechniciansCacheData>> watchAll() {
    return (select(techniciansCache)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Stream<TechniciansCacheData?> watchById(String id) {
    return (select(techniciansCache)..where((t) => t.id.equals(id)))
        .watchSingleOrNull();
  }

  Future<TechniciansCacheData?> getAny() {
    return (select(techniciansCache)..limit(1)).getSingleOrNull();
  }

  Future<TechniciansCacheData?> getByUsername(String username) {
  final u = username.trim().toLowerCase();
  if (u.isEmpty) return Future.value(null);

  return customSelect(
    'SELECT * FROM technicians_cache WHERE lower(name) = ? LIMIT 1',
    variables: [Variable<String>(u)],
    readsFrom: {techniciansCache},
  ).map((row) => techniciansCache.map(row.data)).getSingleOrNull();
}


  Future<bool> hasAnyTechnicians() async {
    final row = await (db.select(db.techniciansCache)..limit(1)).getSingleOrNull();
    return row != null;
  }

  Future<bool> nameExists(String name) async {
    final row = await (select(techniciansCache)..where((t) => t.name.equals(name)))
        .getSingleOrNull();
    return row != null;
  }

  Future<TechniciansCacheData?> getById(String id) =>
    (select(techniciansCache)..where((t) => t.id.equals(id))).getSingleOrNull();

  // Local upsert (user/admin action) => pending + updatedAt
  Future<void> upsertOne({required String id, required String name}) {
    final now = DateTime.now();
    return into(techniciansCache).insertOnConflictUpdate(
      TechniciansCacheCompanion(
        id: Value(id),
        name: Value(name),
        updatedAt: Value(now),
        syncStatus: const Value(kSyncPending),
      ),
    );
  }

  /// Server upsert => synced
  Future<void> upsertFromServer({
    required String id,
    required String name,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) {
    return into(techniciansCache).insertOnConflictUpdate(
      TechniciansCacheCompanion(
        id: Value(id),
        name: Value(name),
        createdAt: Value(createdAt),
        updatedAt: Value(updatedAt),
        syncStatus: const Value(kSyncSynced),
      ),
    );
  }

  /// Replace-all is OK only if you truly want server to be source-of-truth.
  /// If you keep this, it should mark all rows as synced and preserve timestamps.
  Future<void> replaceAll(List<TechniciansCacheCompanion> rows) async {
    await transaction(() async {
      await delete(techniciansCache).go();
      await batch((b) => b.insertAll(techniciansCache, rows));
    });
  }

  // ---- Sync helpers ----

  Future<List<TechniciansCacheData>> getPendingChanges({DateTime? since}) {
    final q = select(techniciansCache)
      ..where((t) => t.syncStatus.equals(kSyncPending));
    if (since != null) {
      q.where((t) => t.updatedAt.isBiggerThanValue(since));
    }
    return q.get();
  }

  Future<int> markSyncedByIds(List<String> ids) {
    if (ids.isEmpty) return Future.value(0);
    final now = DateTime.now();
    return (update(techniciansCache)..where((t) => t.id.isIn(ids))).write(
      TechniciansCacheCompanion(
        syncStatus: const Value(kSyncSynced),
        updatedAt: Value(now),
      ),
    );
  }

  Future<int> markConflictByIds(List<String> ids) {
    if (ids.isEmpty) return Future.value(0);
    final now = DateTime.now();
    return (update(techniciansCache)..where((t) => t.id.isIn(ids))).write(
      TechniciansCacheCompanion(
        syncStatus: const Value(kSyncConflict),
        updatedAt: Value(now),
      ),
    );
  }
}
