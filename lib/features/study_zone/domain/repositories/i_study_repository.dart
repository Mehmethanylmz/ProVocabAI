import '../../../../core/error/failures.dart';
import '../entities/word_entity.dart'; // Bir önceki adımda oluşturduk
import 'package:dartz/dartz.dart'; // Fonksiyonel programlama için (Hata yönetimi)

// Repository Interface: "Ne yapacağız?" (Nasıl yapacağımız umurumuzda değil)
abstract class IStudyRepository {
  // Çalışılacak kelimeleri getir (Günlük, Zor veya Özel filtreli)
  Future<Either<Failure, List<WordEntity>>> getWordsForStudy({
    required String mode, // 'daily', 'difficult', 'custom'
    required String targetLang,
    List<String>? categories,
    int limit = 10,
  });

  // Kelime öğrenildi mi? İlerlemesini kaydet.
  Future<Either<Failure, void>> updateWordStats({
    required int wordId,
    required bool isCorrect,
    required int currentLevel,
    required int currentStreak,
    required String targetLang,
  });

  // Kategorileri getir
  Future<Either<Failure, List<String>>> getCategories();
}
