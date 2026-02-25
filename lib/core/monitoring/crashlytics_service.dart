// lib/core/monitoring/crashlytics_service.dart
//
// T-22: Crashlytics wrapper
// main_production.dart'ta wiring yapıldı (T-22 için FlutterError.onError zaten eklendi).
// Bu servis: BLoC hatalarını + custom event'leri kaydeder.
//
// Blueprint AC-12: release build'de 3 gün beta → sıfır crash.

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashlyticsService {
  CrashlyticsService._();

  static final _instance = FirebaseCrashlytics.instance;

  /// Kullanıcı UID'sini Crashlytics'e bağla (auth sonrası çağrılır).
  static Future<void> setUserId(String uid) async {
    if (!kDebugMode) {
      await _instance.setUserIdentifier(uid);
    }
  }

  /// Non-fatal hata kaydet (BLoC onError'dan çağrılır).
  static Future<void> recordError(
    Object error,
    StackTrace stack, {
    String? reason,
    bool fatal = false,
  }) async {
    if (kDebugMode) {
      debugPrint('🔴 [Crashlytics] $reason: $error\n$stack');
      return;
    }
    await _instance.recordError(error, stack, reason: reason, fatal: fatal);
  }

  /// Custom log mesajı (breadcrumb).
  static void log(String message) {
    if (kDebugMode) {
      debugPrint('📋 [Crashlytics] $message');
      return;
    }
    _instance.log(message);
  }

  /// Test crash — Firebase Console'da görünüp görünmediğini doğrula.
  /// Sadece debug build'de ve açıkça çağrıldığında çalışır.
  @visibleForTesting
  static Future<void> sendTestCrash() async {
    _instance.crash();
  }
}
