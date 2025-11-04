// lib/models/word_model.dart
class Word {
  final int id;
  final String en;
  final String tr;
  final String meaning;
  final String exampleSentence;
  String status; // 'unseen', 'learning', 'learned'

  Word({
    required this.id,
    required this.en,
    required this.tr,
    required this.meaning,
    required this.exampleSentence,
    this.status = 'unseen',
  });

  // Veritabanı işlemleri için Map'e dönüştürme
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'en': en,
      'tr': tr,
      'meaning': meaning,
      'example_sentence': exampleSentence,
      'status': status,
    };
  }

  // JSON'dan Word nesnesine dönüştürme
  factory Word.fromMap(Map<String, dynamic> map) {
    return Word(
      id: map['id'],
      en: map['en'],
      tr: map['tr'],
      meaning: map['meaning'],
      exampleSentence: map['example_sentence'],
      status: map['status'] ?? 'unseen',
    );
  }
}
