class Word {
  final int id;
  final String en;
  final String tr;
  final String meaning;
  final String exampleSentence;
  String status;
  int? batchId;

  Word({
    required this.id,
    required this.en,
    required this.tr,
    required this.meaning,
    required this.exampleSentence,
    this.status = 'unseen',
    this.batchId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'en': en,
      'tr': tr,
      'meaning': meaning,
      'example_sentence': exampleSentence,
      'status': status,
      'batchId': batchId,
    };
  }

  factory Word.fromMap(Map<String, dynamic> map) {
    return Word(
      id: map['id'],
      en: map['en'],
      tr: map['tr'],
      meaning: map['meaning'] ?? '',
      exampleSentence: map['example_sentence'] ?? '',
      status: map['status'] ?? 'unseen',
      batchId: map['batchId'],
    );
  }
}
