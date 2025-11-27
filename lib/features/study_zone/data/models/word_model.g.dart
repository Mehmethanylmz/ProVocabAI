// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'word_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WordModel _$WordModelFromJson(Map<String, dynamic> json) => WordModel(
      id: (json['id'] as num).toInt(),
      partOfSpeech: json['partOfSpeech'] as String,
      transcription: json['transcription'] as String,
      categoriesJson: json['categoriesJson'] as String,
      contentJson: json['contentJson'] as String,
      sentencesJson: json['sentencesJson'] as String,
      masteryLevel: (json['masteryLevel'] as num?)?.toInt(),
      nextReview: (json['nextReview'] as num?)?.toInt(),
      streak: (json['streak'] as num?)?.toInt(),
    );

Map<String, dynamic> _$WordModelToJson(WordModel instance) => <String, dynamic>{
      'id': instance.id,
      'partOfSpeech': instance.partOfSpeech,
      'transcription': instance.transcription,
      'categoriesJson': instance.categoriesJson,
      'contentJson': instance.contentJson,
      'sentencesJson': instance.sentencesJson,
      'masteryLevel': instance.masteryLevel,
      'nextReview': instance.nextReview,
      'streak': instance.streak,
    };
