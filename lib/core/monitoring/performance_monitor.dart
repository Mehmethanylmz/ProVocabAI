// lib/core/monitoring/performance_monitor.dart
//
// T-22: Performans izleme yardımcısı
// Blueprint AC-11:
//   cold start   < 2s  (DevTools'ta ölçülür)
//   buildPlan()  < 500ms (Stopwatch trace)
//   FSRS calc    < 5ms   (unit test — t03'te mevcut)
//
// Kullanım:
//   final result = await PerformanceMonitor.trace('buildPlan', () => planner.buildPlan(...));
//   // Debug modda otomatik log → "⏱ buildPlan: 123ms"

import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

class PerformanceMonitor {
  PerformanceMonitor._();

  /// Bir async işlemi ölçer.
  /// Debug'da sadece print, release'de Firebase Performance trace kaydeder.
  static Future<T> trace<T>(
    String name,
    Future<T> Function() work, {
    Map<String, int>? metrics,
  }) async {
    if (kDebugMode) {
      final sw = Stopwatch()..start();
      final result = await work();
      sw.stop();
      debugPrint('⏱ $name: ${sw.elapsedMilliseconds}ms');
      return result;
    }

    // Production: Firebase Performance
    final trace = FirebasePerformance.instance.newTrace(name);
    metrics?.forEach((k, v) => trace.setMetric(k, v));
    await trace.start();
    try {
      return await work();
    } finally {
      await trace.stop();
    }
  }

  /// Sync işlemi ölçer.
  static T traceSync<T>(String name, T Function() work) {
    final sw = Stopwatch()..start();
    final result = work();
    sw.stop();
    if (kDebugMode) {
      debugPrint('⏱ $name: ${sw.elapsedMicroseconds}μs');
    }
    return result;
  }
}
