import 'package:equatable/equatable.dart';
import 'dart:convert';

class WordEntity extends Equatable {
  final int id;
  final String partOfSpeech;
  final String transcription;
  final String categoriesJson;
  final String contentJson;
  final String sentencesJson;
  final int? masteryLevel;
  final int? nextReview;
  final int? streak;

  const WordEntity({
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

  @override
  List<Object?> get props => [id, partOfSpeech];

  // Localized içerik metodu
  Map<String, String> getLocalizedContent(String langCode) {
    try {
      final Map<String, dynamic> content = jsonDecode(contentJson);
      if (content.containsKey(langCode)) {
        return {
          'word': content[langCode]['word'] ?? '',
          'meaning': content[langCode]['meaning'] ?? '',
        };
      }
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

  // Cümle metodu
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
