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

  Future<TechnicianUi?> getByUsername(String username) async {
    final row = await db.technicianDao.getByUsername(username);
    return row?.toUi();
  }


  Stream<TechnicianUi?> watchByName(String name) =>
      db.technicianDao.watchByName(name).map((row) => row?.toUi());

  Future<TechnicianUi?> getByName(String name) async {
    final row = await db.technicianDao.getByName(name);
    return row?.toUi();
  }

  // Optional raw access
  Stream<List<TechniciansCacheData>> watchAll() => db.technicianDao.watchAll();
  Stream<TechniciansCacheData?> watchById(String id) => db.technicianDao.watchById(id);

  Future<void> upsertOne({required String id, required String name}) =>
      db.technicianDao.upsertOne(id: id, name: name);

  Future<TechniciansCacheData?> getAnyTechnician() => db.technicianDao.getAny();

  Future<String> createTechnician({required String name}) async {
    final formattedName = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    final id = const Uuid().v4();

    if (await db.technicianDao.nameExists(formattedName)) {
      throw Exception('Technician name already exists');
    }

    // DAO will mark pending + updatedAt
    await db.technicianDao.upsertOne(
      id: id,
      name: formattedName,
    );

    return id;
  }

  // ---- Sync (Server -> Local) ----

  Future<void> upsertFromServer({
    required String id,
    required String name,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) {
    return db.technicianDao.upsertFromServer(
      id: id,
      name: name,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Apply a snapshot (or changes list) from server safely via upserts.
  Future<void> applyServerTechnicians(List<Map<String, dynamic>> technicians) async {
    // Expect keys: id, name, created_at/createdAt, updated_at/updatedAt
    // Adjust parsing to match your server's key naming convention.
    for (final t in technicians) {
      final id = (t['id'] ?? '').toString();
      final name = (t['name'] ?? '').toString();
      if (id.isEmpty || name.isEmpty) continue;

      final createdAt = DateTime.tryParse((t['created_at'] ?? t['createdAt'] ?? '').toString()) ??
          DateTime.now();
      final updatedAt = DateTime.tryParse((t['updated_at'] ?? t['updatedAt'] ?? '').toString()) ??
          DateTime.now();

      await upsertFromServer(
        id: id,
        name: name,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    }
  }

  /// Keep this only if you truly want "server snapshot overwrites local cache".
  /// It will delete local pending/conflict rows unless you handle that separately.
  Future<void> replaceAllFromServer(List<Map<String, String>> technicians) {
    final rows = technicians
        .map((t) => TechniciansCacheCompanion(
              id: Value(t['id']!),
              name: Value(t['name']!),
              // NOTE: You should include createdAt/updatedAt/syncStatus here if you keep replaceAll.
            ))
        .toList();
    return db.technicianDao.replaceAll(rows);
  }
}
