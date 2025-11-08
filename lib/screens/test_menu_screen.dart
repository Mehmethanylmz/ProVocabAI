import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/word_provider.dart';
import 'review_screen.dart';

class TestMenuScreen extends StatefulWidget {
  const TestMenuScreen({super.key});

  @override
  State<TestMenuScreen> createState() => _TestMenuScreenState();
}

class _TestMenuScreenState extends State<TestMenuScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WordProvider>(context, listen: false).fetchBatchHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<WordProvider>(
          builder: (context, provider, child) {
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  elevation: 0,
                  centerTitle: false,
                  title: Text(
                    'Test Merkezi',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A90E2),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildTestCard(
                          context: context,
                          icon: Icons.bookmark,
                          title: 'Mevcut Etabı Test Et',
                          subtitle:
                              '${provider.currentBatch.length} kelime öğreniliyor',
                          color: Colors.blue,
                          onTap: () {
                            _startTest(
                              context,
                              testMode: 'current',
                              expectedCount: provider.currentBatch.length,
                            );
                          },
                        ),
                        SizedBox(height: 16),
                        _buildTestCard(
                          context: context,
                          icon: Icons.all_inclusive,
                          title: 'Tüm Öğrenilenleri Test Et',
                          subtitle: 'Tüm tamamlanan etaplar',
                          color: Colors.green,
                          onTap: () {
                            _startTest(context, testMode: 'all_learned');
                          },
                        ),
                        SizedBox(height: 16),
                        _buildTestCard(
                          context: context,
                          icon: Icons.shuffle,
                          title: 'Rastgele Test',
                          subtitle: 'İstediğin sayıda kelime seç',
                          color: Colors.orange,
                          onTap: () {
                            _showRandomTestDialog(context);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 16, 10),
                    child: Text(
                      'TAMAMLANAN ETAPLAR',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                if (provider.isLoading && provider.batchHistory.isEmpty)
                  SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (provider.batchHistory.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text('Henüz tamamlanmış bir etabın yok.'),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final batch = provider.batchHistory[index];

                      String bestScore =
                          batch.bestScore?.toStringAsFixed(0) ?? '-';
                      String lastScore =
                          batch.lastScore?.toStringAsFixed(0) ?? '-';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[200],
                          child: Text(
                            '${batch.batchId}',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          'Etap ${batch.batchId} (${batch.wordCount} kelime)',
                        ),
                        subtitle: Text(
                          'En İyi Skor: %$bestScore',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '%$lastScore',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Son Skor',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        onTap: () {
                          _startTest(
                            context,
                            testMode: 'specific_batch',
                            batchId: batch.batchId,
                            expectedCount: batch.wordCount,
                          );
                        },
                      );
                    }, childCount: provider.batchHistory.length),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTestCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              foregroundColor: color,
              radius: 24,
              child: Icon(icon, size: 28),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _startTest(
    BuildContext context, {
    required String testMode,
    int? batchId,
    int? randomCount,
    int expectedCount = 0,
  }) async {
    final provider = Provider.of<WordProvider>(context, listen: false);

    await provider.startReview(
      testMode: testMode,
      batchId: batchId,
      randomCount: randomCount,
    );

    if (provider.reviewQueue.isEmpty) {
      String message = "Test edilecek kelime bulunamadı!";
      if (testMode == 'current' && provider.currentBatch.isEmpty) {
        message = "Önce 'Öğrenmeye Başla' butonuna basarak bir grup almalısın.";
      } else if (testMode != 'current' && testMode != 'random_learned') {
        message = "Henüz 'öğrenildi' olarak işaretlenmiş hiç kelimen yok.";
      } else if (testMode == 'random_learned') {
        message = "Rastgele test için 'öğrenildi' kelimesi bulunamadı.";
      }

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
      return;
    }

    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ReviewScreen()),
      );
    }
  }

  void _showRandomTestDialog(BuildContext context) {
    final provider = Provider.of<WordProvider>(context, listen: false);
    final TextEditingController countController = TextEditingController(
      text: provider.batchSize.toString(),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Rastgele Test'),
        content: TextField(
          controller: countController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Kaç kelime test edilsin?'),
        ),
        actions: [
          TextButton(
            child: Text('İptal'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            child: Text('Başlat'),
            onPressed: () {
              final int count =
                  int.tryParse(countController.text) ?? provider.batchSize;
              Navigator.of(ctx).pop();
              _startTest(
                context,
                testMode: 'random_learned',
                randomCount: count,
              );
            },
          ),
        ],
      ),
    );
  }
}
