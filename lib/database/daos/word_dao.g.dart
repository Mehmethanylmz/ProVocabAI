// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'word_dao.dart';

// ignore_for_file: type=lint
mixin _$WordDaoMixin on DatabaseAccessor<AppDatabase> {
  $WordsTable get words => attachedDatabase.words;
  $ProgressTable get progress => attachedDatabase.progress;
  WordDaoManager get managers => WordDaoManager(this);
}

class WordDaoManager {
  final _$WordDaoMixin _db;
  WordDaoManager(this._db);
  $$WordsTableTableManager get words =>
      $$WordsTableTableManager(_db.attachedDatabase, _db.words);
  $$ProgressTableTableManager get progress =>
      $$ProgressTableTableManager(_db.attachedDatabase, _db.progress);
}
