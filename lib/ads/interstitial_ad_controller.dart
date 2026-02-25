// lib/ads/interstitial_ad_controller.dart
//
// T-21: InterstitialAdController — yükleme, gösterme, dispose
// Platform bazında ad unit ID seçimi (Android/iOS).

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/constants/ad_constants.dart';

class InterstitialAdController {
  InterstitialAd? _ad;
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  String get _adUnitId {
    if (kDebugMode) {
      return Platform.isIOS
          ? AdConstants.iosTestInterstitialId
          : AdConstants.androidTestInterstitialId;
    }
    // Production: Firebase Remote Config'den gelir
    // Şimdilik test ID — deploy öncesinde replace edilmeli
    return Platform.isIOS
        ? AdConstants.iosTestInterstitialId
        : AdConstants.androidTestInterstitialId;
  }

  /// Interstitial'ı önceden yükle.
  Future<void> load() async {
    await InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _isLoaded = true;
          debugPrint('[InterstitialAd] Loaded');

          _ad!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              _isLoaded = false;
              ad.dispose();
              _ad = null;
              // Sonraki session için önceden yükle
              load();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('[InterstitialAd] Failed to show: $error');
              _isLoaded = false;
              ad.dispose();
              _ad = null;
              load();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('[InterstitialAd] Failed to load: $error');
          _isLoaded = false;
        },
      ),
    );
  }

  /// Interstitial göster.
  /// [onDismissed]: reklam kapandığında çağrılır (sayaç artırımı için).
  /// Döner: true → gösterildi, false → gösterilemedi.
  Future<bool> show({VoidCallback? onDismissed}) async {
    if (!_isLoaded || _ad == null) return false;

    // onDismissed callback'i fullScreenContentCallback'e inject et
    final existingCallback = _ad!.fullScreenContentCallback;
    _ad!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        onDismissed?.call();
        existingCallback?.onAdDismissedFullScreenContent?.call(ad);
      },
      onAdFailedToShowFullScreenContent:
          existingCallback?.onAdFailedToShowFullScreenContent,
      onAdShowedFullScreenContent:
          existingCallback?.onAdShowedFullScreenContent,
    );

    await _ad!.show();
    return true;
  }

  void dispose() {
    _ad?.dispose();
    _ad = null;
    _isLoaded = false;
  }
}
