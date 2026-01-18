// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'technician_dao.dart';

// ignore_for_file: type=lint
mixin _$TechnicianDaoMixin on DatabaseAccessor<AppDatabase> {
  $TechniciansCacheTable get techniciansCache =>
      attachedDatabase.techniciansCache;
  TechnicianDaoManager get managers => TechnicianDaoManager(this);
}

class TechnicianDaoManager {
  final _$TechnicianDaoMixin _db;
  TechnicianDaoManager(this._db);
  $$TechniciansCacheTableTableManager get techniciansCache =>
      $$TechniciansCacheTableTableManager(
        _db.attachedDatabase,
        _db.techniciansCache,
      );
}
