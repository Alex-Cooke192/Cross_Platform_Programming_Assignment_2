import 'package:drift/drift.dart';

@TableIndex(
  name: 'tasks_inspection_id',
  columns: {#inspectionId},
)
class Tasks extends Table {
  TextColumn get id => text()(); // Uuid string

  TextColumn get inspectionId => text().customConstraint(
    'NOT NULL REFERENCES inspections(id) ON DELETE CASCADE'
  )(); 

  TextColumn get title => text()();

  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(false))();

  TextColumn get result => text().nullable()();
  TextColumn get notes => text().nullable()();

  // Timestamps for sync
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();

  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(() => DateTime.now())();

  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id}; 
}

