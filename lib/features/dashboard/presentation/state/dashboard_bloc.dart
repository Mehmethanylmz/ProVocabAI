// lib/features/dashboard/presentation/state/dashboard_bloc.dart
//
// REWRITE v2:
//   - getAllSessions() → getRecentSessions(targetLang: ..., limit: 500)
//     (SessionDao'da getAllSessions() yok, targetLang zorunlu)
//   - int sayaçlar: .toInt() kullanıldı
//   - getMasteredWordCount / getTierDistribution → inline ProgressDao sorgusu
//   - DashboardStats → DashboardStatsEntity ile uyumlu

import 'package:drift/drift.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../database/daos/progress_dao.dart';
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
  /// Hangi hedef dile ait istatistikler yüklensin?
  /// Boş bırakılırsa tüm diller birleştirilir (targetLang='').
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
  })  : _sessionDao = sessionDao,
        _wordDao = wordDao,
        _progressDao = progressDao,
        super(const DashboardInitial()) {
    on<DashboardLoadRequested>(_onLoad);
    on<DashboardRefreshRequested>(_onLoad);
  }

  final SessionDao _sessionDao;
  final WordDao _wordDao;
  final ProgressDao _progressDao;

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

      // targetLang — event'ten al, boşsa tüm diller için birden fazla fetch
      // Şimdilik 'en' default (ayarlardan almak için DI'ya SettingsRepo da eklenebilir)
      final targetLang = (event is DashboardLoadRequested)
          ? event.targetLang
          : (event as DashboardRefreshRequested).targetLang;

      // Geniş pencere: son 500 session, tüm diller (targetLang boşsa her dil için ayrı)
      // SessionDao'da targetLang zorunlu → ya 'en' ya da ayarlardan gelen değer
      // Workaround: tüm bilinen diller için ayrı ayrı çek, birleştir
      final langs = targetLang.isEmpty
          ? ['en', 'tr', 'de', 'es', 'fr', 'pt']
          : [targetLang];

      final allSessions = <dynamic>[];
      for (final lang in langs) {
        final s = await _sessionDao.getRecentSessions(
          targetLang: lang,
          limit: 500,
        );
        allSessions.addAll(s);
      }

      int todayTotal = 0, todayCorrect = 0;
      int weekTotal = 0, weekCorrect = 0;
      int monthTotal = 0, monthCorrect = 0;

      // Mode sayaçları
      int speakingCount = 0, listeningCount = 0, quizCount = 0, vocabCount = 0;
      int speakingCorrect = 0,
          listeningCorrect = 0,
          quizCorrect = 0,
          vocabCorrect = 0;

      final Map<String, _MonthAcc> monthlyMap = {};

      for (final session in allSessions) {
        final total = session.totalCards as int;
        final correct = session.correctCards as int;
        final startedAt = session.startedAt as int;
        final mode = (session.mode as String?) ?? 'mcq';

        if (startedAt >= todayStart) {
          todayTotal += total;
          todayCorrect += correct;
        }
        if (startedAt >= weekStart) {
          weekTotal += total;
          weekCorrect += correct;
        }
        if (startedAt >= monthStart) {
          monthTotal += total;
          monthCorrect += correct;
        }

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

        final dt = DateTime.fromMillisecondsSinceEpoch(startedAt);
        final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
        final acc = monthlyMap[key] ?? _MonthAcc();
        acc.total += total;
        acc.correct += correct;
        monthlyMap[key] = acc;
      }

      // Mastered words — ProgressDao customSelect
      final masteredCount = await _getMasteredWordCount();

      // Tier distribution — ProgressDao customSelect
      final tierDist = await _getTierDistribution();

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
      );

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

      final coachMessage = _generateCoachMessage(statsEntity, accuracyStats);

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

  /// Mastered = cardState 'review' + repetitions >= 4
  /// ProgressDao'da özel metot yok → customSelect
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

  /// Tier distribution — stability tabanlı basit kümeleme
  Future<Map<String, int>> _getTierDistribution() async {
    try {
      // stability > 60 → Expert, 20-60 → Apprentice, 5-20 → Novice,
      // 0-5 → Struggling. Hiç kayıt → Unlearned (words count - progress count)
      final result = await _progressDao.customSelect(
        '''SELECT 
            SUM(CASE WHEN stability > 60 THEN 1 ELSE 0 END) as expert,
            SUM(CASE WHEN stability > 20 AND stability <= 60 THEN 1 ELSE 0 END) as apprentice,
            SUM(CASE WHEN stability > 5 AND stability <= 20 THEN 1 ELSE 0 END) as novice,
            SUM(CASE WHEN stability <= 5 THEN 1 ELSE 0 END) as struggling
           FROM progress''',
        readsFrom: {_progressDao.db.progress},
      ).getSingle();

      final wordCountResult = await _wordDao.customSelect(
        'SELECT COUNT(*) as cnt FROM words',
        readsFrom: {_wordDao.db.words},
      ).getSingle();

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

  String _generateCoachMessage(
      DashboardStatsEntity stats, Map<String, double> accuracy) {
    if (stats.todayQuestions == 0 && stats.weekQuestions == 0) {
      return 'İlk çalışmanı başlat! Her büyük yolculuk küçük bir adımla başlar.';
    }
    final weakMode =
        accuracy.entries.reduce((a, b) => a.value < b.value ? a : b).key;
    final modeNames = {
      'speaking': 'konuşma',
      'listening': 'dinleme',
      'quiz': 'test',
      'vocabulary': 'kelime',
    };
    if ((accuracy[weakMode] ?? 0) < 60 && stats.weekQuestions > 0) {
      return '${modeNames[weakMode] ?? weakMode} modunda biraz daha pratik yapmak faydalı!';
    }
    if (stats.weekSuccessRate > 80) {
      return 'Harika gidiyorsun! Bu hafta başarı oranın %${stats.weekSuccessRate.toStringAsFixed(0)}.';
    }
    return 'Düzenli çalışmaya devam et. Küçük adımlar büyük sonuçlar doğurur!';
  }
}

class _MonthAcc {
  int total = 0;
  int correct = 0;
}
