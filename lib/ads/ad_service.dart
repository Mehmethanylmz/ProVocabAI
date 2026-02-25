// lib/ads/ad_service.dart
//
// T-21: AdService — Blueprint G.2/G.3 kural matrisi + frekans sınırları
// Bağımlılıklar: InterstitialAdController, RewardedAdController
//
// Kural matrisi (Blueprint G.2):
//   StudyZoneInSession  → interstitial ASLA
//   StudyZoneReviewing  → 15. kelime sonrası, sınırlı
//   StudyZoneCompleted  → interstitial önce, rewarded CTA
//   StudyZoneIdle       → rewarded teklif
//
// Frekans (Blueprint G.3):
//   maxInterstitialsPerDay = 3
//   maxRewardedPerDay      = 5
//   minSecondsBetweenAds   = 120

import 'package:flutter/foundation.dart';

import '../core/constants/ad_constants.dart';
import 'interstitial_ad_controller.dart';
import 'rewarded_ad_controller.dart';

class AdService {
  AdService({
    InterstitialAdController? interstitialController,
    RewardedAdController? rewardedController,
  })  : _interstitial = interstitialController ?? InterstitialAdController(),
        _rewarded = rewardedController ?? RewardedAdController();

  final InterstitialAdController _interstitial;
  final RewardedAdController _rewarded;

  // ── Günlük sayaçlar ───────────────────────────────────────────────────────

  int _todayInterstitialCount = 0;
  int _todayRewardedCount = 0;
  DateTime? _lastAdShownAt;
  String _todayDate = _currentDateStr();

  static String _currentDateStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  /// Gün değiştiyse sayaçları sıfırla.
  void _resetIfNewDay() {
    final today = _currentDateStr();
    if (today != _todayDate) {
      _todayDate = today;
      _todayInterstitialCount = 0;
      _todayRewardedCount = 0;
      debugPrint('[AdService] New day — counters reset');
    }
  }

  // ── Interstitial ──────────────────────────────────────────────────────────

  /// Interstitial hazır mı? (yüklü + sınırlar içinde)
  bool isInterstitialReady() {
    _resetIfNewDay();
    if (!_interstitial.isLoaded) return false;
    if (_todayInterstitialCount >= AdConstants.maxInterstitialsPerDay) {
      return false;
    }
    if (_lastAdShownAt != null) {
      final elapsed = DateTime.now().difference(_lastAdShownAt!).inSeconds;
      if (elapsed < AdConstants.minSecondsBetweenAds) return false;
    }
    return true;
  }

  /// Session'da kaç kart yanıtlandı → interstitial tetiklenecek mi?
  /// Blueprint: 15. kelime sonrası, InSession'da ASLA.
  /// [cardCount]: session içinde yanıtlanan toplam kart sayısı.
  /// [isInSession]: true → quiz kartı okuma anı → ASLA gösterme.
  bool shouldShowInterstitial({
    required int cardCount,
    bool isInSession = false,
  }) {
    if (isInSession) return false; // Blueprint Kural 1
    if (cardCount < AdConstants.interstitialTriggerCount) return false;
    return isInterstitialReady();
  }

  /// Interstitial göster. Sınırlar geçilmişse no-op.
  Future<bool> showInterstitialIfReady({
    VoidCallback? onDismissed,
  }) async {
    if (!isInterstitialReady()) return false;

    final shown = await _interstitial.show(onDismissed: () {
      _todayInterstitialCount++;
      _lastAdShownAt = DateTime.now();
      onDismissed?.call();
    });

    return shown;
  }

  // ── Rewarded ──────────────────────────────────────────────────────────────

  /// Rewarded hazır mı?
  bool isRewardedReady() {
    _resetIfNewDay();
    if (!_rewarded.isLoaded) return false;
    if (_todayRewardedCount >= AdConstants.maxRewardedPerDay) return false;
    return true;
  }

  /// Rewarded göster.
  /// [onRewarded]: ödül verildiğinde çağrılır.
  /// [onFailed]: gösterilemezse çağrılır.
  Future<void> showRewarded({
    required RewardCallback onRewarded,
    VoidCallback? onFailed,
  }) async {
    if (!isRewardedReady()) {
      onFailed?.call();
      return;
    }

    await _rewarded.show(
      onRewarded: (type) {
        _todayRewardedCount++;
        _lastAdShownAt = DateTime.now();
        onRewarded(type);
      },
      onFailed: onFailed,
    );
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// DI init'te çağrılır — interstitial + rewarded önceden yükle.
  Future<void> preload() async {
    await Future.wait([
      _interstitial.load(),
      _rewarded.load(),
    ]);
  }

  void dispose() {
    _interstitial.dispose();
    _rewarded.dispose();
  }

  // ── Test yardımcıları ─────────────────────────────────────────────────────

  @visibleForTesting
  int get todayInterstitialCount => _todayInterstitialCount;

  @visibleForTesting
  int get todayRewardedCount => _todayRewardedCount;

  @visibleForTesting
  void setTodayInterstitialCount(int count) => _todayInterstitialCount = count;

  @visibleForTesting
  void setTodayRewardedCount(int count) => _todayRewardedCount = count;

  @visibleForTesting
  void setLastAdShownAt(DateTime dt) => _lastAdShownAt = dt;
}
