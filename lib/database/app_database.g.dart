// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $WordsTable extends Words with TableInfo<$WordsTable, Word> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _partOfSpeechMeta =
      const VerificationMeta('partOfSpeech');
  @override
  late final GeneratedColumn<String> partOfSpeech = GeneratedColumn<String>(
      'part_of_speech', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _transcriptionMeta =
      const VerificationMeta('transcription');
  @override
  late final GeneratedColumn<String> transcription = GeneratedColumn<String>(
      'transcription', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _categoriesJsonMeta =
      const VerificationMeta('categoriesJson');
  @override
  late final GeneratedColumn<String> categoriesJson = GeneratedColumn<String>(
      'categories_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _contentJsonMeta =
      const VerificationMeta('contentJson');
  @override
  late final GeneratedColumn<String> contentJson = GeneratedColumn<String>(
      'content_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _sentencesJsonMeta =
      const VerificationMeta('sentencesJson');
  @override
  late final GeneratedColumn<String> sentencesJson = GeneratedColumn<String>(
      'sentences_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _difficultyRankMeta =
      const VerificationMeta('difficultyRank');
  @override
  late final GeneratedColumn<int> difficultyRank = GeneratedColumn<int>(
      'difficulty_rank', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        partOfSpeech,
        transcription,
        categoriesJson,
        contentJson,
        sentencesJson,
        difficultyRank
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'words';
  @override
  VerificationContext validateIntegrity(Insertable<Word> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('part_of_speech')) {
      context.handle(
          _partOfSpeechMeta,
          partOfSpeech.isAcceptableOrUnknown(
              data['part_of_speech']!, _partOfSpeechMeta));
    }
    if (data.containsKey('transcription')) {
      context.handle(
          _transcriptionMeta,
          transcription.isAcceptableOrUnknown(
              data['transcription']!, _transcriptionMeta));
    }
    if (data.containsKey('categories_json')) {
      context.handle(
          _categoriesJsonMeta,
          categoriesJson.isAcceptableOrUnknown(
              data['categories_json']!, _categoriesJsonMeta));
    }
    if (data.containsKey('content_json')) {
      context.handle(
          _contentJsonMeta,
          contentJson.isAcceptableOrUnknown(
              data['content_json']!, _contentJsonMeta));
    }
    if (data.containsKey('sentences_json')) {
      context.handle(
          _sentencesJsonMeta,
          sentencesJson.isAcceptableOrUnknown(
              data['sentences_json']!, _sentencesJsonMeta));
    }
    if (data.containsKey('difficulty_rank')) {
      context.handle(
          _difficultyRankMeta,
          difficultyRank.isAcceptableOrUnknown(
              data['difficulty_rank']!, _difficultyRankMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Word map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Word(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      partOfSpeech: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}part_of_speech'])!,
      transcription: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}transcription']),
      categoriesJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}categories_json'])!,
      contentJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content_json'])!,
      sentencesJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sentences_json'])!,
      difficultyRank: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}difficulty_rank'])!,
    );
  }

  @override
  $WordsTable createAlias(String alias) {
    return $WordsTable(attachedDatabase, alias);
  }
}

class Word extends DataClass implements Insertable<Word> {
  /// JSON id alanından gelir — PRIMARY KEY, auto-increment DEĞİL.
  final int id;

  /// meta.part_of_speech
  final String partOfSpeech;

  /// meta.transcription (nullable — bazı kelimelerde yok)
  final String? transcription;

  /// meta.categories — JSON encoded: '["oxford-american/a1","a2"]'
  final String categoriesJson;

  /// content — JSON encoded multilang: '{"en":{"word":"about","meaning":"..."},...}'
  final String contentJson;

  /// sentences — JSON encoded: '{"beginner":{"en":"..."},...}'
  final String sentencesJson;

  /// Zorluk sıralaması için türetilmiş sütun.
  /// 1=A1, 2=A2, 3=B1, 4=B2, 5=C1, 6=C2
  /// DailyPlanner getNewCards() ORDER BY difficulty_rank ile kullanır.
  final int difficultyRank;
  const Word(
      {required this.id,
      required this.partOfSpeech,
      this.transcription,
      required this.categoriesJson,
      required this.contentJson,
      required this.sentencesJson,
      required this.difficultyRank});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['part_of_speech'] = Variable<String>(partOfSpeech);
    if (!nullToAbsent || transcription != null) {
      map['transcription'] = Variable<String>(transcription);
    }
    map['categories_json'] = Variable<String>(categoriesJson);
    map['content_json'] = Variable<String>(contentJson);
    map['sentences_json'] = Variable<String>(sentencesJson);
    map['difficulty_rank'] = Variable<int>(difficultyRank);
    return map;
  }

  WordsCompanion toCompanion(bool nullToAbsent) {
    return WordsCompanion(
      id: Value(id),
      partOfSpeech: Value(partOfSpeech),
      transcription: transcription == null && nullToAbsent
          ? const Value.absent()
          : Value(transcription),
      categoriesJson: Value(categoriesJson),
      contentJson: Value(contentJson),
      sentencesJson: Value(sentencesJson),
      difficultyRank: Value(difficultyRank),
    );
  }

  factory Word.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Word(
      id: serializer.fromJson<int>(json['id']),
      partOfSpeech: serializer.fromJson<String>(json['partOfSpeech']),
      transcription: serializer.fromJson<String?>(json['transcription']),
      categoriesJson: serializer.fromJson<String>(json['categoriesJson']),
      contentJson: serializer.fromJson<String>(json['contentJson']),
      sentencesJson: serializer.fromJson<String>(json['sentencesJson']),
      difficultyRank: serializer.fromJson<int>(json['difficultyRank']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'partOfSpeech': serializer.toJson<String>(partOfSpeech),
      'transcription': serializer.toJson<String?>(transcription),
      'categoriesJson': serializer.toJson<String>(categoriesJson),
      'contentJson': serializer.toJson<String>(contentJson),
      'sentencesJson': serializer.toJson<String>(sentencesJson),
      'difficultyRank': serializer.toJson<int>(difficultyRank),
    };
  }

  Word copyWith(
          {int? id,
          String? partOfSpeech,
          Value<String?> transcription = const Value.absent(),
          String? categoriesJson,
          String? contentJson,
          String? sentencesJson,
          int? difficultyRank}) =>
      Word(
        id: id ?? this.id,
        partOfSpeech: partOfSpeech ?? this.partOfSpeech,
        transcription:
            transcription.present ? transcription.value : this.transcription,
        categoriesJson: categoriesJson ?? this.categoriesJson,
        contentJson: contentJson ?? this.contentJson,
        sentencesJson: sentencesJson ?? this.sentencesJson,
        difficultyRank: difficultyRank ?? this.difficultyRank,
      );
  Word copyWithCompanion(WordsCompanion data) {
    return Word(
      id: data.id.present ? data.id.value : this.id,
      partOfSpeech: data.partOfSpeech.present
          ? data.partOfSpeech.value
          : this.partOfSpeech,
      transcription: data.transcription.present
          ? data.transcription.value
          : this.transcription,
      categoriesJson: data.categoriesJson.present
          ? data.categoriesJson.value
          : this.categoriesJson,
      contentJson:
          data.contentJson.present ? data.contentJson.value : this.contentJson,
      sentencesJson: data.sentencesJson.present
          ? data.sentencesJson.value
          : this.sentencesJson,
      difficultyRank: data.difficultyRank.present
          ? data.difficultyRank.value
          : this.difficultyRank,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Word(')
          ..write('id: $id, ')
          ..write('partOfSpeech: $partOfSpeech, ')
          ..write('transcription: $transcription, ')
          ..write('categoriesJson: $categoriesJson, ')
          ..write('contentJson: $contentJson, ')
          ..write('sentencesJson: $sentencesJson, ')
          ..write('difficultyRank: $difficultyRank')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, partOfSpeech, transcription,
      categoriesJson, contentJson, sentencesJson, difficultyRank);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Word &&
          other.id == this.id &&
          other.partOfSpeech == this.partOfSpeech &&
          other.transcription == this.transcription &&
          other.categoriesJson == this.categoriesJson &&
          other.contentJson == this.contentJson &&
          other.sentencesJson == this.sentencesJson &&
          other.difficultyRank == this.difficultyRank);
}

class WordsCompanion extends UpdateCompanion<Word> {
  final Value<int> id;
  final Value<String> partOfSpeech;
  final Value<String?> transcription;
  final Value<String> categoriesJson;
  final Value<String> contentJson;
  final Value<String> sentencesJson;
  final Value<int> difficultyRank;
  const WordsCompanion({
    this.id = const Value.absent(),
    this.partOfSpeech = const Value.absent(),
    this.transcription = const Value.absent(),
    this.categoriesJson = const Value.absent(),
    this.contentJson = const Value.absent(),
    this.sentencesJson = const Value.absent(),
    this.difficultyRank = const Value.absent(),
  });
  WordsCompanion.insert({
    this.id = const Value.absent(),
    this.partOfSpeech = const Value.absent(),
    this.transcription = const Value.absent(),
    this.categoriesJson = const Value.absent(),
    this.contentJson = const Value.absent(),
    this.sentencesJson = const Value.absent(),
    this.difficultyRank = const Value.absent(),
  });
  static Insertable<Word> custom({
    Expression<int>? id,
    Expression<String>? partOfSpeech,
    Expression<String>? transcription,
    Expression<String>? categoriesJson,
    Expression<String>? contentJson,
    Expression<String>? sentencesJson,
    Expression<int>? difficultyRank,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (partOfSpeech != null) 'part_of_speech': partOfSpeech,
      if (transcription != null) 'transcription': transcription,
      if (categoriesJson != null) 'categories_json': categoriesJson,
      if (contentJson != null) 'content_json': contentJson,
      if (sentencesJson != null) 'sentences_json': sentencesJson,
      if (difficultyRank != null) 'difficulty_rank': difficultyRank,
    });
  }

  WordsCompanion copyWith(
      {Value<int>? id,
      Value<String>? partOfSpeech,
      Value<String?>? transcription,
      Value<String>? categoriesJson,
      Value<String>? contentJson,
      Value<String>? sentencesJson,
      Value<int>? difficultyRank}) {
    return WordsCompanion(
      id: id ?? this.id,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      transcription: transcription ?? this.transcription,
      categoriesJson: categoriesJson ?? this.categoriesJson,
      contentJson: contentJson ?? this.contentJson,
      sentencesJson: sentencesJson ?? this.sentencesJson,
      difficultyRank: difficultyRank ?? this.difficultyRank,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (partOfSpeech.present) {
      map['part_of_speech'] = Variable<String>(partOfSpeech.value);
    }
    if (transcription.present) {
      map['transcription'] = Variable<String>(transcription.value);
    }
    if (categoriesJson.present) {
      map['categories_json'] = Variable<String>(categoriesJson.value);
    }
    if (contentJson.present) {
      map['content_json'] = Variable<String>(contentJson.value);
    }
    if (sentencesJson.present) {
      map['sentences_json'] = Variable<String>(sentencesJson.value);
    }
    if (difficultyRank.present) {
      map['difficulty_rank'] = Variable<int>(difficultyRank.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordsCompanion(')
          ..write('id: $id, ')
          ..write('partOfSpeech: $partOfSpeech, ')
          ..write('transcription: $transcription, ')
          ..write('categoriesJson: $categoriesJson, ')
          ..write('contentJson: $contentJson, ')
          ..write('sentencesJson: $sentencesJson, ')
          ..write('difficultyRank: $difficultyRank')
          ..write(')'))
        .toString();
  }
}

class $ProgressTable extends Progress
    with TableInfo<$ProgressTable, ProgressData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<int> wordId = GeneratedColumn<int>(
      'word_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES words (id)'));
  static const VerificationMeta _targetLangMeta =
      const VerificationMeta('targetLang');
  @override
  late final GeneratedColumn<String> targetLang = GeneratedColumn<String>(
      'target_lang', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _stabilityMeta =
      const VerificationMeta('stability');
  @override
  late final GeneratedColumn<double> stability = GeneratedColumn<double>(
      'stability', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.5));
  static const VerificationMeta _difficultyMeta =
      const VerificationMeta('difficulty');
  @override
  late final GeneratedColumn<double> difficulty = GeneratedColumn<double>(
      'difficulty', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(5.0));
  static const VerificationMeta _cardStateMeta =
      const VerificationMeta('cardState');
  @override
  late final GeneratedColumn<String> cardState = GeneratedColumn<String>(
      'card_state', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('new'));
  static const VerificationMeta _nextReviewMsMeta =
      const VerificationMeta('nextReviewMs');
  @override
  late final GeneratedColumn<int> nextReviewMs = GeneratedColumn<int>(
      'next_review_ms', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastReviewMsMeta =
      const VerificationMeta('lastReviewMs');
  @override
  late final GeneratedColumn<int> lastReviewMs = GeneratedColumn<int>(
      'last_review_ms', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lapsesMeta = const VerificationMeta('lapses');
  @override
  late final GeneratedColumn<int> lapses = GeneratedColumn<int>(
      'lapses', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _repetitionsMeta =
      const VerificationMeta('repetitions');
  @override
  late final GeneratedColumn<int> repetitions = GeneratedColumn<int>(
      'repetitions', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _isLeechMeta =
      const VerificationMeta('isLeech');
  @override
  late final GeneratedColumn<bool> isLeech = GeneratedColumn<bool>(
      'is_leech', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_leech" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _isSuspendedMeta =
      const VerificationMeta('isSuspended');
  @override
  late final GeneratedColumn<bool> isSuspended = GeneratedColumn<bool>(
      'is_suspended', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_suspended" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _modeHistoryJsonMeta =
      const VerificationMeta('modeHistoryJson');
  @override
  late final GeneratedColumn<String> modeHistoryJson = GeneratedColumn<String>(
      'mode_history_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        wordId,
        targetLang,
        stability,
        difficulty,
        cardState,
        nextReviewMs,
        lastReviewMs,
        lapses,
        repetitions,
        isLeech,
        isSuspended,
        modeHistoryJson,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'progress';
  @override
  VerificationContext validateIntegrity(Insertable<ProgressData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('word_id')) {
      context.handle(_wordIdMeta,
          wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta));
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    if (data.containsKey('target_lang')) {
      context.handle(
          _targetLangMeta,
          targetLang.isAcceptableOrUnknown(
              data['target_lang']!, _targetLangMeta));
    } else if (isInserting) {
      context.missing(_targetLangMeta);
    }
    if (data.containsKey('stability')) {
      context.handle(_stabilityMeta,
          stability.isAcceptableOrUnknown(data['stability']!, _stabilityMeta));
    }
    if (data.containsKey('difficulty')) {
      context.handle(
          _difficultyMeta,
          difficulty.isAcceptableOrUnknown(
              data['difficulty']!, _difficultyMeta));
    }
    if (data.containsKey('card_state')) {
      context.handle(_cardStateMeta,
          cardState.isAcceptableOrUnknown(data['card_state']!, _cardStateMeta));
    }
    if (data.containsKey('next_review_ms')) {
      context.handle(
          _nextReviewMsMeta,
          nextReviewMs.isAcceptableOrUnknown(
              data['next_review_ms']!, _nextReviewMsMeta));
    }
    if (data.containsKey('last_review_ms')) {
      context.handle(
          _lastReviewMsMeta,
          lastReviewMs.isAcceptableOrUnknown(
              data['last_review_ms']!, _lastReviewMsMeta));
    }
    if (data.containsKey('lapses')) {
      context.handle(_lapsesMeta,
          lapses.isAcceptableOrUnknown(data['lapses']!, _lapsesMeta));
    }
    if (data.containsKey('repetitions')) {
      context.handle(
          _repetitionsMeta,
          repetitions.isAcceptableOrUnknown(
              data['repetitions']!, _repetitionsMeta));
    }
    if (data.containsKey('is_leech')) {
      context.handle(_isLeechMeta,
          isLeech.isAcceptableOrUnknown(data['is_leech']!, _isLeechMeta));
    }
    if (data.containsKey('is_suspended')) {
      context.handle(
          _isSuspendedMeta,
          isSuspended.isAcceptableOrUnknown(
              data['is_suspended']!, _isSuspendedMeta));
    }
    if (data.containsKey('mode_history_json')) {
      context.handle(
          _modeHistoryJsonMeta,
          modeHistoryJson.isAcceptableOrUnknown(
              data['mode_history_json']!, _modeHistoryJsonMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {wordId, targetLang};
  @override
  ProgressData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProgressData(
      wordId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}word_id'])!,
      targetLang: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}target_lang'])!,
      stability: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}stability'])!,
      difficulty: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}difficulty'])!,
      cardState: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}card_state'])!,
      nextReviewMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}next_review_ms'])!,
      lastReviewMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_review_ms'])!,
      lapses: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}lapses'])!,
      repetitions: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}repetitions'])!,
      isLeech: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_leech'])!,
      isSuspended: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_suspended'])!,
      modeHistoryJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}mode_history_json'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ProgressTable createAlias(String alias) {
    return $ProgressTable(attachedDatabase, alias);
  }
}

class ProgressData extends DataClass implements Insertable<ProgressData> {
  /// FK → words.id
  final int wordId;

  /// Hedef dil kodu: 'en', 'tr', 'es', 'de', 'fr', 'pt'
  final String targetLang;

  /// FSRS stability (gün cinsinden, continuous).
  /// Yeni kart cold-start: 0.5 (FSRS-4.5 w[2] default)
  final double stability;

  /// FSRS difficulty (1.0–10.0 aralığı).
  /// Yeni kart cold-start: 5.0 (w[4] neutral)
  final double difficulty;

  /// CardState: 'new' | 'learning' | 'review' | 'relearning'
  /// Default 'new' — progress tablosunda kayıt yoksa yeni kart anlamına gelir.
  final String cardState;

  /// Bir sonraki review zamanı (Unix ms).
  /// Yeni kart: DateTime.now().millisecondsSinceEpoch (hemen göster)
  final int nextReviewMs;

  /// Son review zamanı (Unix ms).
  final int lastReviewMs;

  /// Kaç kez "again" verildi (FSRS lapses).
  final int lapses;

  /// Toplam başarılı review sayısı.
  final int repetitions;

  /// lapses >= 4 → leech işaretlendi (LeechHandler tarafından set edilir).
  final bool isLeech;

  /// lapses >= 8 → kullanıcı onayıyla suspend edildi.
  final bool isSuspended;

  /// ModeSelector için mod kullanım istatistiği.
  /// JSON encoded: '{"mcq":5,"listening":3,"speaking":2}'
  final String modeHistoryJson;

  /// Son güncelleme zamanı (Unix ms) — ConflictResolver'da server-wins karşılaştırması için.
  final int updatedAt;
  const ProgressData(
      {required this.wordId,
      required this.targetLang,
      required this.stability,
      required this.difficulty,
      required this.cardState,
      required this.nextReviewMs,
      required this.lastReviewMs,
      required this.lapses,
      required this.repetitions,
      required this.isLeech,
      required this.isSuspended,
      required this.modeHistoryJson,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['word_id'] = Variable<int>(wordId);
    map['target_lang'] = Variable<String>(targetLang);
    map['stability'] = Variable<double>(stability);
    map['difficulty'] = Variable<double>(difficulty);
    map['card_state'] = Variable<String>(cardState);
    map['next_review_ms'] = Variable<int>(nextReviewMs);
    map['last_review_ms'] = Variable<int>(lastReviewMs);
    map['lapses'] = Variable<int>(lapses);
    map['repetitions'] = Variable<int>(repetitions);
    map['is_leech'] = Variable<bool>(isLeech);
    map['is_suspended'] = Variable<bool>(isSuspended);
    map['mode_history_json'] = Variable<String>(modeHistoryJson);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ProgressCompanion toCompanion(bool nullToAbsent) {
    return ProgressCompanion(
      wordId: Value(wordId),
      targetLang: Value(targetLang),
      stability: Value(stability),
      difficulty: Value(difficulty),
      cardState: Value(cardState),
      nextReviewMs: Value(nextReviewMs),
      lastReviewMs: Value(lastReviewMs),
      lapses: Value(lapses),
      repetitions: Value(repetitions),
      isLeech: Value(isLeech),
      isSuspended: Value(isSuspended),
      modeHistoryJson: Value(modeHistoryJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory ProgressData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProgressData(
      wordId: serializer.fromJson<int>(json['wordId']),
      targetLang: serializer.fromJson<String>(json['targetLang']),
      stability: serializer.fromJson<double>(json['stability']),
      difficulty: serializer.fromJson<double>(json['difficulty']),
      cardState: serializer.fromJson<String>(json['cardState']),
      nextReviewMs: serializer.fromJson<int>(json['nextReviewMs']),
      lastReviewMs: serializer.fromJson<int>(json['lastReviewMs']),
      lapses: serializer.fromJson<int>(json['lapses']),
      repetitions: serializer.fromJson<int>(json['repetitions']),
      isLeech: serializer.fromJson<bool>(json['isLeech']),
      isSuspended: serializer.fromJson<bool>(json['isSuspended']),
      modeHistoryJson: serializer.fromJson<String>(json['modeHistoryJson']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'wordId': serializer.toJson<int>(wordId),
      'targetLang': serializer.toJson<String>(targetLang),
      'stability': serializer.toJson<double>(stability),
      'difficulty': serializer.toJson<double>(difficulty),
      'cardState': serializer.toJson<String>(cardState),
      'nextReviewMs': serializer.toJson<int>(nextReviewMs),
      'lastReviewMs': serializer.toJson<int>(lastReviewMs),
      'lapses': serializer.toJson<int>(lapses),
      'repetitions': serializer.toJson<int>(repetitions),
      'isLeech': serializer.toJson<bool>(isLeech),
      'isSuspended': serializer.toJson<bool>(isSuspended),
      'modeHistoryJson': serializer.toJson<String>(modeHistoryJson),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  ProgressData copyWith(
          {int? wordId,
          String? targetLang,
          double? stability,
          double? difficulty,
          String? cardState,
          int? nextReviewMs,
          int? lastReviewMs,
          int? lapses,
          int? repetitions,
          bool? isLeech,
          bool? isSuspended,
          String? modeHistoryJson,
          int? updatedAt}) =>
      ProgressData(
        wordId: wordId ?? this.wordId,
        targetLang: targetLang ?? this.targetLang,
        stability: stability ?? this.stability,
        difficulty: difficulty ?? this.difficulty,
        cardState: cardState ?? this.cardState,
        nextReviewMs: nextReviewMs ?? this.nextReviewMs,
        lastReviewMs: lastReviewMs ?? this.lastReviewMs,
        lapses: lapses ?? this.lapses,
        repetitions: repetitions ?? this.repetitions,
        isLeech: isLeech ?? this.isLeech,
        isSuspended: isSuspended ?? this.isSuspended,
        modeHistoryJson: modeHistoryJson ?? this.modeHistoryJson,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  ProgressData copyWithCompanion(ProgressCompanion data) {
    return ProgressData(
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      targetLang:
          data.targetLang.present ? data.targetLang.value : this.targetLang,
      stability: data.stability.present ? data.stability.value : this.stability,
      difficulty:
          data.difficulty.present ? data.difficulty.value : this.difficulty,
      cardState: data.cardState.present ? data.cardState.value : this.cardState,
      nextReviewMs: data.nextReviewMs.present
          ? data.nextReviewMs.value
          : this.nextReviewMs,
      lastReviewMs: data.lastReviewMs.present
          ? data.lastReviewMs.value
          : this.lastReviewMs,
      lapses: data.lapses.present ? data.lapses.value : this.lapses,
      repetitions:
          data.repetitions.present ? data.repetitions.value : this.repetitions,
      isLeech: data.isLeech.present ? data.isLeech.value : this.isLeech,
      isSuspended:
          data.isSuspended.present ? data.isSuspended.value : this.isSuspended,
      modeHistoryJson: data.modeHistoryJson.present
          ? data.modeHistoryJson.value
          : this.modeHistoryJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProgressData(')
          ..write('wordId: $wordId, ')
          ..write('targetLang: $targetLang, ')
          ..write('stability: $stability, ')
          ..write('difficulty: $difficulty, ')
          ..write('cardState: $cardState, ')
          ..write('nextReviewMs: $nextReviewMs, ')
          ..write('lastReviewMs: $lastReviewMs, ')
          ..write('lapses: $lapses, ')
          ..write('repetitions: $repetitions, ')
          ..write('isLeech: $isLeech, ')
          ..write('isSuspended: $isSuspended, ')
          ..write('modeHistoryJson: $modeHistoryJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      wordId,
      targetLang,
      stability,
      difficulty,
      cardState,
      nextReviewMs,
      lastReviewMs,
      lapses,
      repetitions,
      isLeech,
      isSuspended,
      modeHistoryJson,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProgressData &&
          other.wordId == this.wordId &&
          other.targetLang == this.targetLang &&
          other.stability == this.stability &&
          other.difficulty == this.difficulty &&
          other.cardState == this.cardState &&
          other.nextReviewMs == this.nextReviewMs &&
          other.lastReviewMs == this.lastReviewMs &&
          other.lapses == this.lapses &&
          other.repetitions == this.repetitions &&
          other.isLeech == this.isLeech &&
          other.isSuspended == this.isSuspended &&
          other.modeHistoryJson == this.modeHistoryJson &&
          other.updatedAt == this.updatedAt);
}

class ProgressCompanion extends UpdateCompanion<ProgressData> {
  final Value<int> wordId;
  final Value<String> targetLang;
  final Value<double> stability;
  final Value<double> difficulty;
  final Value<String> cardState;
  final Value<int> nextReviewMs;
  final Value<int> lastReviewMs;
  final Value<int> lapses;
  final Value<int> repetitions;
  final Value<bool> isLeech;
  final Value<bool> isSuspended;
  final Value<String> modeHistoryJson;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const ProgressCompanion({
    this.wordId = const Value.absent(),
    this.targetLang = const Value.absent(),
    this.stability = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.cardState = const Value.absent(),
    this.nextReviewMs = const Value.absent(),
    this.lastReviewMs = const Value.absent(),
    this.lapses = const Value.absent(),
    this.repetitions = const Value.absent(),
    this.isLeech = const Value.absent(),
    this.isSuspended = const Value.absent(),
    this.modeHistoryJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProgressCompanion.insert({
    required int wordId,
    required String targetLang,
    this.stability = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.cardState = const Value.absent(),
    this.nextReviewMs = const Value.absent(),
    this.lastReviewMs = const Value.absent(),
    this.lapses = const Value.absent(),
    this.repetitions = const Value.absent(),
    this.isLeech = const Value.absent(),
    this.isSuspended = const Value.absent(),
    this.modeHistoryJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : wordId = Value(wordId),
        targetLang = Value(targetLang);
  static Insertable<ProgressData> custom({
    Expression<int>? wordId,
    Expression<String>? targetLang,
    Expression<double>? stability,
    Expression<double>? difficulty,
    Expression<String>? cardState,
    Expression<int>? nextReviewMs,
    Expression<int>? lastReviewMs,
    Expression<int>? lapses,
    Expression<int>? repetitions,
    Expression<bool>? isLeech,
    Expression<bool>? isSuspended,
    Expression<String>? modeHistoryJson,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (wordId != null) 'word_id': wordId,
      if (targetLang != null) 'target_lang': targetLang,
      if (stability != null) 'stability': stability,
      if (difficulty != null) 'difficulty': difficulty,
      if (cardState != null) 'card_state': cardState,
      if (nextReviewMs != null) 'next_review_ms': nextReviewMs,
      if (lastReviewMs != null) 'last_review_ms': lastReviewMs,
      if (lapses != null) 'lapses': lapses,
      if (repetitions != null) 'repetitions': repetitions,
      if (isLeech != null) 'is_leech': isLeech,
      if (isSuspended != null) 'is_suspended': isSuspended,
      if (modeHistoryJson != null) 'mode_history_json': modeHistoryJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProgressCompanion copyWith(
      {Value<int>? wordId,
      Value<String>? targetLang,
      Value<double>? stability,
      Value<double>? difficulty,
      Value<String>? cardState,
      Value<int>? nextReviewMs,
      Value<int>? lastReviewMs,
      Value<int>? lapses,
      Value<int>? repetitions,
      Value<bool>? isLeech,
      Value<bool>? isSuspended,
      Value<String>? modeHistoryJson,
      Value<int>? updatedAt,
      Value<int>? rowid}) {
    return ProgressCompanion(
      wordId: wordId ?? this.wordId,
      targetLang: targetLang ?? this.targetLang,
      stability: stability ?? this.stability,
      difficulty: difficulty ?? this.difficulty,
      cardState: cardState ?? this.cardState,
      nextReviewMs: nextReviewMs ?? this.nextReviewMs,
      lastReviewMs: lastReviewMs ?? this.lastReviewMs,
      lapses: lapses ?? this.lapses,
      repetitions: repetitions ?? this.repetitions,
      isLeech: isLeech ?? this.isLeech,
      isSuspended: isSuspended ?? this.isSuspended,
      modeHistoryJson: modeHistoryJson ?? this.modeHistoryJson,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (wordId.present) {
      map['word_id'] = Variable<int>(wordId.value);
    }
    if (targetLang.present) {
      map['target_lang'] = Variable<String>(targetLang.value);
    }
    if (stability.present) {
      map['stability'] = Variable<double>(stability.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<double>(difficulty.value);
    }
    if (cardState.present) {
      map['card_state'] = Variable<String>(cardState.value);
    }
    if (nextReviewMs.present) {
      map['next_review_ms'] = Variable<int>(nextReviewMs.value);
    }
    if (lastReviewMs.present) {
      map['last_review_ms'] = Variable<int>(lastReviewMs.value);
    }
    if (lapses.present) {
      map['lapses'] = Variable<int>(lapses.value);
    }
    if (repetitions.present) {
      map['repetitions'] = Variable<int>(repetitions.value);
    }
    if (isLeech.present) {
      map['is_leech'] = Variable<bool>(isLeech.value);
    }
    if (isSuspended.present) {
      map['is_suspended'] = Variable<bool>(isSuspended.value);
    }
    if (modeHistoryJson.present) {
      map['mode_history_json'] = Variable<String>(modeHistoryJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProgressCompanion(')
          ..write('wordId: $wordId, ')
          ..write('targetLang: $targetLang, ')
          ..write('stability: $stability, ')
          ..write('difficulty: $difficulty, ')
          ..write('cardState: $cardState, ')
          ..write('nextReviewMs: $nextReviewMs, ')
          ..write('lastReviewMs: $lastReviewMs, ')
          ..write('lapses: $lapses, ')
          ..write('repetitions: $repetitions, ')
          ..write('isLeech: $isLeech, ')
          ..write('isSuspended: $isSuspended, ')
          ..write('modeHistoryJson: $modeHistoryJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReviewEventsTable extends ReviewEvents
    with TableInfo<$ReviewEventsTable, ReviewEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _wordIdMeta = const VerificationMeta('wordId');
  @override
  late final GeneratedColumn<int> wordId = GeneratedColumn<int>(
      'word_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES words (id)'));
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
      'session_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _targetLangMeta =
      const VerificationMeta('targetLang');
  @override
  late final GeneratedColumn<String> targetLang = GeneratedColumn<String>(
      'target_lang', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<String> rating = GeneratedColumn<String>(
      'rating', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _responseMsMeta =
      const VerificationMeta('responseMs');
  @override
  late final GeneratedColumn<int> responseMs = GeneratedColumn<int>(
      'response_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
      'mode', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _wasCorrectMeta =
      const VerificationMeta('wasCorrect');
  @override
  late final GeneratedColumn<bool> wasCorrect = GeneratedColumn<bool>(
      'was_correct', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("was_correct" IN (0, 1))'));
  static const VerificationMeta _stabilityBeforeMeta =
      const VerificationMeta('stabilityBefore');
  @override
  late final GeneratedColumn<double> stabilityBefore = GeneratedColumn<double>(
      'stability_before', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _stabilityAfterMeta =
      const VerificationMeta('stabilityAfter');
  @override
  late final GeneratedColumn<double> stabilityAfter = GeneratedColumn<double>(
      'stability_after', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _reviewedAtMeta =
      const VerificationMeta('reviewedAt');
  @override
  late final GeneratedColumn<int> reviewedAt = GeneratedColumn<int>(
      'reviewed_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        wordId,
        sessionId,
        targetLang,
        rating,
        responseMs,
        mode,
        wasCorrect,
        stabilityBefore,
        stabilityAfter,
        reviewedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'review_events';
  @override
  VerificationContext validateIntegrity(Insertable<ReviewEvent> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('word_id')) {
      context.handle(_wordIdMeta,
          wordId.isAcceptableOrUnknown(data['word_id']!, _wordIdMeta));
    } else if (isInserting) {
      context.missing(_wordIdMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('target_lang')) {
      context.handle(
          _targetLangMeta,
          targetLang.isAcceptableOrUnknown(
              data['target_lang']!, _targetLangMeta));
    } else if (isInserting) {
      context.missing(_targetLangMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(_ratingMeta,
          rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta));
    } else if (isInserting) {
      context.missing(_ratingMeta);
    }
    if (data.containsKey('response_ms')) {
      context.handle(
          _responseMsMeta,
          responseMs.isAcceptableOrUnknown(
              data['response_ms']!, _responseMsMeta));
    } else if (isInserting) {
      context.missing(_responseMsMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
          _modeMeta, mode.isAcceptableOrUnknown(data['mode']!, _modeMeta));
    } else if (isInserting) {
      context.missing(_modeMeta);
    }
    if (data.containsKey('was_correct')) {
      context.handle(
          _wasCorrectMeta,
          wasCorrect.isAcceptableOrUnknown(
              data['was_correct']!, _wasCorrectMeta));
    } else if (isInserting) {
      context.missing(_wasCorrectMeta);
    }
    if (data.containsKey('stability_before')) {
      context.handle(
          _stabilityBeforeMeta,
          stabilityBefore.isAcceptableOrUnknown(
              data['stability_before']!, _stabilityBeforeMeta));
    } else if (isInserting) {
      context.missing(_stabilityBeforeMeta);
    }
    if (data.containsKey('stability_after')) {
      context.handle(
          _stabilityAfterMeta,
          stabilityAfter.isAcceptableOrUnknown(
              data['stability_after']!, _stabilityAfterMeta));
    } else if (isInserting) {
      context.missing(_stabilityAfterMeta);
    }
    if (data.containsKey('reviewed_at')) {
      context.handle(
          _reviewedAtMeta,
          reviewedAt.isAcceptableOrUnknown(
              data['reviewed_at']!, _reviewedAtMeta));
    } else if (isInserting) {
      context.missing(_reviewedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReviewEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReviewEvent(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      wordId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}word_id'])!,
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_id'])!,
      targetLang: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}target_lang'])!,
      rating: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}rating'])!,
      responseMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}response_ms'])!,
      mode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mode'])!,
      wasCorrect: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}was_correct'])!,
      stabilityBefore: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}stability_before'])!,
      stabilityAfter: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}stability_after'])!,
      reviewedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}reviewed_at'])!,
    );
  }

  @override
  $ReviewEventsTable createAlias(String alias) {
    return $ReviewEventsTable(attachedDatabase, alias);
  }
}

class ReviewEvent extends DataClass implements Insertable<ReviewEvent> {
  /// UUID — SyncManager ile uyumlu unique ID.
  final String id;

  /// FK → words.id
  final int wordId;

  /// Hangi oturumda yapıldı.
  final String sessionId;

  /// Hedef dil.
  final String targetLang;

  /// Review puanı: 'again' | 'hard' | 'good' | 'easy'
  final String rating;

  /// Kullanıcının cevap süresi (ms).
  final int responseMs;

  /// Bu review'da kullanılan mod: 'mcq' | 'listening' | 'speaking'
  final String mode;

  /// Cevap doğru muydu (rating != again → true).
  final bool wasCorrect;

  /// Review anındaki FSRS stability değeri (log amaçlı).
  final double stabilityBefore;

  /// Review sonrası FSRS stability değeri.
  final double stabilityAfter;

  /// Review zamanı (Unix ms).
  final int reviewedAt;
  const ReviewEvent(
      {required this.id,
      required this.wordId,
      required this.sessionId,
      required this.targetLang,
      required this.rating,
      required this.responseMs,
      required this.mode,
      required this.wasCorrect,
      required this.stabilityBefore,
      required this.stabilityAfter,
      required this.reviewedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['word_id'] = Variable<int>(wordId);
    map['session_id'] = Variable<String>(sessionId);
    map['target_lang'] = Variable<String>(targetLang);
    map['rating'] = Variable<String>(rating);
    map['response_ms'] = Variable<int>(responseMs);
    map['mode'] = Variable<String>(mode);
    map['was_correct'] = Variable<bool>(wasCorrect);
    map['stability_before'] = Variable<double>(stabilityBefore);
    map['stability_after'] = Variable<double>(stabilityAfter);
    map['reviewed_at'] = Variable<int>(reviewedAt);
    return map;
  }

  ReviewEventsCompanion toCompanion(bool nullToAbsent) {
    return ReviewEventsCompanion(
      id: Value(id),
      wordId: Value(wordId),
      sessionId: Value(sessionId),
      targetLang: Value(targetLang),
      rating: Value(rating),
      responseMs: Value(responseMs),
      mode: Value(mode),
      wasCorrect: Value(wasCorrect),
      stabilityBefore: Value(stabilityBefore),
      stabilityAfter: Value(stabilityAfter),
      reviewedAt: Value(reviewedAt),
    );
  }

  factory ReviewEvent.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReviewEvent(
      id: serializer.fromJson<String>(json['id']),
      wordId: serializer.fromJson<int>(json['wordId']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      targetLang: serializer.fromJson<String>(json['targetLang']),
      rating: serializer.fromJson<String>(json['rating']),
      responseMs: serializer.fromJson<int>(json['responseMs']),
      mode: serializer.fromJson<String>(json['mode']),
      wasCorrect: serializer.fromJson<bool>(json['wasCorrect']),
      stabilityBefore: serializer.fromJson<double>(json['stabilityBefore']),
      stabilityAfter: serializer.fromJson<double>(json['stabilityAfter']),
      reviewedAt: serializer.fromJson<int>(json['reviewedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'wordId': serializer.toJson<int>(wordId),
      'sessionId': serializer.toJson<String>(sessionId),
      'targetLang': serializer.toJson<String>(targetLang),
      'rating': serializer.toJson<String>(rating),
      'responseMs': serializer.toJson<int>(responseMs),
      'mode': serializer.toJson<String>(mode),
      'wasCorrect': serializer.toJson<bool>(wasCorrect),
      'stabilityBefore': serializer.toJson<double>(stabilityBefore),
      'stabilityAfter': serializer.toJson<double>(stabilityAfter),
      'reviewedAt': serializer.toJson<int>(reviewedAt),
    };
  }

  ReviewEvent copyWith(
          {String? id,
          int? wordId,
          String? sessionId,
          String? targetLang,
          String? rating,
          int? responseMs,
          String? mode,
          bool? wasCorrect,
          double? stabilityBefore,
          double? stabilityAfter,
          int? reviewedAt}) =>
      ReviewEvent(
        id: id ?? this.id,
        wordId: wordId ?? this.wordId,
        sessionId: sessionId ?? this.sessionId,
        targetLang: targetLang ?? this.targetLang,
        rating: rating ?? this.rating,
        responseMs: responseMs ?? this.responseMs,
        mode: mode ?? this.mode,
        wasCorrect: wasCorrect ?? this.wasCorrect,
        stabilityBefore: stabilityBefore ?? this.stabilityBefore,
        stabilityAfter: stabilityAfter ?? this.stabilityAfter,
        reviewedAt: reviewedAt ?? this.reviewedAt,
      );
  ReviewEvent copyWithCompanion(ReviewEventsCompanion data) {
    return ReviewEvent(
      id: data.id.present ? data.id.value : this.id,
      wordId: data.wordId.present ? data.wordId.value : this.wordId,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      targetLang:
          data.targetLang.present ? data.targetLang.value : this.targetLang,
      rating: data.rating.present ? data.rating.value : this.rating,
      responseMs:
          data.responseMs.present ? data.responseMs.value : this.responseMs,
      mode: data.mode.present ? data.mode.value : this.mode,
      wasCorrect:
          data.wasCorrect.present ? data.wasCorrect.value : this.wasCorrect,
      stabilityBefore: data.stabilityBefore.present
          ? data.stabilityBefore.value
          : this.stabilityBefore,
      stabilityAfter: data.stabilityAfter.present
          ? data.stabilityAfter.value
          : this.stabilityAfter,
      reviewedAt:
          data.reviewedAt.present ? data.reviewedAt.value : this.reviewedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReviewEvent(')
          ..write('id: $id, ')
          ..write('wordId: $wordId, ')
          ..write('sessionId: $sessionId, ')
          ..write('targetLang: $targetLang, ')
          ..write('rating: $rating, ')
          ..write('responseMs: $responseMs, ')
          ..write('mode: $mode, ')
          ..write('wasCorrect: $wasCorrect, ')
          ..write('stabilityBefore: $stabilityBefore, ')
          ..write('stabilityAfter: $stabilityAfter, ')
          ..write('reviewedAt: $reviewedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      wordId,
      sessionId,
      targetLang,
      rating,
      responseMs,
      mode,
      wasCorrect,
      stabilityBefore,
      stabilityAfter,
      reviewedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReviewEvent &&
          other.id == this.id &&
          other.wordId == this.wordId &&
          other.sessionId == this.sessionId &&
          other.targetLang == this.targetLang &&
          other.rating == this.rating &&
          other.responseMs == this.responseMs &&
          other.mode == this.mode &&
          other.wasCorrect == this.wasCorrect &&
          other.stabilityBefore == this.stabilityBefore &&
          other.stabilityAfter == this.stabilityAfter &&
          other.reviewedAt == this.reviewedAt);
}

class ReviewEventsCompanion extends UpdateCompanion<ReviewEvent> {
  final Value<String> id;
  final Value<int> wordId;
  final Value<String> sessionId;
  final Value<String> targetLang;
  final Value<String> rating;
  final Value<int> responseMs;
  final Value<String> mode;
  final Value<bool> wasCorrect;
  final Value<double> stabilityBefore;
  final Value<double> stabilityAfter;
  final Value<int> reviewedAt;
  final Value<int> rowid;
  const ReviewEventsCompanion({
    this.id = const Value.absent(),
    this.wordId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.targetLang = const Value.absent(),
    this.rating = const Value.absent(),
    this.responseMs = const Value.absent(),
    this.mode = const Value.absent(),
    this.wasCorrect = const Value.absent(),
    this.stabilityBefore = const Value.absent(),
    this.stabilityAfter = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReviewEventsCompanion.insert({
    required String id,
    required int wordId,
    required String sessionId,
    required String targetLang,
    required String rating,
    required int responseMs,
    required String mode,
    required bool wasCorrect,
    required double stabilityBefore,
    required double stabilityAfter,
    required int reviewedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        wordId = Value(wordId),
        sessionId = Value(sessionId),
        targetLang = Value(targetLang),
        rating = Value(rating),
        responseMs = Value(responseMs),
        mode = Value(mode),
        wasCorrect = Value(wasCorrect),
        stabilityBefore = Value(stabilityBefore),
        stabilityAfter = Value(stabilityAfter),
        reviewedAt = Value(reviewedAt);
  static Insertable<ReviewEvent> custom({
    Expression<String>? id,
    Expression<int>? wordId,
    Expression<String>? sessionId,
    Expression<String>? targetLang,
    Expression<String>? rating,
    Expression<int>? responseMs,
    Expression<String>? mode,
    Expression<bool>? wasCorrect,
    Expression<double>? stabilityBefore,
    Expression<double>? stabilityAfter,
    Expression<int>? reviewedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (wordId != null) 'word_id': wordId,
      if (sessionId != null) 'session_id': sessionId,
      if (targetLang != null) 'target_lang': targetLang,
      if (rating != null) 'rating': rating,
      if (responseMs != null) 'response_ms': responseMs,
      if (mode != null) 'mode': mode,
      if (wasCorrect != null) 'was_correct': wasCorrect,
      if (stabilityBefore != null) 'stability_before': stabilityBefore,
      if (stabilityAfter != null) 'stability_after': stabilityAfter,
      if (reviewedAt != null) 'reviewed_at': reviewedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReviewEventsCompanion copyWith(
      {Value<String>? id,
      Value<int>? wordId,
      Value<String>? sessionId,
      Value<String>? targetLang,
      Value<String>? rating,
      Value<int>? responseMs,
      Value<String>? mode,
      Value<bool>? wasCorrect,
      Value<double>? stabilityBefore,
      Value<double>? stabilityAfter,
      Value<int>? reviewedAt,
      Value<int>? rowid}) {
    return ReviewEventsCompanion(
      id: id ?? this.id,
      wordId: wordId ?? this.wordId,
      sessionId: sessionId ?? this.sessionId,
      targetLang: targetLang ?? this.targetLang,
      rating: rating ?? this.rating,
      responseMs: responseMs ?? this.responseMs,
      mode: mode ?? this.mode,
      wasCorrect: wasCorrect ?? this.wasCorrect,
      stabilityBefore: stabilityBefore ?? this.stabilityBefore,
      stabilityAfter: stabilityAfter ?? this.stabilityAfter,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (wordId.present) {
      map['word_id'] = Variable<int>(wordId.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (targetLang.present) {
      map['target_lang'] = Variable<String>(targetLang.value);
    }
    if (rating.present) {
      map['rating'] = Variable<String>(rating.value);
    }
    if (responseMs.present) {
      map['response_ms'] = Variable<int>(responseMs.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (wasCorrect.present) {
      map['was_correct'] = Variable<bool>(wasCorrect.value);
    }
    if (stabilityBefore.present) {
      map['stability_before'] = Variable<double>(stabilityBefore.value);
    }
    if (stabilityAfter.present) {
      map['stability_after'] = Variable<double>(stabilityAfter.value);
    }
    if (reviewedAt.present) {
      map['reviewed_at'] = Variable<int>(reviewedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewEventsCompanion(')
          ..write('id: $id, ')
          ..write('wordId: $wordId, ')
          ..write('sessionId: $sessionId, ')
          ..write('targetLang: $targetLang, ')
          ..write('rating: $rating, ')
          ..write('responseMs: $responseMs, ')
          ..write('mode: $mode, ')
          ..write('wasCorrect: $wasCorrect, ')
          ..write('stabilityBefore: $stabilityBefore, ')
          ..write('stabilityAfter: $stabilityAfter, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionsTable extends Sessions with TableInfo<$SessionsTable, Session> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _targetLangMeta =
      const VerificationMeta('targetLang');
  @override
  late final GeneratedColumn<String> targetLang = GeneratedColumn<String>(
      'target_lang', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  @override
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
      'mode', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('mcq'));
  static const VerificationMeta _startedAtMeta =
      const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<int> startedAt = GeneratedColumn<int>(
      'started_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _endedAtMeta =
      const VerificationMeta('endedAt');
  @override
  late final GeneratedColumn<int> endedAt = GeneratedColumn<int>(
      'ended_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _totalCardsMeta =
      const VerificationMeta('totalCards');
  @override
  late final GeneratedColumn<int> totalCards = GeneratedColumn<int>(
      'total_cards', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _correctCardsMeta =
      const VerificationMeta('correctCards');
  @override
  late final GeneratedColumn<int> correctCards = GeneratedColumn<int>(
      'correct_cards', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _xpEarnedMeta =
      const VerificationMeta('xpEarned');
  @override
  late final GeneratedColumn<int> xpEarned = GeneratedColumn<int>(
      'xp_earned', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _categoriesJsonMeta =
      const VerificationMeta('categoriesJson');
  @override
  late final GeneratedColumn<String> categoriesJson = GeneratedColumn<String>(
      'categories_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        targetLang,
        mode,
        startedAt,
        endedAt,
        totalCards,
        correctCards,
        xpEarned,
        categoriesJson,
        isSynced
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(Insertable<Session> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('target_lang')) {
      context.handle(
          _targetLangMeta,
          targetLang.isAcceptableOrUnknown(
              data['target_lang']!, _targetLangMeta));
    } else if (isInserting) {
      context.missing(_targetLangMeta);
    }
    if (data.containsKey('mode')) {
      context.handle(
          _modeMeta, mode.isAcceptableOrUnknown(data['mode']!, _modeMeta));
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta,
          startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(_endedAtMeta,
          endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta));
    }
    if (data.containsKey('total_cards')) {
      context.handle(
          _totalCardsMeta,
          totalCards.isAcceptableOrUnknown(
              data['total_cards']!, _totalCardsMeta));
    }
    if (data.containsKey('correct_cards')) {
      context.handle(
          _correctCardsMeta,
          correctCards.isAcceptableOrUnknown(
              data['correct_cards']!, _correctCardsMeta));
    }
    if (data.containsKey('xp_earned')) {
      context.handle(_xpEarnedMeta,
          xpEarned.isAcceptableOrUnknown(data['xp_earned']!, _xpEarnedMeta));
    }
    if (data.containsKey('categories_json')) {
      context.handle(
          _categoriesJsonMeta,
          categoriesJson.isAcceptableOrUnknown(
              data['categories_json']!, _categoriesJsonMeta));
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Session map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Session(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      targetLang: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}target_lang'])!,
      mode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}mode'])!,
      startedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}started_at'])!,
      endedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ended_at']),
      totalCards: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_cards'])!,
      correctCards: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}correct_cards'])!,
      xpEarned: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}xp_earned'])!,
      categoriesJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}categories_json'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class Session extends DataClass implements Insertable<Session> {
  /// UUID — Firestore session doküman ID'si ile aynı.
  final String id;

  /// Hedef dil.
  final String targetLang;

  /// Birincil mod (en çok kullanılan): 'mcq' | 'listening' | 'speaking'
  final String mode;

  /// Oturum başlangıç zamanı (Unix ms).
  final int startedAt;

  /// Oturum bitiş zamanı (Unix ms). null → aktif oturum.
  final int? endedAt;

  /// Toplam gösterilen kart sayısı.
  final int totalCards;

  /// Doğru cevaplanan kart sayısı (rating != again).
  final int correctCards;

  /// Bu oturumda kazanılan XP.
  final int xpEarned;

  /// Seçilen kategoriler — JSON encoded: '["oxford-american/a1","a2"]'
  final String categoriesJson;

  /// Firestore'a sync edildi mi?
  final bool isSynced;
  const Session(
      {required this.id,
      required this.targetLang,
      required this.mode,
      required this.startedAt,
      this.endedAt,
      required this.totalCards,
      required this.correctCards,
      required this.xpEarned,
      required this.categoriesJson,
      required this.isSynced});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['target_lang'] = Variable<String>(targetLang);
    map['mode'] = Variable<String>(mode);
    map['started_at'] = Variable<int>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<int>(endedAt);
    }
    map['total_cards'] = Variable<int>(totalCards);
    map['correct_cards'] = Variable<int>(correctCards);
    map['xp_earned'] = Variable<int>(xpEarned);
    map['categories_json'] = Variable<String>(categoriesJson);
    map['is_synced'] = Variable<bool>(isSynced);
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      targetLang: Value(targetLang),
      mode: Value(mode),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      totalCards: Value(totalCards),
      correctCards: Value(correctCards),
      xpEarned: Value(xpEarned),
      categoriesJson: Value(categoriesJson),
      isSynced: Value(isSynced),
    );
  }

  factory Session.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Session(
      id: serializer.fromJson<String>(json['id']),
      targetLang: serializer.fromJson<String>(json['targetLang']),
      mode: serializer.fromJson<String>(json['mode']),
      startedAt: serializer.fromJson<int>(json['startedAt']),
      endedAt: serializer.fromJson<int?>(json['endedAt']),
      totalCards: serializer.fromJson<int>(json['totalCards']),
      correctCards: serializer.fromJson<int>(json['correctCards']),
      xpEarned: serializer.fromJson<int>(json['xpEarned']),
      categoriesJson: serializer.fromJson<String>(json['categoriesJson']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'targetLang': serializer.toJson<String>(targetLang),
      'mode': serializer.toJson<String>(mode),
      'startedAt': serializer.toJson<int>(startedAt),
      'endedAt': serializer.toJson<int?>(endedAt),
      'totalCards': serializer.toJson<int>(totalCards),
      'correctCards': serializer.toJson<int>(correctCards),
      'xpEarned': serializer.toJson<int>(xpEarned),
      'categoriesJson': serializer.toJson<String>(categoriesJson),
      'isSynced': serializer.toJson<bool>(isSynced),
    };
  }

  Session copyWith(
          {String? id,
          String? targetLang,
          String? mode,
          int? startedAt,
          Value<int?> endedAt = const Value.absent(),
          int? totalCards,
          int? correctCards,
          int? xpEarned,
          String? categoriesJson,
          bool? isSynced}) =>
      Session(
        id: id ?? this.id,
        targetLang: targetLang ?? this.targetLang,
        mode: mode ?? this.mode,
        startedAt: startedAt ?? this.startedAt,
        endedAt: endedAt.present ? endedAt.value : this.endedAt,
        totalCards: totalCards ?? this.totalCards,
        correctCards: correctCards ?? this.correctCards,
        xpEarned: xpEarned ?? this.xpEarned,
        categoriesJson: categoriesJson ?? this.categoriesJson,
        isSynced: isSynced ?? this.isSynced,
      );
  Session copyWithCompanion(SessionsCompanion data) {
    return Session(
      id: data.id.present ? data.id.value : this.id,
      targetLang:
          data.targetLang.present ? data.targetLang.value : this.targetLang,
      mode: data.mode.present ? data.mode.value : this.mode,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      totalCards:
          data.totalCards.present ? data.totalCards.value : this.totalCards,
      correctCards: data.correctCards.present
          ? data.correctCards.value
          : this.correctCards,
      xpEarned: data.xpEarned.present ? data.xpEarned.value : this.xpEarned,
      categoriesJson: data.categoriesJson.present
          ? data.categoriesJson.value
          : this.categoriesJson,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Session(')
          ..write('id: $id, ')
          ..write('targetLang: $targetLang, ')
          ..write('mode: $mode, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('totalCards: $totalCards, ')
          ..write('correctCards: $correctCards, ')
          ..write('xpEarned: $xpEarned, ')
          ..write('categoriesJson: $categoriesJson, ')
          ..write('isSynced: $isSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, targetLang, mode, startedAt, endedAt,
      totalCards, correctCards, xpEarned, categoriesJson, isSynced);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Session &&
          other.id == this.id &&
          other.targetLang == this.targetLang &&
          other.mode == this.mode &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.totalCards == this.totalCards &&
          other.correctCards == this.correctCards &&
          other.xpEarned == this.xpEarned &&
          other.categoriesJson == this.categoriesJson &&
          other.isSynced == this.isSynced);
}

class SessionsCompanion extends UpdateCompanion<Session> {
  final Value<String> id;
  final Value<String> targetLang;
  final Value<String> mode;
  final Value<int> startedAt;
  final Value<int?> endedAt;
  final Value<int> totalCards;
  final Value<int> correctCards;
  final Value<int> xpEarned;
  final Value<String> categoriesJson;
  final Value<bool> isSynced;
  final Value<int> rowid;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.targetLang = const Value.absent(),
    this.mode = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.totalCards = const Value.absent(),
    this.correctCards = const Value.absent(),
    this.xpEarned = const Value.absent(),
    this.categoriesJson = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionsCompanion.insert({
    required String id,
    required String targetLang,
    this.mode = const Value.absent(),
    required int startedAt,
    this.endedAt = const Value.absent(),
    this.totalCards = const Value.absent(),
    this.correctCards = const Value.absent(),
    this.xpEarned = const Value.absent(),
    this.categoriesJson = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        targetLang = Value(targetLang),
        startedAt = Value(startedAt);
  static Insertable<Session> custom({
    Expression<String>? id,
    Expression<String>? targetLang,
    Expression<String>? mode,
    Expression<int>? startedAt,
    Expression<int>? endedAt,
    Expression<int>? totalCards,
    Expression<int>? correctCards,
    Expression<int>? xpEarned,
    Expression<String>? categoriesJson,
    Expression<bool>? isSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (targetLang != null) 'target_lang': targetLang,
      if (mode != null) 'mode': mode,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (totalCards != null) 'total_cards': totalCards,
      if (correctCards != null) 'correct_cards': correctCards,
      if (xpEarned != null) 'xp_earned': xpEarned,
      if (categoriesJson != null) 'categories_json': categoriesJson,
      if (isSynced != null) 'is_synced': isSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? targetLang,
      Value<String>? mode,
      Value<int>? startedAt,
      Value<int?>? endedAt,
      Value<int>? totalCards,
      Value<int>? correctCards,
      Value<int>? xpEarned,
      Value<String>? categoriesJson,
      Value<bool>? isSynced,
      Value<int>? rowid}) {
    return SessionsCompanion(
      id: id ?? this.id,
      targetLang: targetLang ?? this.targetLang,
      mode: mode ?? this.mode,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      totalCards: totalCards ?? this.totalCards,
      correctCards: correctCards ?? this.correctCards,
      xpEarned: xpEarned ?? this.xpEarned,
      categoriesJson: categoriesJson ?? this.categoriesJson,
      isSynced: isSynced ?? this.isSynced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (targetLang.present) {
      map['target_lang'] = Variable<String>(targetLang.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<int>(endedAt.value);
    }
    if (totalCards.present) {
      map['total_cards'] = Variable<int>(totalCards.value);
    }
    if (correctCards.present) {
      map['correct_cards'] = Variable<int>(correctCards.value);
    }
    if (xpEarned.present) {
      map['xp_earned'] = Variable<int>(xpEarned.value);
    }
    if (categoriesJson.present) {
      map['categories_json'] = Variable<String>(categoriesJson.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('targetLang: $targetLang, ')
          ..write('mode: $mode, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('totalCards: $totalCards, ')
          ..write('correctCards: $correctCards, ')
          ..write('xpEarned: $xpEarned, ')
          ..write('categoriesJson: $categoriesJson, ')
          ..write('isSynced: $isSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DailyPlansTable extends DailyPlans
    with TableInfo<$DailyPlansTable, DailyPlan> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyPlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _planDateMeta =
      const VerificationMeta('planDate');
  @override
  late final GeneratedColumn<String> planDate = GeneratedColumn<String>(
      'plan_date', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _targetLangMeta =
      const VerificationMeta('targetLang');
  @override
  late final GeneratedColumn<String> targetLang = GeneratedColumn<String>(
      'target_lang', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cardIdsJsonMeta =
      const VerificationMeta('cardIdsJson');
  @override
  late final GeneratedColumn<String> cardIdsJson = GeneratedColumn<String>(
      'card_ids_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('[]'));
  static const VerificationMeta _totalCardsMeta =
      const VerificationMeta('totalCards');
  @override
  late final GeneratedColumn<int> totalCards = GeneratedColumn<int>(
      'total_cards', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _completedCardsMeta =
      const VerificationMeta('completedCards');
  @override
  late final GeneratedColumn<int> completedCards = GeneratedColumn<int>(
      'completed_cards', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _dueCountMeta =
      const VerificationMeta('dueCount');
  @override
  late final GeneratedColumn<int> dueCount = GeneratedColumn<int>(
      'due_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _newCountMeta =
      const VerificationMeta('newCount');
  @override
  late final GeneratedColumn<int> newCount = GeneratedColumn<int>(
      'new_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _leechCountMeta =
      const VerificationMeta('leechCount');
  @override
  late final GeneratedColumn<int> leechCount = GeneratedColumn<int>(
      'leech_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _estimatedMinutesMeta =
      const VerificationMeta('estimatedMinutes');
  @override
  late final GeneratedColumn<int> estimatedMinutes = GeneratedColumn<int>(
      'estimated_minutes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        planDate,
        targetLang,
        cardIdsJson,
        totalCards,
        completedCards,
        dueCount,
        newCount,
        leechCount,
        createdAt,
        estimatedMinutes
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_plans';
  @override
  VerificationContext validateIntegrity(Insertable<DailyPlan> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('plan_date')) {
      context.handle(_planDateMeta,
          planDate.isAcceptableOrUnknown(data['plan_date']!, _planDateMeta));
    } else if (isInserting) {
      context.missing(_planDateMeta);
    }
    if (data.containsKey('target_lang')) {
      context.handle(
          _targetLangMeta,
          targetLang.isAcceptableOrUnknown(
              data['target_lang']!, _targetLangMeta));
    } else if (isInserting) {
      context.missing(_targetLangMeta);
    }
    if (data.containsKey('card_ids_json')) {
      context.handle(
          _cardIdsJsonMeta,
          cardIdsJson.isAcceptableOrUnknown(
              data['card_ids_json']!, _cardIdsJsonMeta));
    }
    if (data.containsKey('total_cards')) {
      context.handle(
          _totalCardsMeta,
          totalCards.isAcceptableOrUnknown(
              data['total_cards']!, _totalCardsMeta));
    }
    if (data.containsKey('completed_cards')) {
      context.handle(
          _completedCardsMeta,
          completedCards.isAcceptableOrUnknown(
              data['completed_cards']!, _completedCardsMeta));
    }
    if (data.containsKey('due_count')) {
      context.handle(_dueCountMeta,
          dueCount.isAcceptableOrUnknown(data['due_count']!, _dueCountMeta));
    }
    if (data.containsKey('new_count')) {
      context.handle(_newCountMeta,
          newCount.isAcceptableOrUnknown(data['new_count']!, _newCountMeta));
    }
    if (data.containsKey('leech_count')) {
      context.handle(
          _leechCountMeta,
          leechCount.isAcceptableOrUnknown(
              data['leech_count']!, _leechCountMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('estimated_minutes')) {
      context.handle(
          _estimatedMinutesMeta,
          estimatedMinutes.isAcceptableOrUnknown(
              data['estimated_minutes']!, _estimatedMinutesMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {planDate, targetLang};
  @override
  DailyPlan map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyPlan(
      planDate: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}plan_date'])!,
      targetLang: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}target_lang'])!,
      cardIdsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}card_ids_json'])!,
      totalCards: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_cards'])!,
      completedCards: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}completed_cards'])!,
      dueCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}due_count'])!,
      newCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}new_count'])!,
      leechCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}leech_count'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      estimatedMinutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}estimated_minutes'])!,
    );
  }

  @override
  $DailyPlansTable createAlias(String alias) {
    return $DailyPlansTable(attachedDatabase, alias);
  }
}

class DailyPlan extends DataClass implements Insertable<DailyPlan> {
  /// Plan tarihi: 'YYYY-MM-DD' formatında string.
  final String planDate;

  /// Hedef dil.
  final String targetLang;

  /// Planlanan kart ID listesi (sıralı) — JSON encoded: '[1,2,3,...]'
  /// PlanCard nesneleri yerine sadece word_id'ler tutulur (hafif).
  final String cardIdsJson;

  /// Toplam kart sayısı (cardIds.length ile aynı — quick access).
  final int totalCards;

  /// Tamamlanan kart sayısı (session boyunca güncellenir).
  final int completedCards;

  /// Due kart sayısı (plan oluşturulurken snapshot).
  final int dueCount;

  /// Yeni kart sayısı (plan oluşturulurken snapshot).
  final int newCount;

  /// Leech kart sayısı (plan oluşturulurken snapshot).
  final int leechCount;

  /// Plan oluşturulma zamanı (Unix ms).
  final int createdAt;

  /// Tahmini çalışma süresi (dakika). DailyPlanner._estimateMinutes() ile hesaplanır.
  final int estimatedMinutes;
  const DailyPlan(
      {required this.planDate,
      required this.targetLang,
      required this.cardIdsJson,
      required this.totalCards,
      required this.completedCards,
      required this.dueCount,
      required this.newCount,
      required this.leechCount,
      required this.createdAt,
      required this.estimatedMinutes});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['plan_date'] = Variable<String>(planDate);
    map['target_lang'] = Variable<String>(targetLang);
    map['card_ids_json'] = Variable<String>(cardIdsJson);
    map['total_cards'] = Variable<int>(totalCards);
    map['completed_cards'] = Variable<int>(completedCards);
    map['due_count'] = Variable<int>(dueCount);
    map['new_count'] = Variable<int>(newCount);
    map['leech_count'] = Variable<int>(leechCount);
    map['created_at'] = Variable<int>(createdAt);
    map['estimated_minutes'] = Variable<int>(estimatedMinutes);
    return map;
  }

  DailyPlansCompanion toCompanion(bool nullToAbsent) {
    return DailyPlansCompanion(
      planDate: Value(planDate),
      targetLang: Value(targetLang),
      cardIdsJson: Value(cardIdsJson),
      totalCards: Value(totalCards),
      completedCards: Value(completedCards),
      dueCount: Value(dueCount),
      newCount: Value(newCount),
      leechCount: Value(leechCount),
      createdAt: Value(createdAt),
      estimatedMinutes: Value(estimatedMinutes),
    );
  }

  factory DailyPlan.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyPlan(
      planDate: serializer.fromJson<String>(json['planDate']),
      targetLang: serializer.fromJson<String>(json['targetLang']),
      cardIdsJson: serializer.fromJson<String>(json['cardIdsJson']),
      totalCards: serializer.fromJson<int>(json['totalCards']),
      completedCards: serializer.fromJson<int>(json['completedCards']),
      dueCount: serializer.fromJson<int>(json['dueCount']),
      newCount: serializer.fromJson<int>(json['newCount']),
      leechCount: serializer.fromJson<int>(json['leechCount']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      estimatedMinutes: serializer.fromJson<int>(json['estimatedMinutes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'planDate': serializer.toJson<String>(planDate),
      'targetLang': serializer.toJson<String>(targetLang),
      'cardIdsJson': serializer.toJson<String>(cardIdsJson),
      'totalCards': serializer.toJson<int>(totalCards),
      'completedCards': serializer.toJson<int>(completedCards),
      'dueCount': serializer.toJson<int>(dueCount),
      'newCount': serializer.toJson<int>(newCount),
      'leechCount': serializer.toJson<int>(leechCount),
      'createdAt': serializer.toJson<int>(createdAt),
      'estimatedMinutes': serializer.toJson<int>(estimatedMinutes),
    };
  }

  DailyPlan copyWith(
          {String? planDate,
          String? targetLang,
          String? cardIdsJson,
          int? totalCards,
          int? completedCards,
          int? dueCount,
          int? newCount,
          int? leechCount,
          int? createdAt,
          int? estimatedMinutes}) =>
      DailyPlan(
        planDate: planDate ?? this.planDate,
        targetLang: targetLang ?? this.targetLang,
        cardIdsJson: cardIdsJson ?? this.cardIdsJson,
        totalCards: totalCards ?? this.totalCards,
        completedCards: completedCards ?? this.completedCards,
        dueCount: dueCount ?? this.dueCount,
        newCount: newCount ?? this.newCount,
        leechCount: leechCount ?? this.leechCount,
        createdAt: createdAt ?? this.createdAt,
        estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      );
  DailyPlan copyWithCompanion(DailyPlansCompanion data) {
    return DailyPlan(
      planDate: data.planDate.present ? data.planDate.value : this.planDate,
      targetLang:
          data.targetLang.present ? data.targetLang.value : this.targetLang,
      cardIdsJson:
          data.cardIdsJson.present ? data.cardIdsJson.value : this.cardIdsJson,
      totalCards:
          data.totalCards.present ? data.totalCards.value : this.totalCards,
      completedCards: data.completedCards.present
          ? data.completedCards.value
          : this.completedCards,
      dueCount: data.dueCount.present ? data.dueCount.value : this.dueCount,
      newCount: data.newCount.present ? data.newCount.value : this.newCount,
      leechCount:
          data.leechCount.present ? data.leechCount.value : this.leechCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      estimatedMinutes: data.estimatedMinutes.present
          ? data.estimatedMinutes.value
          : this.estimatedMinutes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyPlan(')
          ..write('planDate: $planDate, ')
          ..write('targetLang: $targetLang, ')
          ..write('cardIdsJson: $cardIdsJson, ')
          ..write('totalCards: $totalCards, ')
          ..write('completedCards: $completedCards, ')
          ..write('dueCount: $dueCount, ')
          ..write('newCount: $newCount, ')
          ..write('leechCount: $leechCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('estimatedMinutes: $estimatedMinutes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      planDate,
      targetLang,
      cardIdsJson,
      totalCards,
      completedCards,
      dueCount,
      newCount,
      leechCount,
      createdAt,
      estimatedMinutes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyPlan &&
          other.planDate == this.planDate &&
          other.targetLang == this.targetLang &&
          other.cardIdsJson == this.cardIdsJson &&
          other.totalCards == this.totalCards &&
          other.completedCards == this.completedCards &&
          other.dueCount == this.dueCount &&
          other.newCount == this.newCount &&
          other.leechCount == this.leechCount &&
          other.createdAt == this.createdAt &&
          other.estimatedMinutes == this.estimatedMinutes);
}

class DailyPlansCompanion extends UpdateCompanion<DailyPlan> {
  final Value<String> planDate;
  final Value<String> targetLang;
  final Value<String> cardIdsJson;
  final Value<int> totalCards;
  final Value<int> completedCards;
  final Value<int> dueCount;
  final Value<int> newCount;
  final Value<int> leechCount;
  final Value<int> createdAt;
  final Value<int> estimatedMinutes;
  final Value<int> rowid;
  const DailyPlansCompanion({
    this.planDate = const Value.absent(),
    this.targetLang = const Value.absent(),
    this.cardIdsJson = const Value.absent(),
    this.totalCards = const Value.absent(),
    this.completedCards = const Value.absent(),
    this.dueCount = const Value.absent(),
    this.newCount = const Value.absent(),
    this.leechCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.estimatedMinutes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyPlansCompanion.insert({
    required String planDate,
    required String targetLang,
    this.cardIdsJson = const Value.absent(),
    this.totalCards = const Value.absent(),
    this.completedCards = const Value.absent(),
    this.dueCount = const Value.absent(),
    this.newCount = const Value.absent(),
    this.leechCount = const Value.absent(),
    required int createdAt,
    this.estimatedMinutes = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : planDate = Value(planDate),
        targetLang = Value(targetLang),
        createdAt = Value(createdAt);
  static Insertable<DailyPlan> custom({
    Expression<String>? planDate,
    Expression<String>? targetLang,
    Expression<String>? cardIdsJson,
    Expression<int>? totalCards,
    Expression<int>? completedCards,
    Expression<int>? dueCount,
    Expression<int>? newCount,
    Expression<int>? leechCount,
    Expression<int>? createdAt,
    Expression<int>? estimatedMinutes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (planDate != null) 'plan_date': planDate,
      if (targetLang != null) 'target_lang': targetLang,
      if (cardIdsJson != null) 'card_ids_json': cardIdsJson,
      if (totalCards != null) 'total_cards': totalCards,
      if (completedCards != null) 'completed_cards': completedCards,
      if (dueCount != null) 'due_count': dueCount,
      if (newCount != null) 'new_count': newCount,
      if (leechCount != null) 'leech_count': leechCount,
      if (createdAt != null) 'created_at': createdAt,
      if (estimatedMinutes != null) 'estimated_minutes': estimatedMinutes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyPlansCompanion copyWith(
      {Value<String>? planDate,
      Value<String>? targetLang,
      Value<String>? cardIdsJson,
      Value<int>? totalCards,
      Value<int>? completedCards,
      Value<int>? dueCount,
      Value<int>? newCount,
      Value<int>? leechCount,
      Value<int>? createdAt,
      Value<int>? estimatedMinutes,
      Value<int>? rowid}) {
    return DailyPlansCompanion(
      planDate: planDate ?? this.planDate,
      targetLang: targetLang ?? this.targetLang,
      cardIdsJson: cardIdsJson ?? this.cardIdsJson,
      totalCards: totalCards ?? this.totalCards,
      completedCards: completedCards ?? this.completedCards,
      dueCount: dueCount ?? this.dueCount,
      newCount: newCount ?? this.newCount,
      leechCount: leechCount ?? this.leechCount,
      createdAt: createdAt ?? this.createdAt,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (planDate.present) {
      map['plan_date'] = Variable<String>(planDate.value);
    }
    if (targetLang.present) {
      map['target_lang'] = Variable<String>(targetLang.value);
    }
    if (cardIdsJson.present) {
      map['card_ids_json'] = Variable<String>(cardIdsJson.value);
    }
    if (totalCards.present) {
      map['total_cards'] = Variable<int>(totalCards.value);
    }
    if (completedCards.present) {
      map['completed_cards'] = Variable<int>(completedCards.value);
    }
    if (dueCount.present) {
      map['due_count'] = Variable<int>(dueCount.value);
    }
    if (newCount.present) {
      map['new_count'] = Variable<int>(newCount.value);
    }
    if (leechCount.present) {
      map['leech_count'] = Variable<int>(leechCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (estimatedMinutes.present) {
      map['estimated_minutes'] = Variable<int>(estimatedMinutes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyPlansCompanion(')
          ..write('planDate: $planDate, ')
          ..write('targetLang: $targetLang, ')
          ..write('cardIdsJson: $cardIdsJson, ')
          ..write('totalCards: $totalCards, ')
          ..write('completedCards: $completedCards, ')
          ..write('dueCount: $dueCount, ')
          ..write('newCount: $newCount, ')
          ..write('leechCount: $leechCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('estimatedMinutes: $estimatedMinutes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityTypeMeta =
      const VerificationMeta('entityType');
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
      'entity_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
      'entity_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _operationMeta =
      const VerificationMeta('operation');
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
      'operation', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('upsert'));
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _retryCountMeta =
      const VerificationMeta('retryCount');
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
      'retry_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _lastAttemptAtMeta =
      const VerificationMeta('lastAttemptAt');
  @override
  late final GeneratedColumn<int> lastAttemptAt = GeneratedColumn<int>(
      'last_attempt_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _deletedAtMeta =
      const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
      'deleted_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        entityType,
        entityId,
        operation,
        payloadJson,
        retryCount,
        createdAt,
        lastAttemptAt,
        deletedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(Insertable<SyncQueueData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
          _entityTypeMeta,
          entityType.isAcceptableOrUnknown(
              data['entity_type']!, _entityTypeMeta));
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta));
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(_operationMeta,
          operation.isAcceptableOrUnknown(data['operation']!, _operationMeta));
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
          _retryCountMeta,
          retryCount.isAcceptableOrUnknown(
              data['retry_count']!, _retryCountMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
          _lastAttemptAtMeta,
          lastAttemptAt.isAcceptableOrUnknown(
              data['last_attempt_at']!, _lastAttemptAtMeta));
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta,
          deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      entityType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_type'])!,
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_id'])!,
      operation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}operation'])!,
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
      retryCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}retry_count'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      lastAttemptAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_attempt_at']),
      deletedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}deleted_at']),
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueData extends DataClass implements Insertable<SyncQueueData> {
  /// UUID.
  final String id;

  /// Hangi varlık tipi: 'progress' | 'session'
  final String entityType;

  /// İlgili kaydın ID'si.
  /// progress → 'wordId:targetLang' formatı
  /// session → sessionId
  final String entityId;

  /// İşlem tipi: 'upsert' | 'delete'
  final String operation;

  /// Firestore'a gönderilecek payload — JSON encoded.
  final String payloadJson;

  /// Kaç kez denendi (max 5 — R-05 mitigation).
  final int retryCount;

  /// Kuyruğa eklenme zamanı (Unix ms).
  final int createdAt;

  /// Son deneme zamanı (Unix ms). null → henüz denenmedi.
  final int? lastAttemptAt;

  /// Soft-delete: retry >= 5 olduğunda set edilir.
  /// SyncManager bu kayıtları işlemez, kullanıcıya toast gösterilir.
  final int? deletedAt;
  const SyncQueueData(
      {required this.id,
      required this.entityType,
      required this.entityId,
      required this.operation,
      required this.payloadJson,
      required this.retryCount,
      required this.createdAt,
      this.lastAttemptAt,
      this.deletedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['operation'] = Variable<String>(operation);
    map['payload_json'] = Variable<String>(payloadJson);
    map['retry_count'] = Variable<int>(retryCount);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<int>(lastAttemptAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      entityType: Value(entityType),
      entityId: Value(entityId),
      operation: Value(operation),
      payloadJson: Value(payloadJson),
      retryCount: Value(retryCount),
      createdAt: Value(createdAt),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory SyncQueueData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueData(
      id: serializer.fromJson<String>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      operation: serializer.fromJson<String>(json['operation']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      lastAttemptAt: serializer.fromJson<int?>(json['lastAttemptAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'operation': serializer.toJson<String>(operation),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'retryCount': serializer.toJson<int>(retryCount),
      'createdAt': serializer.toJson<int>(createdAt),
      'lastAttemptAt': serializer.toJson<int?>(lastAttemptAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  SyncQueueData copyWith(
          {String? id,
          String? entityType,
          String? entityId,
          String? operation,
          String? payloadJson,
          int? retryCount,
          int? createdAt,
          Value<int?> lastAttemptAt = const Value.absent(),
          Value<int?> deletedAt = const Value.absent()}) =>
      SyncQueueData(
        id: id ?? this.id,
        entityType: entityType ?? this.entityType,
        entityId: entityId ?? this.entityId,
        operation: operation ?? this.operation,
        payloadJson: payloadJson ?? this.payloadJson,
        retryCount: retryCount ?? this.retryCount,
        createdAt: createdAt ?? this.createdAt,
        lastAttemptAt:
            lastAttemptAt.present ? lastAttemptAt.value : this.lastAttemptAt,
        deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
      );
  SyncQueueData copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueData(
      id: data.id.present ? data.id.value : this.id,
      entityType:
          data.entityType.present ? data.entityType.value : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      operation: data.operation.present ? data.operation.value : this.operation,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      retryCount:
          data.retryCount.present ? data.retryCount.value : this.retryCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueData(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, entityType, entityId, operation,
      payloadJson, retryCount, createdAt, lastAttemptAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueData &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.operation == this.operation &&
          other.payloadJson == this.payloadJson &&
          other.retryCount == this.retryCount &&
          other.createdAt == this.createdAt &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.deletedAt == this.deletedAt);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueData> {
  final Value<String> id;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> operation;
  final Value<String> payloadJson;
  final Value<int> retryCount;
  final Value<int> createdAt;
  final Value<int?> lastAttemptAt;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.operation = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    required String id,
    required String entityType,
    required String entityId,
    this.operation = const Value.absent(),
    required String payloadJson,
    this.retryCount = const Value.absent(),
    required int createdAt,
    this.lastAttemptAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        entityType = Value(entityType),
        entityId = Value(entityId),
        payloadJson = Value(payloadJson),
        createdAt = Value(createdAt);
  static Insertable<SyncQueueData> custom({
    Expression<String>? id,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? operation,
    Expression<String>? payloadJson,
    Expression<int>? retryCount,
    Expression<int>? createdAt,
    Expression<int>? lastAttemptAt,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (operation != null) 'operation': operation,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (retryCount != null) 'retry_count': retryCount,
      if (createdAt != null) 'created_at': createdAt,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncQueueCompanion copyWith(
      {Value<String>? id,
      Value<String>? entityType,
      Value<String>? entityId,
      Value<String>? operation,
      Value<String>? payloadJson,
      Value<int>? retryCount,
      Value<int>? createdAt,
      Value<int?>? lastAttemptAt,
      Value<int?>? deletedAt,
      Value<int>? rowid}) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      payloadJson: payloadJson ?? this.payloadJson,
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt ?? this.createdAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<int>(lastAttemptAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('operation: $operation, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $WordsTable words = $WordsTable(this);
  late final $ProgressTable progress = $ProgressTable(this);
  late final $ReviewEventsTable reviewEvents = $ReviewEventsTable(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $DailyPlansTable dailyPlans = $DailyPlansTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final WordDao wordDao = WordDao(this as AppDatabase);
  late final ProgressDao progressDao = ProgressDao(this as AppDatabase);
  late final ReviewEventDao reviewEventDao =
      ReviewEventDao(this as AppDatabase);
  late final SessionDao sessionDao = SessionDao(this as AppDatabase);
  late final DailyPlanDao dailyPlanDao = DailyPlanDao(this as AppDatabase);
  late final SyncQueueDao syncQueueDao = SyncQueueDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [words, progress, reviewEvents, sessions, dailyPlans, syncQueue];
}

typedef $$WordsTableCreateCompanionBuilder = WordsCompanion Function({
  Value<int> id,
  Value<String> partOfSpeech,
  Value<String?> transcription,
  Value<String> categoriesJson,
  Value<String> contentJson,
  Value<String> sentencesJson,
  Value<int> difficultyRank,
});
typedef $$WordsTableUpdateCompanionBuilder = WordsCompanion Function({
  Value<int> id,
  Value<String> partOfSpeech,
  Value<String?> transcription,
  Value<String> categoriesJson,
  Value<String> contentJson,
  Value<String> sentencesJson,
  Value<int> difficultyRank,
});

final class $$WordsTableReferences
    extends BaseReferences<_$AppDatabase, $WordsTable, Word> {
  $$WordsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ProgressTable, List<ProgressData>>
      _progressRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.progress,
              aliasName: $_aliasNameGenerator(db.words.id, db.progress.wordId));

  $$ProgressTableProcessedTableManager get progressRefs {
    final manager = $$ProgressTableTableManager($_db, $_db.progress)
        .filter((f) => f.wordId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_progressRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ReviewEventsTable, List<ReviewEvent>>
      _reviewEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.reviewEvents,
          aliasName: $_aliasNameGenerator(db.words.id, db.reviewEvents.wordId));

  $$ReviewEventsTableProcessedTableManager get reviewEventsRefs {
    final manager = $$ReviewEventsTableTableManager($_db, $_db.reviewEvents)
        .filter((f) => f.wordId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_reviewEventsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$WordsTableFilterComposer extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get partOfSpeech => $composableBuilder(
      column: $table.partOfSpeech, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get transcription => $composableBuilder(
      column: $table.transcription, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoriesJson => $composableBuilder(
      column: $table.categoriesJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contentJson => $composableBuilder(
      column: $table.contentJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sentencesJson => $composableBuilder(
      column: $table.sentencesJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get difficultyRank => $composableBuilder(
      column: $table.difficultyRank,
      builder: (column) => ColumnFilters(column));

  Expression<bool> progressRefs(
      Expression<bool> Function($$ProgressTableFilterComposer f) f) {
    final $$ProgressTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.progress,
        getReferencedColumn: (t) => t.wordId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProgressTableFilterComposer(
              $db: $db,
              $table: $db.progress,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> reviewEventsRefs(
      Expression<bool> Function($$ReviewEventsTableFilterComposer f) f) {
    final $$ReviewEventsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.reviewEvents,
        getReferencedColumn: (t) => t.wordId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ReviewEventsTableFilterComposer(
              $db: $db,
              $table: $db.reviewEvents,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$WordsTableOrderingComposer
    extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get partOfSpeech => $composableBuilder(
      column: $table.partOfSpeech,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get transcription => $composableBuilder(
      column: $table.transcription,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoriesJson => $composableBuilder(
      column: $table.categoriesJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contentJson => $composableBuilder(
      column: $table.contentJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sentencesJson => $composableBuilder(
      column: $table.sentencesJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get difficultyRank => $composableBuilder(
      column: $table.difficultyRank,
      builder: (column) => ColumnOrderings(column));
}

class $$WordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordsTable> {
  $$WordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get partOfSpeech => $composableBuilder(
      column: $table.partOfSpeech, builder: (column) => column);

  GeneratedColumn<String> get transcription => $composableBuilder(
      column: $table.transcription, builder: (column) => column);

  GeneratedColumn<String> get categoriesJson => $composableBuilder(
      column: $table.categoriesJson, builder: (column) => column);

  GeneratedColumn<String> get contentJson => $composableBuilder(
      column: $table.contentJson, builder: (column) => column);

  GeneratedColumn<String> get sentencesJson => $composableBuilder(
      column: $table.sentencesJson, builder: (column) => column);

  GeneratedColumn<int> get difficultyRank => $composableBuilder(
      column: $table.difficultyRank, builder: (column) => column);

  Expression<T> progressRefs<T extends Object>(
      Expression<T> Function($$ProgressTableAnnotationComposer a) f) {
    final $$ProgressTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.progress,
        getReferencedColumn: (t) => t.wordId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProgressTableAnnotationComposer(
              $db: $db,
              $table: $db.progress,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> reviewEventsRefs<T extends Object>(
      Expression<T> Function($$ReviewEventsTableAnnotationComposer a) f) {
    final $$ReviewEventsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.reviewEvents,
        getReferencedColumn: (t) => t.wordId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ReviewEventsTableAnnotationComposer(
              $db: $db,
              $table: $db.reviewEvents,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$WordsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WordsTable,
    Word,
    $$WordsTableFilterComposer,
    $$WordsTableOrderingComposer,
    $$WordsTableAnnotationComposer,
    $$WordsTableCreateCompanionBuilder,
    $$WordsTableUpdateCompanionBuilder,
    (Word, $$WordsTableReferences),
    Word,
    PrefetchHooks Function({bool progressRefs, bool reviewEventsRefs})> {
  $$WordsTableTableManager(_$AppDatabase db, $WordsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> partOfSpeech = const Value.absent(),
            Value<String?> transcription = const Value.absent(),
            Value<String> categoriesJson = const Value.absent(),
            Value<String> contentJson = const Value.absent(),
            Value<String> sentencesJson = const Value.absent(),
            Value<int> difficultyRank = const Value.absent(),
          }) =>
              WordsCompanion(
            id: id,
            partOfSpeech: partOfSpeech,
            transcription: transcription,
            categoriesJson: categoriesJson,
            contentJson: contentJson,
            sentencesJson: sentencesJson,
            difficultyRank: difficultyRank,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> partOfSpeech = const Value.absent(),
            Value<String?> transcription = const Value.absent(),
            Value<String> categoriesJson = const Value.absent(),
            Value<String> contentJson = const Value.absent(),
            Value<String> sentencesJson = const Value.absent(),
            Value<int> difficultyRank = const Value.absent(),
          }) =>
              WordsCompanion.insert(
            id: id,
            partOfSpeech: partOfSpeech,
            transcription: transcription,
            categoriesJson: categoriesJson,
            contentJson: contentJson,
            sentencesJson: sentencesJson,
            difficultyRank: difficultyRank,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$WordsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {progressRefs = false, reviewEventsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (progressRefs) db.progress,
                if (reviewEventsRefs) db.reviewEvents
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (progressRefs)
                    await $_getPrefetchedData<Word, $WordsTable, ProgressData>(
                        currentTable: table,
                        referencedTable:
                            $$WordsTableReferences._progressRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$WordsTableReferences(db, table, p0).progressRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.wordId == item.id),
                        typedResults: items),
                  if (reviewEventsRefs)
                    await $_getPrefetchedData<Word, $WordsTable, ReviewEvent>(
                        currentTable: table,
                        referencedTable:
                            $$WordsTableReferences._reviewEventsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$WordsTableReferences(db, table, p0)
                                .reviewEventsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.wordId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$WordsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WordsTable,
    Word,
    $$WordsTableFilterComposer,
    $$WordsTableOrderingComposer,
    $$WordsTableAnnotationComposer,
    $$WordsTableCreateCompanionBuilder,
    $$WordsTableUpdateCompanionBuilder,
    (Word, $$WordsTableReferences),
    Word,
    PrefetchHooks Function({bool progressRefs, bool reviewEventsRefs})>;
typedef $$ProgressTableCreateCompanionBuilder = ProgressCompanion Function({
  required int wordId,
  required String targetLang,
  Value<double> stability,
  Value<double> difficulty,
  Value<String> cardState,
  Value<int> nextReviewMs,
  Value<int> lastReviewMs,
  Value<int> lapses,
  Value<int> repetitions,
  Value<bool> isLeech,
  Value<bool> isSuspended,
  Value<String> modeHistoryJson,
  Value<int> updatedAt,
  Value<int> rowid,
});
typedef $$ProgressTableUpdateCompanionBuilder = ProgressCompanion Function({
  Value<int> wordId,
  Value<String> targetLang,
  Value<double> stability,
  Value<double> difficulty,
  Value<String> cardState,
  Value<int> nextReviewMs,
  Value<int> lastReviewMs,
  Value<int> lapses,
  Value<int> repetitions,
  Value<bool> isLeech,
  Value<bool> isSuspended,
  Value<String> modeHistoryJson,
  Value<int> updatedAt,
  Value<int> rowid,
});

final class $$ProgressTableReferences
    extends BaseReferences<_$AppDatabase, $ProgressTable, ProgressData> {
  $$ProgressTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WordsTable _wordIdTable(_$AppDatabase db) => db.words
      .createAlias($_aliasNameGenerator(db.progress.wordId, db.words.id));

  $$WordsTableProcessedTableManager get wordId {
    final $_column = $_itemColumn<int>('word_id')!;

    final manager = $$WordsTableTableManager($_db, $_db.words)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_wordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ProgressTableFilterComposer
    extends Composer<_$AppDatabase, $ProgressTable> {
  $$ProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get targetLang => $composableBuilder(
      column: $table.targetLang, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get stability => $composableBuilder(
      column: $table.stability, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cardState => $composableBuilder(
      column: $table.cardState, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get nextReviewMs => $composableBuilder(
      column: $table.nextReviewMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastReviewMs => $composableBuilder(
      column: $table.lastReviewMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lapses => $composableBuilder(
      column: $table.lapses, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get repetitions => $composableBuilder(
      column: $table.repetitions, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isLeech => $composableBuilder(
      column: $table.isLeech, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSuspended => $composableBuilder(
      column: $table.isSuspended, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get modeHistoryJson => $composableBuilder(
      column: $table.modeHistoryJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$WordsTableFilterComposer get wordId {
    final $$WordsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.wordId,
        referencedTable: $db.words,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WordsTableFilterComposer(
              $db: $db,
              $table: $db.words,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $ProgressTable> {
  $$ProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get targetLang => $composableBuilder(
      column: $table.targetLang, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get stability => $composableBuilder(
      column: $table.stability, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cardState => $composableBuilder(
      column: $table.cardState, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get nextReviewMs => $composableBuilder(
      column: $table.nextReviewMs,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastReviewMs => $composableBuilder(
      column: $table.lastReviewMs,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lapses => $composableBuilder(
      column: $table.lapses, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get repetitions => $composableBuilder(
      column: $table.repetitions, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isLeech => $composableBuilder(
      column: $table.isLeech, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSuspended => $composableBuilder(
      column: $table.isSuspended, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get modeHistoryJson => $composableBuilder(
      column: $table.modeHistoryJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$WordsTableOrderingComposer get wordId {
    final $$WordsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.wordId,
        referencedTable: $db.words,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WordsTableOrderingComposer(
              $db: $db,
              $table: $db.words,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProgressTable> {
  $$ProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get targetLang => $composableBuilder(
      column: $table.targetLang, builder: (column) => column);

  GeneratedColumn<double> get stability =>
      $composableBuilder(column: $table.stability, builder: (column) => column);

  GeneratedColumn<double> get difficulty => $composableBuilder(
      column: $table.difficulty, builder: (column) => column);

  GeneratedColumn<String> get cardState =>
      $composableBuilder(column: $table.cardState, builder: (column) => column);

  GeneratedColumn<int> get nextReviewMs => $composableBuilder(
      column: $table.nextReviewMs, builder: (column) => column);

  GeneratedColumn<int> get lastReviewMs => $composableBuilder(
      column: $table.lastReviewMs, builder: (column) => column);

  GeneratedColumn<int> get lapses =>
      $composableBuilder(column: $table.lapses, builder: (column) => column);

  GeneratedColumn<int> get repetitions => $composableBuilder(
      column: $table.repetitions, builder: (column) => column);

  GeneratedColumn<bool> get isLeech =>
      $composableBuilder(column: $table.isLeech, builder: (column) => column);

  GeneratedColumn<bool> get isSuspended => $composableBuilder(
      column: $table.isSuspended, builder: (column) => column);

  GeneratedColumn<String> get modeHistoryJson => $composableBuilder(
      column: $table.modeHistoryJson, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$WordsTableAnnotationComposer get wordId {
    final $$WordsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.wordId,
        referencedTable: $db.words,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WordsTableAnnotationComposer(
              $db: $db,
              $table: $db.words,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ProgressTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProgressTable,
    ProgressData,
    $$ProgressTableFilterComposer,
    $$ProgressTableOrderingComposer,
    $$ProgressTableAnnotationComposer,
    $$ProgressTableCreateCompanionBuilder,
    $$ProgressTableUpdateCompanionBuilder,
    (ProgressData, $$ProgressTableReferences),
    ProgressData,
    PrefetchHooks Function({bool wordId})> {
  $$ProgressTableTableManager(_$AppDatabase db, $ProgressTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> wordId = const Value.absent(),
            Value<String> targetLang = const Value.absent(),
            Value<double> stability = const Value.absent(),
            Value<double> difficulty = const Value.absent(),
            Value<String> cardState = const Value.absent(),
            Value<int> nextReviewMs = const Value.absent(),
            Value<int> lastReviewMs = const Value.absent(),
            Value<int> lapses = const Value.absent(),
            Value<int> repetitions = const Value.absent(),
            Value<bool> isLeech = const Value.absent(),
            Value<bool> isSuspended = const Value.absent(),
            Value<String> modeHistoryJson = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProgressCompanion(
            wordId: wordId,
            targetLang: targetLang,
            stability: stability,
            difficulty: difficulty,
            cardState: cardState,
            nextReviewMs: nextReviewMs,
            lastReviewMs: lastReviewMs,
            lapses: lapses,
            repetitions: repetitions,
            isLeech: isLeech,
            isSuspended: isSuspended,
            modeHistoryJson: modeHistoryJson,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int wordId,
            required String targetLang,
            Value<double> stability = const Value.absent(),
            Value<double> difficulty = const Value.absent(),
            Value<String> cardState = const Value.absent(),
            Value<int> nextReviewMs = const Value.absent(),
            Value<int> lastReviewMs = const Value.absent(),
            Value<int> lapses = const Value.absent(),
            Value<int> repetitions = const Value.absent(),
            Value<bool> isLeech = const Value.absent(),
            Value<bool> isSuspended = const Value.absent(),
            Value<String> modeHistoryJson = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProgressCompanion.insert(
            wordId: wordId,
            targetLang: targetLang,
            stability: stability,
            difficulty: difficulty,
            cardState: cardState,
            nextReviewMs: nextReviewMs,
            lastReviewMs: lastReviewMs,
            lapses: lapses,
            repetitions: repetitions,
            isLeech: isLeech,
            isSuspended: isSuspended,
            modeHistoryJson: modeHistoryJson,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ProgressTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({wordId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (wordId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.wordId,
                    referencedTable: $$ProgressTableReferences._wordIdTable(db),
                    referencedColumn:
                        $$ProgressTableReferences._wordIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ProgressTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProgressTable,
    ProgressData,
    $$ProgressTableFilterComposer,
    $$ProgressTableOrderingComposer,
    $$ProgressTableAnnotationComposer,
    $$ProgressTableCreateCompanionBuilder,
    $$ProgressTableUpdateCompanionBuilder,
    (ProgressData, $$ProgressTableReferences),
    ProgressData,
    PrefetchHooks Function({bool wordId})>;
typedef $$ReviewEventsTableCreateCompanionBuilder = ReviewEventsCompanion
    Function({
  required String id,
  required int wordId,
  required String sessionId,
  required String targetLang,
  required String rating,
  required int responseMs,
  required String mode,
  required bool wasCorrect,
  required double stabilityBefore,
  required double stabilityAfter,
  required int reviewedAt,
  Value<int> rowid,
});
typedef $$ReviewEventsTableUpdateCompanionBuilder = ReviewEventsCompanion
    Function({
  Value<String> id,
  Value<int> wordId,
  Value<String> sessionId,
  Value<String> targetLang,
  Value<String> rating,
  Value<int> responseMs,
  Value<String> mode,
  Value<bool> wasCorrect,
  Value<double> stabilityBefore,
  Value<double> stabilityAfter,
  Value<int> reviewedAt,
  Value<int> rowid,
});

final class $$ReviewEventsTableReferences
    extends BaseReferences<_$AppDatabase, $ReviewEventsTable, ReviewEvent> {
  $$ReviewEventsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WordsTable _wordIdTable(_$AppDatabase db) => db.words
      .createAlias($_aliasNameGenerator(db.reviewEvents.wordId, db.words.id));

  $$WordsTableProcessedTableManager get wordId {
    final $_column = $_itemColumn<int>('word_id')!;

    final manager = $$WordsTableTableManager($_db, $_db.words)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_wordIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ReviewEventsTableFilterComposer
    extends Composer<_$AppDatabase, $ReviewEventsTable> {
  $$ReviewEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sessionId => $composableBuilder(
      column: $table.sessionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get targetLang => $composableBuilder(
      column: $table.targetLang, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rating => $composableBuilder(
      column: $table.rating, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get responseMs => $composableBuilder(
      column: $table.responseMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mode => $composableBuilder(
      column: $table.mode, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get wasCorrect => $composableBuilder(
      column: $table.wasCorrect, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get stabilityBefore => $composableBuilder(
      column: $table.stabilityBefore,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get stabilityAfter => $composableBuilder(
      column: $table.stabilityAfter,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reviewedAt => $composableBuilder(
      column: $table.reviewedAt, builder: (column) => ColumnFilters(column));

  $$WordsTableFilterComposer get wordId {
    final $$WordsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.wordId,
        referencedTable: $db.words,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WordsTableFilterComposer(
              $db: $db,
              $table: $db.words,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReviewEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReviewEventsTable> {
  $$ReviewEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sessionId => $composableBuilder(
      column: $table.sessionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get targetLang => $composableBuilder(
      column: $table.targetLang, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rating => $composableBuilder(
      column: $table.rating, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get responseMs => $composableBuilder(
      column: $table.responseMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mode => $composableBuilder(
      column: $table.mode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get wasCorrect => $composableBuilder(
      column: $table.wasCorrect, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get stabilityBefore => $composableBuilder(
      column: $table.stabilityBefore,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get stabilityAfter => $composableBuilder(
      column: $table.stabilityAfter,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reviewedAt => $composableBuilder(
      column: $table.reviewedAt, builder: (column) => ColumnOrderings(column));

  $$WordsTableOrderingComposer get wordId {
    final $$WordsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.wordId,
        referencedTable: $db.words,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WordsTableOrderingComposer(
              $db: $db,
              $table: $db.words,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReviewEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReviewEventsTable> {
  $$ReviewEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get targetLang => $composableBuilder(
      column: $table.targetLang, builder: (column) => column);

  GeneratedColumn<String> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<int> get responseMs => $composableBuilder(
      column: $table.responseMs, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<bool> get wasCorrect => $composableBuilder(
      column: $table.wasCorrect, builder: (column) => column);

  GeneratedColumn<double> get stabilityBefore => $composableBuilder(
      column: $table.stabilityBefore, builder: (column) => column);

  GeneratedColumn<double> get stabilityAfter => $composableBuilder(
      column: $table.stabilityAfter, builder: (column) => column);

  GeneratedColumn<int> get reviewedAt => $composableBuilder(
      column: $table.reviewedAt, builder: (column) => column);

  $$WordsTableAnnotationComposer get wordId {
    final $$WordsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.wordId,
        referencedTable: $db.words,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$WordsTableAnnotationComposer(
              $db: $db,
              $table: $db.words,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ReviewEventsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ReviewEventsTable,
    ReviewEvent,
    $$ReviewEventsTableFilterComposer,
    $$ReviewEventsTableOrderingComposer,
    $$ReviewEventsTableAnnotationComposer,
    $$ReviewEventsTableCreateCompanionBuilder,
    $$ReviewEventsTableUpdateCompanionBuilder,
    (ReviewEvent, $$ReviewEventsTableReferences),
    ReviewEvent,
    PrefetchHooks Function({bool wordId})> {
  $$ReviewEventsTableTableManager(_$AppDatabase db, $ReviewEventsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<int> wordId = const Value.absent(),
            Value<String> sessionId = const Value.absent(),
            Value<String> targetLang = const Value.absent(),
            Value<String> rating = const Value.absent(),
            Value<int> responseMs = const Value.absent(),
            Value<String> mode = const Value.absent(),
            Value<bool> wasCorrect = const Value.absent(),
            Value<double> stabilityBefore = const Value.absent(),
            Value<double> stabilityAfter = const Value.absent(),
            Value<int> reviewedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ReviewEventsCompanion(
            id: id,
            wordId: wordId,
            sessionId: sessionId,
            targetLang: targetLang,
            rating: rating,
            responseMs: responseMs,
            mode: mode,
            wasCorrect: wasCorrect,
            stabilityBefore: stabilityBefore,
            stabilityAfter: stabilityAfter,
            reviewedAt: reviewedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required int wordId,
            required String sessionId,
            required String targetLang,
            required String rating,
            required int responseMs,
            required String mode,
            required bool wasCorrect,
            required double stabilityBefore,
            required double stabilityAfter,
            required int reviewedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ReviewEventsCompanion.insert(
            id: id,
            wordId: wordId,
            sessionId: sessionId,
            targetLang: targetLang,
            rating: rating,
            responseMs: responseMs,
            mode: mode,
            wasCorrect: wasCorrect,
            stabilityBefore: stabilityBefore,
            stabilityAfter: stabilityAfter,
            reviewedAt: reviewedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ReviewEventsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({wordId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (wordId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.wordId,
                    referencedTable:
                        $$ReviewEventsTableReferences._wordIdTable(db),
                    referencedColumn:
                        $$ReviewEventsTableReferences._wordIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ReviewEventsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ReviewEventsTable,
    ReviewEvent,
    $$ReviewEventsTableFilterComposer,
    $$ReviewEventsTableOrderingComposer,
    $$ReviewEventsTableAnnotationComposer,
    $$ReviewEventsTableCreateCompanionBuilder,
    $$ReviewEventsTableUpdateCompanionBuilder,
    (ReviewEvent, $$ReviewEventsTableReferences),
    ReviewEvent,
    PrefetchHooks Function({bool wordId})>;
typedef $$SessionsTableCreateCompanionBuilder = SessionsCompanion Function({
  required String id,
  required String targetLang,
  Value<String> mode,
  required int startedAt,
  Value<int?> endedAt,
  Value<int> totalCards,
  Value<int> correctCards,
  Value<int> xpEarned,
  Value<String> categoriesJson,
  Value<bool> isSynced,
  Value<int> rowid,
});
typedef $$SessionsTableUpdateCompanionBuilder = SessionsCompanion Function({
  Value<String> id,
  Value<String> targetLang,
  Value<String> mode,
  Value<int> startedAt,
  Value<int?> endedAt,
  Value<int> totalCards,
  Value<int> correctCards,
  Value<int> xpEarned,
  Value<String> categoriesJson,
  Value<bool> isSynced,
  Value<int> rowid,
});

class $$SessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get targetLang => $composableBuilder(
      column: $table.targetLang, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mode => $composableBuilder(
      column: $table.mode, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get endedAt => $composableBuilder(
      column: $table.endedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalCards => $composableBuilder(
      column: $table.totalCards, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get correctCards => $composableBuilder(
      column: $table.correctCards, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get xpEarned => $composableBuilder(
      column: $table.xpEarned, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoriesJson => $composableBuilder(
      column: $table.categoriesJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get targetLang => $composableBuilder(
      column: $table.targetLang, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mode => $composableBuilder(
      column: $table.mode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get endedAt => $composableBuilder(
      column: $table.endedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalCards => $composableBuilder(
      column: $table.totalCards, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get correctCards => $composableBuilder(
      column: $table.correctCards,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get xpEarned => $composableBuilder(
      column: $table.xpEarned, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoriesJson => $composableBuilder(
      column: $table.categoriesJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get targetLang => $composableBuilder(
      column: $table.targetLang, builder: (column) => column);

  GeneratedColumn<String> get mode =>
      $composableBuilder(column: $table.mode, builder: (column) => column);

  GeneratedColumn<int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get totalCards => $composableBuilder(
      column: $table.totalCards, builder: (column) => column);

  GeneratedColumn<int> get correctCards => $composableBuilder(
      column: $table.correctCards, builder: (column) => column);

  GeneratedColumn<int> get xpEarned =>
      $composableBuilder(column: $table.xpEarned, builder: (column) => column);

  GeneratedColumn<String> get categoriesJson => $composableBuilder(
      column: $table.categoriesJson, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);
}

class $$SessionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SessionsTable,
    Session,
    $$SessionsTableFilterComposer,
    $$SessionsTableOrderingComposer,
    $$SessionsTableAnnotationComposer,
    $$SessionsTableCreateCompanionBuilder,
    $$SessionsTableUpdateCompanionBuilder,
    (Session, BaseReferences<_$AppDatabase, $SessionsTable, Session>),
    Session,
    PrefetchHooks Function()> {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> targetLang = const Value.absent(),
            Value<String> mode = const Value.absent(),
            Value<int> startedAt = const Value.absent(),
            Value<int?> endedAt = const Value.absent(),
            Value<int> totalCards = const Value.absent(),
            Value<int> correctCards = const Value.absent(),
            Value<int> xpEarned = const Value.absent(),
            Value<String> categoriesJson = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SessionsCompanion(
            id: id,
            targetLang: targetLang,
            mode: mode,
            startedAt: startedAt,
            endedAt: endedAt,
            totalCards: totalCards,
            correctCards: correctCards,
            xpEarned: xpEarned,
            categoriesJson: categoriesJson,
            isSynced: isSynced,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String targetLang,
            Value<String> mode = const Value.absent(),
            required int startedAt,
            Value<int?> endedAt = const Value.absent(),
            Value<int> totalCards = const Value.absent(),
            Value<int> correctCards = const Value.absent(),
            Value<int> xpEarned = const Value.absent(),
            Value<String> categoriesJson = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SessionsCompanion.insert(
            id: id,
            targetLang: targetLang,
            mode: mode,
            startedAt: startedAt,
            endedAt: endedAt,
            totalCards: totalCards,
            correctCards: correctCards,
            xpEarned: xpEarned,
            categoriesJson: categoriesJson,
            isSynced: isSynced,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SessionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SessionsTable,
    Session,
    $$SessionsTableFilterComposer,
    $$SessionsTableOrderingComposer,
    $$SessionsTableAnnotationComposer,
    $$SessionsTableCreateCompanionBuilder,
    $$SessionsTableUpdateCompanionBuilder,
    (Session, BaseReferences<_$AppDatabase, $SessionsTable, Session>),
    Session,
    PrefetchHooks Function()>;
typedef $$DailyPlansTableCreateCompanionBuilder = DailyPlansCompanion Function({
  required String planDate,
  required String targetLang,
  Value<String> cardIdsJson,
  Value<int> totalCards,
  Value<int> completedCards,
  Value<int> dueCount,
  Value<int> newCount,
  Value<int> leechCount,
  required int createdAt,
  Value<int> estimatedMinutes,
  Value<int> rowid,
});
typedef $$DailyPlansTableUpdateCompanionBuilder = DailyPlansCompanion Function({
  Value<String> planDate,
  Value<String> targetLang,
  Value<String> cardIdsJson,
  Value<int> totalCards,
  Value<int> completedCards,
  Value<int> dueCount,
  Value<int> newCount,
  Value<int> leechCount,
  Value<int> createdAt,
  Value<int> estimatedMinutes,
  Value<int> rowid,
});

class $$DailyPlansTableFilterComposer
    extends Composer<_$AppDatabase, $DailyPlansTable> {
  $$DailyPlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get planDate => $composableBuilder(
      column: $table.planDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get targetLang => $composableBuilder(
      column: $table.targetLang, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cardIdsJson => $composableBuilder(
      column: $table.cardIdsJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalCards => $composableBuilder(
      column: $table.totalCards, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get completedCards => $composableBuilder(
      column: $table.completedCards,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get dueCount => $composableBuilder(
      column: $table.dueCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get newCount => $composableBuilder(
      column: $table.newCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get leechCount => $composableBuilder(
      column: $table.leechCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get estimatedMinutes => $composableBuilder(
      column: $table.estimatedMinutes,
      builder: (column) => ColumnFilters(column));
}

class $$DailyPlansTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyPlansTable> {
  $$DailyPlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get planDate => $composableBuilder(
      column: $table.planDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get targetLang => $composableBuilder(
      column: $table.targetLang, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cardIdsJson => $composableBuilder(
      column: $table.cardIdsJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalCards => $composableBuilder(
      column: $table.totalCards, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get completedCards => $composableBuilder(
      column: $table.completedCards,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get dueCount => $composableBuilder(
      column: $table.dueCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get newCount => $composableBuilder(
      column: $table.newCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get leechCount => $composableBuilder(
      column: $table.leechCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get estimatedMinutes => $composableBuilder(
      column: $table.estimatedMinutes,
      builder: (column) => ColumnOrderings(column));
}

class $$DailyPlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyPlansTable> {
  $$DailyPlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get planDate =>
      $composableBuilder(column: $table.planDate, builder: (column) => column);

  GeneratedColumn<String> get targetLang => $composableBuilder(
      column: $table.targetLang, builder: (column) => column);

  GeneratedColumn<String> get cardIdsJson => $composableBuilder(
      column: $table.cardIdsJson, builder: (column) => column);

  GeneratedColumn<int> get totalCards => $composableBuilder(
      column: $table.totalCards, builder: (column) => column);

  GeneratedColumn<int> get completedCards => $composableBuilder(
      column: $table.completedCards, builder: (column) => column);

  GeneratedColumn<int> get dueCount =>
      $composableBuilder(column: $table.dueCount, builder: (column) => column);

  GeneratedColumn<int> get newCount =>
      $composableBuilder(column: $table.newCount, builder: (column) => column);

  GeneratedColumn<int> get leechCount => $composableBuilder(
      column: $table.leechCount, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get estimatedMinutes => $composableBuilder(
      column: $table.estimatedMinutes, builder: (column) => column);
}

class $$DailyPlansTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DailyPlansTable,
    DailyPlan,
    $$DailyPlansTableFilterComposer,
    $$DailyPlansTableOrderingComposer,
    $$DailyPlansTableAnnotationComposer,
    $$DailyPlansTableCreateCompanionBuilder,
    $$DailyPlansTableUpdateCompanionBuilder,
    (DailyPlan, BaseReferences<_$AppDatabase, $DailyPlansTable, DailyPlan>),
    DailyPlan,
    PrefetchHooks Function()> {
  $$DailyPlansTableTableManager(_$AppDatabase db, $DailyPlansTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyPlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyPlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyPlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> planDate = const Value.absent(),
            Value<String> targetLang = const Value.absent(),
            Value<String> cardIdsJson = const Value.absent(),
            Value<int> totalCards = const Value.absent(),
            Value<int> completedCards = const Value.absent(),
            Value<int> dueCount = const Value.absent(),
            Value<int> newCount = const Value.absent(),
            Value<int> leechCount = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> estimatedMinutes = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DailyPlansCompanion(
            planDate: planDate,
            targetLang: targetLang,
            cardIdsJson: cardIdsJson,
            totalCards: totalCards,
            completedCards: completedCards,
            dueCount: dueCount,
            newCount: newCount,
            leechCount: leechCount,
            createdAt: createdAt,
            estimatedMinutes: estimatedMinutes,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String planDate,
            required String targetLang,
            Value<String> cardIdsJson = const Value.absent(),
            Value<int> totalCards = const Value.absent(),
            Value<int> completedCards = const Value.absent(),
            Value<int> dueCount = const Value.absent(),
            Value<int> newCount = const Value.absent(),
            Value<int> leechCount = const Value.absent(),
            required int createdAt,
            Value<int> estimatedMinutes = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DailyPlansCompanion.insert(
            planDate: planDate,
            targetLang: targetLang,
            cardIdsJson: cardIdsJson,
            totalCards: totalCards,
            completedCards: completedCards,
            dueCount: dueCount,
            newCount: newCount,
            leechCount: leechCount,
            createdAt: createdAt,
            estimatedMinutes: estimatedMinutes,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DailyPlansTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DailyPlansTable,
    DailyPlan,
    $$DailyPlansTableFilterComposer,
    $$DailyPlansTableOrderingComposer,
    $$DailyPlansTableAnnotationComposer,
    $$DailyPlansTableCreateCompanionBuilder,
    $$DailyPlansTableUpdateCompanionBuilder,
    (DailyPlan, BaseReferences<_$AppDatabase, $DailyPlansTable, DailyPlan>),
    DailyPlan,
    PrefetchHooks Function()>;
typedef $$SyncQueueTableCreateCompanionBuilder = SyncQueueCompanion Function({
  required String id,
  required String entityType,
  required String entityId,
  Value<String> operation,
  required String payloadJson,
  Value<int> retryCount,
  required int createdAt,
  Value<int?> lastAttemptAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});
typedef $$SyncQueueTableUpdateCompanionBuilder = SyncQueueCompanion Function({
  Value<String> id,
  Value<String> entityType,
  Value<String> entityId,
  Value<String> operation,
  Value<String> payloadJson,
  Value<int> retryCount,
  Value<int> createdAt,
  Value<int?> lastAttemptAt,
  Value<int?> deletedAt,
  Value<int> rowid,
});

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastAttemptAt => $composableBuilder(
      column: $table.lastAttemptAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnFilters(column));
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastAttemptAt => $composableBuilder(
      column: $table.lastAttemptAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get deletedAt => $composableBuilder(
      column: $table.deletedAt, builder: (column) => ColumnOrderings(column));
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get lastAttemptAt => $composableBuilder(
      column: $table.lastAttemptAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$SyncQueueTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncQueueTable,
    SyncQueueData,
    $$SyncQueueTableFilterComposer,
    $$SyncQueueTableOrderingComposer,
    $$SyncQueueTableAnnotationComposer,
    $$SyncQueueTableCreateCompanionBuilder,
    $$SyncQueueTableUpdateCompanionBuilder,
    (
      SyncQueueData,
      BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>
    ),
    SyncQueueData,
    PrefetchHooks Function()> {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> entityType = const Value.absent(),
            Value<String> entityId = const Value.absent(),
            Value<String> operation = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int?> lastAttemptAt = const Value.absent(),
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncQueueCompanion(
            id: id,
            entityType: entityType,
            entityId: entityId,
            operation: operation,
            payloadJson: payloadJson,
            retryCount: retryCount,
            createdAt: createdAt,
            lastAttemptAt: lastAttemptAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String entityType,
            required String entityId,
            Value<String> operation = const Value.absent(),
            required String payloadJson,
            Value<int> retryCount = const Value.absent(),
            required int createdAt,
            Value<int?> lastAttemptAt = const Value.absent(),
            Value<int?> deletedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SyncQueueCompanion.insert(
            id: id,
            entityType: entityType,
            entityId: entityId,
            operation: operation,
            payloadJson: payloadJson,
            retryCount: retryCount,
            createdAt: createdAt,
            lastAttemptAt: lastAttemptAt,
            deletedAt: deletedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncQueueTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncQueueTable,
    SyncQueueData,
    $$SyncQueueTableFilterComposer,
    $$SyncQueueTableOrderingComposer,
    $$SyncQueueTableAnnotationComposer,
    $$SyncQueueTableCreateCompanionBuilder,
    $$SyncQueueTableUpdateCompanionBuilder,
    (
      SyncQueueData,
      BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>
    ),
    SyncQueueData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$WordsTableTableManager get words =>
      $$WordsTableTableManager(_db, _db.words);
  $$ProgressTableTableManager get progress =>
      $$ProgressTableTableManager(_db, _db.progress);
  $$ReviewEventsTableTableManager get reviewEvents =>
      $$ReviewEventsTableTableManager(_db, _db.reviewEvents);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$DailyPlansTableTableManager get dailyPlans =>
      $$DailyPlansTableTableManager(_db, _db.dailyPlans);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
}
