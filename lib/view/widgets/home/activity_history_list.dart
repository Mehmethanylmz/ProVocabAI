import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../viewmodel/home_viewmodel.dart';
import '../../../../core/extensions/responsive_extension.dart';

class ActivityHistoryList extends StatefulWidget {
  const ActivityHistoryList({super.key});

  @override
  State<ActivityHistoryList> createState() => _ActivityHistoryListState();
}

class _ActivityHistoryListState extends State<ActivityHistoryList> {
  String? _selectedMonth;
  String? _selectedWeek;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeViewModel>();
    final monthlyActivity = provider.monthlyActivity;

    if (provider.isLoading && monthlyActivity.isEmpty) {
      return _buildLoadingState(context);
    }

    if (monthlyActivity.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      children: [
        _buildMonthSelector(monthlyActivity, context),
        SizedBox(height: context.mediumValue),
        if (_selectedMonth != null)
          _buildMonthDetail(context, provider, _selectedMonth!),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Container(
      height: context.value(mobile: 200, tablet: 250),
      decoration: BoxDecoration(
        gradient:
            LinearGradient(colors: [Colors.blue[50]!, Colors.purple[50]!]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(child: CircularProgressIndicator()),
    ).animate().fadeIn();
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: context.paddingHigh,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.history_toggle_off,
              size: context.value(mobile: 60, tablet: 80),
              color: Colors.grey[300]),
          SizedBox(height: context.mediumValue),
          Text(
            'Henüz Aktivite Yok',
            style: GoogleFonts.poppins(
                fontSize: context.fontMedium,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800]),
          ),
          SizedBox(height: context.normalValue),
          Text(
            'Test çözdükçe geçmişin burada görünecek.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
                color: Colors.grey[600], fontSize: context.fontNormal),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector(
      List<Map<String, dynamic>> monthlyActivity, BuildContext context) {
    if (_selectedMonth == null && monthlyActivity.isNotEmpty) {
      _selectedMonth = monthlyActivity.first['monthYear'] as String;
    }

    return SizedBox(
      height: context.value(mobile: 110, tablet: 140),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: monthlyActivity.length,
        padding: context.paddingHorizontalMedium,
        itemBuilder: (context, index) {
          final monthData = monthlyActivity[index];
          final isSelected = _selectedMonth == monthData['monthYear'];
          return _buildMonthChip(monthData, isSelected, context);
        },
      ),
    );
  }

  Widget _buildMonthChip(
      Map<String, dynamic> monthData, bool isSelected, BuildContext context) {
    final parts = (monthData['monthYear'] as String).split('-');
    final monthName = _getMonthName(parts[1]);
    final year = parts[0];
    final total = (monthData['total'] as int?) ?? 0;
    final correct = (monthData['correct'] as int?) ?? 0;
    final successRate = total > 0 ? (correct / total * 100) : 0.0;

    final gradients = [
      [const Color(0xFF667eea), const Color(0xFF764ba2)],
      [const Color(0xFF11998e), const Color(0xFF38ef7d)],
      [const Color(0xFFF093FB), const Color(0xFFF5576C)],
      [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
    ];
    final gradient = gradients[int.parse(parts[1]) % gradients.length];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.lowValue),
      child: InkWell(
        onTap: () => setState(() {
          _selectedMonth = monthData['monthYear'];
          _selectedWeek = null;
        }),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: context.value(mobile: 130, tablet: 160),
          padding: context.paddingMedium,
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(colors: gradient)
                : LinearGradient(colors: [Colors.white, Colors.grey[50]!]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : gradient[0].withOpacity(0.3),
                width: 2),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: gradient[0].withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6))
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(monthName,
                  style: GoogleFonts.poppins(
                      fontSize: context.fontNormal,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : gradient[0])),
              Text(year,
                  style: GoogleFonts.poppins(
                      fontSize: context.fontSmall,
                      color: isSelected
                          ? Colors.white.withOpacity(0.9)
                          : Colors.grey[600])),
              SizedBox(height: context.normalValue),
              Text('%${successRate.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                      fontSize: context.fontLarge,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : gradient[0])),
            ],
          ),
        ),
      ),
    ).animate().scale(duration: 300.ms);
  }

  Widget _buildMonthDetail(
      BuildContext context, HomeViewModel provider, String monthYear) {
    final weeklyData = provider.getWeeklyActivity(monthYear);

    final monthData = provider.monthlyActivity.firstWhere(
      (m) => m['monthYear'] == monthYear,
      orElse: () => {'total': 0, 'correct': 0},
    );

    final total = (monthData['total'] as int?) ?? 0;
    final correct = (monthData['correct'] as int?) ?? 0;
    final wrong = total - correct;
    final successRate = total > 0 ? (correct / total * 100) : 0.0;

    return Column(
      children: [
        Container(
          padding: context.paddingMedium,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8))
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                  "Toplam", "$total", Icons.quiz, Colors.blue, context),
              _buildStatItem("Doğru", "$correct", Icons.check_circle,
                  Colors.green, context),
              _buildStatItem(
                  "Yanlış", "$wrong", Icons.cancel, Colors.red, context),
              _buildStatItem("Oran", "%${successRate.toStringAsFixed(0)}",
                  Icons.percent, Colors.purple, context),
            ],
          ),
        ),
        SizedBox(height: context.mediumValue),
        if (weeklyData.isNotEmpty)
          _buildWeekSelector(weeklyData, monthYear, context),
        SizedBox(height: context.mediumValue),
        if (_selectedWeek != null)
          _buildWeekDetail(context, provider, _selectedWeek!, monthYear),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color,
      BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: context.iconNormal),
        SizedBox(height: context.lowValue),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: context.fontMedium,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
              fontSize: context.fontSmall, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildWeekSelector(List<Map<String, dynamic>> weeklyData,
      String monthYear, BuildContext context) {
    if (_selectedWeek == null && weeklyData.isNotEmpty) {
      _selectedWeek = weeklyData.first['weekOfYear'] as String;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
              left: context.lowValue, bottom: context.normalValue),
          child: Text(
            'Haftalık Performans',
            style: GoogleFonts.poppins(
                fontSize: context.fontMedium,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800]),
          ),
        ),
        SizedBox(
          height: context.value(mobile: 90, tablet: 110),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: weeklyData.length,
            padding: context.paddingHorizontalMedium,
            itemBuilder: (context, index) {
              final weekData = weeklyData[index];
              final isSelected = _selectedWeek == weekData['weekOfYear'];
              return _buildWeekChip(weekData, isSelected, context);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWeekChip(
      Map<String, dynamic> weekData, bool isSelected, BuildContext context) {
    final weekOfYear = weekData['weekOfYear'] as String;
    final total = (weekData['total'] as int?) ?? 0;
    final weekStartDate = DateTime.fromMillisecondsSinceEpoch(
        ((weekData['weekStartDate'] as int?) ?? 0) * 1000);
    final weekNumber = (weekStartDate.day / 7).ceil();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.lowValue),
      child: InkWell(
        onTap: () => setState(() => _selectedWeek = weekOfYear),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: context.value(mobile: 90, tablet: 110),
          padding: context.paddingNormal,
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue[600] : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: Colors.blue.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4))
                  ]
                : null,
            border: Border.all(
                color: isSelected ? Colors.transparent : Colors.grey[300]!),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Hafta $weekNumber',
                  style: GoogleFonts.poppins(
                      fontSize: context.fontSmall,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.grey[800])),
              SizedBox(height: context.lowValue),
              Text('$total Soru',
                  style: GoogleFonts.poppins(
                      fontSize: context.fontSmall - 1,
                      color: isSelected
                          ? Colors.white.withOpacity(0.9)
                          : Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeekDetail(BuildContext context, HomeViewModel provider,
      String weekOfYear, String monthYear) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: provider.getDailyStats(weekOfYear, monthYear.split('-')[0]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
              child: Padding(
                  padding: context.paddingMedium,
                  child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox();
        }

        final dailyStats = snapshot.data!;
        int weekTotal = 0;
        int weekCorrect = 0;
        for (var day in dailyStats) {
          weekTotal += (day['total'] as int? ?? 0);
          weekCorrect += (day['correct'] as int? ?? 0);
        }
        int weekWrong = weekTotal - weekCorrect;
        double weekSuccessRate =
            weekTotal > 0 ? (weekCorrect / weekTotal * 100) : 0.0;

        return Container(
          padding: context.paddingMedium,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey[100]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: context.paddingMedium,
                margin: EdgeInsets.only(bottom: context.mediumValue),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem("Toplam", "$weekTotal", Icons.quiz,
                        Colors.blue, context),
                    _buildStatItem("Doğru", "$weekCorrect", Icons.check_circle,
                        Colors.green, context),
                    _buildStatItem("Yanlış", "$weekWrong", Icons.cancel,
                        Colors.red, context),
                    _buildStatItem(
                        "Oran",
                        "%${weekSuccessRate.toStringAsFixed(0)}",
                        Icons.percent,
                        Colors.purple,
                        context),
                  ],
                ),
              ),
              Text('Günlük Detay',
                  style: GoogleFonts.poppins(
                      fontSize: context.fontMedium,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: context.mediumValue),
              ...dailyStats.map((dayData) => _buildDayRow(dayData, context)),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
      },
    );
  }

  Widget _buildDayRow(Map<String, dynamic> dayData, BuildContext context) {
    final date = DateTime.fromMillisecondsSinceEpoch(
        ((dayData['date'] as int?) ?? 0) * 1000);
    final total = (dayData['total'] as int?) ?? 0;
    final correct = (dayData['correct'] as int?) ?? 0;
    final wrong = total - correct;
    final successRate = total > 0 ? (correct / total * 100) : 0.0;

    return Padding(
      padding: EdgeInsets.only(bottom: context.normalValue),
      child: Row(
        children: [
          Container(
            width: context.value(mobile: 40, tablet: 48),
            height: context.value(mobile: 40, tablet: 48),
            decoration: BoxDecoration(
              color: _getSuccessColor(successRate).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text("${date.day}",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getSuccessColor(successRate))),
            ),
          ),
          SizedBox(width: context.normalValue),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_getDayName(date.weekday),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: context.fontNormal)),
                SizedBox(height: context.lowValue),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: context.lowValue, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(4)),
                      child: Row(
                        children: [
                          Icon(Icons.quiz,
                              size: context.fontSmall, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text("$total",
                              style: TextStyle(
                                  fontSize: context.fontSmall - 1,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue)),
                        ],
                      ),
                    ),
                    SizedBox(width: context.normalValue),
                    Icon(Icons.check_circle,
                        size: context.fontSmall, color: Colors.green),
                    const SizedBox(width: 2),
                    Text("$correct",
                        style: TextStyle(
                            color: Colors.green,
                            fontSize: context.fontSmall,
                            fontWeight: FontWeight.bold)),
                    SizedBox(width: context.normalValue),
                    Icon(Icons.cancel,
                        size: context.fontSmall, color: Colors.red),
                    const SizedBox(width: 2),
                    Text("$wrong",
                        style: TextStyle(
                            color: Colors.red,
                            fontSize: context.fontSmall,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          Text("%${successRate.toStringAsFixed(0)}",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: context.fontMedium,
                  color: _getSuccessColor(successRate))),
        ],
      ),
    );
  }

  Color _getSuccessColor(double rate) {
    if (rate >= 80) return Colors.green;
    if (rate >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getMonthName(String monthNum) {
    const monthNames = {
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
      '12': 'Aralık'
    };
    return monthNames[monthNum] ?? monthNum;
  }

  String _getDayName(int weekday) {
    const dayNames = {
      1: 'Pazartesi',
      2: 'Salı',
      3: 'Çarşamba',
      4: 'Perşembe',
      5: 'Cuma',
      6: 'Cumartesi',
      7: 'Pazar'
    };
    return dayNames[weekday] ?? '';
  }
}
