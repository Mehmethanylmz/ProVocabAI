// C:\Users\Mete\Desktop\englishwordsapp\pratikapp\lib\models\word_model.dart

import 'dart:convert';

class Word {
  final int id;
  final String en;
  final String tr;
  final String meaning;
  final List<String> exampleSentences;
  final String notes;
  String status;
  int? batchId;
  int masteryLevel;
  int reviewDueDate;
  int wrongStreak;

  Word({
    required this.id,
    required this.en,
    required this.tr,
    required this.meaning,
    this.exampleSentences = const [],
    this.notes = '',
    this.status = 'unseen',
    this.batchId,
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
      'example_sentence': jsonEncode(exampleSentences),
      'notes': notes,
      'status': status,
      'batchId': batchId,
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
      exampleSentences: _parseExampleSentences(map['example_sentence']),
      notes: map['notes'] ?? '',
      status: map['status'] ?? 'unseen',
      batchId: map['batchId'],
      masteryLevel: map['mastery_level'] ?? 0,
      reviewDueDate: map['review_due_date'] ?? 0,
      wrongStreak: map['wrong_streak'] ?? 0,
    );
  }

  static List<String> _parseExampleSentences(dynamic data) {
    if (data == null || data.toString().isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(data.toString());
      if (decoded is List) {
        return List<String>.from(decoded.map((e) => e.toString()));
      }
      return [data.toString()];
    } catch (e) {
      return [data.toString()];
    }
  }
}
