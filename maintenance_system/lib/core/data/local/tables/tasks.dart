import 'package:drift/drift.dart';

class Tasks extends Table {
  TextColumn get id => text()(); // UUID string

  TextColumn get inspectionId => text()(); // FK by convention

  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
