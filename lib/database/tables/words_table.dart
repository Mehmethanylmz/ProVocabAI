import 'package:drift/drift.dart';

/// Drift tablo tanımı: words
///
/// FAZ 15 — Schema v2: sourceLang + targetLang kolonları eklendi.
/// İndirilen kelime verisi dil çiftine göre filtrelenmiş olarak saklanır.
/// contentJson sadece sourceLang + targetLang içeriğini tutar (APK boyutu azaltılır).
///
/// words.json / Firestore yapısı:
///   meta.part_of_speech, meta.transcription, meta.categories[]
///   content.{en,tr,es,de,fr,pt}.{word, meaning}
///   sentences.{beginner,intermediate,advanced}.{en,tr,...}
///
/// Tüm JSON alanları TEXT olarak saklanır — parse app katmanında yapılır.
/// difficulty_rank: categories'den türetilir (a1=1, a2=2, b1=3...) — seeding'de set edilir.
class Words extends Table {
  /// JSON id alanından gelir — PRIMARY KEY, auto-increment DEĞİL.
  IntColumn get id => integer()();

  /// meta.part_of_speech
  TextColumn get partOfSpeech => text().withDefault(const Constant(''))();

  /// meta.transcription (nullable — bazı kelimelerde yok)
  TextColumn get transcription => text().nullable()();

  /// meta.categories — JSON encoded: '["oxford-american/a1","a2"]'
  TextColumn get categoriesJson => text().withDefault(const Constant('[]'))();

  /// content — JSON encoded, sadece sourceLang + targetLang içeriği:
  /// '{"tr":{"word":"hakkında","meaning":"..."},"en":{"word":"about","meaning":"..."}}'
  TextColumn get contentJson => text().withDefault(const Constant('{}'))();

  /// sentences — JSON encoded: '{"beginner":{"en":"...","tr":"..."},...}'
  TextColumn get sentencesJson => text().withDefault(const Constant('{}'))();

  /// Zorluk sıralaması için türetilmiş sütun.
  /// 1=A1, 2=A2, 3=B1, 4=B2, 5=C1, 6=C2
  /// DailyPlanner getNewCards() ORDER BY difficulty_rank ile kullanır.
  IntColumn get difficultyRank => integer().withDefault(const Constant(1))();

  /// F15-03: Kullanıcının ana dili — bu kelime verisi bu dil için indirildi.
  /// Örn: 'tr' (Türkçe konuşan kullanıcı)
  TextColumn get sourceLang => text().withDefault(const Constant('tr'))();

  /// F15-03: Kullanıcının öğrendiği dil — quiz sorusu bu dilde gösterilir.
  /// Örn: 'en' (İngilizce öğrenen kullanıcı)
  TextColumn get targetLang => text().withDefault(const Constant('en'))();

  @override
  Set<Column> get primaryKey => {id};
}
