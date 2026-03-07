// lib/features/dashboard/presentation/state/dashboard_bloc.dart
//
// FAZ 12 — F12-02, F12-10:
//   - ReviewEventDao eklendi → heatmap verisi
//   - Detaylı bugün/hafta/ay metrikleri (correct, wrong, timeMinutes)
//   - todayModeDistribution: Bugünkü mod dağılımı
//   - heatmapData: Son 26 hafta günlük aktivite
//   - Akıllı koç mesajı (kural bazlı, F12-10)

import 'package:drift/drift.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../database/daos/progress_dao.dart';
import '../../../../database/daos/review_event_dao.dart';
import '../../../../database/daos/session_dao.dart';
import '../../../../database/daos/word_dao.dart';
import '../../domain/entities/dashboard_stats_entity.dart';

// ── Events ────────────────────────────────────────────────────────────────────

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();
  @override
  List<Object?> get props => [];
}

class DashboardLoadRequested extends DashboardEvent {
  final String targetLang;
  const DashboardLoadRequested({this.targetLang = ''});
  @override
  List<Object?> get props => [targetLang];
}

class DashboardRefreshRequested extends DashboardEvent {
  final String targetLang;
  const DashboardRefreshRequested({this.targetLang = ''});
  @override
  List<Object?> get props => [targetLang];
}

// ── States ────────────────────────────────────────────────────────────────────

abstract class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final DashboardStatsEntity stats;
  final Map<String, double> volumeStats;
  final Map<String, double> accuracyStats;
  final String coachMessage;
  final List<Map<String, dynamic>> monthlyActivity;

  const DashboardLoaded({
    required this.stats,
    required this.volumeStats,
    required this.accuracyStats,
    required this.coachMessage,
    required this.monthlyActivity,
  });

  @override
  List<Object?> get props =>
      [stats, volumeStats, accuracyStats, coachMessage, monthlyActivity];

  /// Share text üretimi (ProfileView için)
  String? get shareText {
    if (stats.todayQuestions == 0 &&
        stats.weekQuestions == 0 &&
        stats.monthQuestions == 0) return null;
    return '🎓 ProVocabAI\'da ${stats.weekQuestions} kelime çalıştım! '
        'Bu hafta başarı oranım: %${stats.weekSuccessRate.toStringAsFixed(0)}. '
        'Sen de dene! #ProVocabAI';
  }
}

class DashboardError extends DashboardState {
  final String message;
  const DashboardError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ──────────────────────────────────────────────────────────────────────

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc({
    required SessionDao sessionDao,
    required WordDao wordDao,
    required ProgressDao progressDao,
    required ReviewEventDao reviewEventDao,
  })  : _sessionDao = sessionDao,
        _wordDao = wordDao,
        _progressDao = progressDao,
        _reviewEventDao = reviewEventDao,
        super(const DashboardInitial()) {
    on<DashboardLoadRequested>(_onLoad);
    on<DashboardRefreshRequested>(_onLoad);
  }

  final SessionDao _sessionDao;
  final WordDao _wordDao;
  final ProgressDao _progressDao;
  final ReviewEventDao _reviewEventDao;

  Future<void> _onLoad(
    DashboardEvent event,
    Emitter<DashboardState> emit,
  ) async {
    emit(const DashboardLoading());
    try {
      final now = DateTime.now();
      final todayStart =
          DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
      final weekStart = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1))
          .millisecondsSinceEpoch;
      final monthStart =
          DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
      final heatmapStart = now
          .subtract(const Duration(days: 181))
          .millisecondsSinceEpoch;

      final targetLang = (event is DashboardLoadRequested)
          ? event.targetLang
          : (event as DashboardRefreshRequested).targetLang;

      final langs = targetLang.isEmpty
          ? ['en', 'tr', 'de', 'es', 'fr', 'pt']
          : [targetLang];

