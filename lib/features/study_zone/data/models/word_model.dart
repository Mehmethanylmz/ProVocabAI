import 'dart:convert';
import '../../domain/entities/word_entity.dart';

class WordModel extends WordEntity {
  const WordModel({
    required super.id,
    required super.partOfSpeech,
    required super.transcription,
    required super.categoriesJson,
    required super.contentJson,
    required super.sentencesJson,
    super.masteryLevel,
    super.nextReview,
    super.streak,
  });

  factory WordModel.fromMap(Map<String, dynamic> map) {
    return WordModel(
      id: map['id'] as int,
      partOfSpeech: map['part_of_speech'] as String? ?? '',
      transcription: map['transcription'] as String? ?? '',
      categoriesJson: map['categories'] as String? ?? '[]',
      contentJson: map['content'] as String? ?? '{}',
      sentencesJson: map['sentences'] as String? ?? '{}',
      masteryLevel: map['mastery_level'] as int?,
      nextReview: map['due_date'] as int?,
      streak: map['streak'] as int?,
    );
  }

  factory WordModel.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>? ?? {};

    String categoriesStr = '[]';
    if (meta['categories'] != null) {
      categoriesStr = jsonEncode(meta['categories']);
    }

    String contentStr = '{}';
    if (json['content'] != null) {
      contentStr = jsonEncode(json['content']);
    }

    String sentencesStr = '{}';
    if (json['sentences'] != null) {
      sentencesStr = jsonEncode(json['sentences']);
    }

    return WordModel(
      id: json['id'] as int,
      partOfSpeech: meta['part_of_speech'] as String? ?? 'unknown',
      transcription: meta['transcription'] as String? ?? '',
      categoriesJson: categoriesStr,
      contentJson: contentStr,
      sentencesJson: sentencesStr,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'partOfSpeech': partOfSpeech,
      'transcription': transcription,
      'categoriesJson': categoriesJson,
      'contentJson': contentJson,
      'sentencesJson': sentencesJson,
      'masteryLevel': masteryLevel,
      'nextReview': nextReview,
      'streak': streak,
    };
  }

  /// SQLite'a kaydederken kullanılacak Map yapısı
  Map<String, dynamic> toSqlMap() {
    return {
      'id': id,
      'part_of_speech': partOfSpeech,
      'transcription': transcription,
      'categories': categoriesJson,
      'content': contentJson,
      'sentences': sentencesJson,
    };
  }

  WordEntity toEntity() {
    return WordEntity(
      id: id,
      partOfSpeech: partOfSpeech,
      transcription: transcription,
      categoriesJson: categoriesJson,
      contentJson: contentJson,
      sentencesJson: sentencesJson,
      masteryLevel: masteryLevel,
      nextReview: nextReview,
      streak: streak,
    );
  }
}
