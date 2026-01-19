import 'package:drift/drift.dart';

class TechniciansCache extends Table {
  TextColumn get id => text()();   // UUID from server / domain
  TextColumn get name => text()(); // Display name

  @override
  Set<Column> get primaryKey => {id};
}