      // ── Sessions yükle (paralel) ──────────────────────────────────────────
      final sessionsList = await Future.wait(
        langs.map((lang) => _sessionDao.getRecentSessions(
              targetLang: lang,
              limit: 1000,
            )),
      );
      final allSessions = [for (final list in sessionsList) ...list];

      // ── Session loop: period stats ────────────────────────────────────────
      int todayTotal = 0, todayCorrect = 0, todayTimeMs = 0;
      int weekTotal = 0, weekCorrect = 0, weekTimeMs = 0;
      int monthTotal = 0, monthCorrect = 0;

      int speakingCount = 0, listeningCount = 0, quizCount = 0, vocabCount = 0;
      int speakingCorrect = 0,
          listeningCorrect = 0,
          quizCorrect = 0,
          vocabCorrect = 0;

      final Map<String, int> todayModeMap = {};
      final Map<String, _MonthAcc> monthlyMap = {};

      for (final session in allSessions) {
        final total = session.totalCards as int;
        final correct = session.correctCards as int;
        final startedAt = session.startedAt as int;
        final endedAt = session.endedAt as int?;
        final mode = (session.mode as String?) ?? 'mcq';

        final durationMs = endedAt != null
            ? (endedAt - startedAt).clamp(0, 7200000)
            : 0;

        // ── Period accumulators ──────────────────────────────────────────
        if (startedAt >= todayStart) {
          todayTotal += total;
          todayCorrect += correct;
          todayTimeMs += durationMs;
          todayModeMap[mode] = (todayModeMap[mode] ?? 0) + total;
        }
        if (startedAt >= weekStart) {
          weekTotal += total;
          weekCorrect += correct;
          weekTimeMs += durationMs;
        }
        if (startedAt >= monthStart) {
          monthTotal += total;
          monthCorrect += correct;
        }

        // ── Mode accumulators ────────────────────────────────────────────
        switch (mode) {
          case 'speaking':
            speakingCount += total;
            speakingCorrect += correct;
            break;
          case 'listening':
            listeningCount += total;
            listeningCorrect += correct;
            break;
          case 'vocabulary':
            vocabCount += total;
            vocabCorrect += correct;
            break;
          default:
            quizCount += total;
            quizCorrect += correct;
        }

        // ── Monthly archive ──────────────────────────────────────────────
        final dt = DateTime.fromMillisecondsSinceEpoch(startedAt);
        final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
        final acc = monthlyMap[key] ?? _MonthAcc();
        acc.total += total;
        acc.correct += correct;
        monthlyMap[key] = acc;
      }

      // ── Heatmap + helpers: tümü paralel ──────────────────────────────────
      final nowMs = now.millisecondsSinceEpoch;
      final reviewActivityFut =
          _reviewEventDao.getDailyActivityForRange(heatmapStart, nowMs);
      final sessionTimeFut =
          _sessionDao.getDailySessionStats(heatmapStart, nowMs);
      final masteredFut = _getMasteredWordCount();
      final tierFut = _getTierDistribution();
      final leechFut = _getLeechCount();

      final reviewActivity = await reviewActivityFut;
      final sessionTimeByDay = await sessionTimeFut;
      final masteredCount = await masteredFut;
      final tierDist = await tierFut;
      final leechCount = await leechFut;

