import 'package:drift/drift.dart';
import '../../../../models/ui_models.dart';
import '../../../../models/technician_mapper.dart';
import 'package:uuid/uuid.dart';

import '../app_database.dart';

class TechnicianRepository {
  final AppDatabase db;
  TechnicianRepository(this.db);

  Stream<List<TechnicianUi>> watchAllUi() =>
      db.technicianDao.watchAll().map((rows) => rows.map((r) => r.toUi()).toList());

  Stream<TechnicianUi?> watchByIdUi(String id) =>
      db.technicianDao.watchById(id).map((row) => row?.toUi());

  Future<TechnicianUi?> getAnyTechnicianUi() async {
    final row = await db.technicianDao.getAny();
    return row?.toUi();
  }

  Stream<TechnicianUi?> watchByName(String name) =>
    db.technicianDao.watchByName(name).map((row) => row?.toUi()); 

  Future<TechnicianUi?> getByName(String name) async {
      final row = await db.technicianDao.getByName(name);
      return row?.toUi(); 
  }


  // These methods are now optional, as ui now uses TechnicianUi model
  Stream<List<TechniciansCacheData>> watchAll() => db.technicianDao.watchAll();

  Stream<TechniciansCacheData?> watchById(String id) =>
      db.technicianDao.watchById(id);

  Future<void> upsertOne({required String id, required String name}) =>
      db.technicianDao.upsertOne(id: id, name: name);

  Future<TechniciansCacheData?> getAnyTechnician() {
    return db.technicianDao.getAny();
  }

  Future<String> createTechnician({required String name}) async {
    final formattedName = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    final id = const Uuid().v4();

    if (await db.technicianDao.nameExists(formattedName)) {
      throw Exception('Technician name already exists');
    }
    await db.technicianDao.upsertOne(
        id: id,
        name: formattedName,
    ); 

    return id;
  }

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
