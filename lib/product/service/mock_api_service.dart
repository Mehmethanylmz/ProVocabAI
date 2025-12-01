import 'package:flutter/foundation.dart';
import '../../features/study_zone/data/models/word_model.dart';
import 'api_service.dart';

class MockApiService implements ApiService {
  @override
  Future<List<WordModel>> getInitialWords(
      String nativeLang, String targetLang) async {
    await Future.delayed(const Duration(seconds: 1));
    if (kDebugMode) {
      print("🔔 MOCK API: Veriler getiriliyor ($nativeLang -> $targetLang)...");
    }

    final List<Map<String, dynamic>> mockData = [
      {
        "id": 1,
        "meta": {
          "part_of_speech": "noun",
          "transcription": "/ˈæpl/",
          "categories": ["food", "a1"]
        },
        "content": {
          "en": {
            "word": "Apple",
            "meaning": "A round fruit with red or green skin"
          },
          "tr": {
            "word": "Elma",
            "meaning": "Kırmızı veya yeşil kabuklu yuvarlak meyve"
          },
          "es": {
            "word": "Manzana",
            "meaning": "Una fruta redonda de piel roja o verde"
          },
          "de": {
            "word": "Apfel",
            "meaning": "Eine runde Frucht mit roter oder grüner Schale"
          },
          "fr": {
            "word": "Pomme",
            "meaning": "Un fruit rond à peau rouge ou verte"
          },
          "pt": {
            "word": "Maçã",
            "meaning": "Uma fruta redonda com casca vermelha ou verde"
          }
        },
        "sentences": {
          "beginner": {
            "en": "I eat an apple every day.",
            "tr": "Her gün bir elma yerim.",
            "es": "Como una manzana todos los días.",
            "de": "Ich esse jeden Tag einen Apfel.",
            "fr": "Je mange une pomme tous les jours.",
            "pt": "Eu como uma maçã todos os dias."
          }
        }
      },
      {
        "id": 2,
        "meta": {
          "part_of_speech": "verb",
          "transcription": "/rʌn/",
          "categories": ["action", "a1"]
        },
        "content": {
          "en": {
            "word": "Run",
            "meaning": "To move at a speed faster than a walk"
          },
          "tr": {
            "word": "Koşmak",
            "meaning": "Yürümekten daha hızlı hareket etmek"
          },
          "es": {
            "word": "Correr",
            "meaning": "Moverse a una velocidad más rápida que caminar"
          },
          "de": {
            "word": "Laufen",
            "meaning": "Sich schneller als beim Gehen bewegen"
          },
          "fr": {
            "word": "Courir",
            "meaning": "Se déplacer plus vite qu'en marchant"
          },
          "pt": {
            "word": "Correr",
            "meaning": "Mover-se a uma velocidade mais rápida que andar"
          }
        },
        "sentences": {
          "beginner": {
            "en": "He runs very fast.",
            "tr": "O çok hızlı koşar.",
            "es": "Él corre muy rápido.",
            "de": "Er läuft sehr schnell.",
            "fr": "Il court très vite.",
            "pt": "Ele corre muito rápido."
          }
        }
      },
      {
        "id": 3,
        "meta": {
          "part_of_speech": "adjective",
          "transcription": "/ɡʊd/",
          "categories": ["general", "a1"]
        },
        "content": {
          "en": {"word": "Good", "meaning": "To be desired or approved of"},
          "tr": {"word": "İyi", "meaning": "İstenilen veya onaylanan"},
          "es": {"word": "Bueno", "meaning": "Ser deseado o aprobado"},
          "de": {"word": "Gut", "meaning": "Erwünscht oder gebilligt"},
          "fr": {"word": "Bon", "meaning": "Être désiré ou approuvé"},
          "pt": {"word": "Bom", "meaning": "Ser desejado ou aprovado"}
        },
        "sentences": {
          "beginner": {
            "en": "This is a good book.",
            "tr": "Bu iyi bir kitap.",
            "es": "Este es un buen libro.",
            "de": "Das ist ein gutes Buch.",
            "fr": "C'est un bon livre.",
            "pt": "Este é um bom livro."
          }
        }
      }
    ];

    return mockData.map((e) => WordModel.fromJson(e)).toList();
  }

  @override
  Future<void> syncProgress(Map<String, dynamic> progressData) async {
    // Sync işlemi
  }
}
