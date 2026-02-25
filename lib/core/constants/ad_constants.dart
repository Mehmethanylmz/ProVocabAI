// lib/core/constants/ad_constants.dart
//
// T-21: AdMob sabitler — Blueprint G.3 frekans kuralları
// Production Ad Unit ID'leri → Firebase Remote Config'den alınır.
// Şimdilik test ID'leri ile başla.

class AdConstants {
  AdConstants._();

  // ── Frekans kuralları (Blueprint G.3) ────────────────────────────────────

  /// Session başına interstitial tetiklenecek kart sayısı.
  static const int interstitialTriggerCount = 15;

  /// Günlük maksimum interstitial gösterimi.
  static const int maxInterstitialsPerDay = 3;

  /// Günlük maksimum rewarded gösterimi.
  static const int maxRewardedPerDay = 5;

  /// İki reklam arası minimum süre (saniye).
  static const int minSecondsBetweenAds = 120;

  // ── Test Ad Unit ID'leri (Google resmi test ID'leri) ─────────────────────
  // Production'da Firebase Remote Config'den override edilir.

  /// Android test interstitial.
  static const String androidTestInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';

  /// Android test rewarded.
  static const String androidTestRewardedId =
      'ca-app-pub-3940256099942544/5224354917';

  /// iOS test interstitial.
  static const String iosTestInterstitialId =
      'ca-app-pub-3940256099942544/4411468910';

  /// iOS test rewarded.
  static const String iosTestRewardedId =
      'ca-app-pub-3940256099942544/1712485313';

  // ── Günlük XP cap ─────────────────────────────────────────────────────────
  /// Rewarded ad ile kazanılabilecek maksimum bonus XP (günlük).
  static const int maxRewardedBonusXPPerDay = 500;
}
