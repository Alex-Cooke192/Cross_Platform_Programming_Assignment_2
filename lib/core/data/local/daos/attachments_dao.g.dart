// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attachments_dao.dart';

// ignore_for_file: type=lint
mixin _$AttachmentsDaoMixin on DatabaseAccessor<AppDatabase> {
  $InspectionsTable get inspections => attachedDatabase.inspections;
  $TasksTable get tasks => attachedDatabase.tasks;
  $AttachmentsTable get attachments => attachedDatabase.attachments;
  AttachmentsDaoManager get managers => AttachmentsDaoManager(this);
}

class AttachmentsDaoManager {
  final _$AttachmentsDaoMixin _db;
  AttachmentsDaoManager(this._db);
  $$InspectionsTableTableManager get inspections =>
      $$InspectionsTableTableManager(_db.attachedDatabase, _db.inspections);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db.attachedDatabase, _db.tasks);
  $$AttachmentsTableTableManager get attachments =>
      $$AttachmentsTableTableManager(_db.attachedDatabase, _db.attachments);
}
