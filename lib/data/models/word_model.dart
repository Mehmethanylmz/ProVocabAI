import 'dart:convert';

class Word {
  final int id;
  final String partOfSpeech;
  final String transcription;
  final String categoriesJson;
  final String contentJson;
  final String sentencesJson;

  // İlerleme verisi (Veritabanından join ile gelirse dolu olur)
  final int? masteryLevel;
  final int? nextReview;
  final int? streak;

  Word({
    required this.id,
    required this.partOfSpeech,
    required this.transcription,
    required this.categoriesJson,
    required this.contentJson,
    required this.sentencesJson,
    this.masteryLevel,
    this.nextReview,
    this.streak,
  });

  factory Word.fromMap(Map<String, dynamic> map) {
    return Word(
      id: map['id'],
      partOfSpeech: map['part_of_speech'] ?? '',
      transcription: map['transcription'] ?? '',
      categoriesJson: map['categories'] ?? '[]',
      contentJson: map['content'] ?? '{}',
      sentencesJson: map['sentences'] ?? '{}',
      masteryLevel: map['mastery_level'],
      nextReview: map['due_date'],
      streak: map['streak'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'part_of_speech': partOfSpeech,
      'transcription': transcription,
      'categories': categoriesJson,
      'content': contentJson,
      'sentences': sentencesJson,
    };
  }

  factory Word.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] ?? {};
    return Word(
      id: json['id'],
      partOfSpeech: meta['part_of_speech'] ?? 'unknown',
      transcription: meta['transcription'] ?? '',
      categoriesJson: jsonEncode(meta['categories'] ?? []),
      contentJson: jsonEncode(json['content'] ?? {}),
      sentencesJson: jsonEncode(json['sentences'] ?? {}),
    );
  }

  Map<String, String> getLocalizedContent(String langCode) {
    try {
      final Map<String, dynamic> content = jsonDecode(contentJson);
      if (content.containsKey(langCode)) {
        return {
          'word': content[langCode]['word'] ?? '',
          'meaning': content[langCode]['meaning'] ?? '',
        };
      }
      // Fallback to English if target lang not found
      if (content.containsKey('en')) {
        return {
          'word': content['en']['word'] ?? '',
          'meaning': content['en']['meaning'] ?? '',
        };
      }
    } catch (e) {
      // Silent error
    }
    return {'word': '?', 'meaning': '?'};
  }

  String getSentence(String level, String langCode) {
    try {
      final Map<String, dynamic> sentences = jsonDecode(sentencesJson);
      if (sentences.containsKey(level)) {
        final levelData = sentences[level];
        if (levelData.containsKey(langCode)) {
          return levelData[langCode];
        }
        if (levelData.containsKey('en')) {
          return levelData['en'];
        }
      }
    } catch (e) {
      // Silent error
    }
    return '';
  }
}
