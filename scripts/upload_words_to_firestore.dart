// scripts/upload_words_to_firestore.dart
//
// FAZ 15 — F15-01: Firestore'a kelime verisi yükleme scripti
//
// ÇALIŞTIRILMA:
//   Bu script bir Flutter entegrasyon testi olarak çalıştırılır:
//   1. Bir test cihazı veya emülatöre bağlı olun
//   2. flutter run --flavor development -t scripts/upload_words_to_firestore.dart
//
// GEREKSINIMLER:
//   - Firebase projesi yapılandırılmış ve GoogleService-Info.plist / google-services.json mevcut
//   - assets/data/words.json dosyası mevcut
//   - Firebase konsolunda Firestore etkin ve yazma kuralları açık
//
// Firestore yapısı (yükleme sonrası):
//   words/{wordId}
//     id: int
//     meta:
//       part_of_speech: string
//       transcription: string?
//       categories: List<string>
//       difficulty_rank: int
//     content:
//       en: { word: string, meaning: string }
//       tr: { word: string, meaning: string }
//       ...
//     sentences:
//       beginner:   { en: string, tr: string, ... }
//       intermediate: { en: string, tr: string, ... }
//       advanced:   { en: string, tr: string, ... }

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Anonymous sign-in is required: Firestore rules deny unauthenticated writes.
  // The 'words' collection rule must also allow authenticated writes (see firestore.rules).
  debugPrint('[UploadScript] Signing in anonymously…');
  await FirebaseAuth.instance.signInAnonymously();
  debugPrint('[UploadScript] Signed in as: ${FirebaseAuth.instance.currentUser?.uid}');

  await uploadWordsToFirestore();
}

Future<void> uploadWordsToFirestore() async {
  const assetPath = 'assets/data/words.json';
  const batchSize = 400; // Firestore batch limit 500, keep margin

  debugPrint('[UploadScript] Reading $assetPath …');
  final jsonStr = await rootBundle.loadString(assetPath);
  final dynamic raw = json.decode(jsonStr);

  final List<dynamic> wordList;
  if (raw is List) {
    wordList = raw;
  } else if (raw is Map && raw['words'] is List) {
    wordList = raw['words'] as List;
  } else {
    debugPrint('[UploadScript] ERROR: Unexpected JSON structure');
    return;
  }

  debugPrint('[UploadScript] Parsed ${wordList.length} words. Uploading…');

  final firestore = FirebaseFirestore.instance;
  int uploaded = 0;

  for (int i = 0; i < wordList.length; i += batchSize) {
    final chunk = wordList.sublist(
      i,
      (i + batchSize).clamp(0, wordList.length),
    );

    final batch = firestore.batch();
    for (final item in chunk) {
      if (item is! Map<String, dynamic>) continue;
      final id = item['id'];
      if (id == null) continue;

      final meta = item['meta'] as Map<String, dynamic>? ?? {};
      final docRef = firestore.collection('words').doc('$id');

      batch.set(docRef, {
        'id': id,
        'meta': {
          'part_of_speech': meta['part_of_speech'] ?? '',
          'transcription': meta['transcription'],
          'categories': meta['categories'] ?? [],
          'difficulty_rank': meta['difficulty_rank'] ?? 1,
        },
        'content': item['content'] ?? {},
        'sentences': item['sentences'] ?? {},
      });
    }

    try {
      await batch.commit();
    } on FirebaseException catch (e) {
      debugPrint('[UploadScript] BATCH FAILED at word ~$uploaded');
      debugPrint('[UploadScript] Code   : ${e.code}');
      debugPrint('[UploadScript] Message: ${e.message}');
      if (e.code == 'permission-denied') {
        debugPrint(
          '[UploadScript] ACTION REQUIRED:\n'
          '  1. Add a write rule for the "words" collection in firestore.rules:\n'
          '       match /words/{wordId} { allow write: if request.auth != null; }\n'
          '  2. Deploy the updated rules: firebase deploy --only firestore:rules\n'
          '  3. Re-run the script.',
        );
      }
      return;
    }
    uploaded += chunk.length;
    debugPrint(
        '[UploadScript] Uploaded $uploaded / ${wordList.length} words …');
  }

  debugPrint('[UploadScript] DONE. $uploaded words uploaded to Firestore.');
}
