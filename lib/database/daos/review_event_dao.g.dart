// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_event_dao.dart';

// ignore_for_file: type=lint
mixin _$ReviewEventDaoMixin on DatabaseAccessor<AppDatabase> {
  $WordsTable get words => attachedDatabase.words;
  $ReviewEventsTable get reviewEvents => attachedDatabase.reviewEvents;
  ReviewEventDaoManager get managers => ReviewEventDaoManager(this);
}

class ReviewEventDaoManager {
  final _$ReviewEventDaoMixin _db;
  ReviewEventDaoManager(this._db);
  $$WordsTableTableManager get words =>
      $$WordsTableTableManager(_db.attachedDatabase, _db.words);
  $$ReviewEventsTableTableManager get reviewEvents =>
      $$ReviewEventsTableTableManager(_db.attachedDatabase, _db.reviewEvents);
}
