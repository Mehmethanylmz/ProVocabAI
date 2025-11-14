class Word {
  final int id;
  final String en;
  final String tr;
  final String meaning;
  final String exampleSentence;
  int masteryLevel;
  int reviewDueDate;
  int wrongStreak;

  Word({
    required this.id,
    required this.en,
    required this.tr,
    required this.meaning,
    required this.exampleSentence,
    this.masteryLevel = 0,
    this.reviewDueDate = 0,
    this.wrongStreak = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'en': en,
      'tr': tr,
      'meaning': meaning,
      'example_sentence': exampleSentence,
      'mastery_level': masteryLevel,
      'review_due_date': reviewDueDate,
      'wrong_streak': wrongStreak,
    };
  }

  factory Word.fromMap(Map<String, dynamic> map) {
    return Word(
      id: map['id'],
      en: map['en'],
      tr: map['tr'],
      meaning: map['meaning'] ?? '',
      exampleSentence: map['example_sentence'] ?? '',
      masteryLevel: map['mastery_level'] ?? 0,
      reviewDueDate: map['review_due_date'] ?? 0,
      wrongStreak: map['wrong_streak'] ?? 0,
    );
  }
}
