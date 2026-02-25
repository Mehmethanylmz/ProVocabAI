// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_dao.dart';

// ignore_for_file: type=lint
mixin _$ProgressDaoMixin on DatabaseAccessor<AppDatabase> {
  $WordsTable get words => attachedDatabase.words;
  $ProgressTable get progress => attachedDatabase.progress;
  ProgressDaoManager get managers => ProgressDaoManager(this);
}

class ProgressDaoManager {
  final _$ProgressDaoMixin _db;
  ProgressDaoManager(this._db);
  $$WordsTableTableManager get words =>
      $$WordsTableTableManager(_db.attachedDatabase, _db.words);
  $$ProgressTableTableManager get progress =>
      $$ProgressTableTableManager(_db.attachedDatabase, _db.progress);
}
