// lib/ads/rewarded_ad_controller.dart
//
// T-21: RewardedAdController — Blueprint G.4 RewardType akışı
// RewardType: doubleXP | extraCards | skipLeech

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/constants/ad_constants.dart';

/// Rewarded ad ödül türleri — Blueprint G.4
enum RewardType {
  /// Session sonucu ekranında 2x XP — StudyZoneBloc.add(RewardedAdCompleted)
  doubleXP,

  /// DailyPlanner'a +5 ek kart ekle
  extraCards,

  /// LeechWarningBanner: zor kelimeyi geç
  skipLeech,
}

typedef RewardCallback = void Function(RewardType type);

class RewardedAdController {
  RewardedAd? _ad;
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  String get _adUnitId {
    if (kDebugMode) {
      return Platform.isIOS
          ? AdConstants.iosTestRewardedId
          : AdConstants.androidTestRewardedId;
    }
    return Platform.isIOS
        ? AdConstants.iosTestRewardedId
        : AdConstants.androidTestRewardedId;
  }

  /// Rewarded ad'i önceden yükle.
  Future<void> load() async {
    await RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _isLoaded = true;
          debugPrint('[RewardedAd] Loaded');
        },
        onAdFailedToLoad: (error) {
          debugPrint('[RewardedAd] Failed to load: $error');
          _isLoaded = false;
        },
      ),
    );
  }

  /// Rewarded ad göster.
  /// [onRewarded]: kullanıcı ödülü hak ettiğinde çağrılır.
  /// [onFailed]: gösterilemezse çağrılır.
  ///
  /// RewardType: AdService.showRewarded çağrısında [rewardType] ile belirtilir.
  /// AdMob'un kendi reward amount/type alanı kullanılmaz (Blueprint G.4).
  Future<void> show({
    required RewardCallback onRewarded,
    VoidCallback? onFailed,
    RewardType rewardType = RewardType.doubleXP,
  }) async {
    if (!_isLoaded || _ad == null) {
      onFailed?.call();
      return;
    }

    _ad!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        _isLoaded = false;
        ad.dispose();
        _ad = null;
        load(); // Sonraki için önceden yükle
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[RewardedAd] Failed to show: $error');
        _isLoaded = false;
        ad.dispose();
        _ad = null;
        onFailed?.call();
        load();
      },
    );

    await _ad!.show(
      onUserEarnedReward: (_, __) {
        // AdMob'un reward value'su ignore edilir — kendi RewardType'ımızı kullanırız
        onRewarded(rewardType);
      },
    );
  }

  void dispose() {
    _ad?.dispose();
    _ad = null;
    _isLoaded = false;
  }
}
