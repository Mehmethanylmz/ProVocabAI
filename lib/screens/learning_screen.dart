// lib/screens/learning_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/word_provider.dart';
import 'word_card_widget.dart';
import 'go_to_review_card.dart';

// 1. StatefulWidget'a dönüştür
class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  // 2. PageController'ı tanımla
  late PageController _pageController;
  int _currentPage = 0; // Hangi kelimede olduğumuzu takip etmek için
  late int _totalItems; // Kelime + 1 (Test kartı)

  @override
  void initState() {
    super.initState();
    // Provider'ı 'dinlemeden' al
    final provider = Provider.of<WordProvider>(context, listen: false);
    _totalItems = provider.currentBatch.length + 1;

    // 3. Controller'ı başlat
    _pageController = PageController();

    // Sayfa değişimlerini dinle
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!.round();
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose(); // Controller'ı temizle
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Provider'ı 'dinlemeden' alıyoruz çünkü liste zaten yüklendi.
    final provider = Provider.of<WordProvider>(context, listen: false);
    final wordBatch = provider.currentBatch;

    return Scaffold(
      appBar: AppBar(
        title: Text('Öğrenme Ekranı'),
        actions: [
          // "Grubu Bitir" butonu aynı kalıyor
          TextButton(
            onPressed: () {
              // ... (showDialog mantığı aynı)
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('Grubu Bitir'),
                  content: Text(
                    'Bu gruptaki kelimeleri öğrendiğinizi onaylıyor musunuz? (Testi bitirdikten sonra bunu yapmanız önerilir.)',
                  ),
                  actions: [
                    TextButton(
                      child: Text('İptal'),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                    ElevatedButton(
                      child: Text('Evet, Bitir'),
                      onPressed: () {
                        provider.completeCurrentBatch();
                        Navigator.of(ctx).pop();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              );
            },
            child: Text(
              'Grubu Bitir',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      // 4. PageView'i Stack ile sar
      body: Stack(
        children: [
          // 5. PageView'e controller'ı bağla
          PageView.builder(
            controller: _pageController,
            itemCount: _totalItems, // Kelime sayısı + "Test Et" kartı
            itemBuilder: (context, index) {
              if (index < wordBatch.length) {
                // Kelimeleri göster
                return WordCardWidget(
                  word: wordBatch[index],
                  progress: '${index + 1} / ${wordBatch.length}',
                );
              } else {
                // Son kart olarak "Test Et" kartını göster
                return GoToReviewCard();
              }
            },
          ),

          // 6. İLERİ ve GERİ Butonlarını Ekle
          _buildNavigationButtons(context, wordBatch.length),
        ],
      ),
    );
  }

  // 7. Butonları oluşturan yeni fonksiyon
  Widget _buildNavigationButtons(BuildContext context, int wordCount) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // GERİ BUTONU
            // Sadece ilk sayfada (index 0) değilsek göster
            if (_currentPage > 0)
              FloatingActionButton(
                heroTag: 'prev', // Hero tag çakışmasını önle
                onPressed: () {
                  _pageController.previousPage(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Icon(Icons.arrow_back),
              )
            else
              // İlk sayfadaysak, butonun yerini doldurmak için boş bir kutu
              SizedBox(width: 56),

            // İLERİ BUTONU
            // Sadece son sayfada (Test kartı) değilsek göster
            if (_currentPage < wordCount)
              FloatingActionButton(
                heroTag: 'next',
                onPressed: () {
                  _pageController.nextPage(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Icon(Icons.arrow_forward),
              )
            else
              // Son sayfadaysak boş bir kutu
              SizedBox(width: 56),
          ],
        ),
      ),
    );
  }
}
