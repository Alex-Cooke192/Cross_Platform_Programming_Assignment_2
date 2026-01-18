import 'package:drift/drift.dart';

import '../app_database.dart';

class TechnicianRepository {
  final AppDatabase db;
  TechnicianRepository(this.db);

  Stream<List<TechniciansCacheData>> watchAll() => db.technicianDao.watchAll();

  Stream<TechniciansCacheData?> watchById(String id) =>
      db.technicianDao.watchById(id);

  Future<void> upsertOne({required String id, required String name}) =>
      db.technicianDao.upsertOne(id: id, name: name);

  Future<void> replaceAllFromServer(List<Map<String, String>> technicians) {
    final rows = technicians
        .map((t) => TechniciansCacheCompanion(
              id: Value(t['id']!),
              name: Value(t['name']!),
            ))
        .toList();
    return db.technicianDao.replaceAll(rows);
  }
}
