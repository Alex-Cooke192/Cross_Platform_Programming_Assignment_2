import 'package:drift/drift.dart';

class Inspections extends Table {
  TextColumn get id => text()();

  TextColumn get aircraftId => text()();

  DateTimeColumn get openedAt => dateTime().nullable()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(() => DateTime.now())();

  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(false))();

  DateTimeColumn get completedAt => dateTime().nullable()();

  // FK to technicians cache table
  TextColumn get technicianId => text().nullable()();

  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}

