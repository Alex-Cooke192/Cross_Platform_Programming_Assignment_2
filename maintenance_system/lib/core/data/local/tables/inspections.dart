import 'package:drift/drift.dart';

class Inspections extends Table {
  TextColumn get id => text()(); // UUID string

  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(false))();

  // other columns later...

  @override
  Set<Column> get primaryKey => {id};
}
