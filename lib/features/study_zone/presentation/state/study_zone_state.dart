// lib/features/study_zone/presentation/state/study_zone_state.dart
//
// Blueprint T-09: StudyZone BLoC States (8 sınıf).
// Blueprint E.1 State Machine Tasarımı'na birebir uyumlu.

import 'package:equatable/equatable.dart';

import '../../../../srs/fsrs_state.dart';
import '../../../../srs/plan_models.dart';
import '../../../../srs/mode_selector.dart';

// ── Base ─────────────────────────────────────────────────────────────────────

abstract class StudyZoneState extends Equatable {
  const StudyZoneState();

  @override
  List<Object?> get props => [];
}

// ── 1. StudyZoneIdle ──────────────────────────────────────────────────────────
/// Başlangıç durumu / session tamamlandı / aborted.
/// LoadPlanRequested → StudyZonePlanning
class StudyZoneIdle extends StudyZoneState {
  /// null → henüz plan yüklenmedi / session aborted.
  final EmptyReason? emptyReason;

  const StudyZoneIdle({this.emptyReason});

  @override
  List<Object?> get props => [emptyReason];
}

// ── 2. StudyZonePlanning ──────────────────────────────────────────────────────
/// DailyPlanner.buildPlan() çalışıyor — loading indicator göster.
class StudyZonePlanning extends StudyZoneState {
  const StudyZonePlanning();
}

// ── 3. StudyZoneReady ─────────────────────────────────────────────────────────
/// Plan hazır — "Başla" butonu göster.
/// SessionStarted → StudyZoneInSession
class StudyZoneReady extends StudyZoneState {
  final DailyPlan plan;

  const StudyZoneReady({required this.plan});

  @override
  List<Object?> get props => [plan];
}

// ── 4. StudyZoneInSession ─────────────────────────────────────────────────────
/// Aktif çalışma — mevcut kart gösterilmekte.
/// AnswerSubmitted → StudyZoneReviewing
/// SessionAborted → StudyZoneIdle
class StudyZoneInSession extends StudyZoneState {
  final PlanCard currentCard;
  final String sessionId; // UUID — SessionDao FK
  final int sessionStreak; // Arka arkaya doğru sayısı
  final int sessionCardCount; // Bu session'da görülen kart sayısı
  final bool hasRewardedAdBonus; // doubleXP aktif mi?
  final StudyMode currentMode; // ModeSelector çıktısı
  final DateTime timerStart; // Kart gösterim zamanı (responseMs için)

  /// Kalan kart index'i — plan.cards[_cardIndex]
  final int cardIndex;

  /// Toplam plan büyüklüğü (progress bar için)
  final int totalCards;

  /// Tamamlanan kart sayısı (progress bar: completedCount / totalCards)
  final int completedCount;

  /// Hedef dil kodu — ListeningScreen / SpeakingScreen için
  final String targetLang;

  /// Mevcut kartın hedef dildeki kelimesi (ListeningScreen cevap kontrolü)
  final String? currentWordText;

  /// Mevcut kartın anlamı / çevirisi (SpeakingScreen'de gösterilir)
  final String? currentWordMeaning;

  const StudyZoneInSession({
    required this.currentCard,
    required this.sessionId,
    required this.sessionStreak,
    required this.sessionCardCount,
    required this.hasRewardedAdBonus,
    required this.currentMode,
    required this.timerStart,
    required this.cardIndex,
    required this.totalCards,
    this.completedCount = 0,
    this.targetLang = 'en',
    this.currentWordText,
    this.currentWordMeaning,
  });

  @override
  List<Object?> get props => [
        currentCard,
        sessionId,
        sessionStreak,
        sessionCardCount,
        hasRewardedAdBonus,
        currentMode,
        timerStart,
        cardIndex,
        totalCards,
        completedCount,
        targetLang,
        currentWordText,
        currentWordMeaning,
      ];

