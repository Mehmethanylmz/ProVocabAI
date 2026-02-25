// lib/features/study_zone/domain/usecases/start_session.dart
//
// Blueprint T-11: sessions INSERT (UUID, startedAt, categoriesJson, mode).

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../database/app_database.dart';
import '../../../../srs/mode_selector.dart';

class StartSession {
  final AppDatabase _db;
  static const _uuid = Uuid();

  const StartSession(this._db);

  /// Yeni session başlat, oluşturulan sessionId'yi döndür.
  Future<String> call({
    required String targetLang,
    required List<String> categories,
    required StudyMode mode,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;

    await _db.into(_db.sessions).insert(SessionsCompanion.insert(
          id: id,
          targetLang: targetLang,
          mode: Value(mode.key),
          startedAt: now,
          categoriesJson: Value(jsonEncode(categories)),
        ));

    return id;
  }
}