      final heatmapData = reviewActivity.entries
          .map((e) => DayActivity(
                date: e.key,
                questionCount: e.value['questionCount'] ?? 0,
                correctCount: e.value['correctCount'] ?? 0,
                timeMinutes: sessionTimeByDay[e.key] ?? 0,
              ))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      // ── Stats entity ──────────────────────────────────────────────────────
      final statsEntity = DashboardStatsEntity(
        todayQuestions: todayTotal,
        todaySuccessRate:
            todayTotal > 0 ? todayCorrect / todayTotal * 100 : 0.0,
        weekQuestions: weekTotal,
        weekSuccessRate: weekTotal > 0 ? weekCorrect / weekTotal * 100 : 0.0,
        monthQuestions: monthTotal,
        monthSuccessRate:
            monthTotal > 0 ? monthCorrect / monthTotal * 100 : 0.0,
        masteredWords: masteredCount,
        tierDistribution: tierDist,
        // New
        todayCorrect: todayCorrect,
        todayWrong: todayTotal - todayCorrect,
        todayTimeMinutes: (todayTimeMs / 60000).round(),
        weekCorrect: weekCorrect,
        weekWrong: weekTotal - weekCorrect,
        weekTimeMinutes: (weekTimeMs / 60000).round(),
        monthCorrect: monthCorrect,
        monthWrong: monthTotal - monthCorrect,
        todayModeDistribution: todayModeMap,
        heatmapData: heatmapData,
      );

      // ── Volume + Accuracy stats ───────────────────────────────────────────
      final maxVol = [speakingCount, listeningCount, quizCount, vocabCount]
          .fold(1, (a, b) => a > b ? a : b);

      final volumeStats = <String, double>{
        'speaking': speakingCount / maxVol * 100,
        'listening': listeningCount / maxVol * 100,
        'quiz': quizCount / maxVol * 100,
        'vocabulary': vocabCount / maxVol * 100,
      };

      final accuracyStats = <String, double>{
        'speaking':
            speakingCount > 0 ? speakingCorrect / speakingCount * 100 : 0.0,
        'listening':
            listeningCount > 0 ? listeningCorrect / listeningCount * 100 : 0.0,
        'quiz': quizCount > 0 ? quizCorrect / quizCount * 100 : 0.0,
        'vocabulary': vocabCount > 0 ? vocabCorrect / vocabCount * 100 : 0.0,
      };

      // ── Akıllı koç mesajı (F12-10) ────────────────────────────────────────
      final coachMessage = _generateCoachMessage(
        stats: statsEntity,
        accuracyStats: accuracyStats,
        leechCount: leechCount,
      );

      // ── Monthly activity ──────────────────────────────────────────────────
      final monthlyActivity = monthlyMap.entries
          .map((e) => <String, dynamic>{
                'monthYear': e.key,
                'total': e.value.total,
                'correct': e.value.correct,
              })
          .toList()
        ..sort((a, b) =>
            (b['monthYear'] as String).compareTo(a['monthYear'] as String));

