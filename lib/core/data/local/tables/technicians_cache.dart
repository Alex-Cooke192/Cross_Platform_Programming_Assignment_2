import 'package:drift/drift.dart';

class TechniciansCache extends Table {
  TextColumn get id => text()();   // UUID from server / domain
  TextColumn get name => text()(); // Display name

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// NEW: sync state
  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}