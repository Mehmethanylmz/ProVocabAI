class SpacedRepetition {
  static const Map<int, Duration> _levelDurations = {
    1: Duration(days: 1),
    2: Duration(days: 3),
    3: Duration(days: 7),
    4: Duration(days: 14),
    5: Duration(days: 30),
    6: Duration(days: 60),
    7: Duration(days: 120),
    8: Duration(days: 180),
  };

  static const int maxLevel = 8;
  static const int leechThreshold = 3;
  static const int leechLevel = -1;

  static DateTime getNextReviewDate(int masteryLevel) {
    final duration = _levelDurations[masteryLevel];
    if (duration != null) {
      return DateTime.now().add(duration);
    }
    return DateTime.now().add(Duration(days: 365));
  }
}
