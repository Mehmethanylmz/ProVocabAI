// test/stats/profile_percentage_test.dart
//
// F16-04: Profile percentage calculation correctness
//
// Tests the todaySuccessRate display formula:
//   (stats.todaySuccessRate * 100).toStringAsFixed(0)
// where todaySuccessRate is a 0.0–1.0 value.
//
// Also tests DayActivity.successRate (0–100 range) for heatmap/calendar.

import 'package:flutter_test/flutter_test.dart';

import 'package:savgolearnvocabulary/features/dashboard/domain/entities/dashboard_stats_entity.dart';

/// Simulates how DashboardBloc computes todaySuccessRate.
double computeTodaySuccessRate(int correct, int total) {
  if (total == 0) return 0.0;
  return correct / total;
}

/// Simulates the profile view display formula (F13-06).
String formatPercentage(double successRate) {
  return (successRate * 100).toStringAsFixed(0);
}

void main() {
  group('Profile percentage display (F13-06)', () {
    test('80% — 8 correct out of 10', () {
      final rate = computeTodaySuccessRate(8, 10);
      expect(formatPercentage(rate), equals('80'));
    });

    test('100% — 10 correct out of 10', () {
      final rate = computeTodaySuccessRate(10, 10);
      expect(formatPercentage(rate), equals('100'));
    });

    test('0% — 0 correct out of 10', () {
      final rate = computeTodaySuccessRate(0, 10);
      expect(formatPercentage(rate), equals('0'));
    });

    test('0% — 0 correct out of 0 (no NaN / divide-by-zero)', () {
      final rate = computeTodaySuccessRate(0, 0);
      expect(rate, isNot(isNaN),
          reason: 'Must handle division by zero gracefully');
      expect(formatPercentage(rate), equals('0'));
    });

    test('50% — 5 correct out of 10', () {
      final rate = computeTodaySuccessRate(5, 10);
      expect(formatPercentage(rate), equals('50'));
    });

    test('33% — 1 correct out of 3 (rounds down)', () {
      final rate = computeTodaySuccessRate(1, 3);
      expect(formatPercentage(rate), equals('33'));
    });

    test('67% — 2 correct out of 3 (rounds down)', () {
      final rate = computeTodaySuccessRate(2, 3);
      expect(formatPercentage(rate), equals('67'));
    });

    test('90% — 9 correct out of 10', () {
      final rate = computeTodaySuccessRate(9, 10);
      expect(formatPercentage(rate), equals('90'));
    });

    test('result is string without decimal point', () {
      final rate = computeTodaySuccessRate(7, 10);
      final display = formatPercentage(rate);
      expect(display.contains('.'), isFalse,
          reason: 'toStringAsFixed(0) should not have decimal');
    });
  });

  group('DashboardStatsEntity.todaySuccessRate range', () {
    test('todaySuccessRate defaults to 0.0', () {
      const entity = DashboardStatsEntity();
      expect(entity.todaySuccessRate, equals(0.0));
    });

    test('todaySuccessRate of 1.0 displays as 100%', () {
      const entity = DashboardStatsEntity(todaySuccessRate: 1.0);
      expect(formatPercentage(entity.todaySuccessRate), equals('100'));
    });

    test('todaySuccessRate of 0.5 displays as 50%', () {
      const entity = DashboardStatsEntity(todaySuccessRate: 0.5);
      expect(formatPercentage(entity.todaySuccessRate), equals('50'));
    });
  });

  group('DayActivity.successRate (heatmap/calendar)', () {
    test('successRate is 0 when questionCount is 0', () {
      const day = DayActivity(date: '2026-01-01', questionCount: 0);
      expect(day.successRate, equals(0.0));
    });

    test('successRate = 100.0 when all correct', () {
      const day = DayActivity(
        date: '2026-01-02',
        questionCount: 10,
        correctCount: 10,
      );
      expect(day.successRate, closeTo(100.0, 0.001));
    });

    test('successRate = 70.0 for 7/10', () {
      const day = DayActivity(
        date: '2026-01-03',
        questionCount: 10,
        correctCount: 7,
      );
      expect(day.successRate, closeTo(70.0, 0.001));
    });

    test('wrongCount = questionCount - correctCount', () {
      const day = DayActivity(
        date: '2026-01-04',
        questionCount: 10,
        correctCount: 7,
      );
      expect(day.wrongCount, equals(3));
    });

    test('wrongCount is 0 when all correct', () {
      const day = DayActivity(
        date: '2026-01-05',
        questionCount: 5,
        correctCount: 5,
      );
      expect(day.wrongCount, equals(0));
    });
  });

  group('Profile percentage edge cases', () {
    test('very small rate: 1 correct out of 100 → 1%', () {
      final rate = computeTodaySuccessRate(1, 100);
      expect(formatPercentage(rate), equals('1'));
    });

    test('99 correct out of 100 → 99%', () {
      final rate = computeTodaySuccessRate(99, 100);
      expect(formatPercentage(rate), equals('99'));
    });

    test('rate is bounded 0.0–1.0', () {
      final rate = computeTodaySuccessRate(8, 10);
      expect(rate, greaterThanOrEqualTo(0.0));
      expect(rate, lessThanOrEqualTo(1.0));
    });
  });
}
