import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/word_provider.dart';
import 'learning_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WordProvider>(context);
    final stats = provider.stats;
    final theme = Theme.of(context);
    final Widget learnButton = ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF50E3C2),
        padding: EdgeInsets.symmetric(vertical: 20),
        textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      onPressed: (provider.unlearnedCount == 0 && provider.currentBatch.isEmpty)
          ? null
          : () async {
              if (provider.currentBatch.isEmpty) {
                await provider.fetchNewBatch();
              }
              if (provider.currentBatch.isNotEmpty && context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LearningScreen()),
                );
              }
            },
      child: Text(
        provider.currentBatch.isNotEmpty
            ? 'Öğrenmeye Devam Et (${provider.currentBatch.length} Kelime)'
            : 'Bugünkü ${provider.batchSize} Kelimeyi Öğren',
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: theme.scaffoldBackgroundColor,
              elevation: 0,
              actions: [
                IconButton(
                  icon: Icon(Icons.settings_outlined, color: Colors.grey[700]),
                  tooltip: 'Ayarlar',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingsScreen()),
                    );
                  },
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                title: Text(
                  'Hoş Geldin!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
              ),
              toolbarHeight: 80,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 30),
                child: learnButton,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Genel Durum',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(24.0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.2,
                ),
                delegate: SliverChildListDelegate([
                  _buildStatCard(
                    context,
                    title: 'Bugün Öğrenilen',
                    value: stats?.wordsLearnedToday.toString() ?? '0',
                    icon: Icons.today,
                    color: Colors.blue,
                  ),
                  _buildStatCard(
                    context,
                    title: 'Genel Başarı',
                    value:
                        '%${stats?.overallSuccessRate.toStringAsFixed(0) ?? '0'}',
                    icon: Icons.star,
                    color: Colors.orange,
                  ),
                  _buildStatCard(
                    context,
                    title: 'Toplam Öğrenilen',
                    value: stats?.totalLearnedWords.toString() ?? '0',
                    icon: Icons.school,
                    color: Colors.green,
                  ),
                  _buildStatCard(
                    context,
                    title: 'Kalan Kelime',
                    value: provider.unlearnedCount.toString(),
                    icon: Icons.inventory_2,
                    color: Colors.red,
                  ),
                ]),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 16.0),
                child: Text(
                  'Haftalık Aktivite',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildWeeklyChart(context, provider.weeklyEffort),
            ),

            SliverToBoxAdapter(child: SizedBox(height: 30)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            foregroundColor: color,
            radius: 20,
            child: Icon(icon, size: 22),
          ),
          Spacer(),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(BuildContext context, List<int> weeklyEffort) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    if (weeklyEffort.isEmpty || weeklyEffort.every((count) => count == 0)) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Text(
          'Bu hafta hiç kelime çalışmadın.',
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
      );
    }
    double maxY = (weeklyEffort.reduce((a, b) => a > b ? a : b) * 1.2);
    if (maxY < 10) maxY = 10;

    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          maxY: maxY,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => Colors.grey[700]!,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${rod.toY.round()} kelime',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  Widget child;
                  if (value == 0 || value == maxY / 2 || value == maxY) {
                    child = Text(
                      value.round().toString(),
                      style: TextStyle(color: Colors.grey[600], fontSize: 10),
                    );
                  } else {
                    child = Text('');
                  }
                  return SideTitleWidget(meta: meta, child: child);
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const labels = [
                    'Pzt',
                    'Sal',
                    'Çrş',
                    'Per',
                    'Cum',
                    'Cmt',
                    'Paz',
                  ];
                  final todayWeekday = DateTime.now().weekday - 1;
                  final dayIndex = (todayWeekday - 6 + value.toInt()) % 7;

                  final Widget text = Text(
                    labels[dayIndex < 0 ? dayIndex + 7 : dayIndex],
                    style: TextStyle(color: Colors.grey[800], fontSize: 12),
                  );

                  return SideTitleWidget(meta: meta, child: text);
                },
              ),
            ),
          ),

          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) {
              return FlLine(color: Colors.grey[200]!, strokeWidth: 1);
            },
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(7, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: weeklyEffort[index].toDouble(),
                  color: primaryColor,
                  width: 16,
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
