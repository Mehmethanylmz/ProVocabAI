// lib/core/utils/levenshtein.dart
//
// T-23: Levenshtein fuzzy match — Speaking ekran için
// Blueprint: score >= 0.75 → wasCorrect = true
//
// Kullanım:
//   final score = Levenshtein.similarity('hello', 'helo'); // 0.80
//   final correct = Levenshtein.isCorrect('apple', 'appl'); // true (>= 0.75)

class Levenshtein {
  Levenshtein._();

  /// İki string arasındaki düzenleme mesafesini hesapla.
  static int distance(String a, String b) {
    final s1 = a.toLowerCase().trim();
    final s2 = b.toLowerCase().trim();

    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    // dp[i][j] = s1[0..i] ile s2[0..j] arası mesafe
    final rows = s1.length + 1;
    final cols = s2.length + 1;
    final dp = List.generate(rows, (i) => List<int>.filled(cols, 0));

    for (var i = 0; i < rows; i++) {
      dp[i][0] = i;
    }
    for (var j = 0; j < cols; j++) {
      dp[0][j] = j;
    }

    for (var i = 1; i < rows; i++) {
      for (var j = 1; j < cols; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        dp[i][j] = [
          dp[i - 1][j] + 1, // silme
          dp[i][j - 1] + 1, // ekleme
          dp[i - 1][j - 1] + cost, // değiştirme
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return dp[s1.length][s2.length];
  }

  /// 0.0–1.0 benzerlik skoru.
  /// 1.0 = tam eşleşme, 0.0 = tamamen farklı.
  static double similarity(String a, String b) {
    final s1 = a.toLowerCase().trim();
    final s2 = b.toLowerCase().trim();
    if (s1.isEmpty && s2.isEmpty) return 1.0;
    final maxLen = s1.length > s2.length ? s1.length : s2.length;
    if (maxLen == 0) return 1.0;
    final dist = distance(s1, s2);
    return 1.0 - dist / maxLen;
  }

  /// Blueprint: score >= 0.75 → wasCorrect = true
  static bool isCorrect(String spoken, String expected,
      {double threshold = 0.75}) {
    return similarity(spoken, expected) >= threshold;
  }
}
