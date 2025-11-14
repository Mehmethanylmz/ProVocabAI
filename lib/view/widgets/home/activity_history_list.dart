import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodel/home_viewmodel.dart';
import '../../screens/week_detail_screen.dart';

class ActivityHistoryList extends StatelessWidget {
  const ActivityHistoryList({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeViewModel>();
    final monthlyActivity = provider.monthlyActivity;

    if (provider.isLoading && monthlyActivity.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }

    if (monthlyActivity.isEmpty) {
      return Center(child: Text('Henüz hiç test çözülmemiş.'));
    }

    final monthNames = {
      '01': 'Ocak',
      '02': 'Şubat',
      '03': 'Mart',
      '04': 'Nisan',
      '05': 'Mayıs',
      '06': 'Haziran',
      '07': 'Temmuz',
      '08': 'Ağustos',
      '09': 'Eylül',
      '10': 'Ekim',
      '11': 'Kasım',
      '12': 'Aralık',
    };

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: monthlyActivity.length,
        itemBuilder: (context, index) {
          final monthData = monthlyActivity[index];
          final String monthYear = monthData['monthYear'] as String;
          final int total = monthData['total'] as int;
          final int correct = monthData['correct'] as int;
          final int wrong = total - correct;

          final parts = monthYear.split('-');
          final String title = "${monthNames[parts[1]]} ${parts[0]}";
          final String subtitle = "S: $total 🧠 D: $correct ✅ Y: $wrong ❌";

          final weeklyData = provider.getWeeklyActivity(monthYear);
          final progressData = provider.getMonthlyProgress(monthYear);

          return ExpansionTile(
            key: PageStorageKey(monthYear),
            title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[700])),
            leading: Icon(Icons.calendar_month, color: Colors.blue[700]),
            children: [
              ...weeklyData.map((week) {
                return _buildWeekTile(context, week, parts[0]);
              }).toList(),
              _buildMonthSummary(progressData),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWeekTile(
    BuildContext context,
    Map<String, dynamic> weekData,
    String year,
  ) {
    final String weekOfYear = weekData['weekOfYear'] as String;
    final int total = weekData['total'] as int;
    final int correct = weekData['correct'] as int;
    final int wrong = total - correct;

    final weekStartDate = DateTime.fromMillisecondsSinceEpoch(
      (weekData['weekStartDate'] as int) * 1000,
    );
    final weekNumber = (weekStartDate.day / 7).ceil();

    final String title = "$weekNumber. Hafta";
    final String subtitle = "S: $total D: $correct Y: $wrong";

    return Material(
      color: Colors.blue.withOpacity(0.05),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        leading: SizedBox(width: 8),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WeekDetailScreen(
                weekOfYear: weekOfYear,
                year: year,
                title: "$title ($year)",
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthSummary(Map<String, dynamic> progressData) {
    if (progressData.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'Bu ay için ilerleme özeti yakında hesaplanacak.',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      );
    }

    final start = progressData['start'] as Map<String, dynamic>;
    final end = progressData['end'] as Map<String, dynamic>;

    final strugglingChange =
        (end['struggling'] as int) - (start['struggling'] as int);
    final expertChange = (end['expert'] as int) - (start['expert'] as int);

    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aylık İlerleme Özeti',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 8),
          _buildProgressRow(
            'Zorlanılan Kelimeler:',
            strugglingChange,
            isBad: true,
          ),
          _buildProgressRow('Uzman Kelimeler:', expertChange),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, int change, {bool isBad = false}) {
    String changeText;
    Color changeColor;
    IconData icon;

    if (change > 0) {
      changeText = "+$change";
      changeColor = isBad ? Colors.red[700]! : Colors.green[700]!;
      icon = isBad ? Icons.arrow_upward : Icons.arrow_upward;
    } else if (change < 0) {
      changeText = "$change";
      changeColor = isBad ? Colors.green[700]! : Colors.red[700]!;
      icon = isBad ? Icons.arrow_downward : Icons.arrow_downward;
    } else {
      changeText = "Değişim Yok";
      changeColor = Colors.grey[700]!;
      icon = Icons.remove;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14)),
        Row(
          children: [
            Icon(icon, color: changeColor, size: 18),
            SizedBox(width: 4),
            Text(
              changeText,
              style: TextStyle(
                color: changeColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
