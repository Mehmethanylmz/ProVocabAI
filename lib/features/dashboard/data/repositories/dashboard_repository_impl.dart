// lib/features/dashboard/data/repositories/dashboard_repository_impl.dart
//
// REWRITE: sqflite/ProductDatabaseManager → Drift SessionDao
// Tüm sqflite import'ları ve ham SQL kaldırıldı.
// IDashboardRepository arayüzü korundu (domain katmanı bozulmadı).

import 'package:dartz/dartz.dart';
import 'package:drift/drift.dart';

import '../../../../core/error/failures.dart';
import '../../../../database/daos/progress_dao.dart';
import '../../../../database/daos/session_dao.dart';
import '../../../../database/daos/word_dao.dart';
import '../../domain/entities/dashboard_stats_entity.dart';
import '../../domain/repositories/i_dashboard_repository.dart';

class DashboardRepositoryImpl implements IDashboardRepository {
  final SessionDao _sessionDao;
  final ProgressDao _progressDao;
  final WordDao _wordDao;

  DashboardRepositoryImpl({
    required SessionDao sessionDao,
    required ProgressDao progressDao,
    required WordDao wordDao,
  })  : _sessionDao = sessionDao,
        _progressDao = progressDao,
        _wordDao = wordDao;

  // ── IDashboardRepository ──────────────────────────────────────────────────

  @override
  Future<Either<Failure, DashboardStatsEntity>> getDashboardStats(
      String targetLang) async {
    try {
      final now = DateTime.now();
      final todayStart =
          DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
      final weekStart = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: now.weekday - 1))
          .millisecondsSinceEpoch;
      final monthStart =
          DateTime(now.year, now.month, 1).millisecondsSinceEpoch;

      final sessions = await _sessionDao.getRecentSessions(
          targetLang: targetLang, limit: 500);

      int todayTotal = 0, todayCorrect = 0;
      int weekTotal = 0, weekCorrect = 0;
      int monthTotal = 0, monthCorrect = 0;

      for (final s in sessions) {
        if (s.startedAt >= todayStart) {
          todayTotal += s.totalCards;
          todayCorrect += s.correctCards;
        }
        if (s.startedAt >= weekStart) {
          weekTotal += s.totalCards;
          weekCorrect += s.correctCards;
        }
        if (s.startedAt >= monthStart) {
          monthTotal += s.totalCards;
          monthCorrect += s.correctCards;
        }
      }

      // Mastered
      final masteredResult = await _progressDao.customSelect(
        '''SELECT COUNT(*) as cnt FROM progress 
           WHERE card_state = 'review' AND repetitions >= 4''',
        readsFrom: {_progressDao.db.progress},
      ).getSingle();
      final mastered = masteredResult.data['cnt'] as int? ?? 0;

      // Tier distribution
      final tierResult = await _progressDao.customSelect(
        '''SELECT 
            SUM(CASE WHEN stability > 60 THEN 1 ELSE 0 END) as expert,
            SUM(CASE WHEN stability > 20 AND stability <= 60 THEN 1 ELSE 0 END) as apprentice,
            SUM(CASE WHEN stability > 5 AND stability <= 20 THEN 1 ELSE 0 END) as novice,
            SUM(CASE WHEN stability <= 5 THEN 1 ELSE 0 END) as struggling
           FROM progress''',
        readsFrom: {_progressDao.db.progress},
      ).getSingle();

      final wordCntResult = await _wordDao.customSelect(
        'SELECT COUNT(*) as cnt FROM words',
        readsFrom: {_wordDao.db.words},
      ).getSingle();
      final totalWords = wordCntResult.data['cnt'] as int? ?? 0;
      final expert = tierResult.data['expert'] as int? ?? 0;
      final apprentice = tierResult.data['apprentice'] as int? ?? 0;
      final novice = tierResult.data['novice'] as int? ?? 0;
      final struggling = tierResult.data['struggling'] as int? ?? 0;
      final unlearned = (totalWords - expert - apprentice - novice - struggling)
          .clamp(0, totalWords);

