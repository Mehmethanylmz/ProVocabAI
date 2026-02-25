// lib/features/study_zone/domain/usecases/complete_session.dart
//
// Blueprint T-11: sessions UPDATE (endedAt=now, totalTimeMs), XP.

import 'package:drift/drift.dart';
import '../../../../database/app_database.dart';

class CompleteSessionParams {
  final String sessionId;
  final int totalCards;
  final int correctCards;
  final int xpEarned;

  const CompleteSessionParams({
    required this.sessionId,
    required this.totalCards,
    required this.correctCards,
    required this.xpEarned,
  });
}

class CompleteSession {
  final AppDatabase _db;

  const CompleteSession(this._db);

  Future<void> call(CompleteSessionParams p) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await (_db.update(_db.sessions)..where((s) => s.id.equals(p.sessionId)))
        .write(SessionsCompanion(
      endedAt: Value(now),
      totalCards: Value(p.totalCards),
      correctCards: Value(p.correctCards),
      xpEarned: Value(p.xpEarned),
    ));
  }
}