  StudyZoneInSession copyWith({
    PlanCard? currentCard,
    String? sessionId,
    int? sessionStreak,
    int? sessionCardCount,
    int? completedCount,
    String? targetLang,
    String? currentWordText,
    String? currentWordMeaning,
    bool? hasRewardedAdBonus,
    StudyMode? currentMode,
    DateTime? timerStart,
    int? cardIndex,
    int? totalCards,
  }) =>
      StudyZoneInSession(
        currentCard: currentCard ?? this.currentCard,
        sessionId: sessionId ?? this.sessionId,
        sessionStreak: sessionStreak ?? this.sessionStreak,
        sessionCardCount: sessionCardCount ?? this.sessionCardCount,
        hasRewardedAdBonus: hasRewardedAdBonus ?? this.hasRewardedAdBonus,
        currentMode: currentMode ?? this.currentMode,
        timerStart: timerStart ?? this.timerStart,
        cardIndex: cardIndex ?? this.cardIndex,
        totalCards: totalCards ?? this.totalCards,
        completedCount: completedCount ?? this.completedCount,
        targetLang: targetLang ?? this.targetLang,
        currentWordText: currentWordText ?? this.currentWordText,
        currentWordMeaning: currentWordMeaning ?? this.currentWordMeaning,
      );
}

// ── 5. StudyZoneReviewing ─────────────────────────────────────────────────────
/// Cevap verildi — FSRS güncellendi, XP hesaplandı, feedback göster.
/// NextCardRequested → InSession | Completed
class StudyZoneReviewing extends StudyZoneState {
  // InSession alanları (snapshot)
  final PlanCard currentCard;
  final String sessionId;
  final int sessionStreak;
  final int sessionCardCount;
  final bool hasRewardedAdBonus;
  final StudyMode currentMode;
  final int cardIndex;
  final int totalCards;

  // Reviewing'e özgü
  final ReviewRating lastRating;
  final FSRSState updatedFSRS;
  final int xpJustEarned;

  const StudyZoneReviewing({
    required this.currentCard,
    required this.sessionId,
    required this.sessionStreak,
    required this.sessionCardCount,
    required this.hasRewardedAdBonus,
    required this.currentMode,
    required this.cardIndex,
    required this.totalCards,
    required this.lastRating,
    required this.updatedFSRS,
    required this.xpJustEarned,
  });

  @override
  List<Object?> get props => [
        currentCard,
        sessionId,
        sessionStreak,
        sessionCardCount,
        hasRewardedAdBonus,
        currentMode,
        cardIndex,
        totalCards,
        lastRating,
        updatedFSRS,
        xpJustEarned,
      ];

  /// InSession snapshot'ını InSession'a geri çevir (NextCardRequested için).
  StudyZoneInSession toInSession({
    required PlanCard nextCard,
    required int nextCardIndex,
    required StudyMode nextMode,
    required int newStreak,
    required DateTime timerStart,
  }) =>
      StudyZoneInSession(
        currentCard: nextCard,
        sessionId: sessionId,
        sessionStreak: newStreak,
        sessionCardCount: sessionCardCount + 1,
        hasRewardedAdBonus: false, // bonus tek seferlik
        currentMode: nextMode,
        timerStart: timerStart,
        cardIndex: nextCardIndex,
        totalCards: totalCards,
      );
}

// ── 6. StudyZonePaused ────────────────────────────────────────────────────────
/// Uygulama arka plana geçti — timer durduruldu.
/// AppLifecycleChanged(resumed) → InSession (snapshot restore)
class StudyZonePaused extends StudyZoneState {
  /// Pause anındaki tam InSession snapshot'ı.
  final StudyZoneInSession snapshot;

  const StudyZonePaused({required this.snapshot});

  @override
  List<Object?> get props => [snapshot];
}

// ── 7. StudyZoneCompleted ─────────────────────────────────────────────────────
/// Tüm plan kartları bitti — session özeti göster.
/// Idle (kullanıcı ana sayfaya döner)
class StudyZoneCompleted extends StudyZoneState {
  final int totalCards;
  final int correctCards; // rating != again sayısı
  final int totalTimeMs; // session başından itibaren
  final int xpEarned; // toplam
  final List<int> wrongWordIds; // again alanlar (review için)
  final String sessionId;

  const StudyZoneCompleted({
    required this.totalCards,
    required this.correctCards,
    required this.totalTimeMs,
    required this.xpEarned,
    required this.wrongWordIds,
    required this.sessionId,
  });

  double get accuracy => totalCards == 0 ? 0.0 : correctCards / totalCards;

  @override
  List<Object?> get props => [
        totalCards,
        correctCards,
        totalTimeMs,
        xpEarned,
        wrongWordIds,
        sessionId,
      ];
}

// ── 8. StudyZoneError ─────────────────────────────────────────────────────────
/// Plan yüklenemedi veya kritik hata.
/// LoadPlanRequested (retry) → Planning
class StudyZoneError extends StudyZoneState {
  final String message;

  const StudyZoneError({required this.message});

  @override
  List<Object?> get props => [message];
}
