// test/ads/ad_service_test.dart
//
// T-21 Acceptance Criteria:
//   AC: isInSession=true → shouldShowInterstitial=false (Blueprint Kural 1)
//   AC: cardCount<15 → shouldShowInterstitial=false
//   AC: cardCount>=15, isInSession=false, sınırlar OK → isInterstitialReady'ye bağlı
//   AC: günlük limit 3 → 4. interstitial skip (isInterstitialReady=false)
//   AC: minSecondsBetweenAds=120 → 60s sonra ready=false
//   AC: isRewardedReady → günlük limit 5 → 6. rewarded skip
//   AC: showRewarded isLoaded=false → onFailed çağrıldı
//
// google_mobile_ads gerçek platform gerektirdiğinden AdController'lar
// stub ile replace edilir.
//
// Çalıştır: flutter test test/ads/ad_service_test.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pratikapp/ads/ad_service.dart';
import 'package:pratikapp/ads/interstitial_ad_controller.dart';
import 'package:pratikapp/ads/rewarded_ad_controller.dart';
import 'package:pratikapp/core/constants/ad_constants.dart';

// ── Stub controllers (google_mobile_ads'e gerek yok) ─────────────────────────

class _StubInterstitial extends InterstitialAdController {
  bool _loaded;
  bool showCalled = false;

  _StubInterstitial({bool loaded = true}) : _loaded = loaded;

  @override
  bool get isLoaded => _loaded;

  @override
  Future<void> load() async => _loaded = true;

  @override
  Future<bool> show({VoidCallback? onDismissed}) async {
    if (!_loaded) return false;
    showCalled = true;
    onDismissed?.call();
    return true;
  }

  @override
  void dispose() {}
}

class _StubRewarded extends RewardedAdController {
  bool _loaded;
  bool failOnShow;

  _StubRewarded({bool loaded = true, this.failOnShow = false})
      : _loaded = loaded;

  @override
  bool get isLoaded => _loaded;

  @override
  Future<void> load() async => _loaded = true;

  @override
  Future<void> show({
    required RewardCallback onRewarded,
    VoidCallback? onFailed,
    RewardType rewardType = RewardType.doubleXP,
  }) async {
    if (!_loaded || failOnShow) {
      onFailed?.call();
      return;
    }
    onRewarded(rewardType);
  }

  @override
  void dispose() {}
}

// ── Helper ────────────────────────────────────────────────────────────────────

AdService _makeService({
  bool interstitialLoaded = true,
  bool rewardedLoaded = true,
  bool rewardedFails = false,
}) =>
    AdService(
      interstitialController: _StubInterstitial(loaded: interstitialLoaded),
      rewardedController:
          _StubRewarded(loaded: rewardedLoaded, failOnShow: rewardedFails),
    );

