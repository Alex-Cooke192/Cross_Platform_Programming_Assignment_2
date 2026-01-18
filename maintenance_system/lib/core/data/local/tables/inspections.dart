import 'package:drift/drift.dart';

class Inspections extends Table {
  TextColumn get id => text()();

  TextColumn get aircraftId => text()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(false))();

  DateTimeColumn get completedAt => dateTime().nullable()();

  TextColumn get technicianId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

