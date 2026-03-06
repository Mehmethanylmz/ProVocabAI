# ProVocabAI — Kapsamlı Restorasyon Planı
**Tarih:** 2 Mart 2026  
**Versiyon:** 1.0  
**Durum:** FAZ 9–18 Planlama Dokümanı

---

## İÇİNDEKİLER

1. [Yönetici Özeti](#1-yönetici-özeti)
2. [Sorun Envanteri — Kök Neden Analizi](#2-sorun-envanteri)
3. [Mimari Etki Haritası](#3-mimari-etki-haritası)
4. [Faz Planı](#4-faz-planı)
5. [Uygulama Detayları](#5-uygulama-detayları)
6. [Risk Analizi ve Geri Dönüş Planı](#6-risk-analizi)
7. [Test Matrisi](#7-test-matrisi)

---

## 1. YÖNETİCİ ÖZETİ

Bu doküman, ProVocabAI uygulamasındaki 10 ana sorunun kök neden analizini, etkilenen dosyaların tespitini ve 10 fazlık uygulama planını içerir.

**Sorun Dağılımı:**

| Kategori | Sorun Sayısı | Kritiklik |
|----------|-------------|-----------|
| Mimari / Veri Akışı Hatası | 3 | 🔴 Kritik |
| UX Akış Hatası | 3 | 🟠 Yüksek |
| Eksik Özellik | 2 | 🟡 Orta |
| UI/UX Tasarım | 2 | 🟡 Orta |

**Toplam Etkilenen Dosya Sayısı:** ~35 dosya  
**Tahmini Süre:** 10 Faz (Faz 9–18)

---

## 2. SORUN ENVANTERİ — KÖK NEDEN ANALİZİ

---

### SORUN 1 — Günlük Hedef Kelime Limiti Kullanıcıyı Engelliyor

**Belirti:** Onboarding'de seçilen günlük hedef (ör. 10 kelime), kullanıcının çalışabileceği maksimum kelime sayısını belirliyor. Hedefi tamamlayan kullanıcı daha fazla çalışamıyor.

**Kök Neden (Kod Tespiti):**

`daily_planner.dart` satır 97–104:
```dart
final remaining = (newWordsGoal - doneToday).clamp(0, newWordsGoal);
final newWords = remaining > 0
    ? await _wordDao.getNewCards(...)
    : <Word>[];  // ← Hedef dolunca YENİ KELİME VERİLMİYOR
```

`study_zone_bloc.dart` satır 113:
```dart
final plan = await _dailyPlanner.buildPlan(
  newWordsGoal: event.newWordsGoal, // ← Ayarlardan gelen sabit limit
);
```

Plan oluşturulurken `newWordsGoal` sabit üst sınır olarak kullanılıyor. Due kartlar bittikten ve yeni kart limiti dolunca plan boş dönüyor → kullanıcı çalışamıyor.

**Doğru Mimari:**

Günlük hedef `newWordsGoal` → **istatistik eşiği** olmalı, **hard cap** değil.

- `dailyGoalMet: bool` → Hedefe ulaşıldı mı? (Dashboard'da rozet, bildirim tetikleyici)
- `dailyGoalStreak: int` → Kaç gün üst üste hedef tutturuldu? (Profil istatistiği)
- Plan her zaman tüm due kartları + ek yeni kartları sunmalı.
- Yeni kelime akışı: Hedefe ulaşılınca "Hedefini tamamladın! 🎯 Devam etmek ister misin?" şeklinde onay UX'i, ardından ek kelimeler sunulmalı.

**Etkilenen Dosyalar:**
- `daily_planner.dart` — `newWordsGoal` hard cap → soft cap dönüşümü
- `study_zone_bloc.dart` — `_onLoadPlan` ve `_onSessionStarted` — plan bittikten sonra "devam et" akışı
- `study_zone_screen.dart` — "Hedefini tamamladın" kartı + "Devam Et" butonu
- `study_zone_state.dart` — `StudyZoneReady` → `goalMet: bool` alanı eklenmeli
- `study_zone_event.dart` — `ContinueBeyondGoal` event eklenmeli
- `settings_repository_impl.dart` — `dailyGoalStreak` persist
- `progress_dao.dart` — `getDailyGoalHistory()` sorgusu (istatistik için)

---

### SORUN 2 — Dashboard ve Profil'de Veri Tekrarı

**Belirti:** Her iki ekranda da aynı 3 veri gösteriliyor: Toplam XP, Gün Serisi, Bu Hafta.

**Kök Neden:**

`dashboard_view.dart` → `_QuickStatsRow`: streak, totalXp, weekQuestions gösteriyor (AuthBloc'tan).

`profile_view.dart` → Şu an profil ekranı **çok basit**: avatar, isim, email, çıkış butonu. Profil'e FAZ 5'te eklenen XP/streak stat kartları ve başarı rozetleri mevcut olan `/mnt/user-data/outputs/profile_view.dart`'ta var ama proje dosyasında (`/mnt/project/profile_view.dart`) istatistik widget'ları hiç yok.

**Doğru Mimari:**

Dashboard ve Profil farklı görevlere sahip olmalı:

| Alan | Dashboard | Profil |
|------|-----------|--------|
| Amaç | Bugünkü aktivite + hızlı özet | Genel profil + tarihsel istatistik |
| Streak | ✅ Quick stat chip | ❌ Kaldır |
| Toplam XP | ✅ Quick stat chip | ✅ Büyük hero banner |
| Bu Hafta | ✅ Quick stat chip | ❌ Kaldır |
| Isı Haritası | ✅ GitHub-tarzı (Sorun 3) | ❌ |
| Tarihsel İstatistik | ❌ | ✅ Detaylı (Sorun 3) |
| Başarı Rozetleri | ❌ | ✅ |
| Hesap Bilgileri | ❌ | ✅ |
| Paylaş | ❌ | ✅ Zengin paylaşım |

**Etkilenen Dosyalar:**
- `dashboard_view.dart` — Quick stats korunur, detaylı istatistik bölümü yeniden tasarlanır
- `profile_view.dart` — Tamamen yeniden yazılır (tarihsel istatistik, başarılar, paylaşım)

---

### SORUN 3 — Dashboard Detaylı Analiz Eksik + GitHub Isı Haritası

**Belirti:** Dashboard'daki istatistik yetersiz. Kullanıcı bugün/bu hafta/bu ay detaylı istatistik göremiyor. GitHub contribution graph benzeri ısı haritası istenli.

**Kök Neden:**

`dashboard_bloc.dart` satır 152–228: İstatistikler session bazlı hesaplanıyor, yeterli detay mevcut ama UI'da gösterilmiyor.

Mevcut `DashboardStatsEntity` alanları:
- `todayQuestions`, `todaySuccessRate`
- `weekQuestions`, `weekSuccessRate`
- `monthQuestions`, `monthSuccessRate`
- `masteredWords`, `tierDistribution`

**Eksik veriler:**
- Bugün doğru/yanlış ayrımı (sadece rate var, sayı yok)
- Ortalama cevap süresi
- Mod bazlı dağılım (bugün için)
- Gün gün tarihsel veri (ısı haritası için)
- Aylık arşiv verileri
- Takvim görünümü için gün bazlı sorgular

**Doğru Mimari:**

1. **DashboardStatsEntity genişletilecek:**
```dart
class DashboardStatsEntity {
  // Mevcut alanlar korunur
  // YENİ:
  final int todayCorrect;
  final int todayWrong;
  final int todayTimeMinutes;
  final int todayNewWords;
  final int weekCorrect;
  final int weekWrong;
  final int weekTimeMinutes;
  final int weekNewWords;
  final int monthCorrect;
  final int monthWrong;
  final Map<String, int> todayModeDistribution; // {'mcq': 5, 'listening': 3}
  final List<DayActivity> heatmapData; // Son 365 gün
}

class DayActivity {
  final String date; // 'yyyy-MM-dd'
  final int questionCount;
  final int correctCount;
  final int timeMinutes;
}
```

2. **Dashboard UI Bölümleri:**
   - Quick Stats Row (mevcut — streak, XP, bu hafta)
   - 🆕 **Isı Haritası (Heatmap)** — GitHub contribution calendar benzeri, son 26 hafta, 7×26 grid, 5 renk seviyesi (0=boş, 1-5=açık→koyu yeşil)
   - 🆕 **Bugün Detay Kartı** — soru sayısı, doğru/yanlış, süre, yeni kelime, mod dağılımı
   - 🆕 **Bu Hafta Özet** — aynı metrikler haftalık
   - 🆕 **Aylık Arşiv** — genişleyebilir liste, her ay tıklanabilir
   - 🆕 **Takvim Görünümü** — ay takvimi, her güne tıklanınca o günün istatistiği

3. **Profil'e Taşınacaklar:**
   - SkillRadarCard
   - WordTierPanel
   - ActivityHistoryList

**Etkilenen Dosyalar:**
- `dashboard_stats_entity.dart` — Yeni alanlar eklenir
- `dashboard_bloc.dart` — Heatmap verisi + detaylı metrik hesaplama
- `dashboard_view.dart` — Tamamen yeniden tasarım
- `dashboard_stats_grid.dart` — Bugün detay kartına dönüşür
- 🆕 `heatmap_widget.dart` — GitHub contribution graph widget
- 🆕 `day_detail_card.dart` — Bugün/seçili gün detayları
- 🆕 `calendar_stats_view.dart` — Takvim + gün istatistiği
- `review_event_dao.dart` — Gün bazlı sorgu eklenir (`getDailyActivityForRange`)
- `session_dao.dart` — Gün bazlı session sorgusu

---

### SORUN 4 — AI Koç Analizi Uyumsuz

**Belirti:** Dashboard'daki `coachMessage` statik ve anlamsız.

**Kök Neden:**

`dashboard_bloc.dart` satır 248:
```dart
final coachMessage = _generateCoachMessage(statsEntity, accuracyStats);
```

`_generateCoachMessage` basit if-else ile statik mesaj üretiyor. AI entegrasyonu yok. Gerçek değer katmıyor.

**Doğru Mimari — 2 Seçenek:**

**Seçenek A: Akıllı Koç (Önerilen)** — Basit kural motoru ile kişiselleştirilmiş tavsiyeler:
- Streak kırıldıysa → "Dün ara verdin, bugün tekrar başla! 💪"
- Leech sayısı artıyorsa → "3 zor kelimen var, onlara ekstra odaklan"
- Accuracy düşükse → "Bu hafta %60 doğruluk — listening modu dene"
- Hedefe ulaşıldıysa → "Harika! 5 gündür hedefini tutturuyorsun! 🔥"
- İlk kez bir kategori bitirilmişse → "A1 kelimelerini %80 öğrendin!"

**Seçenek B: Kaldır** — `coachMessage` alanı ve ilgili UI kaldırılır. Dashboard'da boş alan kazanılır.

**Öneri:** Seçenek A — kural bazlı, API gerektirmez, kişiselleştirilmiş.

**Etkilenen Dosyalar:**
- `dashboard_bloc.dart` — `_generateCoachMessage` yeniden yazılır
- `dashboard_view.dart` — Koç kartı tasarımı güncellenir

---

### SORUN 5 — Kategori Filtreleme UI/UX Yetersiz

**Belirti:** Atölye'deki FilterChip listesi çok uzun kategoriler için uygunsuz.

**Kök Neden:**

`study_zone_screen.dart` → `CategoryFilterChips` widget:
```dart
SizedBox(
  height: 36,
  child: ListView.separated(
    scrollDirection: Axis.horizontal,
    itemCount: allCategories.length, // 16 kategori — düz liste
  ),
)
```

Kategoriler düz slug formatında: `engineering-and-manufacturing`, `it-and-software-development` vb. Okunabilirlik düşük, seçim zorlaştırıyor.

**Doğru Mimari:**

Kategoriler **2 gruba** ayrılmalı:

| Grup | Kategoriler | UI |
|------|------------|-----|
| **Dil Seviyeleri** | A1, A2, B1, B2, C1, C2 | Yatay chip bar (6 chip sığar) |
| **Alan Kategorileri** | business, engineering, finance, hospitality, IT, legal, marketing, medical, oxford-american, science | Grid modal veya expandable section |

Her kategoriye **ikon + kısa etiket** atanmalı:

| Slug | Etiket | İkon |
|------|--------|------|
| `a1` | A1 | 🌱 |
| `a2` | A2 | 🌿 |
| `b1` | B1 | 🌳 |
| `b2` | B2 | 🏔️ |
| `c1` | C1 | ⭐ |
| `c2` | C2 | 💎 |
| `business` | İş | 💼 |
| `engineering-and-manufacturing` | Mühendislik | ⚙️ |
| `finance-and-accounting` | Finans | 💰 |
| `hospitality-and-tourism` | Turizm | ✈️ |
| `it-and-software-development` | Yazılım | 💻 |
| `legal-and-law` | Hukuk | ⚖️ |
| `marketing-and-advertising` | Pazarlama | 📢 |
| `medical-and-healthcare` | Tıp | 🏥 |
| `oxford-american` | Oxford | 📚 |
| `science-and-research` | Bilim | 🔬 |

**UI Akışı:**
1. Seviye satırı: 6 chip (A1–C2) — yatay scroll, multi-select
2. "Alan seç" butonu → Bottom sheet açılır → Kategoriler grid görünümde (2 sütun, ikon + etiket)
3. Seçilen kategoriler chip olarak filtreleme satırında gösterilir
4. "Tümü" seçeneği — filtre temizle

**Etkilenen Dosyalar:**
- `study_zone_screen.dart` → `CategoryFilterChips` → tamamen yeniden yazılır
- 🆕 `category_constants.dart` — Kategori metadata (slug, etiket, ikon, grup)
- 🆕 `category_picker_sheet.dart` — Alan kategorileri bottom sheet

---

### SORUN 6 — Kelime Verisi Lokal (APK Boyutu + Dil Optimizasyonu)

**Belirti:** `words.json` (tüm diller, tüm kelimeler) uygulama asset'inde. APK boyutunu artırıyor. Kullanıcı sadece 2 dil kullanıyor ama 6 dilin verisi yükleniyor.

**Kök Neden:**

`dataset_service.dart` satır 100–101:
```dart
final jsonString = await rootBundle.loadString('assets/data/words.json');
// Tüm JSON → tüm diller → tüm kelimeler Drift'e yazılıyor
```

`words_table.dart` — `contentJson` alanı tüm 6 dilin verisini tek TEXT'te tutuyor.

**Doğru Mimari — Firebase + Dil Filtreli İndirme:**

**Firestore Yapısı:**
```
words/{wordId}
  ├── id: 1
  ├── meta: { part_of_speech, transcription, categories }
  ├── sentences: { beginner: {...}, intermediate: {...}, advanced: {...} }
  └── content: { en: {...}, tr: {...}, de: {...}, ... }
```

**İndirme Stratejisi:**

1. Kullanıcı onboarding'de ana dil (ör: `tr`) + hedef dil (ör: `en`) seçer.
2. İlk giriş → Firestore'dan tüm kelimeler çekilir, ama sadece `content.tr` + `content.en` + `sentences` alanları lokal DB'ye yazılır.
3. `words` tablosuna `contentJson` yerine sadece 2 dilin verisi yazılır → boyut ~%60 küçülür.
4. Ayarlardan dil değiştirilirse → yeni dil verisi Firestore'dan indirilir, mevcut kelime satırları güncellenir.
5. Asset'teki `words.json` tamamen kaldırılır.

**Drift Schema Değişikliği:**
```dart
class Words extends Table {
  // Mevcut alanlar korunur
  // DEĞİŞEN:
  // contentJson → sadece sourceLang + targetLang verisi
  // YENİ:
  TextColumn get sourceLang => text().withDefault(const Constant('tr'))();
  TextColumn get targetLang => text().withDefault(const Constant('en'))();
}
```

**Leaderboard Ayrımı:**
Firestore `users/{uid}` dokümanına:
```
weeklyXpByPair: { 'tr-en': 150, 'tr-de': 30 }
```
Leaderboard sorgusu → `weeklyXpByPair.{sourceLang}-{targetLang}` bazlı.

**⚠️ Migration Stratejisi:**
- `schemaVersion` 1 → 2 migration gerekir
- Mevcut kullanıcıların lokal verileri korunmalı
- İlk Firebase indirmede mevcut progress verisi bozulmamalı

**Etkilenen Dosyalar:**
- `dataset_service.dart` — Tamamen yeniden yazılır → `WordSyncService`
- `words_table.dart` — Schema değişikliği (schemaVersion 2)
- `app_database.dart` — Migration eklenir
- `word_dao.dart` — `syncWordsFromFirestore()`, `updateLanguageContent()`
- `splash_bloc.dart` — İlk indirme akışı (progress indicator)
- `settings_bloc.dart` — Dil değişikliğinde kelime verisi güncelleme
- `leaderboard_service.dart` — Dil çifti bazlı sorgular
- `injection_container.dart` — `WordSyncService` register
- 🆕 `word_sync_service.dart` — Firestore → Drift senkronizasyonu
- `pubspec.yaml` — `assets/data/words.json` kaldırılır

---

### SORUN 7 — Hızlı 5 dk (Mini Session) Hatalı + FSRS Riski

**Belirti:** Mini session'da soru İngilizce gösterilirken şıklarda Türkçe anlam çıkıyor (normal quiz gibi değil). FSRS algoritmasıyla etkileşimi belirsiz.

**Kök Neden:**

`mini_session_screen.dart` satır 191–218: Kendi `_MiniMcqOptions` builder'ı var — `quiz_screen.dart`'taki `_parseMeaning()` ile **aynı mantığı** kullanmıyor. Ayrı kod path'i → farklı davranış.

**FSRS Etkisi:** Mini session aynı `StudyZoneBloc` → `SubmitReview` → `FSRSEngine` pipeline'ını kullanıyor. FSRS'e doğrudan zarar vermez ama bozuk quiz deneyimi yanlış rating'lere yol açar → dolaylı olarak FSRS kalitesini düşürür.

**Karar:** Mini session tamamen kaldırılacak.

**Gerekçe:**
1. Ayrı kod path'i bakım yükü yaratıyor
2. Quiz mantığıyla tam senkron değil
3. Günlük plan zaten esnek hale gelecek (Sorun 1 çözümü) — kullanıcı istediği kadar çalışabilecek
4. Mini session'ın sunduğu "hızlı çalışma" deneyimi, ana quiz'in daha iyi UX'i ile karşılanabilir

**Etkilenen Dosyalar:**
- `mini_session_screen.dart` — **SİLİNECEK**
- `study_zone_screen.dart` — `_MiniSessionButton` kaldırılır
- `navigation_route.dart` — Mini session route kaldırılır (varsa)
- `injection_container.dart` — İlgili kayıtlar temizlenir

---

### SORUN 8 — Quiz Ekranı Çoklu UX Sorunları

Bu sorun 8 alt madde içerir. Her biri ayrı analiz edilmiştir.

#### 8a — Kelimeler Alfabetik Sırada Geliyor (Karıştırılmıyor)

**Kök Neden:**

`daily_planner.dart` → `_interleave()` metodu leech + due + new kartları deterministik sırayla birleştiriyor. Due kartlar `ORDER BY next_review_ms ASC` ile geliyor (time-based sıralama). New kartlar `ORDER BY difficulty_rank ASC` ile geliyor — difficulty_rank kelime ID'siyle korelasyon gösteriyor → **fiilen alfabetik sıra**.

`study_zone_bloc.dart` satır 143:
```dart
_planCards = List.of(ready.plan.cards).take(_sessionCardLimit).toList();
// Shuffle YOK → plan sırası korunuyor
```

**Çözüm:** `_onSessionStarted` içinde `_planCards.shuffle(Random())` eklenir. Leech kartlar ayrı tutulup başa alınır, geri kalanı karıştırılır.

#### 8b — Quiz'de Kelime Sesli Okunmuyor

**Kök Neden:**

`quiz_screen.dart` — `_McqWordCard` widget'ında TTS çağrısı **yok**. Listening modunda TTS var ama MCQ'da yok. `settings_view.dart` satır 321–336: `autoPlaySound` ayarı mevcut ama quiz'e bağlı değil.

**Çözüm:**
1. `_QuizBodyState._resetCard()` içinde `if (autoPlaySound) ttsService.speak(wordText, targetLang)` eklenir
2. Quiz AppBar'a 🔊/🔇 toggle butonu eklenir (session-scoped, settings'i override etmez)
3. Kelime kartına tap-to-replay ikonu eklenir

#### 8c — Part of Speech Gösterilmiyor

**Kök Neden:**

`words_table.dart` → `partOfSpeech` alanı mevcut. `quiz_screen.dart` → `_McqWordCard` widget'ında bu alan kullanılmıyor.

**Çözüm:** Kelime kartının altına küçük chip olarak `word.partOfSpeech` gösterilir.

#### 8d — Örnek Cümleler Gösterilmiyor

**Kök Neden:**

`words_table.dart` → `sentencesJson` alanı mevcut (beginner/intermediate/advanced). Quiz'de hiçbir yerde parse edilip gösterilmiyor.

**Çözüm:** Cevap verildikten sonra (answered phase) kelime kartının altında genişleyebilir örnek cümle bölümü gösterilir. 3 seviye tab olarak: Başlangıç / Orta / İleri.

#### 8e — Cevap Sonrası UX Akışı Hatalı (Timeout + BottomSheet)

**Kök Neden:**

`quiz_screen.dart` satır 172–177:
```dart
Future.delayed(const Duration(milliseconds: 1500), () {
  ReviewRatingSheet.show(context, responseMs: responseMs);
});
```

1500ms timeout → bottom sheet açılıyor → 3sn countdown → otomatik GOOD → sonraki kart.

**Kullanıcı İstekleri:**
- Timeout olmamalı
- Cevap sonrası kelime anlamı + örnek cümleler gösterilmeli
- "Bu kelimeyi ne kadar hatırladın?" altında olmalı
- Rating butonuna tıklanınca geçilmeli (countdown kaldırılmalı)

**Yeni Akış:**
```
1. Soru gösterilir (question phase)
2. Kullanıcı cevap seçer → ✅/❌ gösterilir (answered phase)
3. TIMEOUT YOK — Ekranın alt kısmında açılır:
   ├── Kelime anlamı (hedef dil → ana dil)
   ├── Part of speech
   ├── Örnek cümleler (3 seviye, genişleyebilir)
   ├── 🔊 Tekrar dinle butonu
   └── "Bu kelimeyi ne kadar hatırladın?" 4 buton (Çok Zor / Zor / İyi / Kolay)
4. Rating butonuna tıklanınca:
   ├── XP + sonraki tekrar tarihi kısa toast/snackbar ile gösterilir (ör: "+10 XP • 3 gün sonra")
   └── 0.5sn delay → sonraki kart
```

#### 8f — XP/Tekrar Bilgisi Ayrı Ekranda Gösteriliyor

**Kök Neden:**

`study_zone_bloc.dart` → `AnswerSubmitted` sonrası `StudyZoneReviewing` state emit ediliyor. `quiz_screen.dart` → `_ReviewingOverlay` bu state'i ayrı ekran olarak gösteriyor.

**Çözüm:** `StudyZoneReviewing` state kaldırılır. Rating seçimi sonrası `AnswerSubmitted` event'i direkt `NextCardRequested`'a geçer. XP bilgisi inline toast olarak gösterilir.

#### 8g — "Zor" Rating İstatistiği Yanlış Hesaplanıyor

**Kök Neden (KRİTİK BUG):**

`study_zone_bloc.dart` satır 250–254:
```dart
if (rating == ReviewRating.again) {
  _wrongWordIds.add(card.wordId);
} else {
  _correctCards++;
}
```

`submit_review.dart` satır 96:
```dart
wasCorrect: p.rating != ReviewRating.again,
```

**Mevcut davranış:** Rating `again` ise → yanlış. Diğer tüm ratingler (hard, good, easy) → doğru.

**Sorun:** Kullanıcı MCQ'da doğru şıkkı seçiyor → 1500ms → rating sheet açılıyor → "Zor" (hard) seçiyor → `rating = hard` → `wasCorrect = true` → **istatistiğe doğru olarak kaydediliyor.**

Ama kullanıcı "hard seçince yanlış gösteriliyor" diyor. Bu şu anlama geliyor:

**Gerçek sorun:** MCQ seçim sonucu (doğru/yanlış) ile FSRS rating birbirinden bağımsız takip edilmiyor. Tek bir `rating` değeri her ikisini de belirliyor.

**Doğru Mimari:**
```dart
// AnswerSubmitted event'ine isCorrect eklenir
class AnswerSubmitted extends StudyZoneEvent {
  final ReviewRating rating;
  final int responseMs;
  final bool isCorrect; // ← YENİ — MCQ şık seçiminden gelir
}

// submit_review.dart
wasCorrect: p.isCorrect, // rating'den DEĞİL, MCQ sonucundan
```

Bu sayede:
- MCQ doğru + rating hard → `wasCorrect: true`, `rating: hard` → İstatistik: DOĞRU, FSRS: kısa interval
- MCQ yanlış + rating good → `wasCorrect: false`, `rating: good` → İstatistik: YANLIŞ, FSRS: orta interval

#### 8h — Session Sonuç Ekranında Yanlış Kelimeler "Kelime #ID" Gösteriyor

**Kök Neden:**

`session_result_screen.dart` satır 431–437:
```dart
children: wordIds
    .map((id) => ListTile(
          title: Text('Kelime #$id'), // ← Word nesnesini DB'den çekmiyor!
        ))
    .toList(),
```

`_WrongWordsAccordion` sadece `wordId` listesi alıyor, Word nesnesini DB'den sorgulamıyor.

**Çözüm:** `StudyZoneCompleted` state'ine `wrongWords: List<Word>` eklenir (`wrongWordIds` yerine veya ek olarak). Session result ekranı kelime adını gösterir.

**Etkilenen Dosyalar (Sorun 8 Tamamı):**
- `daily_planner.dart` — (8a ile ilgisi yok, shuffle bloc tarafında)
- `study_zone_bloc.dart` — shuffle, isCorrect ayrımı, wrongWords
- `study_zone_event.dart` — `AnswerSubmitted.isCorrect` eklenir
- `study_zone_state.dart` — `StudyZoneReviewing` refactor, `StudyZoneCompleted.wrongWords`
- `quiz_screen.dart` — Tamamen yeniden yazılır (yeni UX akışı)
- `review_rating_sheet.dart` — Kaldırılır → quiz_screen inline'a taşınır
- `session_result_screen.dart` — `_WrongWordsAccordion` düzeltilir
- `submit_review.dart` — `wasCorrect: p.isCorrect`

---

### SORUN 9 — Profil Ekranı Hataları

#### 9a — Yüzde Hesabı Hatalı (%9090)

**Kök Neden:**

Profil ekranında (`profile_view.dart`) istatistik widget'ı **hiç yok**. Bu hata muhtemelen FAZ 5'te eklenen ama proje dosyasına düzgün merge edilmemiş `profile_view.dart` versiyonunda.

`dashboard_bloc.dart` satır 219:
```dart
todaySuccessRate: todayTotal > 0 ? todayCorrect / todayTotal * 100 : 0.0,
```

Bu doğru hesaplıyor ama gösterimde `.toStringAsFixed(0)` yerine direkt yazdırılırsa `90.90909...` → `%9090` gibi görünebilir.

**Çözüm:** `profile_view.dart` tamamen yeniden yazılırken (Sorun 2) yüzde gösterimi `'%${rate.toStringAsFixed(0)}'` formatında olacak.

#### 9b — Çıkış Butonu Bottom Nav Altında Kalıyor

**Kök Neden:**

`profile_view.dart` → `ListView` kullanıyor ama `bottomPadding` yok. Bottom navigation bar 80px civarı alan kaplıyor → son eleman altında kalıyor.

**Çözüm:**
```dart
ListView(
  padding: const EdgeInsets.only(bottom: 100), // ← Nav bar yüksekliği + margin
  children: [...],
)
```

#### 9c — Paylaş Butonu Yetersiz

**Kök Neden:**

`profile_view.dart` satır 50–59: Sadece `Share.share(shareText)` — düz metin. Görsel paylaşım yok.

**Çözüm:** Paylaşım kartı:
- Arka plan gradient + logo
- Kullanıcı adı, streak, XP, mastered kelime sayısı
- "ProVocabAI ile öğreniyorum" tagline
- Screenshot alınıp `Share.shareXFiles()` ile paylaşılır

**Etkilenen Dosyalar:**
- `profile_view.dart` — Tamamen yeniden yazılır
- 🆕 `share_card_widget.dart` — Paylaşım görseli oluşturucu

---

### SORUN 10 — Ayarlar Ekranı Yetersiz

#### 10a — Uygulama Dili Değiştirme Yok

**Kök Neden:**

`settings_view.dart` → `sourceLang` ve `targetLang` var ama **uygulama UI dili** (`easy_localization` locale) değiştirme yok. Uygulama cihaz diline göre açılıyor, kullanıcı değiştiremiyor.

**Çözüm:**
```dart
// Yeni ayar: Uygulama Dili
_buildLanguageItem(
  context,
  title: 'Uygulama Dili',
  currentValue: context.locale.languageCode,
  onChanged: (val) {
    context.setLocale(Locale(val!));
    context.read<SettingsBloc>().add(SettingsAppLangChanged(val));
  },
)
```

#### 10b — Hesap Sil Butonu Yok

**Kök Neden:** Hiçbir yerde `FirebaseAuth.instance.currentUser?.delete()` çağrısı yok.

**Çözüm:**
1. Re-authentication dialog (güvenlik)
2. Firestore'dan kullanıcı verisi silme
3. Drift tabloları temizleme
4. `FirebaseAuth.currentUser.delete()`
5. Login ekranına yönlendirme

#### 10c — Ayarlar Ekranı Genel Görünümü

**Mevcut:** Tema, dil, seviye, günlük hedef slider, soru sayısı slider, otomatik ses. Yetersiz.

**Eklenmesi Gerekenler:**
- Uygulama dili
- Hesap yönetimi bölümü (e-posta değiştir, şifre değiştir, hesap sil)
- Uygulama hakkında (versiyon, lisanslar, gizlilik politikası, kullanım şartları)
- Bildirim ayarları (açık/kapalı, saat seçimi)
- Veri yönetimi (önbellek temizle, verileri dışa aktar)
- Destek / Geri bildirim linki

**Etkilenen Dosyalar:**
- `settings_view.dart` — Tamamen yeniden yazılır
- `settings_bloc.dart` — Yeni event'ler (app lang, delete account, notification settings)
- `i_settings_repository.dart` — Yeni alanlar
- `settings_repository_impl.dart` — Yeni alanlar persist
- `firebase_auth_service.dart` — `deleteAccount()` metodu

---

## 3. MİMARİ ETKİ HARİTASI

```
Sorun →  Etkilenen Katman
─────────────────────────────────────────────────────────
S1   →  SRS (daily_planner) + BLoC (study_zone) + UI (study_zone_screen)
S2   →  UI (dashboard_view, profile_view)
S3   →  Data (DAO sorguları) + Domain (entity) + BLoC + UI (dashboard)
S4   →  BLoC (dashboard_bloc) + UI (dashboard_view)
S5   →  UI (study_zone_screen) + Constants (category_constants)
S6   →  Data (dataset_service → word_sync_service) + DB (schema migration) + Firebase
S7   →  UI (mini_session_screen SİLİNECEK)
S8   →  SRS (xp_calculator) + BLoC (study_zone) + UI (quiz_screen) + Domain (submit_review)
S9   →  UI (profile_view)
S10  →  UI (settings_view) + BLoC (settings) + Firebase (auth)
```

**Bağımlılık Sırası (Hangi sorun hangisinden önce çözülmeli):**
```
S7 → (bağımsız, kaldır)
S8g → S3 (istatistik düzeltilmeden dashboard anlamsız)
S1 → S8 (plan mekanizması değişince quiz akışı da değişmeli)
S6 → S5 (kelime verisi Firebase'e geçince kategori yapısı da değişir)
S2 → S3 → S9 (dashboard + profil birlikte planlanmalı)
S4 → S3 (koç mesajı dashboard yeniden yazılırken eklenir)
S10 → S6 (hesap silme + dil değişikliği kelime sync ile bağlantılı)
```

---

## 4. FAZ PLANI

### FAZ 9 — Quiz UX Tam Yeniden Yapılandırma (Sorun 8)
**Öncelik:** 🔴 Kritik — Uygulamanın çekirdek deneyimi  
**Tahmini Görev:** 12 alt görev

| ID | Görev | Dosya |
|----|-------|-------|
| F9-01 | `AnswerSubmitted` event'ine `isCorrect: bool` ekle | `study_zone_event.dart` |
| F9-02 | `_onAnswerSubmitted` → `isCorrect` parametresini `SubmitReview`'a geçir | `study_zone_bloc.dart` |
| F9-03 | `SubmitReviewParams.isCorrect` + `wasCorrect: p.isCorrect` | `submit_review.dart` |
| F9-04 | `StudyZoneCompleted` → `wrongWords: List<Word>` ekle | `study_zone_state.dart` |
| F9-05 | `_onSessionStarted` → `_planCards.shuffle()` (leech ayrı) | `study_zone_bloc.dart` |
| F9-06 | Quiz yeni UX: answered phase inline (timeout kaldır, anlam+cümle göster) | `quiz_screen.dart` |
| F9-07 | Part of speech chip + örnek cümleler genişleyebilir bölüm | `quiz_screen.dart` |
| F9-08 | Rating butonları inline (bottom sheet kaldır) | `quiz_screen.dart` |
| F9-09 | XP + tekrar günü toast gösterimi | `quiz_screen.dart` |
| F9-10 | TTS otomatik okuma + session-scoped 🔊 toggle + tap-to-replay | `quiz_screen.dart` |
| F9-11 | `_WrongWordsAccordion` → kelime adlarını göster | `session_result_screen.dart` |
| F9-12 | `review_rating_sheet.dart` deprecated (inline'a taşındı) | `review_rating_sheet.dart` |

**Test Kriterleri:**
- MCQ doğru + hard rating → istatistik: doğru, FSRS: hard scheduling
- MCQ yanlış + good rating → istatistik: yanlış, FSRS: good scheduling
- Kelimeler karışık sırada gelir
- Her kelimede TTS çalar (ayar açıksa)
- Cevap sonrası timeout yok, kelime bilgisi gösterilir
- Session sonucu yanlış kelime adlarını gösterir

---

### FAZ 10 — Günlük Hedef Soft Cap + Mini Session Kaldırma (Sorun 1, 7)
**Öncelik:** 🟠 Yüksek

| ID | Görev | Dosya |
|----|-------|-------|
| F10-01 | `mini_session_screen.dart` SİL | `mini_session_screen.dart` |
| F10-02 | `_MiniSessionButton` kaldır | `study_zone_screen.dart` |
| F10-03 | `DailyPlanner.buildPlan()` → `newWordsGoal` soft cap | `daily_planner.dart` |
| F10-04 | `StudyZoneReady` → `goalMet: bool` alanı | `study_zone_state.dart` |
| F10-05 | `ContinueBeyondGoal` event → ek kelime yükle | `study_zone_event.dart`, `study_zone_bloc.dart` |
| F10-06 | "Hedefini tamamladın! Devam et?" UX | `study_zone_screen.dart` |
| F10-07 | `dailyGoalStreak` persist + hesaplama | `settings_repository_impl.dart`, `progress_dao.dart` |

**Test Kriterleri:**
- Günlük hedef 10 kelime → 10 kelime çalışıldıktan sonra "Devam et?" gösterilir
- "Devam et" tıklanınca ek kelimeler yüklenir
- Mini session butonu artık görünmez
- `dailyGoalStreak` ayarlardan okunabilir

---

### FAZ 11 — Kategori Filtreleme Yeniden Tasarım (Sorun 5)
**Öncelik:** 🟡 Orta

| ID | Görev | Dosya |
|----|-------|-------|
| F11-01 | `CategoryConstants` — slug, etiket, ikon, grup mapping | 🆕 `category_constants.dart` |
| F11-02 | Seviye chip bar (A1–C2) yatay | `study_zone_screen.dart` |
| F11-03 | Alan kategorileri bottom sheet grid (2 sütun, ikon + etiket) | 🆕 `category_picker_sheet.dart` |
| F11-04 | Seçili kategoriler birleşik chip gösterimi | `study_zone_screen.dart` |
| F11-05 | "Tümü" seçeneği + filtreleme temizleme | `study_zone_screen.dart` |

**Test Kriterleri:**
- 6 seviye chip'i yatay sığar
- Alan seçimi bottom sheet açılır, 2 sütun grid
- Birden fazla kategori seçilebilir
- Plan doğru kategorilerle yüklenir

---

### FAZ 12 — Dashboard Tam Yeniden Tasarım + Isı Haritası (Sorun 3, 4)
**Öncelik:** 🟠 Yüksek

| ID | Görev | Dosya |
|----|-------|-------|
| F12-01 | `DashboardStatsEntity` genişlet (detaylı metrikler) | `dashboard_stats_entity.dart` |
| F12-02 | `DashboardBloc` → heatmap verisi + gün bazlı sorgu | `dashboard_bloc.dart` |
| F12-03 | `ReviewEventDao` → `getDailyActivityForRange()` | `review_event_dao.dart` |
| F12-04 | `SessionDao` → `getDailySessionStats()` | `session_dao.dart` |
| F12-05 | GitHub contribution graph widget (26 hafta × 7 gün) | 🆕 `heatmap_widget.dart` |
| F12-06 | Bugün detay kartı (doğru/yanlış/süre/mod) | 🆕 `day_detail_card.dart` |
| F12-07 | Bu hafta özet kartı | `dashboard_view.dart` |
| F12-08 | Aylık arşiv genişleyebilir liste | `dashboard_view.dart` |
| F12-09 | Takvim + gün bazlı istatistik görünümü | 🆕 `calendar_stats_view.dart` |
| F12-10 | Akıllı koç mesajı (kural bazlı) | `dashboard_bloc.dart` |
| F12-11 | Dashboard UI tam assembly | `dashboard_view.dart` |

**Test Kriterleri:**
- Isı haritası 26 hafta gösterir, renkler doğru
- Bugün kartında doğru/yanlış sayısı, süre görünür
- Takvimde güne tıklanınca detay gösterilir
- Koç mesajı bağlamsal (streak, accuracy, leech sayısına göre değişir)

---

### FAZ 13 — Profil Ekranı Yeniden Yazım (Sorun 2, 9)
**Öncelik:** 🟡 Orta

| ID | Görev | Dosya |
|----|-------|-------|
| F13-01 | Profil hero banner (avatar, isim, XP, seviye) | `profile_view.dart` |
| F13-02 | Tarihsel istatistik bölümü (toplam soru, doğruluk, öğrenilen kelime) | `profile_view.dart` |
| F13-03 | Başarı rozetleri grid | `profile_view.dart` |
| F13-04 | SkillRadarCard + WordTierPanel (dashboard'dan taşınır) | `profile_view.dart` |
| F13-05 | Zengin paylaşım kartı (screenshot + share) | 🆕 `share_card_widget.dart` |
| F13-06 | Yüzde hesabı düzeltme (`toStringAsFixed(0)`) | `profile_view.dart` |
| F13-07 | Bottom padding düzeltme (nav bar altında kalmama) | `profile_view.dart` |
| F13-08 | Çıkış butonu konumu düzeltme | `profile_view.dart` |
| F13-09 | Misafir hesap bağlama CTA | `profile_view.dart` |

**Test Kriterleri:**
- XP tekrarı yok (dashboard'da quick stat, profil'de hero banner)
- Yüzde %90 olarak gösterilir (%9090 değil)
- Çıkış butonu görünür, nav bar altında kalmaz
- Paylaşım görsel kart oluşturur

---

### FAZ 14 — Ayarlar Ekranı Profesyonelleşme (Sorun 10)
**Öncelik:** 🟡 Orta

| ID | Görev | Dosya |
|----|-------|-------|
| F14-01 | Uygulama dili değiştirme (easy_localization) | `settings_view.dart`, `settings_bloc.dart` |
| F14-02 | Hesap sil butonu + re-auth + Firestore temizleme | `settings_view.dart`, `firebase_auth_service.dart` |
| F14-03 | Bildirim ayarları (açık/kapalı, saat) | `settings_view.dart`, `settings_bloc.dart` |
| F14-04 | Uygulama hakkında bölümü (versiyon, lisanslar, gizlilik) | `settings_view.dart` |
| F14-05 | Veri yönetimi (önbellek temizle) | `settings_view.dart` |
| F14-06 | Destek / Geri bildirim linki | `settings_view.dart` |
| F14-07 | Profesyonel gruplandırılmış UI (sections) | `settings_view.dart` |

**Test Kriterleri:**
- Uygulama dili değiştirilince tüm metinler güncellenir
- Hesap silme re-auth ister, sonra tüm veriler temizlenir
- Bildirim saati seçilebilir

---

### FAZ 15 — Firebase Kelime Verisi Migration (Sorun 6)
**Öncelik:** 🟠 Yüksek (APK boyutu etkisi)

| ID | Görev | Dosya |
|----|-------|-------|
| F15-01 | Firestore'a kelime verisi yükleme scripti | 🆕 `scripts/upload_words_to_firestore.dart` |
| F15-02 | `WordSyncService` — Firestore → Drift dil filtreli indirme | 🆕 `word_sync_service.dart` |
| F15-03 | `words_table.dart` schema v2 (sourceLang, targetLang) | `words_table.dart` |
| F15-04 | `app_database.dart` migration v1 → v2 | `app_database.dart` |
| F15-05 | `dataset_service.dart` → `WordSyncService` dönüşümü | `dataset_service.dart` |
| F15-06 | `splash_bloc.dart` → İlk indirme progress UI | `splash_bloc.dart`, `splash_view.dart` |
| F15-07 | Dil değişikliğinde ek kelime verisi indirme | `settings_bloc.dart` |
| F15-08 | `pubspec.yaml` → `assets/data/words.json` kaldır | `pubspec.yaml` |
| F15-09 | Leaderboard dil çifti bazlı ayrım | `leaderboard_service.dart` |
| F15-10 | `injection_container.dart` → `WordSyncService` register | `injection_container.dart` |

**Test Kriterleri:**
- İlk açılışta kelimeler Firestore'dan indirilir (progress bar)
- Sadece ana dil + hedef dil verisi indirilir
- Dil değişikliğinde yeni dil verisi eklenir
- Mevcut progress verisi bozulmaz (migration test)
- APK boyutu küçülür

---

### FAZ 16 — İstatistik Doğruluğu Entegrasyon Testi
**Öncelik:** 🔴 Kritik

| ID | Görev | Dosya |
|----|-------|-------|
| F16-01 | MCQ doğru/yanlış → wasCorrect doğru kaydediliyor mu | Integration test |
| F16-02 | Rating → FSRS scheduling doğru çalışıyor mu | Unit test |
| F16-03 | Dashboard istatistikleri review_events ile tutarlı mı | Integration test |
| F16-04 | Profil yüzdeleri doğru hesaplanıyor mu | Unit test |
| F16-05 | Leaderboard dil çifti bazlı doğru sıralıyor mu | Integration test |
| F16-06 | Heatmap verisi gün bazlı doğru mu | Integration test |

---

### FAZ 17 — UI/UX Son Cilalama
**Öncelik:** 🟡 Düşük

| ID | Görev |
|----|-------|
| F17-01 | Tüm ekranlarda Midnight Sapphire teması tutarlılık kontrolü |
| F17-02 | Dark mode tüm yeni widget'larda test |
| F17-03 | Animasyon tutarlılığı (fade, slide, scale) |
| F17-04 | Responsive test (küçük/büyük ekran) |
| F17-05 | Accessibility (contrast ratio, font scaling) |

---

### FAZ 18 — Performans ve Son Doğrulama
**Öncelik:** 🟡 Düşük

| ID | Görev |
|----|-------|
| F18-01 | Firebase indirme performansı (10k kelime < 5sn) |
| F18-02 | Dashboard yüklenme süresi (heatmap 365 gün < 500ms) |
| F18-03 | Quiz geçiş animasyonu (< 300ms) |
| F18-04 | Memory leak testi (uzun session) |
| F18-05 | APK boyutu karşılaştırması (words.json öncesi/sonrası) |

---

## 5. UYGULAMA DETAYLARI

### 5.1 Quiz Yeni UX Akışı (FAZ 9) — Detaylı Wireframe

```
┌─────────────────────────────────────┐
│  ← Çık    3/20 ████████░░░  🔊 🔇  │  ← AppBar (progress + ses toggle)
├─────────────────────────────────────┤
│                                     │
│         📝 Tekrar · MCQ             │  ← Kart tipi + mod badge
│                                     │
│     ┌───────────────────────┐       │
│     │                       │       │
│     │      "about"          │       │  ← Hedef dil kelimesi (büyük font)
│     │   /əˈbaʊt/            │       │  ← Transkripsiyon
│     │   🔊 preposition      │       │  ← TTS butonu + part of speech
│     │                       │       │
│     └───────────────────────┘       │
│                                     │
│  ┌─ A) yaklaşık ──────────────┐     │  ← Şık (answered: ✅ yeşil)
│  ├─ B) hakkında ──────────────┤     │  ← Şık (answered: seçilmemiş)
│  ├─ C) sonra ─────────────────┤     │  ← Şık (answered: seçilmemiş)
│  └─ D) ile ───────────────────┘     │  ← Şık (answered: seçilmemiş)
│                                     │
│ ─────── Cevap Sonrası Bölüm ────── │  ← Sadece answered phase'de görünür
│                                     │
│  📖 Anlam: Bir konu üzerine;       │
│     ilgili olarak.                  │
│                                     │
│  💬 Örnek Cümleler          [▼]    │  ← Genişleyebilir
│  ┌ 🌱 This is a book about...    ┐ │
│  │ 🌿 We were talking about...   │ │
│  └ 🌳 The documentary raises...  ┘ │
│                                     │
│  Bu kelimeyi ne kadar hatırladın?   │
│  ┌──────┬──────┬──────┬──────┐     │
│  │ Çok  │ Zor  │ İyi  │Kolay │     │
│  │ Zor  │      │  ✓   │      │     │
│  └──────┴──────┴──────┴──────┘     │
│                                     │
│  ⚡ +10 XP · 3 gün sonra           │  ← Rating seçilince toast
│                                     │
├─────────────────────────────────────┤
│  🔥 5 seri                          │  ← Session status bar
└─────────────────────────────────────┘
```

### 5.2 Dashboard Yeni Layout (FAZ 12) — Detaylı Wireframe

```
┌─────────────────────────────────────┐
│  Günaydın, Mete! 👋         [↻]   │  ← Hero header
├─────────────────────────────────────┤
│  🔥 12   ⭐ 1.2k   📈 45          │  ← Quick stats (streak, XP, hafta)
├─────────────────────────────────────┤
│                                     │
│  ☀ Bugün                            │
│  ┌─────────────────────────────┐   │
│  │ 23 soru │ 20 ✓ │ 3 ✗ │ 8dk│   │  ← Bugün detay kartı
│  │ MCQ: 15  Listen: 5  Speak:3│   │
│  └─────────────────────────────┘   │
│                                     │
│  📊 Aktivite Haritası               │
│  ┌─────────────────────────────┐   │
│  │ Pzt ░░▓▓░░▓█░░▓▓▓░░▓█▓░░ │   │  ← GitHub heatmap
│  │ Sal ░▓▓░░▓█░░░▓▓░░▓█▓▓░░ │   │     26 hafta × 7 gün
│  │ Çar ░░▓░░░▓░░▓▓█░░▓▓█▓░░ │   │     Renk: boş → açık → koyu
│  │ Per ░▓▓▓░▓█░░▓▓▓░░▓█▓▓░░ │   │
│  │ Cum ░░▓░░░▓░░░▓░░░░▓▓░░░ │   │
│  │ Cmt ░░░░░░░░░░░░░░░░░░░░ │   │
│  │ Paz ░░░░░░░░░░▓░░░░░░░░░ │   │
│  └─────────────────────────────┘   │
│                                     │
│  💡 Koç: 3 zor kelimen var —       │  ← Akıllı koç
│     bugün onlara odaklan            │
│                                     │
│  📅 Bu Hafta                        │
│  ┌─────────────────────────────┐   │
│  │ 85 soru │ %87 │ 32dk │ 12▫│   │
│  └─────────────────────────────┘   │
│                                     │
│  📆 Aylık Arşiv                     │
│  ┌─ Şubat 2026 ────────── [▼] ─┐  │
│  │ Mart 2026               [▼] │  │
│  └──────────────────────────────┘  │
│                                     │
└─────────────────────────────────────┘
```

### 5.3 Kategori Filtreleme Yeni UI (FAZ 11)

```
┌─────────────────────────────────────┐
│ 🌱A1  🌿A2  🌳B1  🏔B2  ⭐C1  💎C2│  ← Seviye chip bar (yatay scroll)
│                                     │
│ [📚 Oxford] [💼 İş] [+ Alan Seç]  │  ← Seçili alanlar + ekle butonu
└─────────────────────────────────────┘

        ┌── Alan Kategorileri ──────┐
        │                           │  ← Bottom Sheet
        │  💼 İş         💰 Finans │
        │  ⚙️ Mühendis.  ✈️ Turizm│
        │  💻 Yazılım    ⚖️ Hukuk │
        │  📢 Pazarlama  🏥 Tıp   │
        │  📚 Oxford     🔬 Bilim │
        │                           │
        │      [ Uygula ]           │
        └───────────────────────────┘
```

---

## 6. RİSK ANALİZİ

| Risk | Olasılık | Etki | Azaltma |
|------|----------|------|---------|
| FSRS scheduling bozulması (S8g) | Orta | 🔴 Kritik | isCorrect ve rating kesinlikle ayrılacak, unit test |
| Drift schema migration hatası (S6) | Düşük | 🔴 Kritik | Migration testi + rollback stratejisi |
| Firebase indirme süresi (S6) | Orta | 🟡 Orta | Chunk indirme + progress UI |
| Dashboard performans (S3 heatmap) | Düşük | 🟡 Orta | Veri cache + lazy loading |
| Mevcut progress veri kaybı (S6) | Düşük | 🔴 Kritik | Migration öncesi backup, test |

**Geri Dönüş Planı:**
- Her faz kendi branch'inde geliştirilir
- Faz merge öncesi tüm testler geçmeli
- Drift migration geri alınamazsa eski `schemaVersion` backup'ı tutulur
- Firebase kelime indirmesi başarısızsa lokal words.json fallback korunur (geçiş dönemi)

---

## 7. TEST MATRİSİ

| Faz | Unit Test | Integration Test | Manuel Test |
|-----|-----------|-----------------|-------------|
| F9 (Quiz) | isCorrect ayrımı, XP hesabı | MCQ→Rating→Submit→DB | Tam quiz akışı, TTS |
| F10 (Goal) | Soft cap mantığı | Plan → hedef → devam | UX akışı |
| F11 (Kategori) | Filtre SQL doğruluğu | Filtre → Plan | UI etkileşimi |
| F12 (Dashboard) | Heatmap veri oluşturma | DAO → BLoC → UI | Görsel doğruluk |
| F13 (Profil) | Yüzde hesabı | Auth → Profil UI | Paylaşım, scroll |
| F14 (Ayarlar) | — | Dil değişikliği, hesap silme | Tüm akışlar |
| F15 (Firebase) | Schema migration | Download → Drift → Query | İlk açılış, dil değişikliği |
| F16 (Entegrasyon) | — | Uçtan uca | Tüm metrikler |

---

## ÖNCELİK SIRASI ÖZETİ

```
FAZ 9  → Quiz UX (Sorun 8)         🔴 Çekirdek deneyim
FAZ 10 → Günlük Hedef (Sorun 1,7)  🟠 Kullanıcı engeli kaldır
FAZ 11 → Kategori Filtre (Sorun 5) 🟡 UX iyileştirme
FAZ 12 → Dashboard (Sorun 3,4)     🟠 Analitik temeli
FAZ 13 → Profil (Sorun 2,9)        🟡 Tutarlılık
FAZ 14 → Ayarlar (Sorun 10)        🟡 Profesyonellik
FAZ 15 → Firebase Kelime (Sorun 6) 🟠 Optimizasyon
FAZ 16 → Entegrasyon Testi         🔴 Kalite güvencesi
FAZ 17 → UI Son Cilalama           🟡 Polish
FAZ 18 → Performans                🟡 Optimizasyon
```

---

*ProVocabAI Restorasyon Planı v1.0*  
*Hazırlayan: Claude (Kıdemli Yazılım Mimarı)*  
*Tarih: 2 Mart 2026*  
*Kaynak Analiz: 35+ dosya incelendi*