      emit(DashboardLoaded(
        stats: statsEntity,
        volumeStats: volumeStats,
        accuracyStats: accuracyStats,
        coachMessage: coachMessage,
        monthlyActivity: monthlyActivity.take(6).toList(),
      ));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<int> _getMasteredWordCount() async {
    try {
      final result = await _progressDao.customSelect(
        '''SELECT COUNT(*) as cnt FROM progress
           WHERE card_state = 'review' AND repetitions >= 4''',
        readsFrom: {_progressDao.db.progress},
      ).getSingle();
      return result.data['cnt'] as int? ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<Map<String, int>> _getTierDistribution() async {
    try {
      final tierFuture = _progressDao.customSelect(
        '''SELECT
            SUM(CASE WHEN stability > 60 THEN 1 ELSE 0 END) as expert,
            SUM(CASE WHEN stability > 20 AND stability <= 60 THEN 1 ELSE 0 END) as apprentice,
            SUM(CASE WHEN stability > 5 AND stability <= 20 THEN 1 ELSE 0 END) as novice,
            SUM(CASE WHEN stability <= 5 THEN 1 ELSE 0 END) as struggling
           FROM progress''',
        readsFrom: {_progressDao.db.progress},
      ).getSingle();

      final wordCountFuture = _wordDao.customSelect(
        'SELECT COUNT(*) as cnt FROM words',
        readsFrom: {_wordDao.db.words},
      ).getSingle();

      final queryResults = await Future.wait([tierFuture, wordCountFuture]);
      final result = queryResults[0];
      final wordCountResult = queryResults[1];

      final totalWords = wordCountResult.data['cnt'] as int? ?? 0;
      final expert = result.data['expert'] as int? ?? 0;
      final apprentice = result.data['apprentice'] as int? ?? 0;
      final novice = result.data['novice'] as int? ?? 0;
      final struggling = result.data['struggling'] as int? ?? 0;
      final unlearned = (totalWords - expert - apprentice - novice - struggling)
          .clamp(0, totalWords);

      return {
        'Expert': expert,
        'Apprentice': apprentice,
        'Novice': novice,
        'Struggling': struggling,
        'Unlearned': unlearned,
      };
    } catch (_) {
      return {
        'Expert': 0,
        'Apprentice': 0,
        'Novice': 0,
        'Struggling': 0,
        'Unlearned': 0,
      };
    }
  }

  Future<int> _getLeechCount() async {
    try {
      final result = await _progressDao.customSelect(
        'SELECT COUNT(*) as cnt FROM progress WHERE is_leech = 1',
        readsFrom: {_progressDao.db.progress},
      ).getSingle();
      return result.data['cnt'] as int? ?? 0;
    } catch (_) {
      return 0;
    }
  }

  // ── F12-10: Akıllı koç mesajı (kural bazlı) ──────────────────────────────

  String _generateCoachMessage({
    required DashboardStatsEntity stats,
    required Map<String, double> accuracyStats,
    required int leechCount,
  }) {
    // İlk kullanım
    if (stats.weekQuestions == 0 && stats.todayQuestions == 0) {
      return 'İlk çalışmanı başlat! Her büyük yolculuk küçük bir adımla başlar. 🚀';
    }

    // Bugün hiç çalışılmadı ama bu hafta çalışıldı
    if (stats.todayQuestions == 0 && stats.weekQuestions > 0) {
      return 'Dün ara verdin — bugün kaldığın yerden devam et! 💪';
    }

    // Zor kelimeler var
    if (leechCount >= 3) {
      return '$leechCount zor kelimen var — bugün onlara ekstra odaklan. 🎯';
    }

    // Bugün düşük doğruluk
    if (stats.todayQuestions >= 5 && stats.todaySuccessRate < 60) {
      // Hangi mod zayıf?
      final weakMode = accuracyStats.entries
          .where((e) => e.value > 0)
          .fold<MapEntry<String, double>?>(null,
              (best, e) => best == null || e.value < best.value ? e : best);
      if (weakMode != null && (accuracyStats[weakMode.key] ?? 0) < 60) {
        final modeNames = {
          'speaking': 'konuşma',
          'listening': 'dinleme',
          'quiz': 'test',
          'vocabulary': 'kelime',
        };
        return '${modeNames[weakMode.key] ?? weakMode.key} modunda zorlanıyorsun — farklı bir mod dene. 🔄';
      }
      return 'Bugünkü doğruluk oranın %${stats.todaySuccessRate.toStringAsFixed(0)} — tempo düşür, odaklan. 🧠';
    }

    // Bu hafta yüksek doğruluk
    if (stats.weekQuestions >= 10 && stats.weekSuccessRate >= 85) {
      return 'Harika gidiyorsun! Bu hafta %${stats.weekSuccessRate.toStringAsFixed(0)} başarı oranı. 🔥';
    }

    // Bu hafta orta doğruluk
    if (stats.weekQuestions >= 5 && stats.weekSuccessRate >= 70) {
      return 'İyi gidiyorsun! Düzenli çalışmaya devam et. ${stats.weekQuestions} kart bu hafta. 📈';
    }

    // Mastered kelimeler var
    if (stats.masteredWords > 0) {
      return '${stats.masteredWords} kelimeyi tam öğrendin! Hedefi büyütme zamanı. 🏆';
    }

    // Genel teşvik
    return 'Düzenli çalışmaya devam et. Küçük adımlar büyük sonuçlar doğurur! 🌱';
  }
}

class _MonthAcc {
  int total = 0;
  int correct = 0;
}
