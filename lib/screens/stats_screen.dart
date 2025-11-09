// C:\Users\Mete\Desktop\englishwordsapp\pratikapp\lib\screens\stats_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/detailed_stats.dart';
import '../providers/word_provider.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WordProvider>(context, listen: false).fetchDetailedStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('İstatistik Merkezi')),
      body: Consumer<WordProvider>(
        builder: (context, provider, child) {
          if (provider.isDetailedStatsLoading ||
              provider.detailedStats == null) {
            return Center(child: CircularProgressIndicator());
          }

          final stats = provider.detailedStats!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStreakCard(context, stats.dailyStreak),
                SizedBox(height: 20),
                _buildSectionTitle(context, 'Kelime Hazinesi'),
                _buildMasteryChart(context, stats.masteryDistribution),
                _buildHazineStats(context, stats.hazineStats),
                SizedBox(height: 20),
                _buildSectionTitle(context, 'Haftalık Başarı Grafiği'),
                _buildWeeklySuccessChart(context, stats.weeklySuccessChart),
                SizedBox(height: 20),
                _buildSectionTitle(context, 'Aktivite Dökümü'),
                _buildActivityTable(context, stats),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStreakCard(BuildContext context, int streak) {
    return Card(
      elevation: 4,
      color: Colors.orange[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_fire_department, color: Colors.orange, size: 40),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streak Günlük Seri',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Çalışmaya devam et!',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMasteryChart(
    BuildContext context,
    Map<String, int> distribution,
  ) {
    final List<PieChartSectionData> sections = [];
    final colors = {
      'Yeni': Colors.grey[300],
      'Öğreniliyor': Colors.blue[300],
      'Pekiştirilmiş': Colors.green[300],
      'Usta': Colors.purple[300],
      'Zor': Colors.red[300],
    };

    distribution.forEach((key, value) {
      if (value > 0) {
        sections.add(
          PieChartSectionData(
            value: value.toDouble(),
            title: '$value',
            color: colors[key],
            radius: 80,
            titleStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        );
      }
    });

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: AspectRatio(
                aspectRatio: 1,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: sections,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: distribution.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          color: colors[entry.key],
                        ),
                        SizedBox(width: 8),
                        Text(
                          '${entry.key} (${entry.value})',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHazineStats(BuildContext context, Map<String, int> hazineStats) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: hazineStats.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.key,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    entry.value.toString(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildWeeklySuccessChart(
    BuildContext context,
    List<ChartDataPoint> data,
  ) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16.0),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  Widget child;
                  if (value == 0 || value == 50 || value == 100) {
                    child = Text('%${value.toInt()}');
                  } else {
                    child = Text('');
                  }
                  return SideTitleWidget(meta: meta, child: child);
                },
                reservedSize: 30,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(data[value.toInt()].label),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(data.length, (index) {
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: data[index].value,
                  color: Colors.blueAccent,
                  width: 20,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildActivityTable(BuildContext context, DetailedStats stats) {
    return Card(
      elevation: 2,
      child: DataTable(
        columnSpacing: 20,
        columns: [
          DataColumn(
            label: Text(
              'Periyot',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text('Test', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          DataColumn(
            label: Text('Efor', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          DataColumn(
            label: Text(
              'Başarı',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
        rows: [
          _buildActivityRow('Bugün', stats.todayStats),
          _buildActivityRow('Bu Hafta', stats.weekStats),
          _buildActivityRow('Bu Ay', stats.monthStats),
          _buildActivityRow('Tüm Zamanlar', stats.allTimeStats),
        ],
      ),
    );
  }

  DataRow _buildActivityRow(String label, ActivityStats stats) {
    return DataRow(
      cells: [
        DataCell(Text(label)),
        DataCell(Text(stats.testCount.toString())),
        DataCell(Text(stats.totalEfor.toString())),
        DataCell(Text('%${stats.successRate.toStringAsFixed(0)}')),
      ],
    );
  }
}
