import 'package:drift/drift.dart';
import 'tasks.dart'; // IMPORTANT: import the Dart table class you reference

class Attachments extends Table {
  TextColumn get id => text()();

  // Enforces max 1 attachment per task
  TextColumn get taskId => text()
      .references(Tasks, #id, onDelete: KeyAction.cascade)
      .unique()();

  TextColumn get fileName => text()();
  TextColumn get mimeType => text()();
  IntColumn get sizeBytes => integer()();

  TextColumn get sha256 => text().nullable()();
  TextColumn get localPath => text().nullable()();
  TextColumn get remoteKey => text().nullable()();

  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending'))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
