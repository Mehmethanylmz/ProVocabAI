// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/word_provider.dart';
import 'learning_screen.dart'; // YENİ EKRANIMIZI BURAYA EKLE

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // WordProvider'ı dinle
    return Consumer<WordProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(title: Text('Kelime Ezberleme')),
          body: provider.isLoading
              ? Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Öğrenilecek ${provider.unlearnedCount} kelime kaldı.',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      SizedBox(height: 40),
                      Text('Günlük kaç kelime öğrenmek istersin?'),
                      Slider(
                        value: provider.batchSize.toDouble(),
                        min: 10,
                        max: 100,
                        divisions: 9,
                        label: provider.batchSize.toString(),
                        onChanged: (double value) {
                          provider.updateBatchSize(value.toInt());
                        },
                      ),
                      SizedBox(height: 40),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 50,
                            vertical: 15,
                          ),
                        ),
                        child: Text(
                          'Öğrenmeye Başla',
                          style: TextStyle(fontSize: 18),
                        ),
                        onPressed: provider.unlearnedCount == 0
                            ? null // Eğer öğrenilecek kelime kalmadıysa butonu pasif yap
                            : () async {
                                // 1. Yeni kelime grubunu alması için Provider'ı tetikle
                                await provider.fetchNewBatch();

                                // 2. Provider'ın listeyi doldurduğundan emin ol
                                if (provider.currentBatch.isNotEmpty &&
                                    context.mounted) {
                                  // 3. Yeni Öğrenme Ekranı'na git
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LearningScreen(),
                                    ),
                                  );
                                }
                              },
                      ),
                      SizedBox(height: 20),

                      // -- ÖĞRENME EKRANI (DEMO) --
                      // Bu kısmı ayrı bir 'LearningScreen' widget'ına taşımalısın
                      if (provider.currentBatch.isNotEmpty)
                        Expanded(
                          child: Card(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    provider
                                        .currentBatch[0]
                                        .en, // Şimdilik sadece ilk kelimeyi göster
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineMedium,
                                  ),
                                  TextButton(
                                    child: Text('Anlamı Göster'),
                                    onPressed: () {
                                      // TODO: Cevabı göster
                                    },
                                  ),
                                  TextButton(
                                    child: Text('Bu Grubu Bitirdim'),
                                    onPressed: () {
                                      provider.completeCurrentBatch();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
