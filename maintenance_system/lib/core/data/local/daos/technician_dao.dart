import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/technicians_cache.dart';

part 'technician_dao.g.dart';

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

  Stream<TechniciansCacheData?> watchByName(String name) {
    return (select(techniciansCache)..where((t) => t.name.equals(name)))
        .watchSingleOrNull();
  }

  Future<TechniciansCacheData?> getByName(String name) {
    return (select(techniciansCache)..where((t) => t.name.equals(name)))
        .getSingleOrNull();
  }


  Future<void> upsertOne({required String id, required String name}) {
    return into(techniciansCache).insertOnConflictUpdate(
      TechniciansCacheCompanion(
        id: Value(id),
        name: Value(name),
      ),
    );
  }

  Future<void> replaceAll(List<TechniciansCacheCompanion> rows) async {
    await transaction(() async {
      await delete(techniciansCache).go();
      await batch((b) => b.insertAll(techniciansCache, rows));
    });
  }
}