void main() {
  // ── shouldShowInterstitial ────────────────────────────────────────────────

  group('shouldShowInterstitial', () {
    test(
        'AC: isInSession=true → false (Blueprint Kural 1 — quiz sırasında ASLA)',
        () {
      final service = _makeService();
      expect(
        service.shouldShowInterstitial(
          cardCount: 20, // 15'i geçmiş
          isInSession: true,
        ),
        isFalse,
      );
    });

    test('AC: cardCount < 15 → false', () {
      final service = _makeService();
      expect(
        service.shouldShowInterstitial(cardCount: 10),
        isFalse,
      );
    });

    test('AC: cardCount=14 (tam sınırda değil) → false', () {
      final service = _makeService();
      expect(
        service.shouldShowInterstitial(
            cardCount: AdConstants.interstitialTriggerCount - 1),
        isFalse,
      );
    });

    test('AC: cardCount>=15, isInSession=false, yüklü → true', () {
      final service = _makeService();
      expect(
        service.shouldShowInterstitial(cardCount: 15),
        isTrue,
      );
    });

    test('AC: interstitial yüklü değilse → false', () {
      final service = _makeService(interstitialLoaded: false);
      expect(
        service.shouldShowInterstitial(cardCount: 15),
        isFalse,
      );
    });
  });

  // ── Günlük limit ─────────────────────────────────────────────────────────

  group('Interstitial günlük limit', () {
    test('AC: limit=3 → 3 gösterimden sonra isInterstitialReady=false', () {
      final service = _makeService();
      service
          .setTodayInterstitialCount(AdConstants.maxInterstitialsPerDay); // 3
      expect(service.isInterstitialReady(), isFalse);
    });

    test('AC: limit=2 → 3. öncesi ready=true', () {
      final service = _makeService();
      service.setTodayInterstitialCount(2);
      expect(service.isInterstitialReady(), isTrue);
    });

    test('AC: showInterstitialIfReady → sayaç artar', () async {
      final service = _makeService();
      await service.showInterstitialIfReady();
      expect(service.todayInterstitialCount, 1);
    });
  });

  // ── minSecondsBetweenAds ──────────────────────────────────────────────────

  group('minSecondsBetweenAds', () {
    test('AC: son reklamdan 60s geçmiş → ready=false', () {
      final service = _makeService();
      service.setLastAdShownAt(
        DateTime.now().subtract(
          const Duration(seconds: 60), // 120s gerekli
        ),
      );
      expect(service.isInterstitialReady(), isFalse);
    });

    test('AC: son reklamdan 121s geçmiş → ready=true', () {
      final service = _makeService();
      service.setLastAdShownAt(
        DateTime.now().subtract(
          const Duration(seconds: 121),
        ),
      );
      expect(service.isInterstitialReady(), isTrue);
    });
  });

  // ── Rewarded günlük limit ─────────────────────────────────────────────────

  group('Rewarded günlük limit', () {
    test('AC: limit=5 → 6. rewarded skip (isRewardedReady=false)', () {
      final service = _makeService();
      service.setTodayRewardedCount(AdConstants.maxRewardedPerDay); // 5
      expect(service.isRewardedReady(), isFalse);
    });

    test('AC: showRewarded → sayaç artar', () async {
      final service = _makeService();
      await service.showRewarded(onRewarded: (_) {});
      expect(service.todayRewardedCount, 1);
    });
  });

  // ── showRewarded hata senaryosu ───────────────────────────────────────────

  group('showRewarded', () {
    test('AC: rewarded yüklü değil → onFailed çağrıldı', () async {
      final service = _makeService(rewardedLoaded: false);
      bool failedCalled = false;
      await service.showRewarded(
        onRewarded: (_) {},
        onFailed: () => failedCalled = true,
      );
      expect(failedCalled, isTrue);
    });

    test('AC: rewarded yüklü → onRewarded RewardType.doubleXP ile çağrıldı',
        () async {
      final service = _makeService();
      RewardType? received;
      await service.showRewarded(
        onRewarded: (type) => received = type,
      );
      expect(received, RewardType.doubleXP);
    });

    test('AC: günlük limit aşıldı → onFailed çağrıldı', () async {
      final service = _makeService();
      service.setTodayRewardedCount(AdConstants.maxRewardedPerDay);
      bool failedCalled = false;
      await service.showRewarded(
        onRewarded: (_) {},
        onFailed: () => failedCalled = true,
      );
      expect(failedCalled, isTrue);
    });
  });

  // ── AdConstants ───────────────────────────────────────────────────────────

  group('AdConstants', () {
    test('interstitialTriggerCount = 15', () {
      expect(AdConstants.interstitialTriggerCount, 15);
    });
    test('maxInterstitialsPerDay = 3', () {
      expect(AdConstants.maxInterstitialsPerDay, 3);
    });
    test('maxRewardedPerDay = 5', () {
      expect(AdConstants.maxRewardedPerDay, 5);
    });
    test('minSecondsBetweenAds = 120', () {
      expect(AdConstants.minSecondsBetweenAds, 120);
    });
  });
}
