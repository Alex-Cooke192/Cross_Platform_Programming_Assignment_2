import 'package:drift/drift.dart';

@TableIndex(
  name: 'tasks_inspection_id',
  columns: {#inspectionId},
)
class Tasks extends Table {
  TextColumn get id => text()(); // Uuid string

  TextColumn get inspectionId => text()(); 

  TextColumn get title => text()();

  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(false))();

  TextColumn get result => text().nullable()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id}; 
}

