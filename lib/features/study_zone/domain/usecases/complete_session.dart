// lib/features/study_zone/domain/usecases/complete_session.dart
//
// FAZ 4 FIX:
//   - LeaderboardService constructor injection (getIt direkt erişim kaldırıldı)
//   - updateUserXP() → displayName geçirilir (root doküman için)
//   - FirebaseAuth direkt erişim korunuyor (use case seviyesinde kabul edilebilir)

import 'package:drift/drift.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../database/app_database.dart';
import '../../../../firebase/firestore/leaderboard_service.dart';

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
  final LeaderboardService _leaderboardService;

  const CompleteSession(this._db, this._leaderboardService);

  Future<void> call(CompleteSessionParams p) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // 1. Drift: session'ı kapat
    await (_db.update(_db.sessions)..where((s) => s.id.equals(p.sessionId)))
        .write(SessionsCompanion(
      endedAt: Value(now),
      totalCards: Value(p.totalCards),
      correctCards: Value(p.correctCards),
      xpEarned: Value(p.xpEarned),
    ));

    // 2. Firestore: XP'yi online ise gönder — offline ise sessizce geç
    if (p.xpEarned > 0) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await _leaderboardService.updateUserXP(
            uid: user.uid,
            xpDelta: p.xpEarned,
            displayName: user.displayName,
            photoUrl: user.photoURL,
          );
        } catch (_) {
          // Offline-first: hata susturulur, sonraki sync'te tamamlanır
        }
      }
    }
  }
}
