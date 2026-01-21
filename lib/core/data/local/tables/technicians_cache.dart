import 'package:drift/drift.dart';

class TechniciansCache extends Table {
  TextColumn get id => text()();   // UUID from server / domain
  TextColumn get name => text()(); // Display name

  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now())();

  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(() => DateTime.now())();

  /// NEW: sync state
  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}