      return Right(DashboardStatsEntity(
        todayQuestions: todayTotal,
        todaySuccessRate:
            todayTotal > 0 ? todayCorrect / todayTotal * 100 : 0.0,
        weekQuestions: weekTotal,
        weekSuccessRate: weekTotal > 0 ? weekCorrect / weekTotal * 100 : 0.0,
        monthQuestions: monthTotal,
        monthSuccessRate:
            monthTotal > 0 ? monthCorrect / monthTotal * 100 : 0.0,
        masteredWords: mastered,
        tierDistribution: {
          'Expert': expert,
          'Apprentice': apprentice,
          'Novice': novice,
          'Struggling': struggling,
          'Unlearned': unlearned,
        },
      ));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>>
      getMonthlyActivityStats() async {
    try {
      // Tüm dilleri al, ayda grupla
      final langs = ['en', 'tr', 'de', 'es', 'fr', 'pt'];
      final Map<String, Map<String, int>> monthly = {};

      for (final lang in langs) {
        final sessions =
            await _sessionDao.getRecentSessions(targetLang: lang, limit: 500);
        for (final s in sessions) {
          final dt = DateTime.fromMillisecondsSinceEpoch(s.startedAt);
          final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
          monthly[key] = {
            'total': (monthly[key]?['total'] ?? 0) + s.totalCards,
            'correct': (monthly[key]?['correct'] ?? 0) + s.correctCards,
          };
        }
      }

      final result = monthly.entries
          .map((e) => {
                'monthYear': e.key,
                'total': e.value['total']!,
                'correct': e.value['correct']!,
              })
          .toList()
        ..sort((a, b) =>
            (b['monthYear'] as String).compareTo(a['monthYear'] as String));

      return Right(result);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>>
      getWeeklyActivityStatsForMonth(String monthYear) async {
    // monthYear: '2025-11'
    try {
      final parts = monthYear.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final startMs = DateTime(year, month, 1).millisecondsSinceEpoch;
      final endMs = DateTime(year, month + 1, 1).millisecondsSinceEpoch;

      final Map<String, Map<String, int>> weekly = {};
      final langs = ['en', 'tr', 'de', 'es', 'fr', 'pt'];

      for (final lang in langs) {
        final sessions =
            await _sessionDao.getRecentSessions(targetLang: lang, limit: 500);
        for (final s in sessions) {
          if (s.startedAt < startMs || s.startedAt >= endMs) continue;
          final dt = DateTime.fromMillisecondsSinceEpoch(s.startedAt);
          // ISO week number
          final weekNum = _isoWeekNumber(dt);
          final key = 'W$weekNum';
          weekly[key] = {
            'total': (weekly[key]?['total'] ?? 0) + s.totalCards,
            'correct': (weekly[key]?['correct'] ?? 0) + s.correctCards,
            'weekOfYear': weekNum,
          };
        }
      }

      return Right(weekly.values.toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>>
      getDailyActivityStatsForWeek(String weekOfYear, String year) async {
    try {
      final weekNum = int.parse(weekOfYear);
      final y = int.parse(year);
      // ISO week → başlangıç günü
      final weekStart = _isoWeekStart(y, weekNum);
      final weekEnd = weekStart.add(const Duration(days: 7));
      final startMs = weekStart.millisecondsSinceEpoch;
      final endMs = weekEnd.millisecondsSinceEpoch;

      final Map<String, Map<String, int>> daily = {};
      final langs = ['en', 'tr', 'de', 'es', 'fr', 'pt'];

      for (final lang in langs) {
        final sessions =
            await _sessionDao.getRecentSessions(targetLang: lang, limit: 500);
        for (final s in sessions) {
          if (s.startedAt < startMs || s.startedAt >= endMs) continue;
          final dt = DateTime.fromMillisecondsSinceEpoch(s.startedAt);
          final key =
              '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
          daily[key] = {
            'total': (daily[key]?['total'] ?? 0) + s.totalCards,
            'correct': (daily[key]?['correct'] ?? 0) + s.correctCards,
          };
        }
      }

      return Right(daily.entries
          .map((e) => {'date': e.key, ...e.value})
          .toList()
        ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String)));
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getProgressForMonth(
      String monthYear) async {
    try {
      final parts = monthYear.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final startMs = DateTime(year, month, 1).millisecondsSinceEpoch;
      final endMs = DateTime(year, month + 1, 1).millisecondsSinceEpoch;

      int total = 0, correct = 0;
      final langs = ['en', 'tr', 'de', 'es', 'fr', 'pt'];
      for (final lang in langs) {
        final sessions =
            await _sessionDao.getRecentSessions(targetLang: lang, limit: 500);
        for (final s in sessions) {
          if (s.startedAt < startMs || s.startedAt >= endMs) continue;
          total += s.totalCards;
          correct += s.correctCards;
        }
      }

      return Right({
        'total': total,
        'correct': correct,
        'wrong': total - correct,
        'successRate': total > 0 ? correct / total * 100 : 0.0,
      });
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  int _isoWeekNumber(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final dayOfYear = d.difference(DateTime(d.year, 1, 1)).inDays + 1;
    final weekDay = d.weekday; // 1=Mon, 7=Sun
    return ((dayOfYear - weekDay + 10) / 7).floor();
  }

  DateTime _isoWeekStart(int year, int week) {
    final jan4 = DateTime(year, 1, 4);
    final startOfWeek1 = jan4.subtract(Duration(days: jan4.weekday - 1));
    return startOfWeek1.add(Duration(days: (week - 1) * 7));
  }
}
